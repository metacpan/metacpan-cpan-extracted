#!/usr/bin/perl
use strict;
use warnings;
use Test::More 0.96;

use lib 'lib';

BEGIN { require Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls }

# Constants matching those in the policy
use constant BLOCK_BARE     => 'bare';
use constant BLOCK_DO       => 'do';
use constant BLOCK_EVAL     => 'eval';
use constant BLOCK_MAP_GREP => 'map_grep';
use constant BLOCK_SUB      => 'sub';
use constant FORBID         => 'forbid';
use constant REQUIRE_LABEL  => 'require_label';

{
    my $desc =
        Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_description( 'next', BLOCK_BARE );
    is( $desc, "'next' in bare block", '_make_description: next in bare block' );
}

{
    my $desc =
        Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_description( 'last', BLOCK_DO );
    is( $desc, "'last' in \"do\" block", '_make_description: last in do block' );
}

{
    my $desc =
        Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_description( 'redo', BLOCK_EVAL );
    is( $desc, "'redo' in \"eval\" block", '_make_description: redo in eval block' );
}

{
    my $desc =
        Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_description( 'next', BLOCK_SUB );
    is( $desc, "'next' in anonymous subroutine", '_make_description: next in sub' );
}

{
    my $desc = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_description(
        'next',
        BLOCK_MAP_GREP
    );
    is( $desc, "'next' in map/grep block", '_make_description: next in map/grep' );
}

{
    my $desc =
        Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_description( 'next', 'bogus' );
    is( $desc, "'next' in non-loop block", '_make_description: unknown type fallback' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'next', BLOCK_DO,
        FORBID
    );
    like( $exp, qr/"next" inside a "do" block/, '_make_explanation: do block start' );
    like( $exp, qr/fatal error/,                '_make_explanation: do block fatal' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'last', BLOCK_DO,
        FORBID
    );
    like( $exp, qr/"last" inside a "do" block/, '_make_explanation: do block last' );
    like( $exp, qr/fatal error/,                '_make_explanation: do block last fatal' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'redo', BLOCK_DO,
        FORBID
    );
    like( $exp, qr/"redo" inside a "do" block/, '_make_explanation: do block redo' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'next', BLOCK_SUB,
        FORBID
    );
    like( $exp, qr/anonymous subroutine/, '_make_explanation: sub block' );
    like( $exp, qr/explicit label/,       '_make_explanation: sub block label' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'next', BLOCK_EVAL,
        FORBID
    );
    like( $exp, qr/"eval" is not a loop/, '_make_explanation: eval block' );
    like( $exp, qr/explicit label/,       '_make_explanation: eval block label' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'next',
        BLOCK_MAP_GREP, FORBID
    );
    like( $exp, qr/next element/, '_make_explanation: map block' );
    like( $exp, qr/"for" loop/,   '_make_explanation: map block for' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'last',
        BLOCK_MAP_GREP, FORBID
    );
    like( $exp, qr/last/, '_make_explanation: map block last' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'redo',
        BLOCK_MAP_GREP, FORBID
    );
    like( $exp, qr/redo/, '_make_explanation: map block redo' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'next', BLOCK_BARE,
        FORBID
    );
    like( $exp, qr/just exits the block/, '_make_explanation: bare block forbid next' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'last', BLOCK_BARE,
        FORBID
    );
    like( $exp, qr/just exits the block/, '_make_explanation: bare block forbid last' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'redo', BLOCK_BARE,
        FORBID
    );
    like( $exp, qr/restarts the block/, '_make_explanation: bare block forbid redo' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'next', BLOCK_BARE,
        REQUIRE_LABEL
    );
    like( $exp, qr/explicit label/, '_make_explanation: bare block require_label' );
    unlike( $exp, qr/bare/, '_make_explanation: bare block require_label no bare mention' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'last', BLOCK_BARE,
        REQUIRE_LABEL
    );
    like( $exp, qr/explicit label/, '_make_explanation: bare block require_label last' );
}

{
    my $exp = Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::_make_explanation(
        'redo', BLOCK_BARE,
        REQUIRE_LABEL
    );
    like( $exp, qr/explicit label/, '_make_explanation: bare block require_label redo' );
}

done_testing;
