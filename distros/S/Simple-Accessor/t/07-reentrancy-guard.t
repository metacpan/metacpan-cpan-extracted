use strict;
use warnings;

use Test::More tests => 10;

# --- 1. Direct re-entrancy: _after_foo sets foo again ---
{
    package ReentrantDirect;
    use Simple::Accessor qw{counter};

    my $after_calls = 0;

    sub get_after_calls { $after_calls }
    sub reset_after_calls { $after_calls = 0 }

    sub _after_counter {
        my ($self, $v) = @_;
        $after_calls++;
        # This would cause infinite recursion without the guard
        $self->counter( $v + 1 ) if $v < 100;
        return 1;
    }
}

{
    my $obj = ReentrantDirect->new();
    ReentrantDirect::reset_after_calls();
    $obj->counter(1);
    is( ReentrantDirect::get_after_calls(), 1,
        'direct re-entrancy: _after_counter fires exactly once' );
    is( $obj->counter(), 2,
        'direct re-entrancy: nested set still updates the value' );
}

# --- 2. Mutual re-entrancy: _after_a sets b, _after_b sets a ---
{
    package ReentrantMutual;
    use Simple::Accessor qw{alpha beta};

    my @trace;

    sub get_trace { [@trace] }
    sub reset_trace { @trace = () }

    sub _after_alpha {
        my ($self, $v) = @_;
        push @trace, "after_alpha($v)";
        $self->beta('from_alpha');
        return 1;
    }

    sub _after_beta {
        my ($self, $v) = @_;
        push @trace, "after_beta($v)";
        $self->alpha('from_beta');
        return 1;
    }
}

{
    my $obj = ReentrantMutual->new();
    ReentrantMutual::reset_trace();
    $obj->alpha('start');

    my $trace = ReentrantMutual::get_trace();
    # alpha('start') -> _after_alpha -> beta('from_alpha') -> _after_beta -> alpha('from_beta')
    # alpha('from_beta') is setting alpha while alpha's _after is on the stack -> guard skips _after_alpha
    is( scalar @$trace, 2,
        'mutual re-entrancy: exactly 2 after hooks fire (no infinite loop)' );
    is( $trace->[0], 'after_alpha(start)',
        'mutual re-entrancy: first hook is after_alpha' );
    is( $trace->[1], 'after_beta(from_alpha)',
        'mutual re-entrancy: second hook is after_beta' );
    is( $obj->alpha(), 'from_beta',
        'mutual re-entrancy: final alpha value from nested set' );
    is( $obj->beta(), 'from_alpha',
        'mutual re-entrancy: final beta value from first set' );
}

# --- 3. Guard does NOT block normal sequential calls ---
{
    package SequentialSets;
    use Simple::Accessor qw{val};

    my $after_count = 0;

    sub get_after_count { $after_count }
    sub reset_after_count { $after_count = 0 }

    sub _after_val {
        my ($self, $v) = @_;
        $after_count++;
        return 1;
    }
}

{
    my $obj = SequentialSets->new();
    SequentialSets::reset_after_count();
    $obj->val(1);
    $obj->val(2);
    $obj->val(3);
    is( SequentialSets::get_after_count(), 3,
        'sequential sets: _after_val fires on each independent call' );
}

# --- 4. Guard is per-attribute, not global ---
{
    package PerAttribute;
    use Simple::Accessor qw{x y};

    my @fired;

    sub get_fired { [@fired] }
    sub reset_fired { @fired = () }

    sub _after_x {
        my ($self, $v) = @_;
        push @fired, 'after_x';
        $self->y('set_by_x');
        return 1;
    }

    sub _after_y {
        my ($self, $v) = @_;
        push @fired, 'after_y';
        return 1;
    }
}

{
    my $obj = PerAttribute->new();
    PerAttribute::reset_fired();
    $obj->x('go');
    my $fired = PerAttribute::get_fired();
    is( scalar @$fired, 2,
        'per-attribute guard: both after_x and after_y fire' );
    is_deeply( $fired, ['after_x', 'after_y'],
        'per-attribute guard: after_y fires from within after_x (different attribute)' );
}

done_testing();
