#!/bin/false
# ABSTRACT: Prohibit goto LABEL that jumps into a loop or block construct
# PODNAME: Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct

use strict;
use warnings;

package Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct;
$Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct::VERSION = '0.07';
use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(:severities);

use namespace::clean;

use constant LOOP_TYPES => {
    map { $_ => 1 } qw(for foreach while until),
};

use constant CONDITIONAL_TYPES => {
    map { $_ => 1 } qw(if unless),
};

use constant BLOCK_KEYWORDS => {
    map { $_ => 1 } qw(do sub eval map grep),
};

sub default_severity { return $SEVERITY_HIGH; }
sub default_themes   { return qw(control); }
sub applies_to       { return 'PPI::Statement::Break'; }

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $label = $self->_goto_label($elem);
    return if !$label;

    if ( $self->_any_label_violation( $doc, $label, $elem ) ) {
        return $self->violation(
            qq{"goto $label" jumps into a loop or block construct},
            q{This form of goto is deprecated and will become a fatal error }
                . q{in Perl 5.44. Use loop control (next/last/redo) or restructure }
                . q{the code to avoid jumping into constructs. See perldeprecation.},
            $elem,
        );
    }

    return;
}

sub _goto_label {
    my ( $self, $elem ) = @_;

    my @kids =
        grep { !$_->isa('PPI::Token::Whitespace') && !$_->isa('PPI::Token::Comment') && !$_->isa('PPI::Token::Pod') }
        $elem->children;

    return if @kids < 2;
    return if !$kids[0]->isa('PPI::Token::Word');
    return if $kids[0]->content ne 'goto';

    my $next_token = $kids[1];

    # goto &NAME form -- not a goto-label
    return if $next_token->isa('PPI::Token::Operator') && $next_token->content eq q{&};

    # goto LABEL form: second token is a bareword
    if ( $next_token->isa('PPI::Token::Word') ) {
        return $next_token->content;
    }

    # goto EXPR form (symbol, number, etc.) -- out of scope
    return;
}

sub _any_label_violation {
    my ( $self, $doc, $label, $goto_elem ) = @_;

    my $found = $doc->find('PPI::Token::Label');
    return if !$found;

    my $any_match   = 0;
    my $any_outside = 0;
    my $any_inside  = 0;

    for my $label_token ( @{$found} ) {
        my $content = $label_token->content;
        $content =~ s/:\z//;
        next if $content ne $label;

        $any_match = 1;
        if ( $self->_label_inside_construct( $label_token, $goto_elem ) ) {
            $any_inside = 1;
        }
        else {
            $any_outside = 1;
        }
    }

    return if !$any_match;

    # Only flag if ALL matching labels are inside constructs.
    # If any matching label is outside a construct, the goto could
    # target that one (Perl uses static scoping for goto LABEL).
    return $any_inside && !$any_outside;
}

sub _label_inside_construct {
    my ( $self, $label_token, $goto_elem ) = @_;

    my $current = $label_token->parent;
    PARENT_LOOP: while ( defined $current ) {

        # PPI wraps labels in a Compound with type "label" -- skip it
        if ( $current->isa('PPI::Statement::Compound') && ( $current->type // q() ) eq 'label' ) {
            $current = $current->parent;
            next PARENT_LOOP;
        }

        # If the label token is a direct child of this compound,
        # the label is ON the construct (e.g., LABEL: while (...) {...}).
        # Jumping to it targets the construct itself, not inside it.
        if ( $current->isa('PPI::Statement::Compound') && $label_token->parent == $current ) {
            $current = $current->parent;
            next PARENT_LOOP;
        }

        # Compound statement: loops, if/unless
        if ( $current->isa('PPI::Statement::Compound') ) {
            my $type = $current->type;
            if ( $type && ( exists LOOP_TYPES->{$type} || exists CONDITIONAL_TYPES->{$type} ) ) {    ## no critic (Modules::RequireExplicitInclusion)
                return 1 if $self->_construct_is_violation( $current, $label_token, $goto_elem );
            }
        }

        # given/when blocks (PPI::Statement::Given/When, not Compound)
        if ( $current->isa('PPI::Statement::Given') || $current->isa('PPI::Statement::When') ) {
            return 1 if $self->_construct_is_violation( $current, $label_token, $goto_elem );
        }

        # Block preceded by 'do', 'sub', 'eval', 'map', 'grep', 'defer'
        if ( $current->isa('PPI::Structure::Block') ) {
            my $prev = $self->_prev_significant_sibling($current);
            if ( $prev && $prev->isa('PPI::Token::Word') ) {
                my $kw = $prev->content;
                if ( exists BLOCK_KEYWORDS->{$kw} ) {    ## no critic (Modules::RequireExplicitInclusion)
                    return 1 if $self->_construct_is_violation( $current, $label_token, $goto_elem );
                }
            }
        }

        # Subroutine declaration
        if ( $current->isa('PPI::Statement::Sub') ) {
            return 1 if $self->_construct_is_violation( $current, $label_token, $goto_elem );
        }

        $current = $current->parent;
    }

    return 0;
}

sub _construct_is_violation {
    my ( $self, $construct, $label_token, $goto_elem ) = @_;

    # Check if the goto is also inside this construct.
    # If both the label and goto are inside the same construct,
    # no jump-into-construct is happening.
    return !$construct->contains($goto_elem);
}

sub _prev_significant_sibling {
    my ( $self, $elem ) = @_;

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

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitGotoIntoConstruct - Prohibit goto LABEL that jumps into a loop or block construct

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This policy flags C<goto LABEL> when the target label is inside a loop
or block construct and the goto statement is outside that construct.
Jumping into a construct with C<goto> is deprecated in Perl (since 5.12)
and will become a fatal error in Perl 5.44
(see L<perldeprecation/"Goto Block Construct">, L<perl5#23618|https://github.com/Perl/perl5/issues/23618>).

The three forms of C<goto> are handled as follows:

=over

=item C<goto LABEL>

Flagged if the label is inside a loop, C<if>/C<unless> block, C<given>,
C<eval>, C<do>, C<sub>, C<map>, or C<grep>, and the goto
is outside that construct.

=item C<goto &NAME>

Not flagged -- this is a subroutine restart, not a label jump.

=item C<goto EXPR>

Not flagged -- the target cannot be determined statically.

=back

=head1 EXAMPLES

    while (1) {
        LABEL:
            do_stuff();
    }
    goto LABEL;    # not ok -- jumps into a while loop

    if ($x) {
        LABEL:
            do_stuff();
    }
    goto LABEL;    # not ok -- jumps into an if block

    eval {
        LABEL:
            do_stuff();
    };
    goto LABEL;    # not ok -- jumps into an eval

    do {
        LABEL:
            do_stuff();
    };
    goto LABEL;    # not ok -- jumps into a do block

    LABEL:
    do_stuff();
    goto LABEL;    # ok -- label is at the same scope level

    LABEL:
    while (1) {
        do_stuff();
    }
    goto LABEL;    # ok -- label is on the loop, not inside it

    while (1) {
        LABEL:
            do_stuff();
        goto LABEL;    # ok -- goto and label in the same construct
    }

    goto &some_sub;    # ok -- not a label jump

    my $label = 'LABEL';
    goto $label;       # ok -- goto EXPR, target unknown statically

=head1 CONFIGURATION

This policy has no configurable parameters.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::PolicyBundle::LoopsAndLabels>.

=head1 LIMITATIONS

C<defer> blocks (Perl 5.36+) are not detected.  PPI does not recognize
C<defer> as a keyword, so code following a C<defer> block may be parsed
incorrectly and the C<goto> statement inside it may not be identified
as C<PPI::Statement::Break>.

Labels that are ON a compound statement (e.g., C<LABEL: while (...) {...}>)
are not flagged.  In Perl, jumping to such a label targets the loop
it itself, not the loop body.

=head1 SEE ALSO

L<Perl::Critic>, L<perlfunc/goto>, L<perldeprecation>,
L<https://github.com/Perl/perl5/issues/23618>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
