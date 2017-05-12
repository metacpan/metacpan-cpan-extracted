#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Try::Tiny;

use_ok('Search::OpenSearch::Types');

{

    package Foo;
    use Moose;
    use Search::OpenSearch::Types qw( SOSFacets );
    use Search::OpenSearch::Facets;
    use Types::Standard qw( Maybe );

    has 'facets' => (
        is     => 'rw',
        isa    => Maybe [SOSFacets],
        coerce => 1,
    );

}

my $foo = try {
    Foo->new( facets => { bar => 1 } );
    return 1;
}
catch {
    ok( $_, "Foo->new with bad params throws exeption" );
    return 0;
};
ok( !$foo, "no object on bad params" );

ok( my $good_foo = Foo->new( facets => { names => ['bar'] } ),
    "good Foo->new" );
