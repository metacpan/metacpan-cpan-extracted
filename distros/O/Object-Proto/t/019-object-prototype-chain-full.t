#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Define test classes for prototype chaining
# All classes share 'common_value' to test cross-class inheritance
Object::Proto::define('GrandParent', qw(name common_value gp_only));
Object::Proto::define('Parent', qw(name common_value p_only));
Object::Proto::define('Child', qw(name common_value c_only));

# Same-class prototypes for deep chain testing
Object::Proto::define('Node', qw(value next_value));

# ============================================
# Multi-level property resolution (same class)
# ============================================

subtest 'two-level same-class chain' => sub {
    my $n1 = new Node 'level1', 'n1_next';
    my $n2 = new Node undef, undef;

    Object::Proto::set_prototype($n2, $n1);

    # n2 has no value, should get from n1
    is($n2->value, 'level1', 'value inherits from prototype');
    is($n2->next_value, 'n1_next', 'next_value inherits from prototype');
};

subtest 'three-level same-class chain' => sub {
    my $n1 = new Node 'level1', 'n1_next';
    my $n2 = new Node undef, 'n2_next';
    my $n3 = new Node undef, undef;

    Object::Proto::set_prototype($n2, $n1);
    Object::Proto::set_prototype($n3, $n2);

    # n3 should get value from n1 (2 levels up)
    is($n3->value, 'level1', 'value inherits through 2 levels');
    # n3 should get next_value from n2 (1 level up, shadowed)
    is($n3->next_value, 'n2_next', 'next_value from middle level (shadowed)');
};

subtest 'five-level same-class chain' => sub {
    my @nodes;
    push @nodes, new Node 'root', 'root_next';
    for my $i (1..4) {
        my $n = new Node undef, undef;
        Object::Proto::set_prototype($n, $nodes[-1]);
        push @nodes, $n;
    }

    # Node at index 4 (5th node) should resolve from root
    is($nodes[4]->value, 'root', 'five-level chain resolves correctly');
};

# ============================================
# Cross-class prototypes (shared properties only)
# ============================================

subtest 'cross-class prototype with shared property' => sub {
    my $gp = new GrandParent 'gp_name', 'from_grandparent', 'gp_only_val';
    my $p = new Parent undef, undef, 'p_only_val';

    Object::Proto::set_prototype($p, $gp);

    # common_value is shared between classes
    is($p->common_value, 'from_grandparent', 'shared property inherits cross-class');

    # name is also shared
    is($p->name, 'gp_name', 'name inherits cross-class');

    # p_only is Parent's own property
    is($p->p_only, 'p_only_val', 'Parent own property works');
};

subtest 'three-level cross-class chain' => sub {
    my $gp = new GrandParent 'gp', 'from_gp', 'gp_only';
    my $p = new Parent undef, undef, 'p_only';
    my $c = new Child undef, undef, 'c_only';

    Object::Proto::set_prototype($p, $gp);
    Object::Proto::set_prototype($c, $p);

    # Shared properties resolve through chain
    is($c->common_value, 'from_gp', 'common_value resolves from grandparent');
    is($c->name, 'gp', 'name resolves from grandparent');

    # Class-specific properties work
    is($c->c_only, 'c_only', 'Child c_only works');
};

# ============================================
# Circular reference detection
# ============================================

subtest 'circular reference detection' => sub {
    my $n1 = new Node 'a', 'a_next';
    my $n2 = new Node 'b', 'b_next';

    Object::Proto::set_prototype($n1, $n2);
    Object::Proto::set_prototype($n2, $n1);  # Creates cycle

    # Should warn about circular reference, not infinite loop
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    # Create a node with no value to force chain traversal
    my $n3 = new Node undef, undef;
    Object::Proto::set_prototype($n3, $n1);

    # Access should find value before hitting cycle
    is($n3->value, 'a', 'can still access value in cyclic chain');
};

subtest 'self-referential prototype' => sub {
    my $obj = new Node undef, undef;

    Object::Proto::set_prototype($obj, $obj);  # Self-reference

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $val = $obj->value;

    ok(@warnings > 0, 'self-reference produces warning');
    like($warnings[0], qr/[Cc]ircular/, 'warning mentions circular');
};

# ============================================
# New API functions
# ============================================

subtest 'prototype_chain returns full chain' => sub {
    my $n1 = new Node 'n1', 'n1_next';
    my $n2 = new Node 'n2', 'n2_next';
    my $n3 = new Node 'n3', 'n3_next';

    Object::Proto::set_prototype($n2, $n1);
    Object::Proto::set_prototype($n3, $n2);

    my $chain = Object::Proto::prototype_chain($n3);
    ok(ref($chain) eq 'ARRAY', 'prototype_chain returns arrayref');
    is(scalar(@$chain), 3, 'chain has 3 objects');

    # First object should be the object itself
    is($chain->[0]->value, 'n3', 'first in chain is n3');
    is($chain->[1]->value, 'n2', 'second in chain is n2');
    is($chain->[2]->value, 'n1', 'third in chain is n1');
};

subtest 'prototype_chain with no prototype' => sub {
    my $obj = new Node 'data', 'next';

    my $chain = Object::Proto::prototype_chain($obj);
    is(scalar(@$chain), 1, 'chain has only self when no prototype');
};

subtest 'prototype_depth' => sub {
    my $n1 = new Node 'n1', 'n1';
    my $n2 = new Node 'n2', 'n2';
    my $n3 = new Node 'n3', 'n3';

    Object::Proto::set_prototype($n2, $n1);
    Object::Proto::set_prototype($n3, $n2);

    is(Object::Proto::prototype_depth($n1), 0, 'n1 has depth 0');
    is(Object::Proto::prototype_depth($n2), 1, 'n2 has depth 1');
    is(Object::Proto::prototype_depth($n3), 2, 'n3 has depth 2');
};

subtest 'has_own_property' => sub {
    my $n1 = new Node 'data', 'next';
    my $n2 = new Node undef, undef;

    Object::Proto::set_prototype($n2, $n1);

    ok(Object::Proto::has_own_property($n1, 'value'), 'n1 has own value');
    ok(Object::Proto::has_own_property($n1, 'next_value'), 'n1 has own next_value');
    ok(!Object::Proto::has_own_property($n2, 'value'), 'n2 does not have own value');
    ok(!Object::Proto::has_own_property($n2, 'next_value'), 'n2 does not have own next_value');
};

# ============================================
# Property shadowing
# ============================================

subtest 'property shadowing' => sub {
    my $n1 = new Node 'original', 'n1_next';
    my $n2 = new Node 'shadowed', undef;

    Object::Proto::set_prototype($n2, $n1);

    # n2 shadows n1's value
    is($n2->value, 'shadowed', 'n2 shadows value');
    is($n1->value, 'original', 'n1 retains original');

    # n2 inherits next_value
    is($n2->next_value, 'n1_next', 'n2 inherits next_value');
};

subtest 'setting inherited property creates own copy' => sub {
    my $n1 = new Node 'inherited', 'n1_next';
    my $n2 = new Node undef, undef;

    Object::Proto::set_prototype($n2, $n1);

    # First, read inherits from n1
    is($n2->value, 'inherited', 'initially inherits from n1');
    ok(!Object::Proto::has_own_property($n2, 'value'), 'n2 does not have own value yet');

    # Setting creates own property
    $n2->value('own_value');
    is($n2->value, 'own_value', 'now has own value');
    is($n1->value, 'inherited', 'n1 unchanged');

    # Now has_own_property should be true
    ok(Object::Proto::has_own_property($n2, 'value'), 'now has own property');
};

# ============================================
# Edge cases
# ============================================

subtest 'undefined values vs missing properties' => sub {
    my $n1 = new Node undef, 'n1_next';
    my $n2 = new Node undef, undef;

    Object::Proto::set_prototype($n2, $n1);

    # value is undef at both levels
    my $val = $n2->value;
    ok(!defined($val), 'value is undef (not found in chain)');

    # next_value is undef at n2, should fall through to n1
    is($n2->next_value, 'n1_next', 'next_value inherits from n1');
};

subtest 'empty prototype chain' => sub {
    my $obj = new Node 'data', 'next';

    my $depth = Object::Proto::prototype_depth($obj);
    is($depth, 0, 'object with no prototype has depth 0');

    my $chain = Object::Proto::prototype_chain($obj);
    is(scalar(@$chain), 1, 'chain only contains self');
};

subtest 'prototype chain with frozen objects' => sub {
    my $n1 = new Node 'n1', 'n1_next';
    my $n2 = new Node undef, undef;

    Object::Proto::freeze($n1);
    Object::Proto::set_prototype($n2, $n1);

    # Should still be able to read through frozen prototype
    is($n2->value, 'n1', 'can read through frozen prototype');

    my $chain = Object::Proto::prototype_chain($n2);
    is(scalar(@$chain), 2, 'chain includes frozen prototype');
};

subtest 'modifying prototype affects inheritors' => sub {
    my $n1 = new Node 'original', 'n1_next';
    my $n2 = new Node undef, undef;

    Object::Proto::set_prototype($n2, $n1);

    is($n2->value, 'original', 'initially inherits original');

    # Modify prototype
    $n1->value('modified');

    # n2 should see the change (since it inherits)
    is($n2->value, 'modified', 'inheritor sees prototype change');
};

done_testing();
