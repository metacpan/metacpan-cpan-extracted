use strict;
use warnings;
use Test::More tests => 14;
use Moose::Util::TypeConstraints;

use MooseX::Meta::TypeConstraint::ForceCoercion;

my $tc = Moose::Util::TypeConstraints::find_or_parse_type_constraint('HashRef[HashRef]');

coerce $tc,
    from find_type_constraint('Any'),
    via {
        ref $_ eq 'HASH' && exists $_->{answer} && $_->{answer} == 42
            ? $_
            : +{ actual_value => $_ };
    };

my $coercing_tc = MooseX::Meta::TypeConstraint::ForceCoercion->new(
    type_constraint => $tc,
);

isa_ok($coercing_tc, 'Moose::Meta::TypeConstraint');
is($coercing_tc->name, 'HashRef[HashRef]', 'methods get delegated to the actual tc');

ok(!$coercing_tc->check(42));
ok(!$coercing_tc->check({ answer => 42 }));
ok( $coercing_tc->check({ affe => 'tiger' }));

like($coercing_tc->validate(42), qr/^Validation failed/);
like($coercing_tc->validate({ answer => 42 }), qr/^Coercion failed/);
is($coercing_tc->validate({ affe => 'tiger' }), undef);

my $coerced;
like($coercing_tc->validate(42, \$coerced), qr/^Validation failed/);
is_deeply($coerced, { actual_value => 42 });

undef $coerced;
like($coercing_tc->validate({ answer => 42 }, \$coerced), qr/^Coercion failed/);
is($coerced, undef);

undef $coerced;
is($coercing_tc->validate({ affe => 'tiger' }, \$coerced), undef);
is_deeply($coerced, { actual_value => { affe => 'tiger' } });
