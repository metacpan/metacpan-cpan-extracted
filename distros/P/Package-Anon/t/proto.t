use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Object::Proto;

my ($Vector, $prototype) = new_instance {};

add_method $Vector, new => sub {
    my ($p, $x, $y, $z) = @_;
    new_instance { x => $x, y => $y, z => $z }, $p;
};

for my $attr (qw(x y z)) {
    add_method $Vector, $attr => sub { shift->{$attr} };
}

add_method $Vector, magnitude => sub {
    my ($self) = @_;
    return sqrt($self->x ** 2 + $self->y ** 2 + $self->z ** 2);
};

my $v = $Vector->new(0, 2, 1);

can_ok($v, qw(x y z magnitude));
is($v->x, 0);
is($v->y, 2);
is($v->z, 1);
is($v->magnitude, sqrt(5));

done_testing;
