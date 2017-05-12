#! /usr/local/bin/perl

use blib;
use Table::ParentChild;
use Benchmark;
use Storable;

my $table = new Table::ParentChild;

my $file = "vbom_parent_child.txt";
my $line = 0;

print "Loading relationships...\n";

timethis( 1, sub { 
	open FILE, $file or die $!;
	<FILE>;
	while( <FILE> ) {
		my @relationship = split /\t/;
		$table->add_relationship( @relationship );
		$line++;
	}
	close FILE;
} );

print "$line lines of relationships loaded.\n";

store $table, "bom_lookup.sto";

print `ls -la`;

print "Looking up parents of 0160-6222...\n";

my $results;

timethis( 1000, sub {
	$results = $table->parent_lookup( 305 );
} );

my @keys = sort keys %$results;
for( my $i = 0; $i <= int( @keys ); $i += 3 ) {
	printf( "%5.2ld|%9lf ",		$keys[ $i ],	$results->{ $keys[ $i ] } );
	printf( "%5.2ld|%9lf ",		$keys[ $i+1 ],	$results->{ $keys[ $i+1 ] } );
	printf( "%5.2ld|%9lf\n",	$keys[ $i+2 ],	$results->{ $keys[ $i+2 ] } );
}

