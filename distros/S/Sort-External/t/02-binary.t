use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use lib 'lib';
use Sort::External;

my ( $sortex, $item, @sorted );

my @orig = map { pack( 'N', $_ ) } ( 0 .. 11_000 );
unshift @orig, '';
my @reversed = reverse @orig;

$sortex = Sort::External->new( cache_size => 1_000 );
$sortex->feed(@reversed);
$sortex->finish;
while ( defined( $item = $sortex->fetch ) ) {
    push @sorted, $item;
}
is_deeply( \@sorted, \@orig, "Sorting binary items..." );
use Data::Dumper;
undef $sortex;
@sorted = ();
