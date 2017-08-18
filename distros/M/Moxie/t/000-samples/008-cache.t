#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

package Cache {
    use Moxie;

    extends 'Moxie::Object';

    has '$!fetcher' => ( required => 1 );
    has '$!data';

    sub BUILDARGS : init_args( fetcher => $!fetcher );

    my sub fetcher : private( $!fetcher );

    sub has_data : predicate( $!data );
    sub clear    : clearer( $!data );

    sub data ($self) {
        $self->{'$!data'} //= $self->_fetch_data;
    }

    sub _fetch_data ($self) { fetcher->() }
}

my @data = qw[
    one
    two
    three
];

my $c = Cache->new( fetcher => sub { shift @data } );
isa_ok($c, 'Cache');

ok(!Cache->can('fetcher'), '... out private accessor is not available outside');
ok(!$c->can('fetcher'), '... out private accessor is not available outside');

is($c->data, 'one', '... the data we got is correct');
ok($c->has_data, '... we have data');

$c->clear;

is($c->data, 'two', '... the data we got is correct (cache has been cleared)');
is($c->data, 'two', '... the data is still the same');
ok($c->has_data, '... we have data');

$c->clear;

is($c->data, 'three', '... the data we got is correct (cache has been cleared)');
ok($c->has_data, '... we have data');

$c->clear;

ok(!$c->has_data, '... we no longer have data');
is($c->data, undef, '... the cache is empty now');

done_testing;
