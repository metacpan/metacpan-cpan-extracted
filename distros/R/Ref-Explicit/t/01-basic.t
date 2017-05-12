use strict;
use warnings;

use Test::Most;
use Ref::Explicit qw(arrayref hashref);

my @array = ( qw(George Peter John) );
my $arrayref = arrayref @array;

my %hash = ( first => 'George', last => 'Washington' );
my $hashref = hashref %hash;

is_deeply( $arrayref, \@array, 'create array reference' );
is_deeply( $hashref,  \%hash,  'create hash reference'  );
is_deeply( arrayref(), [], 'create emtpy array reference' );
is_deeply( hashref(),  {}, 'create empty hash reference'  );

done_testing();
