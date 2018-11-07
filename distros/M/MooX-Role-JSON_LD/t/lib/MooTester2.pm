package MooTester2;

use Moo;

use MooX::JSON_LD 'Example';
use JSON::MaybeXS;

use namespace::autoclean;

has foo => (
    is      => 'ro',
    default => 'Foo',
    json_ld => 'baz',
    json_ld_serializer => sub { $_[0]->bar . ' ' . $_[0]->foo },
);

has bar => (
    is      => 'ro',
    default => 'Bar',
    json_ld => 'bax',
);

has boop => (
    is      => 'ro',
    default => 'Bop!',
    json_ld => 1,
);

around _build_json_ld_encoder => sub {
    return JSON->new->utf8->canonical;
};


1;
