#!/usr/bin/perl
use strict;
use warnings;

use Test::More 0.94;

my $class = "SourceCode::LineCounter::Perl";
my @methods = qw( 
	_mark_in_pod _in_pod _clear_in_pod
	_start_pod _end_pod _in_pod 
	documentation
	);

use_ok( $class );
can_ok( $class, @methods );

my $counter = $class->new;
isa_ok( $counter, $class );
can_ok( $counter, @methods );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test marking 
subtest marking => sub {
	ok( ! $counter->_in_pod, "We aren't in pod at start" );

	$counter->_mark_in_pod;
	ok(   $counter->_in_pod, "We are in pod after marking" );

	$counter->_clear_in_pod;
	ok( ! $counter->_in_pod, "We aren't in pod after clearing" );

	$counter->_mark_in_pod;
	ok(   $counter->_in_pod, "We are in pod after marking second time" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test starting pod that should work
subtest in_pod => sub {
	$counter->_clear_in_pod;
	ok( ! $counter->_in_pod, "We aren't in pod before starting" );

	ok( $counter->_start_pod( \ "=pod\n" ), "=pod starts pod" );
	ok(   $counter->_in_pod, "We are in pod after =pod" );
	};


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test starting pod that shouldn't work
subtest shouldnt_work_malformed => sub {
	foreach my $try ( '   =pod', "=.123", "= for" ) {
		my $start_count = $counter->documentation;

		$counter->_clear_in_pod;
		ok( ! $counter->_in_pod, "We aren't in pod before starting" );
	
		$counter->_start_pod( \ $try );
		ok( ! $counter->_in_pod, "We are not in pod after [$try]" );
	
		is( $counter->documentation, $start_count, "documentation count did not change" );
		}
	};

subtest pod_after_pod => sub {
	$counter->_mark_in_pod;
	ok(   $counter->_in_pod, "We are in pod after marking" );

	ok( ! $counter->_start_pod( \ "=pod\n" ), "=pod doesn't start pod already in pod" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test in pod when it should work
subtest should_work => sub {
	$counter->_mark_in_pod;
	ok(   $counter->_in_pod, "We are in pod after marking" );

	foreach my $line ( qw(foo bar baz), '', '0', "\t \t" ) {
		ok(   $counter->_pod_line( \$line  ), "Just saw a pod line" );
		}
	};


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test in pod when it shouldn't work
subtest shouldnt_start => sub {
	$counter->_clear_in_pod;
	ok( ! $counter->_in_pod, "We are in pod after marking" );

	foreach my $line ( qw(foo bar baz =end), '', '0', "\t \t" ) {
		ok( ! $counter->_pod_line( \$line  ), "Just saw a pod line" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test end pod when it should work
subtest end_should_work => sub {
	$counter->_mark_in_pod;
	ok(   $counter->_in_pod, "We are in pod after marking" );

	ok( $counter->_end_pod( \ "=cut\n" ), "Ending pod" );
	ok( ! $counter->_in_pod, "We are not in pod after =cut" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test end pod when it shouldn't work
subtest end_shouldnt_work => sub {
	$counter->_mark_in_pod;
	ok(   $counter->_in_pod, "We are in pod after marking" );

	ok( ! $counter->_end_pod( \ "=end\n" ), "Not ending pod" );
	ok(   $counter->_in_pod, "We are still in pod after =end"  );
	};

subtest end_shouldnt_end => sub {
	$counter->_clear_in_pod;
	ok( ! $counter->_in_pod, "We are in pod after marking" );

	ok( ! $counter->_end_pod( \ "=end\n" ), "Not ending pod when not in pod" );
	};

subtest count => sub {
	is( 0 + $counter->documentation, 0, 'Documentation has no value' );
	ok( $counter->add_to_documentation, 'Adds to documentation' );
	ok( $counter->documentation, 'Documentation has true value' );
	};

done_testing();
