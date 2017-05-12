#!perl

use Test::Most;
use Paginator::Lite;

my ( $pag, %args );

%args = (
    base_url   => '/foo/bar',
    curr       => 5,
    frame_size => 5,
    items      => 200,
    page_size  => 10,
);

##############################################################################

$pag = Paginator::Lite->new(%args);

is( $pag->mode, 'path', 'Default mode: path' );

##############################################################################

$pag = Paginator::Lite->new( %args, mode => 'query' );

is( $pag->mode, 'query', 'Alternate mode: query' );

##############################################################################

throws_ok {
    $pag = Paginator::Lite->new( %args, mode => 'invalid' );
}
qr{mode must be 'path' or 'query'}, 'Invalid mode';

##############################################################################

done_testing;

