#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

package Cache {
    use Moxie
        traits => [':experimental'];

    extends 'Moxie::Object';

    has '_fetcher' => ( required => 1 );
    has '_data';

    sub BUILDARGS : strict( fetcher => _fetcher );

    sub data ($self) : lazy(_data) { $self->{_fetcher}->() }

    sub has_data : predicate(_data);
    sub clear    : clearer(_data);
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
