use strict;
use warnings;
use Test::More 0.88;

do {
    package OtherRole;
    use Moose::Role;
};

do {
    package MyRole;
    use MooseX::Role::Parameterized;

    requires 'requirement';
    excludes 'exclusion';

    has attribute => ();

    method meth => sub {};
    before meth => sub {};
    after  meth => sub {};
    around meth => sub {};

    sub regular_method {}

    override other_meth => sub { super };

    with 'OtherRole';

    role { }
};

for my $meta (MyRole->meta, MyRole->meta->generate_role) {
    ok($meta->has_attribute('attribute'), 'has');
    ok($meta->has_method('meth'), 'method');
    ok($meta->has_method('regular_method'), 'sub');

    is($meta->has_before_method_modifiers('meth'), 1, 'before');
    is($meta->has_after_method_modifiers('meth'),  1, 'after');
    is($meta->has_around_method_modifiers('meth'), 1, 'around');

    is($meta->has_override_method_modifier('other_meth'), 1, 'override');
    is($meta->does_role('OtherRole'), 1, 'with');

    ok($meta->requires_method('requirement'), 'requires');
    ok($meta->excludes_role('exclusion'), 'excludes');
}

done_testing;
