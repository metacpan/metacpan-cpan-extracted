use strict;
use warnings;
use Test::More;
use Object::Proto;

# A type the user registers takes precedence over a built-in of the same
# name. Types are resolved when a class is defined, so a class defined before
# the registration keeps the built-in.

Object::Proto::define('TBefore', 'v:PositiveInt');

# The user's PositiveInt also accepts zero
my $calls = 0;
Object::Proto::register_type('PositiveInt', sub {
    $calls++;
    defined $_[0] && $_[0] =~ /^\d+$/;
});

Object::Proto::define('TAfter', 'v:PositiveInt');

my $after = TAfter->new;
is($after->v(0), 0, "the user's PositiveInt is used: it accepts zero");
ok($calls > 0, "and its check was called");
eval { $after->v(-1) };
like($@, qr/Type constraint failed for 'v': expected PositiveInt\b/, 'a failure names the type');
eval { TAfter->new(v => 'x') };
like($@, qr/in new\(\): expected PositiveInt\b/, 'and new() uses it too');

my $before = TBefore->new;
eval { $before->v(0) };
like($@, qr/expected PositiveInt\b/, 'a class defined before the registration keeps the built-in');

ok(Object::Proto::has_type('PositiveInt'), 'has_type knows PositiveInt');
is(scalar(grep { $_ eq 'PositiveInt' } @{ Object::Proto::list_types() }), 1, 'list_types lists it once');
is(Object::Proto::slot_info('TAfter', 'v')->{type}, 'PositiveInt', 'slot_info names it');
eval { Object::Proto::register_type('PositiveInt', sub { 1 }) };
like($@, qr/Type 'PositiveInt' is already registered/, 'it cannot be registered a second time');

# A user type can bring a coercion that the built-in does not have
Object::Proto::register_type('NonEmptyStr',
    sub { defined $_[0] && length $_[0] },
    sub { defined $_[0] && length $_[0] ? $_[0] : 'none' },
);
Object::Proto::define('TCoerce', 'v:NonEmptyStr');
is(TCoerce->new(v => '')->v, 'none', "the user's NonEmptyStr coerces");

# The rule holds for the original built-ins too
Object::Proto::register_type('Bool', sub { defined $_[0] && $_[0] =~ /^(?:yes|no)$/ });
Object::Proto::define('TBool', 'v:Bool');
is(TBool->new(v => 'yes')->v, 'yes', "a user's Bool takes precedence over the built-in");
eval { TBool->new(v => 1) };
like($@, qr/expected Bool\b/, 'and rejects what it does not accept');
is(scalar(grep { $_ eq 'Bool' } @{ Object::Proto::list_types() }), 1, 'list_types lists Bool once');

# A name that is neither registered nor built in leaves the slot untyped
Object::Proto::define('TUnknown', 'v:Bolt');
ok(!Object::Proto::slot_info('TUnknown', 'v')->{has_type}, 'an unknown type name gives an untyped slot');

done_testing;
