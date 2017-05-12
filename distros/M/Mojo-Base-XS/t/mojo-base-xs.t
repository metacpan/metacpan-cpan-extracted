#!/usr/bin/env perl
use lib 't/lib';

use Test::More tests => 9;

use Mojo::Base::XS;

use BaseTestXS;

can_ok 'BaseTestXS', 'has';

my $self = BaseTestXS->new({foo => 'bar'});

is($self->{foo}, 'bar');
$self->attr('x');

can_ok $self, 'name';
can_ok $self, 'x';
is $self->name, 'Named!';

is_deeply $self->def_array, ['Named!'];

$self->name("ololo");
is $self->name, "ololo";

isa_ok $self->name("ololo"), 'BaseTestXS';

is $self->ears, 2;
