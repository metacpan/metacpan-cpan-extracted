use strict;
use warnings;
use Test::More tests => 21;

use File::Spec::Functions;

use Module::Collect;

do {
    my $collect = Module::Collect->new( path => [ catfile('t', 'plugin3') ] );
    is @{ $collect->modules }, 1;
    is $collect->modules->[0]->package, 'Three';
    is $collect->modules->[1], undef;
};


my $collect = Module::Collect->new( path => [ catfile('t', 'plugin3') ], multiple => 1 );
is @{ $collect->modules }, 3;
is $collect->modules->[0]->package, 'Three';
is $collect->modules->[1]->package, 'Three::Bar';
is $collect->modules->[2]->package, 'ThreeBar';

do {
    my ($module) = grep { $_->package eq 'Three::Bar' } @{ $collect->modules };
    isa_ok $module, 'Module::Collect::Package';
    ok !grep { catfile($_) eq catfile('t', 'plugin3', 'three.pm') } keys %INC;
    ok $module->require;
    ok grep { catfile($_) eq catfile('t', 'plugin3', 'three.pm') } keys %INC;

    my $obj = $module->new({ three => 3 });
    ok $obj;
    isa_ok $obj, 'Three::Bar';
    is $obj->three, 3;
};

do {
    # ThreeBar
    my ($module) = grep { $_->package eq 'ThreeBar' } @{ $collect->modules };
    isa_ok $module, 'Module::Collect::Package';
    ok grep { catfile($_) eq catfile('t', 'plugin3', 'three.pm') } keys %INC;
    ok $module->require;
    ok grep { catfile($_) eq catfile('t', 'plugin3', 'three.pm') } keys %INC;

    my $obj = $module->new({ three => 3 });
    ok $obj;
    isa_ok $obj, 'ThreeBar';
    is $obj->three, 1;
};
