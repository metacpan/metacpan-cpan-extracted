# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 24;

use_ok('Repository::Simple::Engine',
    qw( $NODE_EXISTS $PROPERTY_EXISTS $NOT_EXISTS )
);

use vars qw( $NODE_EXISTS $PROPERTY_EXISTS $NOT_EXISTS );

ok(!$NOT_EXISTS);
ok($NODE_EXISTS);
ok($PROPERTY_EXISTS);
isnt($NODE_EXISTS, $PROPERTY_EXISTS);

package Repository::Simple::Engine::Test;

use base 'Repository::Simple::Engine';

package main;

# Test generic constructor
my $engine = Repository::Simple::Engine::Test->new(foo => 1, bar => 2);
ok($engine);
isa_ok($engine, 'Repository::Simple::Engine::Test');
is($engine->{foo}, 1);
is($engine->{bar}, 2);

my @methods = qw(
    new
    node_type_named
    property_type_named
    path_exists
    node_type_of
    property_type_of
    nodes_in
    properties_in
    get_scalar
    set_scalar
    get_handle
    set_handle
    namespaces
    has_permission
    save_property
);

# Test the presence of all required methods
can_ok($engine, @methods);

for my $method (@methods) {
    next if $method eq 'new';
    eval { $engine->$method };
    ok($@, $method);
}
