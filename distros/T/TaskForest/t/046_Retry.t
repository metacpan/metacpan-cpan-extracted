# -*- perl -*-

# 
use Test::More tests => 52;
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

copy("$src_dir/RETRY", $dest_dir);

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

my $sf = TaskForest::Family->new(name=>'RETRY');

isa_ok($sf,  'TaskForest::Family',  'Created RETRY family');
is($sf->{name},  'RETRY',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $tf = TaskForest->new();
$tf->status();
my $stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["RETRY", "J1",              'Waiting', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["RETRY", "J3",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["RETRY", "J_Retry",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ]
    );





# start the smtp server.
ok(system("$cwd/blib/script/testSmtpServer 25252 $log_dir/smtp.txt") == 0, "Starting test SMTP server");

$tf->{options}->{once_only} = 1;

print "Running ready jobs\n";
$tf->runMainLoop();

$tf->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/RETRY.J_Retry.0"]), "After first cycle RETRY::J_Retry has run");

$sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["RETRY", "J1",              'Ready', "-", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["RETRY", "J3",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["RETRY", "J_Retry",         'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ]
    );


# now read the log file.
my @file_names = glob("$log_dir/RETRY.J_Retry*.stdout");

ok(scalar(@file_names) == 1, "Found one stdout file");

my $file_name = $file_names[0];
my $found = 0;
open (F, $file_name);
while (<F>) {
    if (/^!! Job failed.  Sleeping 2 seconds and then retrying \(retry 1 of 1\)./) { 
        $found = 1;
        last;
    }
}
close F;
ok($found, "Found retry string in stdout file");


# turn off smtp server
my $smtp = Net::SMTP->new(
    Host      => 'localhost:25252',
    Timeout   => 10,
    );
ok($smtp, "Created smtp client");
ok($smtp->datasend("exit"), "Stopped SMTP Server");

my $emails = &TaskForest::Test::parseSMTPFile("$log_dir/smtp.txt");
is(scalar(@$emails), 2, "Got 2 emails");


is($emails->[0]->{ehlo},         'user1@example.com',    "Msg 1 - Got correct ehlo");
is($emails->[0]->{mail_from},    '<user1@example.com>',  "Msg 1 - Got correct mail from");
is($emails->[0]->{rcpt_to},      '<test2@example.com>',  "Msg 1 - Got correct rcpt_to");
is($emails->[0]->{from},         'user1@example.com',    "Msg 1 - Got correct from");
is($emails->[0]->{return_path},  'user3@example.com',    "Msg 1 - Got correct return_path");
is($emails->[0]->{reply_to},     'user2@example.com',    "Msg 1 - Got correct reply-to");
is($emails->[0]->{to},           'test2@example.com',    "Msg 1 - Got correct to");
is($emails->[0]->{subject},      'RETRY RETRY::J_Retry', "Msg 1 - Got correct subject");

like($emails->[0]->{body}->[4],  qr/The following job failed and will be rerun automatically/,          "Msg 1 - Got correct summary");
like($emails->[0]->{body}->[6],  qr/Family: +RETRY/,                                                    "Msg 1 - Got correct family");
like($emails->[0]->{body}->[7],  qr/Job: +J_Retry/,                                                     "Msg 1 - Got correct job");
like($emails->[0]->{body}->[9],  qr/Retry After: +2 seconds/,                                           "Msg 1 - Got correct sleep");
like($emails->[0]->{body}->[10], qr/No. of Retries: +1 of 1/,                                           "Msg 1 - Got correct num of retries");
like($emails->[0]->{body}->[12], qr/These are test instructions that apply to all jobs in the Family named RETRY/, "Msg 1 - Got family instructions");
like($emails->[0]->{body}->[14], qr/These are test instructions that apply to the jobs named J_Retry/,  "Msg 1 - Got job instructions");



is($emails->[1]->{ehlo},         'user1@example.com',    "Msg 2 - Got correct ehlo");
is($emails->[1]->{mail_from},    '<user1@example.com>',  "Msg 2 - Got correct mail from");
is($emails->[1]->{rcpt_to},      '<test3@example.com>',   "Msg 2 - Got correct rcpt_to");
is($emails->[1]->{from},         'user1@example.com',    "Msg 2 - Got correct from");
is($emails->[1]->{return_path},  'user3@example.com',    "Msg 2 - Got correct return_path");
is($emails->[1]->{reply_to},     'user2@example.com',    "Msg 2 - Got correct reply-to");
is($emails->[1]->{to},           'test3@example.com',     "Msg 2 - Got correct to");
is($emails->[1]->{subject},      'RETRY_SUCCESS RETRY::J_Retry', "Msg 2 - Got correct subject");

like($emails->[1]->{body}->[4],  qr/The following job has succeeded after failing initially/,           "Msg 2 - Got correct summary");
like($emails->[1]->{body}->[6],  qr/Family: +RETRY/,                                                    "Msg 2 - Got correct family");
like($emails->[1]->{body}->[7],  qr/Job: +J_Retry/,                                                     "Msg 2 - Got correct job");
like($emails->[1]->{body}->[9],  qr/No. of Retries: +1 of 1/,                                           "Msg 2 - Got correct num of retries");
like($emails->[1]->{body}->[12], qr/\-+/,                                                               "Msg 2 - Got footer dashes");
like($emails->[1]->{body}->[13], qr/For instructions on using TaskForest, please see http:\/\/www.taskforest.com\//,  "Msg 2 - Got footer");



&TaskForest::Test::cleanup_files($log_dir);
