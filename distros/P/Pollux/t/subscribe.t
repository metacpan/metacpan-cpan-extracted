use strict;
use warnings;

use Test::More tests => 1;

use Pollux;
use Pollux::Action;

use experimental 'signatures';

my $Thing = Pollux::Action->new( 'A', 'value' );

my $store = Pollux->new(
    reducer =>  sub($action,$state='') {
        $state = $action->{value}
    }
);

my @log;

for my $s ( 'a'..'b' ) {
    $store->subscribe(sub($store){
        push @log, [ $s => $store->state ];
        $store->dispatch( $Thing->(2) ) if $s eq 'a' and $store->state == 1;
    });
}

$store->dispatch( $Thing->(1) );

is_deeply \@log => [
    [ a => 1 ],
    [ a => 2 ],
    [ b => 2 ],
], "sequence we're expecting";


