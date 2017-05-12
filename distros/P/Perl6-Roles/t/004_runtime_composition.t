use strict;
use warnings;

use Test::More tests => 14;

use Scalar::Util qw( blessed refaddr );

my $CLASS = 'Perl6::Roles';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

package bark;

use base 'Perl6::Roles';

sub talk {
    return 'woof';
}

package sleeper;

use base 'Perl6::Roles';

sub sleep {
    return 'snore';
}

sub talk {
    return 'zzz';
}

package Class;

sub new {
    return bless {}, shift;
}

sub sleep {
    return 'nite-nite';
}

package main;

ok( !Class->can( 'talk' ), "The role is not composed at the class level." );

my $obj = Class->new;
ok( !$obj->can( 'talk' ), "The role is not composed at the object level." );

my $class = 'Class';

# diag "Applying bark ..."
{
    bark->apply( $obj );
    my $newclass = blessed($obj);
    cmp_ok( $newclass, 'ne', $class,
        "The object is no longer blessed into $class" );
    is( $newclass, $class . '::' . refaddr($obj),
        "The object is now blessed into a package composed of the original name "
    ."plus the refaddr of the object" );
    ok( !$class->can( 'talk' ), "The role is not composed at the class level." );
    ok( $obj->can( 'talk' ), "The role is now composed at the object level." );

    $class = $newclass;
}

# diag "Applying sleep ..."
{
    is( $obj->sleep, 'nite-nite', "The class's original method is still there" );

    sleeper->apply( $obj );
    my $newclass = blessed($obj);
    cmp_ok( $newclass, 'ne', $class,
        "The object is no longer blessed into $class" );
    is( $newclass, $class . '::' . refaddr($obj),
        "The object is now blessed into a package composed of the original name "
    ."plus the refaddr of the object" );
    ok( $obj->can( 'sleep' ), "The role is now composed at the object level." );
    ok( $obj->can( 'talk' ), "The old role is still composed at the object level." );

    is( $obj->sleep, 'snore', "The role silently overrides the class method");
    is( $obj->talk, 'zzz', "The role silently overrides the role's method");

    $class = $newclass;
}
