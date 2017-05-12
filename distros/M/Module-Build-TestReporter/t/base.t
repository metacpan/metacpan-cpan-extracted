#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use IO::String;
use File::Spec::Functions 'catfile';

use Test::More tests => 35;
use Test::Exception;

my $module = 'Module::Build::TestReporter';
use_ok( $module ) or exit;

can_ok( $module, 'new' );

my %args = ( module_name => 'Some::Module', dist_version => '1.0' );
my $tr   = $module->new( %args );

isa_ok( $tr, 'Module::Build' );
isa_ok( $tr, $module );
is( $tr->notes( 'report_file' ), 'test_failures.txt',
	'new() should set report_file to test_failures.txt by default' );

$args{report_file} = 'report.txt';
$tr                = $module->new( %args );
is( $tr->notes( 'report_file' ), 'report.txt',
	'... but should set if it passed' );

can_ok( $tr, 'ACTION_test' );
my $io = IO::String->new();
{
	my @args;

	local *Module::Build::ACTION_test;
	*Module::Build::ACTION_test = sub { @args = @_ };

	my $oldfh = select( $io );
	$tr->ACTION_test( qw( 1 2 3 ) );
	is( $io->getline, undef, 'ACTION_test() should not write to selected fh' );
	is_deeply (\@args, [ $tr, 1 .. 3 ], '... calling SUPER with args' );
	my $newfh = select( $oldfh );
	is( $newfh, $io, '... and should restore selected fh' );
}

my $fail_filename;

can_ok( $tr, 'find_test_files' );
{
	local $ENV{TEST_VERBOSE} = 0;
	local *Module::Build::find_test_files;
	*Module::Build::find_test_files = sub
	{
		[ map { catfile( 'fake_tests', $_ ) } qw( fail.t pass.t ) ]
	};

	my $rf;

	local *Module::Build::TestReporter::report_failures;
	*Module::Build::TestReporter::report_failures = sub
	{
		$rf++;
	};

	$tr->notes( test_failures => [ 1 .. 10 ] );

	my $outfh = IO::String->new();
	$tr->notes( test_oldfh => $outfh );

	my $result = $tr->find_test_files();
	is_deeply( $result, [], 'find_test_files() should return empty arrayref' );
	my $text = $outfh->string_ref();
	is( $$text, '', '... writing no output by default' );
	$outfh->pos( 0 );
	is( $rf, 1, '... reporting failures' );
	is( @{ $tr->notes( 'test_failures' ) }, 1,
		'... having cleared out any existing failures' );

	$ENV{TEST_VERBOSE} = 1;
	$tr->find_test_files();
	($fail_filename, my $pass_filename) = @{Module::Build::find_test_files()};
	is( $$text, "${pass_filename}...ok\n", '... writing no output by default' );
	is( $rf, 2, '... yet still reporting failures' );
}

can_ok( $tr, 'save_failure_details' );

my $failures = $tr->notes( 'test_failures' );
is( @$failures, 1,
	'save_failure_details() should save results of all failures' );
is_deeply( $failures->[0],
	{
		file => $fail_filename,
		passing =>  0,
		max     => 10,
		bonus   =>  0,
		ok      =>  9,
		seen    => 10,
		skip    =>  0,
		todo    =>  0,
		failures => [
			{
				number      => 10,
				description => 'no, it is not',
				diagnostics => "\n    Failed test ($fail_filename at line 9)\n"
				            .  "         got: 'foo'\n    expected: 'bar'\n",
			}
		],
	}, '... saving failure information' );

can_ok( $tr, 'report_failures' );
{
	my $outfh    = IO::String->new();
	my $failures = $tr->notes( 'test_failures' );
	$tr->notes( test_failures =>     [] );
	$tr->notes( test_oldfh    => $outfh );

	$tr->report_failures();
	my $text = $outfh->string_ref();
	is( $$text, "All tests passed...\n",
		'report_failures() should report success with no failures' );

	$tr->notes( test_failures => $failures );

	# this report has no actual failures, so skip it
	push @$failures,
	{
		file    => 'another_file.t', 
		ok      =>  6,
		seen    =>  6,
	};

	my ($full_report, $version, $fail_report);

	local *Module::Build::TestReporter::write_report;
	*Module::Build::TestReporter::write_report = sub 
	{
		($full_report, $version) = splice( @_, 1, 2 );
	};

	local *Module::Build::TestReporter::write_failure_results;
	*Module::Build::TestReporter::write_failure_results = sub
	{
		((my $self), $fail_report) = @_;
	};

	$tr->report_failures();

	my $fail_header  = qr/Test failures in '$fail_filename' \(1\/10\):/;
	my $fail_details = qr/fail.t.+line 9.+got: 'foo'.+expected: 'bar'/s;

	like( $full_report, $fail_header,
		'report_failures() should write a full report for all failed tests' );
	like( $full_report, $fail_details,
		'... with test failure information' );

	like( $version, qr/Summary of my perl.+Characteristics of this binary/s,
		'... and the full -V information of this perl' );

	like( $fail_report, $fail_header, '... and a failure report' );
	like( $fail_report, $fail_header, '... with failure details' );
}

can_ok( $tr, 'write_report' );
$tr->write_report( 'my report', '+version' );
ok( -e 'report.txt', 'write_report() should write its report' );
my $text = do { local (@ARGV, $/) = 'report.txt'; <> };
is( $text, 'my report+version', '... from the report passed' );

$tr->notes( report_file => '' );
throws_ok
	{ $tr->write_report( 'my report' ) }
	qr/Can't write/, 
	'... throwing an exception if it cannot write test data';

can_ok( $tr, 'write_failure_results' );
{
	local $ENV{TEST_VERBOSE} = 0;
	my $outfh                = IO::String->new();
	$tr->notes( test_oldfh => $outfh );
	my $text                 = $outfh->string_ref();

	# no contact specified
	$tr->notes( report_address => '' );
	$tr->write_failure_results( 'my report' );
	is( $$text, "Tests failed!\n",
		'write_failure_results() should only warn of failure without contact' );
	$outfh->pos( 0 );

	$tr->notes( report_file    => 'test_failures.txt'    );
	$tr->notes( report_address => 'failures@example.com' );
	$tr->write_failure_results( 'my report' );
	like( $$text, qr/e-mail 'test_failures.txt' to failures\@/,
		'... or giving e-mail directions with a contact' );
	$outfh->pos( 0 );

	$ENV{TEST_VERBOSE}       = 1;
	$tr->write_failure_results( 'my report' );
	like( $$text, qr/my report/, '... adding the report in verbose mode' );
}

END
{
	1 while unlink 'report.txt';
}
