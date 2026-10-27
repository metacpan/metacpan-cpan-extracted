use strict;
use warnings;

use Test::More tests => 12;

# The re-entrancy guard uses an internal hash key in the object.
# These tests verify that attribute names which happen to match
# internal key patterns work correctly and don't corrupt state.

# --- 1. Attribute with dunder prefix works as a normal accessor ---
{
    package DunderAttr;
    use Simple::Accessor qw{__sa_setting normal};

    sub _after_normal {
        my ($self, $v) = @_;
        return 1;
    }
}

{
    my $obj = DunderAttr->new();

    # basic get/set on the dunder-named attribute
    $obj->__sa_setting(42);
    is( $obj->__sa_setting(), 42,
        'dunder attribute: set and get works' );

    $obj->__sa_setting(0);
    is( $obj->__sa_setting(), 0,
        'dunder attribute: set to falsy value works' );

    # normal attribute still works alongside the dunder one
    $obj->normal('hello');
    is( $obj->normal(), 'hello',
        'dunder attribute: other attrs unaffected' );

    # dunder attribute value unchanged after setting normal
    is( $obj->__sa_setting(), 0,
        'dunder attribute: value preserved after other attr set' );
}

# --- 2. Re-entrancy guard works with dunder-named attributes ---
{
    package DunderReentrant;
    use Simple::Accessor qw{__sa_setting trigger};

    my @trace;
    sub get_trace { [@trace] }
    sub reset_trace { @trace = () }

    sub _after_trigger {
        my ($self, $v) = @_;
        push @trace, "after_trigger($v)";
        # this would infinite-loop without a working guard
        $self->trigger( $v + 1 ) if $v < 100;
        return 1;
    }

    sub _after___sa_setting {
        my ($self, $v) = @_;
        push @trace, "after___sa_setting($v)";
        # re-entrant set on the dunder-named attribute
        $self->__sa_setting( $v + 1 ) if $v < 100;
        return 1;
    }
}

{
    my $obj = DunderReentrant->new();

    # re-entrancy guard works for regular attribute
    DunderReentrant::reset_trace();
    $obj->trigger(1);
    is( scalar @{DunderReentrant::get_trace()}, 1,
        'dunder + reentrancy: _after_trigger fires once' );
    is( $obj->trigger(), 2,
        'dunder + reentrancy: trigger value updated by nested set' );

    # re-entrancy guard works for the dunder-named attribute itself
    DunderReentrant::reset_trace();
    $obj->__sa_setting(10);
    is( scalar @{DunderReentrant::get_trace()}, 1,
        'dunder + reentrancy: _after___sa_setting fires once' );
    is( $obj->__sa_setting(), 11,
        'dunder + reentrancy: dunder attr value updated by nested set' );
}

# --- 3. Constructor with dunder-named attributes ---
{
    my $obj = DunderAttr->new( __sa_setting => 99, normal => 'yes' );
    is( $obj->__sa_setting(), 99,
        'constructor: dunder attribute initialized correctly' );
    is( $obj->normal(), 'yes',
        'constructor: normal attribute initialized correctly' );
}

# --- 4. Lazy builder on dunder-named attribute ---
{
    package DunderBuilder;
    use Simple::Accessor qw{__sa_setting};

    sub _build___sa_setting { 'lazy_default' }
}

{
    my $obj = DunderBuilder->new();
    is( $obj->__sa_setting(), 'lazy_default',
        'lazy builder: dunder attribute builds correctly' );

    # override after lazy build
    $obj->__sa_setting('overridden');
    is( $obj->__sa_setting(), 'overridden',
        'lazy builder: dunder attribute can be overridden after build' );
}

done_testing();
