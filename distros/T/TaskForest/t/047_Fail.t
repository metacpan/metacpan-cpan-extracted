# -*- perl -*-

# 
use Test::More tests => 30;
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

copy("$src_dir/FAIL", $dest_dir);

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

my $sf = TaskForest::Family->new(name=>'FAIL');

isa_ok($sf,  'TaskForest::Family',  'Created FAIL family');
is($sf->{name},  'FAIL',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $tf = TaskForest->new();
$tf->status();
my $stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["FAIL", "J_Fail",  'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                   ]
    );


# start the smtp server.
ok(system("$cwd/blib/script/testSmtpServer 25252 $log_dir/smtp.txt") == 0, "Starting test SMTP server");

$tf->{options}->{once_only} = 1;

print "Running ready jobs\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/FAIL.J_Fail.1"]), "After first cycle FAIL::J_Fail has failed");

$sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["FAIL", "J_Fail", 'Failure', '\d+', "America/Chicago", "00:00", "..:..", "..:.."],
                                       ]
    );


# turn off smtp server
my $smtp = Net::SMTP->new(
    Host      => 'localhost:25252',
    Timeout   => 10,
    );
ok($smtp, "Created smtp client");
ok($smtp->datasend("exit"), "Stopped SMTP Server");


my $emails = &TaskForest::Test::parseSMTPFile("$log_dir/smtp.txt");
is(scalar(@$emails),  1, "Got 1 email");


is($emails->[0]->{ehlo},         'user1@example.com',    "Msg 1 - Got correct ehlo");
is($emails->[0]->{mail_from},    '<user1@example.com>',  "Msg 1 - Got correct mail from");
is($emails->[0]->{rcpt_to},      '<test@example.com>',   "Msg 1 - Got correct rcpt_to");
is($emails->[0]->{from},         'user1@example.com',    "Msg 1 - Got correct from");
is($emails->[0]->{return_path},  'user3@example.com',    "Msg 1 - Got correct return_path");
is($emails->[0]->{reply_to},     'user2@example.com',    "Msg 1 - Got correct reply-to");
is($emails->[0]->{to},           'test@example.com',     "Msg 1 - Got correct to");
is($emails->[0]->{subject},      'FAIL FAIL::J_Fail',    "Msg 1 - Got correct subject");

like($emails->[0]->{body}->[4],  qr/The following job has failed\./,                                                  "Msg 1 - Got correct summary");
like($emails->[0]->{body}->[6],  qr/Family: +FAIL/,                                                                   "Msg 1 - Got correct family");
like($emails->[0]->{body}->[7],  qr/Job: +J_Fail/,                                                                    "Msg 1 - Got correct job");
like($emails->[0]->{body}->[11], qr/\-+/,                                                                             "Msg 1 - Got footer dashes");
like($emails->[0]->{body}->[12], qr/For instructions on using TaskForest, please see http:\/\/www.taskforest.com\//,  "Msg 1 - Got footer");


&TaskForest::Test::cleanup_files($log_dir);
