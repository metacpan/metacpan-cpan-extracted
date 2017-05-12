#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $class = "SourceCode::LineCounter::Perl";
my @methods = qw( 
	_is_comment comment
	);

use_ok( $class );
can_ok( $class, @methods );

my $counter = $class->new;
isa_ok( $counter, $class );
can_ok( $counter, @methods );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that should be comments 
subtest should_work => sub {
	my @tests = (
		'my $x = 0; # Set $x to z',
		' # this is a comment',
		'# this is a comment',
		'#',
		);

	foreach my $line ( @tests ) {
		ok( $counter->_is_comment( \$line ), "_is_comment works for true comments" );
		}
	};


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that shouldn't be comments
subtest shouldnt_work => sub {
	foreach my $line ( qw(Buster Mimi), "  Buster", "Mimi  " ) {
		ok( ! $counter->_is_comment( \$line ), "_is_comment fails for non comment" );
		}
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test things that look like comments, but in pod
subtest skip_comments_in_pod => sub {
	$counter->_mark_in_pod;
	ok( $counter->_in_pod, "In pod after marking" );

	my $start_count = $counter->comment;

	my @tests = (
		'my $x = 0; # Set $x to z',
		' # this is a comment',
		'# this is a comment',
		'#',
		);

	foreach my $line ( @tests ) {
		ok( ! $counter->_is_comment( \$line ), "_is_comment fails for comment in pod" );
		}
	};

subtest count => sub {
	is( 0 + $counter->comment, 0, 'comment has no value' );
	ok( $counter->add_to_comment, 'Adds to comment' );
	ok( $counter->comment, 'comment has true value' );
	};

done_testing();
