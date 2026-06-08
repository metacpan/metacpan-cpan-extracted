use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Role::Tiny; 1 } or plan skip_all => 'Role::Tiny required';
    plan skip_all => 'Role::Tiny 1.003000 or newer required (is_role missing)'
        unless Role::Tiny->can('is_role');
    plan skip_all => "& prefix requires perl 5.10+" if $] < 5.010;
}

BEGIN {
    package My::CRole;
    use Role::Tiny;
    use Object::HashBase qw/cr/;
    $INC{'My/CRole.pm'} = __FILE__;
}

# Consumer uses +CR constant at compile time — must resolve
BEGIN {
    package My::CClass;
    use Object::HashBase qw/&My::CRole own/;

    sub uses_constants {
        my $self = shift;
        return [ $self->{+CR}, $self->{+OWN} ];
    }
}

ok(Role::Tiny::does_role('My::CClass', 'My::CRole'), 'role composed into consumer');

can_ok('My::CClass', qw/CR OWN cr own set_cr set_own new uses_constants/);
is(My::CClass::CR(), 'cr', 'CR constant copied to consumer');
is(My::CClass::OWN(), 'own', 'OWN constant');

my $obj = My::CClass->new(cr => 'role-val', own => 'own-val');
is($obj->cr, 'role-val', 'role accessor works on consumer instance');
is($obj->own, 'own-val', 'own accessor works');
is_deeply($obj->uses_constants, ['role-val', 'own-val'], '+CONSTANT resolves at compile in consumer sub');

# Conflict: consumer already has CR sub before & prefix processed
BEGIN {
    package My::ConflictRole;
    use Role::Tiny;
    use Object::HashBase qw/cflict/;
    $INC{'My/ConflictRole.pm'} = __FILE__;
}

BEGIN {
    package My::ConflictConsumer;
    sub CFLICT { 'overridden-value' }
    use Object::HashBase qw/&My::ConflictRole/;
}

is(My::ConflictConsumer::CFLICT(), 'overridden-value',
    'existing sub kept, role constant not copied over it');

# No warnings emitted
{
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, @_ };
    eval q{
        package My::SilentConflict;
        sub CFLICT { 'mine' }
        use Object::HashBase qw/&My::ConflictRole/;
        1;
    } or do { fail("compile failed: $@") };
    is_deeply(\@warns, [], 'no warnings on silent conflict');
}

# attr_list includes role attrs for array-form constructor
{
    my @attrs = Object::HashBase::attr_list('My::CClass');
    is_deeply(
        [ sort @attrs ],
        [ sort qw/cr own/ ],
        'attr_list includes role + own attrs'
    );

    # Array-form constructor uses ordered attr_list
    # Order: role attrs first (composed earlier), then own
    my @ordered = Object::HashBase::attr_list('My::CClass');
    my $obj = My::CClass->new([ map { "v_$_" } @ordered ]);
    for my $a (@ordered) {
        is($obj->{$a}, "v_$a", "array-form set $a from attr_list order");
    }
}

# Multiple roles composed at once
BEGIN {
    package My::RA;
    use Role::Tiny;
    use Object::HashBase qw/ra_attr/;
    sub ra_method { 'RA' }
    $INC{'My/RA.pm'} = __FILE__;

    package My::RB;
    use Role::Tiny;
    use Object::HashBase qw/rb_attr/;
    sub rb_method { 'RB' }
    $INC{'My/RB.pm'} = __FILE__;
}

BEGIN {
    package My::Multi;
    use Object::HashBase qw/&My::RA &My::RB own_attr/;
}

ok(Role::Tiny::does_role('My::Multi', 'My::RA'), 'role RA composed');
ok(Role::Tiny::does_role('My::Multi', 'My::RB'), 'role RB composed');
is(My::Multi->new->ra_method, 'RA', 'RA method');
is(My::Multi->new->rb_method, 'RB', 'RB method');

# Method modifier (around) is covered in t/role_modifiers.t, which is skipped
# when Class::Method::Modifiers is unavailable (Role::Tiny loads it lazily).

# Required method satisfied by consumer's later sub
BEGIN {
    package My::ReqRole;
    use Role::Tiny;
    use Object::HashBase qw/req_attr/;
    requires 'must_have';
    $INC{'My/ReqRole.pm'} = __FILE__;
}

BEGIN {
    package My::ReqConsumer;
    use Object::HashBase qw/&My::ReqRole/;
    sub must_have { 'present' }
}

ok(Role::Tiny::does_role('My::ReqConsumer', 'My::ReqRole'),
    'required method satisfied by later-defined sub');
is(My::ReqConsumer->new->must_have, 'present', 'required method callable');

# Non-existent role
{
    my $err;
    eval q{
        package My::BadRoleConsumer;
        use Object::HashBase '&Bogus::Role::Name';
        1;
    } or $err = $@;
    like($err, qr/Could not load role 'Bogus::Role::Name'/, 'non-existent role croaks');
}

# Plain class (not a Role::Tiny role)
BEGIN {
    package My::PlainClass;
    use Object::HashBase qw/pcattr/;
    $INC{'My/PlainClass.pm'} = __FILE__;
}
{
    my $err;
    eval q{
        package My::BadConsumer1;
        use Object::HashBase '&My::PlainClass';
        1;
    } or $err = $@;
    like($err, qr/'My::PlainClass' is not a Role::Tiny role/, 'plain class as role croaks');
}

# Role without Object::HashBase
BEGIN {
    package My::NoHBRole;
    use Role::Tiny;
    $INC{'My/NoHBRole.pm'} = __FILE__;
}
{
    my $err;
    eval q{
        package My::BadConsumer2;
        use Object::HashBase '&My::NoHBRole';
        1;
    } or $err = $@;
    like($err, qr/'My::NoHBRole' does not use Object::HashBase/, 'role without HashBase croaks');
}

# Auto-load Role::Tiny: simulate by checking it loads on demand.
# We can't fully simulate "Role::Tiny not loaded" in a process that already
# loaded it via the role definitions above, but we can verify the require
# path works by ensuring no croak when consumer omits `use Role::Tiny::With;`.
BEGIN {
    package My::AutoRole;
    use Role::Tiny;
    use Object::HashBase qw/auto/;
    $INC{'My/AutoRole.pm'} = __FILE__;
}

BEGIN {
    package My::AutoConsumer;
    # No `use Role::Tiny` here — Object::HashBase auto-loads it for &
    use Object::HashBase qw/&My::AutoRole/;
}

ok(Role::Tiny::does_role('My::AutoConsumer', 'My::AutoRole'),
    'consumer composed role without explicitly loading Role::Tiny');

done_testing;
