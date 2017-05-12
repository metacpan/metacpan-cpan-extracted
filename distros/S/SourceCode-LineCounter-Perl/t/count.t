#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Output;

use File::Spec::Functions qw(catfile);

$SIG{__WARN__} = sub { print STDERR @_ };

# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
my $class = "SourceCode::LineCounter::Perl";
my @methods = qw( 
	new reset count
	);

use_ok( $class );
can_ok( $class, @methods );

my $counter = $class->new;
isa_ok( $counter, $class );
can_ok( $counter, @methods );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Describe all of the files I should test
my $Corpus = 'corpus';

my @files = (
	{ file => 'hello.pl', total => 15, code => 1, comment => 2, blank => 6, documentation => 10 },
	);
	
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Test all of the files 
foreach my $hash ( @files )
	{
	my $file = catfile( $Corpus, $hash->{file} );
	ok( -e $file, "Test file [$file] exists" );
	
	$counter->reset;
	foreach my $method ( qw(total code comment blank documentation ) ) {
		is( $counter->$method(), 0, "$method starts off at 0" );
		}
		
	ok( $counter->count( $file ), "count returns true for good file" );

	foreach my $method ( qw(total code comment blank documentation ) ) {
		is( $counter->$method(), $hash->{$method}, "$method ends with [$hash->{$method}]" );
		}
	
	}
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try a file that doesn't exist. It should fail
subtest not_there => sub {
	my $not_there = '';
	ok( ! -e $not_there, "File [$not_there] does not exist" );

	stderr_like
		{ $counter->count( $not_there ) }
		qr/not open/,
		"Carps for missing file";
	};

done_testing();
