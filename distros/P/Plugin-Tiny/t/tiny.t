#!perl

use strict;
use warnings;
use Test::More;
use Plugin::Tiny;
use Try::Tiny;
use FindBin;
use File::Spec;
use Scalar::Util 'blessed';

#use Data::Dumper;
use lib File::Spec->catfile('t', 'lib');

use_ok('Plugin::Tiny');

package SampleCore;
use Moo;
use MooX::Types::MooseLike::Base qw(InstanceOf);
has 'plugin_system' => (is => 'ro', isa => InstanceOf['Plugin::Tiny'], required => 1);
1;

package SampleBundle;
use Moo;
use MooX::Types::MooseLike::Base qw(Object);

has 'core' => (is => 'ro', isa => Object, required => 1);
1;


package main;

note "simple new and register";
my $ps = Plugin::Tiny->new(role => ['TestRolePlugin']);
ok($ps, 'new with role as ArrayRef');

$ps = Plugin::Tiny->new(role => 'TestRolePlugin');
ok($ps, 'new with role as String');

$ps = Plugin::Tiny->new(prefix => 'Bla');
ok($ps, 'new with prefix');

$ps = Plugin::Tiny->new();
ok($ps, 'new no args');




ok( $ps->register(
        plugin        => 'TinyTestPlugin',                 #required
        plugin_system => $ps,
        bar           => 'tiny',
    ),
    'register with default phase'
);
ok( $ps->register(
        phase         => 'foo',
        plugin        => 'TinyTestPlugin',                 #required
        plugin_system => $ps,
        bar           => 'tiny',
    ),
    'simple register with phase'
);

try {
    $ps->register(
        phase         => 'foo',
        plugin        => 'TinyTestPlugin',                 #required
        plugin_system => $ps,
    );
}
finally {
    ok(@_, 'register fails if phase already registered');
};

ok( $ps->register(
        phase         => 'foo',
        plugin        => 'TinyTestPlugin',                 #required
        plugin_system => $ps,
        force         => 1
    ),
    'force re-register'
);

try {
    $ps->register(
        plugin => 'TinyTestPlugin',                        #required
        bar    => 'tiny',
    );
}
finally {
    ok(@_, 'register fails without attr plugin_system');
};


try {
    $ps->register(
        phase  => 'foo',
        plugin => 'nonexistingPlugin',                     #required
        bar    => 'tiny',
    );
}
finally {
    ok(@_, 'register fails when non-existing plugin is required');
};

try {
    $ps->register(
        phase  => 'foo',
        plugin => 'nonexistingPlugin',                     #required
        force  => 1,
    );
}
finally {
    ok(@_, 'register still fails when non-existing plugin is required');
};

ok( $ps->register(
        phase         => 'foo',
        plugin        => 'TinyTestPlugin',                 #required
        plugin_system => $ps,
        role          => 'TestRolePlugin',
        force         => 1
    ),
    'register with single roles succeeds'
);

ok( $ps->register(
        phase         => 'foo',
        plugin        => 'TinyTestPlugin',                       #required
        plugin_system => $ps,
        role          => ['TestRolePlugin', 'TestRolePlugin'],
        force         => 1
    ),
    'register with multiple roles succeeds'
);

#try {
#    $ps->register(
#        phase         => 'foo',
#        plugin        => 'TinySubPlug',       #required
#        plugin_system => $ps,
#        role          => 'TestRolePlugin',
#        force         => 1
#    );
#}
#finally {
#    ok($_, 'register with role fails correctly');
#}

#
# get_plugin, get_phase, get_class
#
note "gets";

my ($p1, $p2);
ok($p1 = $ps->get_plugin('foo'), 'get p1');

is($ps->get_class($p1), 'TinyTestPlugin', 'class is good');
is($ps->get_phase($p1), 'foo',            'phase foo');

is($p1->do_something, 'doing something', 'execute return value');


#
#
#

note "a plugin registers a another plugin";
ok($p1->register_another_plugin, 'registering a new plug from inside a plug');
ok($p2 = $ps->get_plugin('bar'), 'get p2');
is( $p2->do_something,
    'a plugin that is loaded by another plugin',
    'return looks good'
);
is($ps->get_phase($p2), 'bar', 'phase bar');

#
# default phase, prefix with a new plugin_system
#
is($ps->default_phase('TinyTestPlugin'), 'TinyTestPlugin', 'default_phase');
is($ps->default_phase('A::B::C'), 'C', 'default_phase');
$ps = Plugin::Tiny->new(prefix => 'A::');    #resets registry
is($ps->default_phase('A::B::C'), 'BC', 'default_phase');


done_testing;
