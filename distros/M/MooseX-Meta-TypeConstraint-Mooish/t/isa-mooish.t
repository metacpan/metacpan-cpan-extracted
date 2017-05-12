use strict;
use warnings;

# de minimus testing

use Test::More;
use Test::Moose::More 0.017;
use Test::Fatal;

use aliased 'Moose::Meta::TypeConstraint'                    => 'TypeConstraint';
use aliased 'MooseX::Meta::TypeConstraint::Mooish'           => 'MooishTC';
use aliased 'MooseX::TraitFor::Meta::TypeConstraint::Mooish' => 'TraitFor';

my $tc = MooishTC->new(
    constraint => sub { die if $_[0] ne '5' },
);
isa_ok $tc, MooishTC;
ok $tc->has_original_constraint => 'has an original constraint';
ok $tc->mooish                  => 'is mooish';

ok  $tc->check(5)      => 'constraint passes with 5';
ok !$tc->check('five') => 'constraint fails with "five"';

done_testing;
