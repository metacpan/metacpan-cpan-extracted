use strict;
use warnings;
use Test::More;
use Moose ();
use Moose::Meta::TypeConstraint::Role;

BEGIN { use_ok('MooseX::Meta::TypeConstraint::Intersection') }

{ package Foo;           use Moose::Role; }
{ package Bar;           use Moose::Role; }
{ package Baz;           use Moose::Role; }
{ package UnrelatedRole; use Moose::Role; }

{ package NoneOfTheRoles;      use Moose;                                           }
{ package OneOfTheRoles;       use Moose; with 'Bar';                               }
{ package AllTheRoles;         use Moose; with 'Bar', 'Foo', 'Baz'                  }
{ package WithAdditionalRoles; use Moose; with 'Bar', 'Foo', 'UnrelatedRole', 'Baz' }

sub new_intersection {
    my (@tcs) = @_;
    return MooseX::Meta::TypeConstraint::Intersection->new(
        type_constraints => \@tcs,
    );
}

my @role_tcs = map {
    Moose::Meta::TypeConstraint::Role->new(role => $_, name => $_)
} qw/Foo Bar Baz/;

isa_ok($_, 'Moose::Meta::TypeConstraint') for @role_tcs;

my $intersection = new_intersection(@role_tcs);

isa_ok($intersection, 'Moose::Meta::TypeConstraint');

is($intersection->name, 'Bar&Baz&Foo', 'union name is built from the name of the contained TCs, joined with &');
is(
    $intersection->name,
    new_intersection(reverse @role_tcs)->name,
    'order of type constraints does not matter',
);

ok($intersection->equals($intersection), 'is equal to itself');
ok($intersection->equals(new_intersection(@role_tcs)), 'is equal to clone');
ok($intersection->equals(new_intersection(reverse @role_tcs)), 'is equal to reversed clone');

ok(!$intersection->check(NoneOfTheRoles->new     ));
ok(!$intersection->check(OneOfTheRoles->new      ));
ok( $intersection->check(AllTheRoles->new        ));
ok( $intersection->check(WithAdditionalRoles->new));

like(
    $intersection->validate(NoneOfTheRoles->new),
    qr{^Validation failed for 'Foo' .*? and Validation failed for 'Bar' .*? and Validation failed for 'Baz' .*? in Bar&Baz&Foo},
);

like(
    $intersection->validate(OneOfTheRoles->new),
    qr{^Validation failed for 'Foo' .*? and Validation failed for 'Baz' .*? in Bar&Baz&Foo},
);

is($intersection->validate(AllTheRoles->new        ), undef);
is($intersection->validate(WithAdditionalRoles->new), undef);

{
    my $msgs = $intersection->validate_all(NoneOfTheRoles->new);
    ok(defined $msgs);

    my $i = 0;
    for my $test (map {
            [@{ $msgs->[$i++] }, qr{^Validation failed for '${_}'}, $_]
        } qw/Foo Bar Baz/) {
        like($test->[0], $test->[2]);
        is($test->[1]->name, $test->[3]);
    }
}

{
    my $msgs = $intersection->validate_all(OneOfTheRoles->new);
    ok(defined $msgs);

    my $i = 0;
    for my $test (map {
            [@{ $msgs->[$i++] }, qr{^Validation failed for '${_}'}, $_]
        } qw/Foo Baz/) {
        like($test->[0], $test->[2]);
        is($test->[1]->name, $test->[3]);
    }
}

ok(!defined $intersection->validate_all(AllTheRoles->new));

done_testing;
