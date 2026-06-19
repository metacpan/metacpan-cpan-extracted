#!/bin/false
# ABSTRACT: Prohibit unlabeled loop controls in non-loop blocks
# PODNAME: Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls

use strict;
use warnings;

package Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls;
$Perl::Critic::Policy::ControlStructures::ProhibitBareBlockLoopControls::VERSION = '0.06';
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
    'bare_block' => FOLLOW,
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

use constant BREAK_KEYWORDS => { map { $_ => 1 } qw(next last redo) };
use constant LOOP_TYPES     => { map { $_ => 1 } qw(while until for foreach) };
use constant CONDITIONAL_KEYWORDS =>
    { map { $_ => 1 } qw(if unless while until for foreach when given not and or xor) };

sub supported_parameters {
    my @params;

    for my $kw (PER_KEYWORD_NAMES) {
        push @params, {
            behavior       => 'string',
            default_string => PER_KEYWORD_DEFAULTS->{$kw},               ## no critic (Modules::RequireExplicitInclusion)
            description    => qq{Policy for "$kw" in non-loop blocks},
            name           => $kw,
        };
    }

    for my $name (BLOCK_CONFIG_NAMES) {
        push @params, {
            behavior       => 'string',
            default_string => BLOCK_CONFIG_DEFAULTS->{$name},            ## no critic (Modules::RequireExplicitInclusion)
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

    return defined $val ? $val : PER_KEYWORD_DEFAULTS->{$name} // BLOCK_CONFIG_DEFAULTS->{$name};    ## no critic (Modules::RequireExplicitInclusion)
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
    return if !exists BREAK_KEYWORDS->{$content};    ## no critic (Modules::RequireExplicitInclusion)

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
            my $type_elem;
            for my $child ( $parent->children ) {
                next if $child->isa('PPI::Token::Label');
                next if $child->isa('PPI::Token::Whitespace');
                next if $child->isa('PPI::Token::Comment');
                next if $child->isa('PPI::Token::Pod');
                $type_elem = $child;
                last;
            }
            my $type = $type_elem ? $type_elem->content : q();

            # Real loop -- safe (first non-label child is keyword like while/for)
            ## no critic (Modules::RequireExplicitInclusion)
            if (   $type_elem
                && $type_elem->isa('PPI::Token::Word')
                && exists LOOP_TYPES->{$type} ) {
                return;
            }

            # Bare block -- first non-label child is PPI::Structure::Block
            if ( $type_elem && $type_elem->isa('PPI::Structure::Block') ) {
                return if _break_targets_loop( $elem, $parent );
                return BLOCK_BARE;
            }

            # if / unless / given / when -- not a loop, keep walking
            next ELEM;
        }

        my $class = _classify_block($current);
        return if !$class;

        if ( $class eq BLOCK_BARE ) {
            return if _break_targets_loop( $elem, $current );
        }

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
        SCAN:
        while ($check) {
            if (   $check->isa('PPI::Token::Word')
                && $check->content eq 'sub' ) {
                return BLOCK_SUB;
            }
            if (   $check->isa('PPI::Token::Attribute')
                || $check->isa('PPI::Token::Prototype')
                || $check->isa('PPI::Token::Operator') ) {
                $check = $check->sprevious_sibling;
                next SCAN;
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

    my $second_kid = $kids[1];

    if ( $second_kid->isa('PPI::Token::Word') ) {
        return
            if exists CONDITIONAL_KEYWORDS->{ $second_kid->content };    ## no critic (Modules::RequireExplicitInclusion)
        return 1;
    }

    if (   $second_kid->isa('PPI::Token::Number')
        || $second_kid->isa('PPI::Token::Symbol') ) {
        return 1;
    }

    return;
}

sub _break_label {
    my ($elem) = @_;

    my @kids =
        grep { !$_->isa('PPI::Token::Whitespace') && !$_->isa('PPI::Token::Comment') && !$_->isa('PPI::Token::Pod') }
        $elem->children;

    return if @kids < 2;
    return if !$kids[0]->isa('PPI::Token::Word');

    my $second_kid = $kids[1];

    if ( $second_kid->isa('PPI::Token::Word') ) {
        my $content = $second_kid->content;
        return if exists CONDITIONAL_KEYWORDS->{$content};    ## no critic (Modules::RequireExplicitInclusion)
        return $content;
    }

    if (   $second_kid->isa('PPI::Token::Number')
        || $second_kid->isa('PPI::Token::Symbol') ) {
        return $second_kid->content;
    }

    return;
}

sub _break_targets_loop {
    my ( $elem, $scope ) = @_;

    my $label = _break_label($elem);
    return if !$label;

    my $current = $scope->parent;
    while ( defined $current ) {
        if ( $current->isa('PPI::Statement::Compound') ) {
            my ( $has_label, $is_loop );
            for my $child ( $current->children ) {
                if ( $child->isa('PPI::Token::Label') ) {
                    ( my $lc = $child->content ) =~ s/:\z//;
                    $has_label = 1 if $lc eq $label;
                }
                next
                    if $child->isa('PPI::Token::Label')
                    || $child->isa('PPI::Token::Whitespace')
                    || $child->isa('PPI::Token::Comment')
                    || $child->isa('PPI::Token::Pod');
                if ( $child->isa('PPI::Token::Word') ) {
                    $is_loop = 1 if exists LOOP_TYPES->{ $child->content };    ## no critic (Modules::RequireExplicitInclusion)
                }
                last;
            }
            return 1 if $has_label && $is_loop;
        }
        $current = $current->parent;
    }

    return;
}

sub _make_description {
    my ( $keyword, $block_type ) = @_;

    my $nick = BLOCK_NICKNAMES->{$block_type} || 'non-loop block';    ## no critic (Modules::RequireExplicitInclusion)
    return qq{'$keyword' in $nick};
}

sub _make_explanation {
    my ( $keyword, $block_type, $effective ) = @_;

    if ( $block_type eq BLOCK_DO ) {
        return
              qq{"$keyword" inside a "do" block escapes to the nearest }
            . q{enclosing real loop --- "do" is not a loop. When no }
            . q{enclosing loop exists, this is a fatal error at runtime.};
    }
    if ( $block_type eq BLOCK_SUB ) {
        return
              qq{"$keyword" inside an anonymous subroutine escapes to the }
            . q{nearest enclosing real loop --- subroutines are not loops. }
            . q{When no enclosing loop exists, this is a fatal error at }
            . q{runtime. Use an explicit label to target an outer loop.};
    }
    if ( $block_type eq BLOCK_EVAL ) {
        return
              qq{"$keyword" inside an "eval" block escapes to the nearest }
            . q{enclosing real loop --- "eval" is not a loop. When no }
            . q{enclosing loop exists, this is a fatal error at runtime. }
            . q{Use an explicit label to target an outer loop.};
    }
    if ( $block_type eq BLOCK_MAP_GREP ) {
        return
              qq{"$keyword" in a map/grep block does not affect the }
            . q{map/grep iteration --- it escapes to the nearest enclosing }
            . q{real loop. Map/grep are iteration constructs but are not }
            . q{loop targets; when no enclosing loop exists, this is a }
            . q{fatal error at runtime. Use an explicit "for" loop }
            . q{for loop control.};
    }

    # BLOCK_BARE
    if ( $effective eq FORBID ) {
        if ( $keyword eq 'redo' ) {
            return
                  q{"redo" in a bare block always re-executes the block }
                . q{indefinitely --- bare blocks execute only once, so }
                . q{any continue block or subsequent code is skipped. }
                . q{Inside a real loop, an unlabeled "redo" targets the }
                . q{bare block, not the outer loop. Use a "for" or }
                . q{"while" loop instead.};
        }
        return
              qq{"$keyword" in a bare block exits the block --- bare }
            . q{blocks execute only once. Inside a real loop, an }
            . qq{unlabeled "$keyword" targets the bare block, }
            . q{not the outer loop. Use a "for" or "while" loop }
            . q{if you need iteration.};
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

version 0.06

=head1 DESCRIPTION

This policy flags C<next>, C<last>, and C<redo> when used inside blocks that
are not real loops or where their loop-control semantics are surprising
(bare C<{}> blocks, C<do {}> blocks, anonymous subroutines, C<eval {}>,
C<map>/C<grep>).

The hazards fall into two distinct categories.

=head2 Bare C<{}> blocks (real loops with surprising semantics)

Bare C<{}> blocks I<are> real loops -- C<next>, C<last>, and C<redo> work
correctly within them.  The danger is that readers often do not recognise
a bare block as a looping construct:

=over

=item * A bare block executes exactly once, so C<next> exits the block
(it does not restart it).  C<last> also exits; C<redo> re-executes the
single pass and skips any code that would follow.

=item * Inside a real loop, an unlabeled C<next> / C<last> / C<redo>
targets the bare block, I<not> the outer loop.  This is almost always
unintentional and can mask subtle bugs when the block is added during
refactoring.

=item * A C<continue> block attached to a bare block runs after C<next>,
which further surprises readers who think of the block as a one-shot
scope.

=back

=head2 Non-loop constructs (controls leak or fail at runtime)

C<do {}>, C<sub {}>, C<eval {}>, C<map {}>, and C<grep {}> are I<not>
loops.  Loop controls inside them either leak to an enclosing real loop
or cause a runtime error:

=over

=item * C<do {}>, C<sub {}>, C<eval {}> -- the control escapes to the
nearest enclosing real loop (Perl emits C<"Exiting %s via %s"> at the
C<warnings> level).  If no enclosing loop exists, Perl dies with
C<Can't "%s" outside a loop block>.

=item * C<map {}> / C<grep {}> -- these I<are> iteration constructs
(the block runs once per element, just like C<for my $x (@list)>), but
they are not loop-control targets.  C<next> does not skip to the next
map element; it escapes to the nearest enclosing real loop (or is a
runtime error).  Use an explicit C<for> loop when you need loop control.

=back

The default policy depends on both the keyword and the enclosing block type:

    Keyword           bare C<{}>      C<do {}>
    ------------------------------------------------
    last              require_label   forbid
    next              forbid          forbid
    redo              forbid          forbid

=head1 EXAMPLES

The following examples illustrate the default configuration.

=head2 Bare blocks (C<{ }>)

    {
        next;           # not ok
    }

    FOO: {
        next FOO;       # not ok
    }

    {
        last;           # not ok
    }

    BAR: {
        last BAR;       # ok
    }

    {
        redo;           # not ok
    }

    BAZ: {
        redo BAZ;       # not ok
    }

=head2 Bare blocks inside real loops

    for my $x (@items) {
        {
            next;           # not ok
        }
    }

    for my $x (@items) {
        FOO: {
            next FOO;       # not ok
        }
    }

    BAR:
    for my $x (@items) {
        {
            next BAR;       # ok  (targets the outer real loop)
        }
    }

=head2 C<do { }> blocks

    do {
        next;           # not ok - fatal error at runtime (no enclosing loop)
    };

    while (1) {
        do {
            next;       # not ok - exits the while, not the do (action-at-a-distance)
        };
    }

    do {
        last LOOP;      # not ok (label does not help --- do is not a loop)
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

    map  { next; } @list;    # not ok - fatal error at runtime (no enclosing loop)

    while (<$fh>) {
        my @words = map { last; } split;  # not ok - exits the while, not the map
    }

    grep { redo; } @list;    # not ok

Use a C<for> loop when you need loop control:

    for my $elem (@list) {
        next if cond($elem);  # ok
    }

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

=item C<forbid> -- always flag this keyword in non-loop blocks (default for
C<next> and C<redo>)

=item C<require_label> -- flag unless the keyword has an explicit label
(default for C<last>)

=item C<allow> -- do not check this keyword at all in non-loop blocks

These per-keyword defaults apply when no block-type override is in effect
(or the override is set to C<follow>; see below).

=back

Block-type overrides (C<do_block>, C<bare_block>) can modify the behaviour
for specific block types:

=over

=item C<bare_block>: C<forbid>, C<require_label>, or C<follow> (default)
per-keyword settings

=item C<do_block>:  C<forbid> (default), C<require_label>, or C<follow>
per-keyword settings

=back

Bare blocks are real loops (they execute once), so labeled controls
work correctly.  The default is C<follow>, which defers to the per-keyword
setting for each keyword: C<last> requires a label, C<next> and C<redo>
are always flagged.  C<do> blocks are not loops at all, so controls are
forbidden entirely by default; C<require_label> allows them when an outer
loop is the intended target.

Example F<perlcriticrc>:

    [ControlStructures::ProhibitBareBlockLoopControls]
    next        = forbid
    last        = require_label
    redo        = forbid
    do_block    = forbid
    bare_block  = follow

Note: This is the default configuration.

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
