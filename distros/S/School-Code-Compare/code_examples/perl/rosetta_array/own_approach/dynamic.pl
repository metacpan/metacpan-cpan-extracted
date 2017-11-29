use strict;
use Data::Dumper;

my @array = ();
 
push @array, 'a';
$array[1] = 'b';
push @array, 'c';
 
print Dumper(\@array);
