# -*- perl -*-

# 
use Test::More tests => 77;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::Hold;
use TaskForest::LocalTime;
use DateTime;
use Net::SMTP;

BEGIN {
    use_ok( 'TaskForest',               "Can use TaskForest" );
    use_ok( 'TaskForest::Family',       "Can use Family" );
    use_ok( 'TaskForest::LogDir',       "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle', "Can use StringHandle" );
    use_ok( 'TaskForest::Release',      "Can use Release" );
    use_ok( 'TaskForest::Hold',         "Can use Hold" );
}

my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/FAIL_RETRY", $dest_dir);

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 05,
                                   day   => 03,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });
                                       


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run_with_log";
$ENV{TF_LOG_DIR}     = "$cwd/t/logs";
$ENV{TF_JOB_DIR}     = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR}  = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";

if (-e "$cwd/t/jobs/TaskForest_foo") {
    `rm -f $cwd/t/jobs/TaskForest_foo`;
}

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}); 
&TaskForest::Test::cleanup_files($log_dir);
$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "America/Chicago");
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'FAIL_RETRY');

isa_ok($sf,  'TaskForest::Family',  'Created FAIL_RETRY family');
is($sf->{name},  'FAIL_RETRY',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $tf = TaskForest->new();
$tf->status();
my $stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["FAIL_RETRY", "J_Fail",  'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                   ]
    );


# start the smtp server.
ok(system("$cwd/blib/script/testSmtpServer 25252 $log_dir/smtp.txt") == 0, "Starting test SMTP server");


$tf->{options}->{once_only} = 1;

print "Running ready jobs\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/FAIL_RETRY.J_Fail.1"]), "After first cycle FAIL_RETRY::J_Fail has failed");

$sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["FAIL_RETRY", "J_Fail", 'Failure', '[1-9]+', "America/Chicago", "00:00", "..:..", "..:.."],
                                       ]
    );


# now read the log file.
my @file_names = glob("$log_dir/FAIL_RETRY.J_Fail*.stdout");

ok(scalar(@file_names) == 1, "Found one stdout file");

my $file_name = $file_names[0];
my $found = 0;
open (F, $file_name);
while (<F>) {
    if (/^!! Job failed.  Sleeping 2 seconds and then retrying \(retry \d+ of 3\)/) { 
        $found++;
    }
}
close F;
ok($found == 3, "Found 10 Fail strings in stdout file");


# turn off smtp server
my $smtp = Net::SMTP->new(
    Host      => 'localhost:25252',
    Timeout   => 10,
    );
ok($smtp, "Created smtp client");
ok($smtp->datasend("exit"), "Stopped SMTP Server");



my $emails = &TaskForest::Test::parseSMTPFile("$log_dir/smtp.txt");
is(scalar(@$emails), 4, "Got 4 emails");


foreach my $index (0..2) {
    my $n = $index + 1;
    is($emails->[$index]->{ehlo},         'user1@example.com',        "Msg $n - Got correct ehlo");
    is($emails->[$index]->{mail_from},    '<user1@example.com>',      "Msg $n - Got correct mail from");
    is($emails->[$index]->{rcpt_to},      '<test2@example.com>',      "Msg $n - Got correct rcpt_to");
    is($emails->[$index]->{from},         'user1@example.com',        "Msg $n - Got correct from");
    is($emails->[$index]->{return_path},  'user3@example.com',        "Msg $n - Got correct return_path");
    is($emails->[$index]->{reply_to},     'user2@example.com',        "Msg $n - Got correct reply-to");
    is($emails->[$index]->{to},           'test2@example.com',        "Msg $n - Got correct to");
    is($emails->[$index]->{subject},      'RETRY FAIL_RETRY::J_Fail', "Msg $n - Got correct subject");

    like($emails->[$index]->{body}->[4],  qr/The following job failed and will be rerun automatically/,                       "Msg $n - Got correct summary");
    like($emails->[$index]->{body}->[6],  qr/Family: +FAIL_RETRY/,                                                            "Msg $n - Got correct family");
    like($emails->[$index]->{body}->[7],  qr/Job: +J_Fail/,                                                                   "Msg $n - Got correct job");
    like($emails->[$index]->{body}->[9],  qr/Retry After: +2 seconds/,                                                        "Msg $n - Got correct sleep");
    like($emails->[$index]->{body}->[10], qr/No. of Retries: +$n of 3/,                                                        "Msg $n - Got correct num of retries");
    like($emails->[$index]->{body}->[13], qr/\-+/,                                                                            "Msg $n - Got footer dashes");
    like($emails->[$index]->{body}->[14], qr/For instructions on using TaskForest, please see http:\/\/www.taskforest.com\//, "Msg $n - Got footer");
}



is($emails->[3]->{ehlo},         'user1@example.com',       "Msg 4 - Got correct ehlo");
is($emails->[3]->{mail_from},    '<user1@example.com>',     "Msg 4 - Got correct mail from");
is($emails->[3]->{rcpt_to},      '<test@example.com>',      "Msg 4 - Got correct rcpt_to");
is($emails->[3]->{from},         'user1@example.com',       "Msg 4 - Got correct from");
is($emails->[3]->{return_path},  'user3@example.com',       "Msg 4 - Got correct return_path");
is($emails->[3]->{reply_to},     'user2@example.com',       "Msg 4 - Got correct reply-to");
is($emails->[3]->{to},           'test@example.com',        "Msg 4 - Got correct to");
is($emails->[3]->{subject},      'FAIL FAIL_RETRY::J_Fail', "Msg 4 - Got correct subject");

like($emails->[3]->{body}->[4],  qr/The following job has failed\./,                                                  "Msg 4 - Got correct summary");
like($emails->[3]->{body}->[6],  qr/Family: +FAIL/,                                                                   "Msg 4 - Got correct family");
like($emails->[3]->{body}->[7],  qr/Job: +J_Fail/,                                                                    "Msg 4 - Got correct job");
like($emails->[3]->{body}->[11], qr/\-+/,                                                                             "Msg 4 - Got footer dashes");
like($emails->[3]->{body}->[12], qr/For instructions on using TaskForest, please see http:\/\/www.taskforest.com\//,  "Msg 4 - Got footer");




&TaskForest::Test::cleanup_files($log_dir);
