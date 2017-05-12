#!perl
package TestModifiers;

use Test::More;
plan tests => 4;

my $CLASS = __PACKAGE__;

use_ok 'Sub::Mage', ':Debug';

can_ok 'Sub::Mage' => qw/
    override
    around
    before
    after
/;

sub test { "World"; }

subtest 'Test Override' => sub {
    $CLASS->override( test => sub {
        "Town";
    });

    is test(), "Town", 'Override succeeded';
};

subtest 'Test Restore' => sub {
    $CLASS->restore( 'test' );
    
    is test(), "World", 'Restore succeeded';
};
