use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use lib 'lib';
use Sort::External;

my ( $sortex, $item, @sorted );

my @orig;

for my $letter ( 'a' .. 'z' ) {
    for my $num (10000) {
        push @orig, $letter x $num;
    }
}

my @reversed = reverse @orig;

$sortex = Sort::External->new( cache_size => 5 );
$sortex->feed($_) for @reversed;
$sortex->finish;
while ( defined( $item = $sortex->fetch ) ) {
    push @sorted, $item;
}
is_deeply( \@sorted, \@orig, "Long strings sort correctly..." );
undef $sortex;
@sorted = ();
