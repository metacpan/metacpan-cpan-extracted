use strict;
use warnings;

use Mojo::DOM58::_Collection;
use Test::More;

BEGIN {
  plan skip_all => 'Role::Tiny 2.000001+ required for this test!'
    unless Mojo::DOM58::_Collection->ROLES;
}

package Mojo::DOM58::RoleTest::Hello;
use Role::Tiny;

sub hello {'hello mojo!'}

package main;

use Mojo::DOM58;

my $c = Mojo::DOM58::_Collection->new->with_roles('Mojo::DOM58::RoleTest::Hello');
is $c->hello, 'hello mojo!', 'right result';
my $dom = Mojo::DOM58->with_roles('Mojo::DOM58::RoleTest::Hello')->new;
is $dom->hello, 'hello mojo!', 'right result';

done_testing();
