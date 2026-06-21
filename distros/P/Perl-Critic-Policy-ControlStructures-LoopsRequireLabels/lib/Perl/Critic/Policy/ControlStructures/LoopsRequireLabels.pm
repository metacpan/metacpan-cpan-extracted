#!/bin/false
# ABSTRACT: Require labels on loops and their break keywords
# PODNAME: Perl::Critic::Policy::ControlStructures::LoopsRequireLabels

use strict;
use warnings;

package Perl::Critic::Policy::ControlStructures::LoopsRequireLabels;
$Perl::Critic::Policy::ControlStructures::LoopsRequireLabels::VERSION = '0.01';
use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw(:severities);

use namespace::clean;

use constant LOOP_TYPES => { map { $_ => 1 } qw(for foreach while until) };

use constant BREAK_KEYWORDS => { map { $_ => 1 } qw(next last redo) };

use constant CONDITIONAL_KEYWORDS =>
    { map { $_ => 1 } qw(if unless while until for foreach when given not and or xor) };

use constant PARAM_DEFAULTS => {
    mode      => 'nested',
    max_lines => 30,
};

sub supported_parameters {
    return (
        {   name           => 'mode',
            behavior       => 'string',
            default_string => 'nested',
            description    => 'When to require labels: always, nested, or max_lines',
        },
        {   name           => 'max_lines',
            behavior       => 'integer',
            default_number => 30,
            description    => 'Loop body line count threshold (used in max_lines mode and combined with nested)',
        },
    );
}

sub default_severity { return $SEVERITY_HIGH; }
sub default_themes   { return qw(control); }
sub applies_to       { return 'PPI::Statement::Compound'; }

sub _param {
    my ( $self, $name ) = @_;
    my $val = $self->{ '_' . $name };
    return defined $val ? $val : PARAM_DEFAULTS->{$name};    ## no critic (Modules::RequireExplicitInclusion)
}

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $type = $elem->type;
    return if !$type || !exists LOOP_TYPES->{$type};         ## no critic (Modules::RequireExplicitInclusion)

    my ($block) = grep { $_->isa('PPI::Structure::Block') } $elem->children;
    return if !$block;

    my @breaks = $self->_find_breaks_in_block($block);

    my $continue_block = $self->_find_continue_block($elem);
    if ($continue_block) {
        push @breaks, $self->_find_breaks_in_block($continue_block);
    }

    return if !@breaks;

    my $loop_has_label = $self->_loop_has_label($elem);
    my $label_required = $self->_label_required($elem);

    my @violations;

    if ( $label_required && !$loop_has_label ) {
        push @violations,
            $self->violation(
            _build_loop_description($type),
            _build_loop_explanation(),
            $elem,
            );
    }

    for my $break (@breaks) {
        next if $self->_break_has_label($break);

        if ( $loop_has_label || $label_required || $self->_ancestor_loop_has_label($elem) ) {
            my $keyword = _break_keyword($break);
            push @violations,
                $self->violation(
                _build_break_description($keyword),
                _build_break_explanation($keyword),
                $break,
                );
        }
    }

    return @violations;
}

sub _loop_has_label {
    my ( $self, $compound ) = @_;
    my $first = $compound->schild(0);
    return $first && $first->isa('PPI::Token::Label');
}

sub _break_has_label {
    my ( $self, $break ) = @_;

    my @kids =
        grep { !$_->isa('PPI::Token::Whitespace') && !$_->isa('PPI::Token::Comment') && !$_->isa('PPI::Token::Pod') }
        $break->children;

    return 0 if @kids < 2;
    return 0 if !$kids[0]->isa('PPI::Token::Word');

    my $second_kid = $kids[1];

    if ( $second_kid->isa('PPI::Token::Word') ) {
        return 0 if exists CONDITIONAL_KEYWORDS->{ $second_kid->content };    ## no critic (Modules::RequireExplicitInclusion)
        return 1;
    }

    if ( $second_kid->isa('PPI::Token::Number') || $second_kid->isa('PPI::Token::Symbol') ) {
        return 1;
    }

    return 0;
}

sub _break_keyword {
    my ($elem) = @_;

    my $first = $elem->schild(0);
    return if !$first || !$first->isa('PPI::Token::Word');

    my $content = $first->content;
    return if !exists BREAK_KEYWORDS->{$content};    ## no critic (Modules::RequireExplicitInclusion)

    return $content;
}

sub _label_required {
    my ( $self, $compound ) = @_;

    my $mode = $self->_param('mode');

    if ( $mode eq 'always' ) {
        return 1;
    }
    elsif ( $mode eq 'nested' ) {
        return 1 if $self->_is_nested_loop($compound);

        my $max   = $self->_param('max_lines');
        my $lines = $self->_loop_line_count($compound);
        return $lines > $max;
    }
    elsif ( $mode eq 'max_lines' ) {
        my $max   = $self->_param('max_lines');
        my $lines = $self->_loop_line_count($compound);
        return $lines > $max;
    }

    return 0;
}

sub _is_nested_loop {
    my ( $self, $compound ) = @_;

    my $current = $compound->parent;
    while ( defined $current ) {
        if ( $current->isa('PPI::Statement::Compound') ) {
            my $type = $current->type;
            return 1 if $type && exists LOOP_TYPES->{$type};    ## no critic (Modules::RequireExplicitInclusion)
        }
        $current = $current->parent;
    }

    return 0;
}

sub _ancestor_loop_has_label {
    my ( $self, $compound ) = @_;

    my $current = $compound->parent;
    while ( defined $current ) {
        if ( $current->isa('PPI::Statement::Compound') ) {
            my $type = $current->type;
            if ( $type && exists LOOP_TYPES->{$type} ) {    ## no critic (Modules::RequireExplicitInclusion)
                return 1 if $self->_loop_has_label($current);
            }
        }
        $current = $current->parent;
    }

    return 0;
}

sub _loop_line_count {
    my ( $self, $compound ) = @_;

    my ($block) = grep { $_->isa('PPI::Structure::Block') } $compound->children;
    return 0 if !$block;

    return $block->finish->line_number - $block->start->line_number + 1;
}

sub _find_continue_block {
    my ( $self, $compound ) = @_;

    my $found_continue;
    for my $child ( $compound->children ) {
        if ( $child->isa('PPI::Token::Word') && $child->content eq 'continue' ) {
            $found_continue = 1;
        }
        elsif ( $found_continue && $child->isa('PPI::Structure::Block') ) {
            return $child;
        }
    }

    return;
}

sub _find_breaks_in_block {
    my ( $self, $block ) = @_;

    my @breaks;
    $self->_walk_for_breaks( $block, \@breaks );
    return @breaks;
}

sub _walk_for_breaks {
    my ( $self, $node, $breaks_ref ) = @_;

    return if !$node->isa('PPI::Node');    # tokens lack children; must stop here

    return if $node->isa('PPI::Statement::Sub');

    if ( $node->isa('PPI::Statement::Compound') ) {
        my $type = $node->type;
        if ( $type && exists LOOP_TYPES->{$type} ) {    ## no critic (Modules::RequireExplicitInclusion)
            return;
        }
    }

    if ( $node->isa('PPI::Statement::Break') ) {
        my $keyword = _break_keyword($node);
        if ($keyword) {
            push @{$breaks_ref}, $node;
        }
        return;
    }

    for my $child ( $node->children ) {
        $self->_walk_for_breaks( $child, $breaks_ref );
    }

    return;
}

sub _build_loop_description {
    my ($type) = @_;
    return "'$type' loop has break keywords but no label";
}

sub _build_loop_explanation {
    return 'Add a label to this loop and reference it from each break keyword inside';
}

sub _build_break_description {
    my ($keyword) = @_;
    return "'$keyword' should reference an explicit label";
}

sub _build_break_explanation {
    my ($keyword) = @_;
    return
          qq{"$keyword" without a label is ambiguous --- add a label }
        . q{that names the target loop so the intent is clear and the }
        . q{code is resilient to refactoring that adds or removes nested loops};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Perl::Critic::Policy::ControlStructures::LoopsRequireLabels - Require labels on loops and their break keywords

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This policy requires loop-control keywords (C<next>, C<last>, C<redo>)
and the loops that contain them to carry explicit labels.

Labels make loop-control flow visible at a glance and prevent bugs when
nested loops are added, removed, or reordered during refactoring.

=head1 EXAMPLES

=head2 mode=always

    while (1) {
        next;           # not ok (loop + break both flagged)
    }

    LOOP:
    while (1) {
        next LOOP;      # ok
    }

    LOOP:
    while (1) {
        next;           # not ok (break inside labeled loop is bare)
    }

    while (1) {
        next OUTER;     # ok (break references a label even if loop lacks one)
    }

=head2 mode=nested (default, max_lines=5)

    while (1) {
        next;           # ok (top-level, body is 2 lines <= 5)
    }

    while (1) {
        while (1) {
            next;       # not ok (inner loop is nested)
        }
    }

    while (1) {
        INNER:
        while (1) {
            next;       # not ok (inner loop has label but break is bare)
        }
    }

    while (1) {
        INNER:
        while (1) {
            next INNER; # ok (inner loop labeled, break references it)
        }
    }

    while (1) {         # not ok (top-level but body is 6 lines > 5)
        print "a";
        print "b";
        print "c";
        next;
    }

=head2 mode=max_lines, max_lines=3

    while (1) {
        next;           # ok (body is 2 lines <= 3)
    }

    while (1) {         # not ok (body is 4 lines > 3)
        next;
        last;
    }

    while (1) {         # ok (body is 5 lines but no break keywords)
        print "hello";
        print "world";
    }

=head2 Cascading labels through ancestor loops (non-configurable)

Regardless of the active mode, a bare break keyword is always flagged when
any ancestor loop carries a label.  This prevents ambiguity about which
loop the keyword targets.

    OUTER:
    while (1) {
        while (1) {     # no label
            next;       # not ok (nearest loop unlabeled AND
                        #   OUTER has a label)
        }
    }

    OUTER:
    while (1) {
        next OUTER;     # ok (break in outer references its label)
        last;           # not ok (outer has label but break is bare)

        INNER:
        while (1) {
            last OUTER; # ok (break references an outer label)
        }
    }

C<continue> blocks attached to a loop are treated as part of that loop
for the purposes of this policy.  Break keywords inside C<continue> are
subject to the same labeling rules as those in the main body.

Note that the C<max_lines> line count considers only the main body
block (from C<{> to C<}>).  A long C<continue> block does not by itself
trigger the line-count threshold; only nesting or break keywords in the
main body can do that.

    while (1) {
        # no break keywords in the body
    } continue {
        next;           # not ok (same rules apply here)
    }

    LOOP:
    while (1) {
    } continue {
        next LOOP;      # ok (break references the loop's label)
        last LOOP;      # ok
    }

=head1 CONFIGURATION

=for Pod::Coverage supported_parameters

Three modes control when labels are required:

=over

=item C<always>

Any loop that contains a C<next>, C<last>, or C<redo> keyword must have
a label, and those keywords must reference a label.  The C<max_lines>
setting has no effect in this mode.

=item C<nested> (default)

Labels are required when the loop is nested inside another real loop
(C<for>, C<foreach>, C<while>, or C<until>).  Additionally, regardless
of nesting, labels are required if the loop body spans more than
C<max_lines> source lines (counting from C<{> to C<}> inclusive of
the body block only; any attached C<continue> block is not counted).
This makes C<max_lines> act as a safety net for long top-level loops.
Set C<max_lines> to a high value (e.g. 1000) to effectively disable
the line-count check and rely on nesting alone.

=item C<max_lines>

Labels are required when the loop body spans more than C<max_lines>
source lines (counting from C<{> to C<}> inclusive of the body block
only; any attached C<continue> block is not counted).  Nesting is not
considered.  The threshold is configured with the C<max_lines>
parameter (default 30).

=back

Example F<perlcriticrc>:

    # Built-in defaults (mode=nested, max_lines=30)
    [ControlStructures::LoopsRequireLabels]

    # Same defaults, written explicitly (default configuration)
    [ControlStructures::LoopsRequireLabels]
    mode      = nested
    max_lines = 30

    # Flag all loops with break keywords
    [ControlStructures::LoopsRequireLabels]
    mode = always

    # Flag only by length, ignore nesting
    [ControlStructures::LoopsRequireLabels]
    mode      = max_lines
    max_lines = 80

=head1 SEE ALSO

L<Perl::Critic>, C<L<perlfunc/last>>, C<L<perlfunc/next>>, C<L<perlfunc/redo>>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
