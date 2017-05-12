use strict;
use warnings;
use Test::More;

use MooseX::LexicalRoleApplication;

use FindBin;
use lib "$FindBin::Bin/lib";

use SomeClass;
use SomeRole;

my $o = SomeClass->new({ moo => 0xaffe });

ok(!$o->can('foo'));
ok( $o->can('moo'));

{
    ok(!$o->can('foo'));
    ok( $o->can('moo'));

    my $scope = MooseX::LexicalRoleApplication->apply(SomeRole->meta, $o, { foo => 'bar' });

    ok( $o->can('foo'));
    ok( $o->can('moo'));

    is($o->foo, 'bar');
    is($o->moo, 0xaffe);
}

ok(!$o->can('foo'));
ok( $o->can('moo'));

ok(!exists $o->{foo});
is($o->moo, 0xaffe);

done_testing;
