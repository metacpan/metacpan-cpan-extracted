#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $class = "SourceCode::LineCounter::Perl";
my @methods = qw( 
	_is_blank blank
	);

use_ok( $class );
can_ok( $class, @methods );

my $counter = $class->new;
isa_ok( $counter, $class );
can_ok( $counter, @methods );

subtest should_be => sub {
	my @tests = ( "\t", "   ", "\f", " \t ", "\n" );
	foreach my $line ( @tests ) {
		ok( $counter->_is_blank( \$line ), "_is_blank works for just whitespace" );
		}
	};

subtest shouldnt_be => sub {
	foreach my $line ( qw(Buster Mimi), "  Buster", "Mimi  " ) {
		ok( ! $counter->_is_blank( \$line ), "_is_blank fails for non whitespace" );
		}
	};

subtest count => sub {
	is( 0 + $counter->blank, 0, 'Documentation has no value' );
	ok( $counter->add_to_blank, 'Adds to blank' );
	ok( $counter->blank, 'blank has true value' );
	};

done_testing();

