#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which sub declarations the policy reads as private by convention,
and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported declaration is a package sub whose name, after the last C<::>,
starts with an underscore.  The edges are the kinds of declaration (C<my>,
C<state>, C<our> and none), a fully qualified name, a forward declaration,
an underscore that is not first, and the C<allow> parameter.

=cut

use Test::More;

use Perl::Critic;

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::Subroutines::ProhibitUnderscorePrivateSubs;    ## no critic (ProhibitUnusedImports)

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::Subroutines::ProhibitUnderscorePrivateSubs$';

my $check_table = sub {
    my ( $critic, $label, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $critic->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

my $critic = Perl::Critic->new( -profile => q{}, '-single-policy' => $POLICY, -severity => 1 );

$check_table->(
    $critic,
    'package subs',
    'a leading underscore'      => [ 1, q{sub _helper { return 1 }} ],
    'two of them'               => [ 1, q{sub __helper { return 1 }} ],
    'a forward declaration'     => [ 1, q{sub _helper;} ],
    'a fully qualified name'    => [ 1, q{sub Some::Module::_helper { return 1 }} ],
    'the old package separator' => [ 1, q{sub Some'_helper { return 1 }} ],
    'declared with our'         => [ 1, q{our sub _helper { return 1 }} ],
    'with a prototype'          => [ 1, q{sub _helper($) { return 1 }} ],
    'with a signature'          => [ 1, q{sub _helper ($x) { return $x }} ],
    'with an attribute'         => [ 1, q{sub _helper :lvalue { return $x }} ],
    'each one'                  => [ 2, q{sub _one { return 1 } sub _two { return 2 }} ],
);

$check_table->(
    $critic,
    'allowed',
    'a public name'                    => [ 0, q{sub helper { return 1 }} ],
    'an underscore that is not first'  => [ 0, q{sub some_helper { return 1 }} ],
    'a package whose name has one'     => [ 0, q{sub _Some::helper { return 1 }} ],
    'a lexical sub'                    => [ 0, q{my sub _helper { return 1 }} ],
    'a state sub'                      => [ 0, q{state sub _helper { return 1 }} ],
    'an anonymous sub'                 => [ 0, q{my $_helper = sub { return 1 };} ],
    'a call to one declared elsewhere' => [ 0, q{_helper(); $self->_helper();} ],
    'a block that perl runs by itself' => [ 0, q{BEGIN { return 1 } END { return 1 }} ],
);

my $allowing = Perl::Critic->new(
    -profile         => \qq{[Subroutines::ProhibitUnderscorePrivateSubs]\nallow = _build_thing _trigger_thing\n},
    '-single-policy' => $POLICY,
    -severity        => 1,
);

$check_table->(
    $allowing,
    'with allow',
    'a name it lists'                 => [ 0, q{sub _build_thing { return 1 }} ],
    'the other name it lists'         => [ 0, q{sub _trigger_thing { return 1 }} ],
    'a fully qualified name it lists' => [ 0, q{sub Some::Module::_build_thing { return 1 }} ],
    'a name it does not list'         => [ 1, q{sub _build_other { return 1 }} ],
    'a longer name that starts alike' => [ 1, q{sub _build_things { return 1 }} ],
);

done_testing;
