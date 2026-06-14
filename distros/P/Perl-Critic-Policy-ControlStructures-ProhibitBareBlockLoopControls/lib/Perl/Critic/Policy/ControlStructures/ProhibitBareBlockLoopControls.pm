#!/bin/false
# ABSTRACT: Prohibit unlabeled loop controls in non-loop blocks
# PODNAME: Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls

use strict;
use warnings;

package Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls;
$Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::VERSION = '0.03';
use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(:severities);

use namespace::clean;

# Block classifications
use constant BLOCK_BARE     => 'bare';
use constant BLOCK_DO       => 'do';
use constant BLOCK_EVAL     => 'eval';
use constant BLOCK_MAP_GREP => 'map_grep';
use constant BLOCK_SUB      => 'sub';

# Per-keyword values
use constant ALLOW         => 'allow';
use constant FORBID        => 'forbid';
use constant REQUIRE_LABEL => 'require_label';
use constant PER_KEYWORD_DEFAULTS => {
    'last' => REQUIRE_LABEL,
    'next' => FORBID,
    'redo' => FORBID,
};
use constant PER_KEYWORD_NAMES => qw(next last redo);

# Block override values
use constant FOLLOW => 'follow';

# Block-level config names and defaults
use constant BLOCK_CONFIG_DEFAULTS => {
    'bare_block' => REQUIRE_LABEL,
    'do_block'   => FORBID,
};
use constant BLOCK_CONFIG_NAMES => qw(do_block bare_block);

# Labels returned by _find_offending_block
use constant BLOCK_NICKNAMES => {
    'bare'     => 'bare block',
    'do'       => q{"do"} . ' block',
    'eval'     => q{"eval"} . ' block',
    'map_grep' => 'map/grep block',
    'sub'      => 'anonymous subroutine',
};

sub supported_parameters {
    my @params;

    for my $kw (PER_KEYWORD_NAMES) {
        push @params, {
            behavior       => 'string',
            default_string => PER_KEYWORD_DEFAULTS->{$kw},
            description    => qq{Policy for "$kw" in non-loop blocks},
            name           => $kw,
        };
    }

    for my $name (BLOCK_CONFIG_NAMES) {
        push @params, {
            behavior       => 'string',
            default_string => BLOCK_CONFIG_DEFAULTS->{$name},
            description    => qq{Override for "$name" blocks},
            name           => $name,
        };
    }

    return @params;
}

sub default_severity { return $SEVERITY_HIGHEST; }
sub default_themes   { return qw(bugs control); }
sub applies_to       { return 'PPI::Statement::Break'; }

sub _param {
    my ( $self, $name ) = @_;

    my $val = $self->{ '_' . $name };

    return defined $val ? $val : PER_KEYWORD_DEFAULTS->{$name} // BLOCK_CONFIG_DEFAULTS->{$name};
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $keyword = _break_keyword($elem);
    return if !$keyword;

    my $per_keyword = $self->_param($keyword);

    return if $per_keyword eq ALLOW;

    my ($block_type) = _find_offending_block($elem);
    return if !$block_type;

    my $effective = $self->_effective_policy( $keyword, $per_keyword, $block_type );

    if ( $effective eq FORBID ) {
        return $self->violation(
            _make_description( $keyword, $block_type ),
            _make_explanation( $keyword, $block_type, $effective ), $elem,
        );
    }

    if ( $effective eq REQUIRE_LABEL ) {
        return if _has_label($elem);
        return $self->violation(
            _make_description( $keyword, $block_type ),
            _make_explanation( $keyword, $block_type, $effective ), $elem,
        );
    }

    return;
}

sub _effective_policy {
    my ( $self, $keyword, $per_keyword, $block_type ) = @_;

    my $override;
    if ( $block_type eq BLOCK_DO ) {
        $override = $self->_param('do_block');
    }
    elsif ( $block_type eq BLOCK_BARE ) {
        $override = $self->_param('bare_block');
    }

    if ( defined $override && $override ne FOLLOW ) {
        return $override;
    }

    return $per_keyword;
}

sub _break_keyword {
    my ($elem) = @_;

    my $first = $elem->schild(0);
    return if !$first || !$first->isa('PPI::Token::Word');

    my $content = $first->content;
    return if $content !~ m/^(?:next|last|redo)\z/;

    return $content;
}

sub _find_offending_block {
    my ($elem) = @_;

    my $current = $elem;
    ELEM:
    while ( defined( $current = $current->parent ) ) {
        next ELEM if !$current->isa('PPI::Structure::Block');

        my $parent = $current->parent;

        if ( $parent && $parent->isa('PPI::Statement::Compound') ) {
            my $type_elem = $parent->schild(0);
            my $type      = $type_elem ? $type_elem->content : q();

            # Real loop — safe (first child is keyword like while/for)
            if (   $type_elem
                && $type_elem->isa('PPI::Token::Word')
                && $type =~ m/^(?:while|until|for|foreach)\z/ ) {
                return;
            }

            # Bare block — first child is PPI::Structure::Block
            if ( $type_elem && $type_elem->isa('PPI::Structure::Block') ) {
                return BLOCK_BARE;
            }

            # if / unless / given / when — not a loop, keep walking
            next ELEM;
        }

        my $class = _classify_block($current);
        return if !$class;

        return $class;
    }

    return;
}

sub _classify_block {
    my ($block) = @_;

    my $prev = _prev_significant_sibling($block);

    if ($prev) {
        my $content = $prev->content;

        if ( $content eq 'do' )   { return BLOCK_DO; }
        if ( $content eq 'eval' ) { return BLOCK_EVAL; }
        if ( $content eq 'map' || $content eq 'grep' ) {
            return BLOCK_MAP_GREP;
        }
        if ( $content eq 'sub' ) { return BLOCK_SUB; }

        my $check = $prev;
        CHECK:
        while ($check) {
            if (   $check->isa('PPI::Token::Word')
                && $check->content eq 'sub' ) {
                return BLOCK_SUB;
            }
            if (   $check->isa('PPI::Token::Attribute')
                || $check->isa('PPI::Token::Prototype')
                || $check->isa('PPI::Token::Operator') ) {
                $check = $check->sprevious_sibling;
                next CHECK;
            }
            last CHECK;
        }
    }

    return BLOCK_BARE;
}

sub _prev_significant_sibling {
    my ($elem) = @_;

    my $prev = $elem->sprevious_sibling;
    while (
        $prev
        && (   $prev->isa('PPI::Token::Whitespace')
            || $prev->isa('PPI::Token::Comment')
            || $prev->isa('PPI::Token::Pod') )
    ) {
        $prev = $prev->sprevious_sibling;
    }
    return $prev;
}

sub _has_label {
    my ($stmt) = @_;

    my @kids =
        grep { !$_->isa('PPI::Token::Whitespace') && !$_->isa('PPI::Token::Comment') && !$_->isa('PPI::Token::Pod') }
        $stmt->children;

    return if @kids < 2;
    return if !$kids[0]->isa('PPI::Token::Word');

    my $second = $kids[1];

    if ( $second->isa('PPI::Token::Word') ) {
        return
            if $second->content =~ m/^(?:if|unless|while|until|for|foreach|when|given|not|and|or|xor)\z/;
        return 1;
    }

    if (   $second->isa('PPI::Token::Number')
        || $second->isa('PPI::Token::Symbol') ) {
        return 1;
    }

    return;
}

sub _make_description {
    my ( $keyword, $block_type ) = @_;

    my $nick = BLOCK_NICKNAMES->{$block_type} || 'non-loop block';
    return qq{'$keyword' in $nick};
}

sub _make_explanation {
    my ( $keyword, $block_type, $effective ) = @_;

    if ( $block_type eq BLOCK_DO ) {
        return
              qq{"$keyword" inside a "do" block targets the nearest real loop }
            . qq{--- "do" itself is not a loop. When no enclosing loop exists, }
            . qq{this is a fatal error.};
    }
    if ( $block_type eq BLOCK_SUB ) {
        return
              qq{"$keyword" inside an anonymous subroutine targets the nearest }
            . qq{enclosing real loop --- subroutines are not loops. Use an }
            . qq{explicit label to target an outer loop.};
    }
    if ( $block_type eq BLOCK_EVAL ) {
        return
              qq{"$keyword" inside an "eval" block targets the nearest }
            . qq{enclosing real loop --- "eval" is not a loop. Use an }
            . qq{explicit label to target an outer loop.};
    }
    if ( $block_type eq BLOCK_MAP_GREP ) {
        return
              qq{"$keyword" in a map/grep block skips to the next element }
            . qq{rather than exiting the block. Use a "for" loop for }
            . qq{clearer loop semantics.};
    }

    # BLOCK_BARE
    if ( $effective eq FORBID ) {
        if ( $keyword eq 'redo' ) {
            return
                  qq{"redo" in a bare block restarts the block indefinitely }
                . qq{--- bare blocks execute only once. Use a "for" or }
                . qq{"while" loop instead.};
        }
        return
              qq{"$keyword" in a bare block just exits the block --- bare }
            . qq{blocks execute only once. Use a "for" or "while" loop }
            . qq{if you need iteration.};
    }

    # REQUIRE_LABEL
    return qq{Add an explicit label to "$keyword" to show which loop it targets.};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls - Prohibit unlabeled loop controls in non-loop blocks

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Using C<next>, C<last>, or C<redo> inside blocks that are not real loops
or where control flow is confusing
(e.g. bare C<{}> blocks, C<do {}> blocks, anonymous subroutines, C<eval {}>,
C<map>/C<grep> blocks) leads to confusing or buggy behaviour:

=over

=item * Bare C<{}> blocks are loops that execute once, so C<next> and C<last>
both exit the block; C<next> additionally runs any attached C<continue> block.

=item * C<do {}> blocks are I<not> loops — control keywords target the nearest
enclosing real loop instead of the C<do> block itself.

=item * Anonymous subroutines C<sub {}> and C<eval {}> are not loops either.

=item * C<map {}> / C<grep {}> blocks are expression blocks — loop controls
do not behave as expected.

=back

=head1 EXAMPLES

=head2 Bare blocks (C<{ }>)

    {
        next;           # not ok
    }

    {
        last;           # not ok
    }

    {
        last LOOP;      # ok
    }

    {
        redo;           # not ok
    }

    {
        redo LOOP;      # ok
    }

=head2 C<do { }> blocks

    do {
        next;           # not ok
    };

    do {
        last LOOP;      # not ok (label does not help — do is not a loop)
    };

=head2 Anonymous subroutines (C<sub { }>)

    sub {
        next;           # not ok
    };

    sub {
        last LABEL;     # ok (if called from within a matching loop)
    };

=head2 C<eval { }> blocks

    eval {
        last;           # not ok
    };

=head2 C<map> and C<grep> blocks

    map  { next; } @list;    # not ok
    grep { redo; } @list;    # not ok

=head2 Real loops (always safe)

    while (1) {
        next;                # ok
    }

    for my $x (@items) {
        last if $x eq 'foo'; # ok
    }

    foreach my $k (keys %h) {
        next;                # ok
    }

=head1 CONFIGURATION

=for Pod::Coverage supported_parameters

Each keyword C<next>, C<last>, C<redo> can be set to one of:

=over

=item C<forbid> — always flag this keyword in non-loop blocks (default for
C<next> and C<redo>)

=item C<require_label> — flag unless the keyword has an explicit label
(default for C<last>)

=item C<allow> — do not check this keyword at all

=back

Block-type overrides (C<do_block>, C<bare_block>) can modify the behaviour
for specific block types:

=over

=item C<bare_block>: C<forbid>, C<require_label> (default), or C<follow>
per-keyword settings

=item C<do_block>:  C<forbid> (default), C<require_label>, or C<follow>
per-keyword settings

=back

Bare blocks are real loops (they execute once), so labeled controls
work correctly — C<require_label> is the default.  C<do> blocks are
not loops at all, so controls are forbidden entirely by default;
C<require_label> allows them when an outer loop is the intended target.

Example F<.perlcriticrc>:

    [ControlStructures::ProhibitBareBlockLoopControls]
    next        = forbid
    last        = require_label
    redo        = forbid
    do_block    = forbid
    bare_block  = require_label

=head1 SEE ALSO

L<perlfunc/last>, L<perlfunc/next>, L<perlfunc/redo>,
L<Perl::Critic::Policy::ControlStructures::ProhibitReturnInDoBlock>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
