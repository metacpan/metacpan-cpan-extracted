#!perl

use strict;
use warnings;

use Carp::Always;
use Data::Dumper;
use File::Temp;
use File::Spec;
use Pherkin::Extension::Weasel;
use Test::BDD::Cucumber::Executor;
use Test::BDD::Cucumber::Harness;
use Test::BDD::Cucumber::Model::Feature;
use Test::BDD::Cucumber::Model::Line;
use Test::BDD::Cucumber::Model::Scenario;
use Test::BDD::Cucumber::Model::Step;
use Test::BDD::Cucumber::StepContext;

use Test::More;

my $dh = File::Temp->newdir();
my $dn = $dh->dirname;
my $screen_dir = File::Spec->catfile($dn, 'screens');
my $log_dir = File::Spec->catfile($dn, 'log');

my $ext = Pherkin::Extension::Weasel->new(
    {
        default_session => 'selenium',
        screenshots_dir => $screen_dir,
        screenshot_events => {
            'pre-step' => 0,
                'post-step' => 0,
                'pre-scenario' => 0,
                'post-scenario' => 0,
        },
        sessions => {
            selenium => {
                driver => {
                    drv_name => 'Weasel::Driver::Mock',
                    states => [
                        {
                            cmd => 'screenshot',
                            content => 'pre-scenario2',
                        },
                        {
                            cmd => 'screenshot',
                            content => 'pre-step1',
                        },
                        {
                            cmd => 'find_all',
                            ret_array => [ 'abc', 'def' ],
                        },
                        # requested as part of the element->widget mapper
                        {
                            cmd => 'tag_name', # abc
                            ret => 'div',
                        },
                        {
                            cmd => 'tag_name', # def
                            ret => 'div',
                        },
                        # requested as part of the logging function
                        {
                            cmd => 'tag_name', # abc
                            ret => 'div',
                        },
                        {
                            cmd => 'tag_name', # def
                            ret => 'div',
                        },
                        ],
                },
            },
        },
        logging_dir => $log_dir,
    });

sub _flush_and_read_log {
    my $output_file = $ext->_flush_log;
    open my $fh, "<", $output_file
        or die "Can't open '$output_file': $!";
    my $content = join('', <$fh>);
    close $fh
        or warn "Can't close '$output_file': $!";

    return $content;
}


mkdir $screen_dir;
mkdir $log_dir;


$ext->pre_execute; #_initialize_logging;
ok($ext->_log, q{logger correctly created});
ok($ext->_log->{template}, q{logger template processor correctly created});

my $f = Test::BDD::Cucumber::Model::Feature->new(
    name => 'feature1',
    satisfaction => [
        Test::BDD::Cucumber::Model::Line->new(
            raw_content => 'satisfaction1'),
    ],
    );

my $feature_stash = {};
$ext->pre_feature($f, $feature_stash);
my $content = _flush_and_read_log();


ok($ext->_log, q{logger correctly retained});
ok($ext->_log->{template}, q{logger template processor correctly retained});
like($content, qr!<title>feature1</title>!,
     q{TITLE tag correctly populated});
like($content, qr!<h1 class="feature">feature1</h1>!,
     q{Feature name correctly interpolated into H1 tag});
like($content, qr!<p>satisfaction1</p>!,
     q{Single line satisfaction correctly interpolated});

my $s = Test::BDD::Cucumber::Model::Scenario->new(
    name => 'scenario1',
    tags => [ qw| weasel | ],
    );

my $scenario_stash = {};
$ext->pre_scenario($s, $feature_stash, $scenario_stash);
$content = _flush_and_read_log();


like($content, qr!<h2 class="scenario">scenario1</h2>!,
     q{Scenario name correctly interpolated into H2 tag});

$s = Test::BDD::Cucumber::Model::Scenario->new(
    name => 'scenario2',
    tags => [ qw| weasel | ],
    );

$ext->screenshot_on('pre-scenario', 1);
$ext->pre_scenario($s, $feature_stash, $scenario_stash);
$content = _flush_and_read_log();


like($content, qr!<img src="scenario-pre-\d+\.png"!,
     q{Pre-scenario screenshot correctly added});


# simple step; no step data or data table

my $step = Test::BDD::Cucumber::Model::Step->new(
    text => 'step 1',
    verb => 'Given',
    verb_original => 'Given',
    );
my $context = Test::BDD::Cucumber::StepContext->new(
    stash => { scenario => $scenario_stash,
               feature => $feature_stash },
    feature => $f,
    scenario => $s,
    step => $step,
    verb => 'Given',
    verb_original => 'Given',
    harness => Test::BDD::Cucumber::Harness->new(),
    executor => Test::BDD::Cucumber::Executor->new(),
    );

$ext->screenshot_on('pre-step', 1);

$ext->pre_step($f, $context);
$content = _flush_and_read_log();


like($content, qr!<img src="step-pre-\d+\.png"!,
     q{Pre-step screenshot correctly added});
like($content, qr!<td>Given step 1</td>!,
     q{Step 1 correctly included in log output});


$ext->_weasel->session->page->find_all('//div');
$content = _flush_and_read_log();

like($content, qr!<td>found 2 elements for //div!,
     q{Logging from driver correctly included in the logs});


$ext->post_step($f, $context, 1); # failed step
$content = _flush_and_read_log();

# early versions (at least Pherkin <= 0.56) repoort "<missing>" due to a bug
like($content, qr!<td>(?:FAIL|&lt;missing&gt;)</td>!,
     q{Step status correctly included in the logs});



done_testing;
