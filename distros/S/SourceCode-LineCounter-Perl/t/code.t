#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $class = "SourceCode::LineCounter::Perl";
my @methods = qw( 
	_is_code code
	);

use_ok( $class );
can_ok( $class, @methods );

my $counter = $class->new;
isa_ok( $counter, $class );
can_ok( $counter, @methods );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that should be code, no comments 
subtest code_without_comments => sub {
	my @tests = (
		'my $x = 0;',
		'foreach my $test ( qw#a b c# ) { 1; }',
		);

	foreach my $line ( @tests ) {
		ok( $counter->_is_code( \$line ), "_is_code works for code lines" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that should be code, with comments 
subtest code_with_comments => sub {
	my @tests = (
		'my $x = 0; # fooey',
		'1; # test',
		);

	foreach my $line ( @tests ) {
		ok( $counter->_is_comment( \$line ), "_is_comment works for code lines with comments" ); 
		ok( $counter->_is_code( \$line ),    "_is_code works for code lines with comments" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that shouldn't be code, with comments 
subtest not_code => sub {
	my @tests = (
		'  # fooey',
		);

	foreach my $line ( @tests ) {
		ok( $counter->_is_comment( \$line ), "_is_comment works for code lines with comments" ); 
		ok( ! $counter->_is_code( \$line ),    "_is_code fails for lines with just comments" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that look like code, but in pod
subtest code_in_pod => sub {
	$counter->_mark_in_pod;
	ok( $counter->_in_pod, "We're in pod territory now" );

	my @tests = (
		'my $x = 0; # fooey',
		'1; # test',
		);

	foreach my $line ( @tests ) {
		ok( ! $counter->_is_code( \$line ), "_is_code fails for code lines in pod" ); 
		}
	};

subtest count => sub {
	is( 0 + $counter->code, 0, 'code has no value' );
	ok( $counter->add_to_code, 'Adds to code' );
	ok( $counter->code, 'code has true value' );
	};

done_testing();
