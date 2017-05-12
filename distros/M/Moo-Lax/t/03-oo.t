use Test::More;

use Moo::Lax;

has foo => (
  is => 'ro',
  default => sub { 'bar' }
);

with qw(Plop);

sub BUILD {
    my ($self) = @_;
    is($self->foo, 'bar', 'Moo::Lax seems to work fine');
    is($self->plop, 'plip', 'Moo::Lax::Role seems to work fine');
}

__PACKAGE__->new();

done_testing;

package Plop;

use Moo::Role::Lax;

requires 'foo';

sub plop { 'plip' }
