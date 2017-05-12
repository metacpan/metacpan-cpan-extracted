# -*- perl -*-

# 
use Test::More tests => 14;
use strict;
use warnings;
use Data::Dumper;
use Cwd;

BEGIN {
    use_ok( 'TaskForest::Options',     "Can use Options" );
}

my $cwd = getcwd();


$ENV{TF_LOG_DIR} = '';
$ENV{TF_FAMILY_DIR} = '';
$ENV{TF_JOB_DIR} = '';
$ENV{TF_RUN_WRAPPER} = '';
eval { my $o = &TaskForest::Options::getOptions(); };
my $exception = $@;
like($exception, qr/run_wrapper, log_dir, job_dir, family_dir/,  'Cannot create options without required fields');


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
eval { my $o = &TaskForest::Options::getOptions(); };
$exception = $@;
like($exception, qr/log_dir, job_dir, family_dir/,  'Cannot create options without required fields');

$ENV{TF_LOG_DIR} = "$cwd/t/logs";
eval { my $o = &TaskForest::Options::getOptions(); };
$exception = $@;
like($exception, qr/job_dir, family_dir/,  'Cannot create options without required fields');

$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
eval { my $o = &TaskForest::Options::getOptions(); };
$exception = $@;
unlike($exception, qr/run_wrapper, log_dir, job_dir, family_dir/,  'Cannot create options without required fields - only missing fields printed');
like($exception, qr/family_dir/,  'Cannot create options without required fields');


$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
my $options = &TaskForest::Options::getOptions();

is(ref($options),                'HASH',             'Option created');
cmp_ok(scalar(keys(%$options)),  '>', 0,             '  and has more than 1 key');
is($options->{end_time},         '2355',             '  end time');
is($options->{wait_time},        '60',               '  wait time');
is($options->{run_wrapper},      "$cwd/blib/script/run",     "  run_wrapper");
is($options->{family_dir},       "$cwd/t/families",  "  families");
is($options->{job_dir},          "$cwd/t/jobs",      "  jobs");
is($options->{log_dir},          "$cwd/t/logs",      "  logs");



