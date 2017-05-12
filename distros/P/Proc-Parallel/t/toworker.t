#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use Test::More;
use File::Temp;
use File::Slurp;
use RPC::ToWorker;
use IO::Event qw(emulate_Event);
use Scalar::Util qw(reftype);
use Eval::LineNumbers qw(eval_line_numbers);
use Cwd;

my $debug = 0;
my $finished = 0;
my $skip = 0;

END { ok($finished, 'finished') unless $skip }

use File::Slurp::Remote;

my $rhost = `$File::Slurp::Remote::SmartOpen::ssh localhost -n hostname`;
my $lhost = `hostname`;

unless ($lhost eq $rhost) {
	$skip = 1;
	plan skip_all => 'Cannot ssh to localhost';
	exit;
}

import Test::More qw(no_plan);

my $timer;
sub set_bomb 
{
	$timer = IO::Event->timer(
		after	=> 10,
		cb	=> sub {
			ok(0, "bomb timer went off, something failed");
			exit 0;
		},
	);
}

sub clear_bomb
{
	$timer->cancel;
	undef $timer;
}

my $test_sets_done = 0;
my $tests_expected = 0;

sub run_test
{
	set_bomb();
	IO::Event::loop();
	clear_bomb();
	$tests_expected++;
}
	
do_remote_job(
	host		=> 'localhost',
	eval		=> 'return (13, 7)',
	desc		=> 'prequel test',
	when_done	=> sub {
		my (@retval) = @_;
		is(scalar(@retval), 2, "basic test returned two values");
		is($retval[0], 13, "first value right");
		is($retval[1], 7, "second value right");
		$test_sets_done++;
		IO::Event::unloop_all();
	},
);

run_test();

do_remote_job(
	host		=> 'localhost',
	prequel		=> 'my $thirteen = 13;',
	eval		=> 'return ($thirteen, 7)',
	when_done	=> sub {
		my (@retval) = @_;
		is(scalar(@retval), 2, "basic test returned two values with prequel");
		is($retval[0], 13, "first value right");
		is($retval[1], 7, "second value right");
		$test_sets_done++;
		IO::Event::unloop_all();
	},
);

run_test();

do_remote_job(
	data		=> [ 3, 7, 22 ],
	preload		=> ['List::Util', 'Scalar::Util', 'Cwd'],
	host		=> 'localhost',
	chdir		=> cwd(),
	eval		=> <<'REMOTE_CODE',
				my (@values) = @{$_[0]};
				my $sum = List::Util::sum(@values);
				my $is_num = Scalar::Util::looks_like_number($sum);
				return [$sum, $is_num, cwd()]
REMOTE_CODE
	when_done	=> sub {
		my (@retval) = @_;
		is(scalar(@retval), 1, "round trip values");
		is(reftype($retval[0]), 'ARRAY', 'got an array back');
		eval {
			is($retval[0][0], 32, "sum of data");
			ok($retval[0][1], "is a num");
			is($retval[0][2], cwd(), "cwd");
		};
		ok(! $@, "no eval errors");
		$test_sets_done++;
		IO::Event::unloop_all();
	},
);

run_test();

do_remote_job(
	host		=> 'localhost',
	preload		=> 'RPC::ToWorker::Callback',
	local_data	=> {
		x	=> 10,
		y	=> 30,
	},
	eval		=> <<'REMOTE_CODE2',
				return master_call('', 't::the_master::a_func', ['x'], 17, 19, undef);
REMOTE_CODE2
	when_done	=> sub {
		my (@retval) = @_;
		is(scalar(@retval), 5, "simple master callback");
		is($retval[0], 10, "localdata 10 first");
		is($retval[1], 'x', "localdata key");
		is($retval[2], undef, "first is undef");
		is($retval[3], 19, "second is 19");
		is($retval[4], 17, "third is 17");
		$test_sets_done++;
		IO::Event::unloop_all();
	},
);

run_test();

our $extra_remote_init = '';
my %invoked;

# $RPC::ToWorker::command = 'cat';

do_remote_job(
	prefix		=> '## ',
	chdir		=> $FindBin::Bin,
	host		=> 'localhost',
	data		=> { 
		this => {
			and	=> 'that'
		}, 
		show	=> 'something'
	},
	preload		=> [],
	prequel		=> "BEGIN { \@INC = (" . join(', ', map { "'$_'" } @INC) . "); }\n" .
		eval_line_numbers(<<PREQUEL),
			BEGIN { no warnings; \$RPC::ToWorker::debug = $debug; }
			use lib '$FindBin::Bin/../lib';
			$extra_remote_init
			use RPC::ToWorker::Callback;
PREQUEL
	desc		=> 'test remote job',
	eval		=> eval_line_numbers(<<'REMOTE_JOB'),
		my $rec = 7;
		$rec++ if $data->{this};
		$rec++ if $data->{this}{and};
		$rec++ if $data->{this}{and} eq 'that';
		$rec++ if $data->{show};
		$rec++ if $data->{show} eq 'something';
		print STDERR "i want to trigger_error_handler\n";
		print "i want to trigger_output_handler\n";
		my ($foo, $bar) = master_call('', 't::the_master::b_func', [qw(return7 nine)], 'foo', 'bar');
		return(rec => $rec, { $foo => $bar }, { 'bar' => $foo });
REMOTE_JOB
	when_done	=> sub {
		my ($recstr, $rec, $v1, $v2) = @_;
		is($recstr, 'rec', "values passed there and back");
		is($rec, 12, "values passed there and back");
		ok(ref($v1), "verify 1st return value");
		ok(ref($v2), "verify 2nd return value");
		is($v1->{foo}, 'bar', 'more verification of 1st return value');
		is($v2->{bar}, 'foo', 'more verification of 2nd return value');
		ok(1, "when_done called");
		$invoked{when_done} = 1;
	},
	all_done	=> sub {
		ok(1, "alldone");
		$test_sets_done++;
		IO::Event::unloop_all();
	},
	error_handler	=> sub {
		my $e = join('', @_);
		print STDERR "#E $e" if $debug;
		$invoked{error_handler} = 1
			if $e =~ /trigger_error_handler/;
	},
	output_handler	=> sub {
		my $o = join('', @_);
		print STDERR "#O $o" if $debug;
		$invoked{output_handler} = 1
			if $o =~ /trigger_output_handler/;
	},
	local_data	=> {
		return7	=> sub { return 7 },
		nine	=> 9,
	},
);

run_test();

ok($invoked{when_done}, "when_done called");
# ok($invoked{error_handler}, "error output trigger");  # not currently supported
ok($invoked{output_handler}, "output trigger");
ok($invoked{example_master}, "example master");

###

is($test_sets_done, $tests_expected, "all tests run");

$finished = 1;

package t::the_master;

use strict;
use warnings;
use Test::More;

sub a_func
{
	reverse(@_);
}

sub b_func
{
	my ($a, $b, %more) = @_;
	$invoked{example_master}++;
	is($a, 'foo', 'first value from slave');
	is($b, 'bar', 'second value from slave');
	ok($more{return7}, "local return7 key");
	is($more{return7}->(), 7, "local return7 value");
	is($more{nine}, 9, "local nine");
	return ('foo', 'bar');
}


1;
