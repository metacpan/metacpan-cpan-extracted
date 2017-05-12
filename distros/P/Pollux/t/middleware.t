use strict;
use warnings;

use Test::More tests => 2;

use Pollux;
use Pollux::Action;

use experimental 'signatures';

my $Action = Pollux::Action->new( 'ACTION', 'text' );

my @middlewares =  map { 
    my $x = $_;
    sub($store,$next,$action) { 
        $next->( $Action->( $action->{text} . $x ) ) 
    } 
} 1..3;

my $store = Pollux->new(
    middlewares => \@middlewares,
    reducer => sub($action,$state='') {
        $state . $action->{text}
    },
);

$store->dispatch( $Action->( 'foo' ) );

is $store->state => 'foo123', "middleware run in order";

subtest "middleware doing a dispatch" => sub {
    my $Action = Pollux::Action->new( 'ACTION', 'text' );

    my $store = Pollux->new(
        middlewares => [
            sub ($store,$next,$action) { $next->( $Action->( $action->{text} . 'o' ) ) },
            sub ($store,$next,$action) { $store->dispatch( $Action->('bar') ) if $action->{text} eq 'foo'; $next->($action) },
        ],
        reducer => sub($action,$state='') {
            $state . $action->{text}
        },
    );

    $store->dispatch( $Action->( 'fo' ) );

    is $store->state => 'barofoo', "middleware can dispatch";
};
