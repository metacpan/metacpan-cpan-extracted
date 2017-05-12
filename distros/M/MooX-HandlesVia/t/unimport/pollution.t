# using Moo and MooX::HandlesVia without cleaning the namespace

use strict;
use warnings;

use Test::More;

{
    package Polluted::Moo;
    use Moo;
}

{
    package Polluted::HandlesVia;
    use Moo;
    use MooX::HandlesVia;
}

my $moo_obj = new_ok "Polluted::Moo";
my $handlesvia_obj = new_ok "Polluted::HandlesVia";

my $moo_has = $moo_obj->can("has");
my $handlesvia_has = $handlesvia_obj->can("has");

ok defined $moo_has, "Plain Moo-Object can 'has'";
ok defined $handlesvia_has, "HandlesVia-Object can 'has'";

ok ! $moo_obj->can("foo"), "Moo-Object can't 'foo'";

$moo_has->(foo => ( is => "lazy", default => sub{{}} ) );

can_ok $moo_obj, "foo";

ok defined $moo_obj->foo, "foo-attribute was set";

ok ! $handlesvia_obj->can("foo"), "HandlesVia-Object can't 'foo'";

$handlesvia_has->(foo => ( 
    is => "lazy", 
    default => sub{{}},
    handles_via => "Hash", 
    handles => { set_foo => "set", get_foo => "get"},
    ) 
);

can_ok $handlesvia_obj, qw/foo set_foo get_foo/;

ok defined $handlesvia_obj->foo, "foo-attribute was set";

ok ! $handlesvia_obj->get_foo("bar"), "bar is not defined in foo attribute";

$handlesvia_obj->set_foo("bar", "baz");

is $handlesvia_obj->get_foo("bar"), "baz", "delegation works as expected";

done_testing;
