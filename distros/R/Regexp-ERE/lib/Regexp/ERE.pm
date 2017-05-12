use 5.008008;
use strict;
use warnings;
use integer;

package Regexp::ERE;
our $VERSION = '0.04';

BEGIN {
    use Exporter ();
    our (@ISA, @EXPORT_OK);
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(
        &ere_to_nfa
        &ere_to_tree
        &ere_to_regex
        &ere_to_input_constraints
        &nfa_to_tree
        &nfa_to_regex
        &nfa_to_input_constraints
        &nfa_clone
        &nfa_concat
        &nfa_union
        &nfa_inter
        &nfa_match
        &nfa_quant
        &nfa_isomorph
        &nfa_to_dfa
        &dfa_to_min_dfa
        &nfa_to_min_dfa
        &tree_to_regex
        &tree_to_input_constraints
        &char_to_cc
        &interval_list_to_cc
        &cc_union
        &quote
    );
}

=encoding utf8

=head1 NAME

Regexp::ERE - extended regular expressions and finite automata

=head1 SYNOPSIS

  use Regexp::ERE qw(
      &ere_to_nfa
      &nfa_inter
      &nfa_to_regex
      &nfa_to_input_constraints
      &nfa_to_dfa
      &dfa_to_min_dfa
  );

  # condition 1: begins with abc or def
  my $nfa1 = ere_to_nfa('^(abc|def)');

  # condition 2: ends with 123 or 456
  my $nfa2 = ere_to_nfa('(123|456)$');

  # condition 1 and condition 2
  my $inter_nfa = nfa_inter($nfa1, $nfa2);

  # compute extended regular expression (string)
  my $ere = nfa_to_regex($inter_nfa);

  # compute perl regular expression
  my $perlre = nfa_to_regex($inter_nfa, 1);

  # compute weaker input constraints suitable for widgets
  my ($input_constraints, $split_perlre)
    = nfa_to_input_constraints($inter_nfa);

  # minimal dfa (simpler regular expression happens to result)
  my $nfa3 = ere_to_nfa('^(a|ab|b)*$');
  my $dfa3 = nfa_to_dfa($nfa3);
  my $min_dfa3 = dfa_to_min_dfa($dfa3);
  my $ere3 = nfa_to_regex($min_dfa3);

=head1 DESCRIPTION

Pure-perl module for:

=over 4

=item *

Parsing POSIX Extended Regular Expressions (C<$ere>) into
Non-Deterministic Finite Automata (C<$nfa>)

=item *

Manipulating C<$nfa>s (concatenating, or-ing, and-ing)

=item *

Computing Deterministic Finite Automata (C<$dfa>s) from C<$nfa>s
(powerset construction)

=item *

Computing minimal C<$dfa>s from C<$dfa>s (Hopcroft's algorithm)

=item *

Computing C<$ere>s or Perl Regular Expressions from C<$nfa> or C<$dfa>
(Warshall algorithm)

=item *

Heuristically deriving (possibly weaker) constraints from a C<$nfa> or C<$dfa>
suitable for display in a graphical user interface,
i.e. a sequence of widgets of type 'free text' and 'drop down';

Example: C<'^(abc|def)'> => C<$nfa> => C<[['abc', 'def'], 'free text']>

=back

=head1 GLOSSARY AND CONVERSIONS OVERVIEW

=head2 Conversions overview

  $ere -> $nfa -> $tree -> $regex  ($ere or $perlre)
                        -> $input_constraints

  The second argument of -> $regex conversions is an optional boolean,
      true : conversion to a compiled perl regular expression
      false: conversion to an ere string

  The -> $input_constraints conversions return a pair (
      $input_constraints: aref as described at tree_to_input_constraints()
      $split_perlre     : a compiled perl regular expression
  )


=head2 Glossary

=over 4

=item $char_class

A set of unicode characters.

=item $ere

Extended regular expression (string).
See C<ere_to_nfa($ere)> for the exact syntax.

=item $perlre

Perl regular expression

=item $nfa

Non-deterministic finite automaton

=item $dfa

Deterministic finite automaton (special case of C<$nfa>)

=item $tree

Intermediate hierarchical representation of a regular expression
(which still can be manipulated before stringification),
similar to a parse tree (but used for generating, not for parsing).

=item $input_constraints

Ad-hoc data structure representing a list of gui-widgets
(free text fields and drop-down lists),
a helper for entering inputs
conforming to a given C<$nfa>.

=back

=cut


##############################################################################
# Config
##############################################################################

# If true, nfa_to_tree() always expands concatenated alternations.
# Example: (ab|cd) (ef|gh)  -> (abef|abgh|cdef|cdgh)
our $TREE_CONCAT_FULL_EXPAND = 0;

# If true, prefixes and suffixes are factorized out even for
# trees with a single alternation.
# Example: (a1b|a2b) -> a(1|2)b
our $FULL_FACTORIZE_FIXES = 0;

# Should be 0. Else, traces nfa_to_tree() on STDERR.
use constant {
    TRACE_NFA_TO_TREE => 0
};

use constant {
    MAX_CHAR   => 0x10FFFF
  , CHAR_CLASS => 'cc' # for blessing $char_classes (label only, no methods)
};


=head1 DATA STRUCTURES AND SUBROUTINES

Each of the documented subroutines can be imported,
for instance C<use ERE qw(&ere_to_nfa &nfa_match);>.

=cut


##############################################################################
# $char_class
##############################################################################

=head2 Character class


WARNING: C<$char_class>es must be created exclusively by
      C<char_to_cc()>
   or C<interval_list_to_cc()>
for equivalent character classes to be always the same array reference.
For the same reason, C<$char_class>es must never be mutated.

In this implementation, the state transitions of a C<$nfa> are based upon
character classes (not single characters). A character class is an ordered
list of disjoint, non-mergeable intervals (over unicode code points,
i.e. positive integers).

  $char_class = [
      [ $low_0, $high_0 ] # $interval_0
    , [ $low_1, $high_1 ] # $interval_1
    , ...
  ]


Constraints:

    1:  0 <= $$char_class[$i][0]                          (0 <= low)
    2:  $$char_class[$i][1] <= MAX_CHAR                   (high <= MAX_CHAR)
    3:  $$char_class[$i][0] <= $$char_class[$i][1]        (low <= high)
    4:  $$char_class[$i][1] + 1 <  $$char_class[$i+1][0]  (non mergeable)


Exceptions (anchors used only in the parsing phase only):

    begin         : [ -2, -1 ]
    end           : [ -3, -2 ]
    begin or end  : [ -3, -1 ]

Immediately after parsing, such pseudo-character classes
are removed by C<nfa_resolve_anchors()> (internal subroutine).

=over 4

=cut

our $ERE_literal = qr/ [^.[\\()*+?{|^\$] /xms;
our $PERLRE_char_class_special = qr/ [\[\]\\\^\-] /xms;

our $cc_any = bless([[ 0, MAX_CHAR ]], CHAR_CLASS);
our $cc_none = bless([], CHAR_CLASS);
our $cc_beg = bless([[ -2, -1]], CHAR_CLASS);
our $cc_end = bless([[ -3, -2]], CHAR_CLASS);
{

    no warnings qw(utf8); # in particular for 0x10FFFF

    my %cc_cache;
    # keys: join(',',1,map{@$_}@{$char_class})

    for ($cc_any, $cc_none, $cc_beg, $cc_end) {
        $cc_cache{ join(',', 1, map {@$_} @$_) } = $_;
    }

=item char_to_cc($c)

Returns the unique C<$char_class> equivalent to C<[[ord($c), ord($c)]]>.

=cut

    sub char_to_cc {
        return $cc_cache{ join(',', 1, (ord($_[0])) x 2) }
         ||= bless([[ord($_[0]), ord($_[0])]], CHAR_CLASS);
    }

    # $interval_list is the same data structure as $char_class.
    # Constraints 1, 2 are assumed.
    # Constraints 3, 4 are enforced.

=item interval_list_to_cc($interval_list)

C<$interval_list> is an arbitrary list of intervals.
Returns the unique C<$char_class> whose reunion of intervals
is the same set as the reunion of the intervals of C<$interval_list>.

Example:

    interval_list_to_cc([[102, 112], [65, 90], [97, 102], [113, 122]])
    returns [[65, 90], [97, 122]]
    (i.e [f-p]|[A-Z]|[a-f]|[q-z] => [A-Z]|[a-z])

Note that both C<$interval_list> and C<$char_class> are lists of intervals,
but only C<$char_class> obeys the constraints above,
while C<$interval_list> does not.

Remark also that C<interval_list_to_cc($char_class)> is the identity
(returns the same reference as given) on C<$char_class>es returned
by either C<interval_list_to_cc()> or C<char_to_cc()>.

=cut

    sub interval_list_to_cc {
        my ($interval_list) =  @_;
        my @sorted
          = sort { $$a[0] <=> $$b[0] }
            grep { $$_[0] <= $$_[1] }
            @$interval_list
        ;
        my $char_class = bless([], CHAR_CLASS);
        my $i = 0;
        while ($i != @sorted) {
            my $interval = $sorted[$i];
            $i++;
            while ($i != @sorted && $$interval[1] + 1 >= $sorted[$i][0]) {
                if ($$interval[1] < $sorted[$i][1]) {
                    $$interval[1] = $sorted[$i][1];
                }
                $i++;
            }
            push(@$char_class, $interval);
        }
        return $cc_cache{ join(',', 1, map {@$_} @$char_class) }
         ||= $char_class;
    }

    sub cc_neg {
        my ($char_class) = @_;

        if (!@$char_class) { return $cc_any; }

        my $neg = bless([], CHAR_CLASS);
        if ($$char_class[0][0] != 0) {
            push(@$neg, [0, $$char_class[0][0] - 1]);
        }
        my $i = 0;
        while ($i != $#$char_class) {
            push(@$neg, [$$char_class[$i][1] + 1, $$char_class[$i+1][0] - 1]);
            $i++;
        }
        if ($$char_class[$i][1] != MAX_CHAR) {
            push(@$neg, [$$char_class[$i][1] + 1, MAX_CHAR]);
        }
        return $cc_cache{ join(',', 1, map{@$_} @$neg) } ||= $neg;
    }

    sub cc_inter2 {
        my ($char_class_0, $char_class_1) = @_;

        my $inter = bless([], CHAR_CLASS);
        my $i_0 = 0;
        my $i_1 = 0;
        while ($i_0 < @$char_class_0 && $i_1 < @$char_class_1) {

            # skip interval_0 if interval_0 < interval_1
            while (
                $i_0 < @$char_class_0
             && $i_1 < @$char_class_1
             && $$char_class_0[$i_0][1] < $$char_class_1[$i_1][0]
            ) {
                $i_0++;
            }

            # skip interval_1 if interval_1 < interval_0
            while (
                $i_0 < @$char_class_0
             && $i_1 < @$char_class_1
             && $$char_class_1[$i_1][1] < $$char_class_0[$i_0][0]
            ) {
                $i_1++;
            }

            # Check that the exit condition of the first while still holds.
            if (
                $i_0 < @$char_class_0
             && $i_1 < @$char_class_1
             && $$char_class_1[$i_1][0] <= $$char_class_0[$i_0][1]
            ) {
                # The exit conditions of both whiles hold:
                #
                #     $$char_class_0[$i_0][1] >= $$char_class_1[$i_1][0]
                #  && $$char_class_1[$i_1][1] >= $$char_class_0[$i_0][0]
                #
                # short:
                #     high_0 >= low_1
                #     high_1 >= low_0
                #
                # furthermore:
                #     high_0 >= low_0
                #     high_1 >= low_1
                #
                # with:
                #     min_high := min(high_0, high_1)
                #     max_low := max(low_0, low_1)
                #
                # holds:
                #     min_high >= max_low_0

                my ($interval_0_done, $interval_1_done);

                my $max_low =
                    $$char_class_0[$i_0][0] > $$char_class_1[$i_1][0]
                  ? $$char_class_0[$i_0][0]
                  : $$char_class_1[$i_1][0]
                ;

                my $min_high;
                if ($$char_class_0[$i_0][1] <= $$char_class_1[$i_1][1]) {
                    $min_high = $$char_class_0[$i_0][1];
                    # interval_0 < next interval_1
                    $interval_0_done = 1;
                }
                if ($$char_class_1[$i_1][1] <= $$char_class_0[$i_0][1]) {
                    $min_high = $$char_class_1[$i_1][1];
                    # interval_1 < next interval_0
                    $interval_1_done = 1;
                }
                if ($interval_0_done) { $i_0++; }
                if ($interval_1_done) { $i_1++; }

                push(@$inter, [$max_low, $min_high]);
            }
        }
        return $cc_cache{ join(',', 1, map{@$_} @$inter) } ||=$inter;
    }
}

sub cc_match {
    my ($char_class, $c) = @_;
    for my $interval (@$char_class) {
        if ($c < $$interval[0])  {
            return 0;
        }
        elsif ($c <= $$interval[1]) {
            return 1;
        }
    }
    return 0;
}

=item cc_union(@char_classes)

Returns the unique C<$char_class> containing all characters of all given
C<@char_classes>.

=cut

sub cc_union {
    return interval_list_to_cc( [ map { map { [@$_] } @$_ } @_ ] );
}

sub cc_is_subset {
    my ($char_class_0, $char_class_1) = @_;
    for my $c ( map { @$_ } @$char_class_0 ) {
        if (!cc_match($char_class_1, $c)) { return 0; }
    }
    return 1;
}

# $to_perlre (boolean)
#     true : perl syntax
#     false: ere syntax
sub cc_to_regex {
    my ($char_class, $to_perlre) = (@_, 0);

    my @items;
    if (@$char_class && $$char_class[0][0] < 0) {
        if ($$char_class[0][0] == -2) {
            if ($$char_class[0][1] == -1) {
                push(@items, '^');
            }
            else {
                push(@items, '^$');
            }
        }
        else {
            if ($$char_class[0][1] == -2) {
                push(@items, '$');
            }
            else {
                push(@items, '^', '$');
            }
        }
        $char_class = [@$char_class[1..$#$char_class]];
    }
    if (@$char_class) {
        if (
            @$char_class == 1
         && $$char_class[0][0] == $$char_class[0][1]
        ) {
            my $c = chr($$char_class[0][0]);
            if ($to_perlre) {
                push(@items, quotemeta($c))
            }
            else {
                push(@items,
                    $c =~ /$ERE_literal/o
                  ? $c
                  : "\\$c"
                );
            }
        }
        elsif (
            @$char_class == 1
         && $$char_class[0][0] == 0
         && $$char_class[0][1] == MAX_CHAR
        ) {
            push(@items, '.');
        }
        elsif ($$char_class[$#$char_class][1] == MAX_CHAR) {
            if ($to_perlre) {
                push(@items,
                    '[^' . _cc_to_perlre(cc_neg($char_class)) . ']'
                );
            }
            else {
                push(@items,
                    '[^' . _cc_to_ere(cc_neg($char_class)) . ']'
                );
            }
        }
        else {
            if ($to_perlre) {
                push(@items, '[' . _cc_to_perlre($char_class) . ']');
            }
            else {
                push(@items, '[' . _cc_to_ere($char_class) . ']');
            }
        }
    }

    my $regex;
    if (@items == 0) {
        return '';
    }
    elsif (@items == 1) {
        return $items[0];
    }
    else {
        if ($to_perlre) {
            return '(?:' . join('|', @items) . ')';
        }
        else {
            return '(' . join('|', @items) . ')';
        }
    }
}

sub _cc_to_ere {
    my ($char_class) = @_;
    my $has_minus;
    my $has_r_bracket;
    my $ere = join('',
        map {
            if ($$_[0] == $$_[1]) {
                if ($$_[0] == ord('-')) {
                    $has_minus = 1;
                    '';
                }
                elsif ($$_[0] == ord(']')) {
                    $has_r_bracket = 1;
                    '';
                }
                else {
                    chr($$_[0]);
                }
            }
            else {
                if (
                    $$_[0] == ord('-')
                 || $$_[0] == ord(']')
                ) {
                    if ($$_[0] == ord('-')) {
                        $has_minus = 1;
                    }
                    else {
                        $has_r_bracket = 1;
                    }
                    if ($$_[1] == $$_[0] + 1) {
                        chr($$_[1]);
                    }
                    elsif ($$_[1] == $$_[0] + 2) {
                        chr($$_[0] + 1) . chr($$_[1]);
                    }
                    else {
                        chr($$_[0] + 1) . '-' . chr($$_[1]);
                    }
                }
                else {
                    if ($$_[1] == $$_[0] + 1) {
                        chr($$_[0]) . chr($$_[1]);
                    }
                    else {
                        chr($$_[0]) . '-' . chr($$_[1]);
                    }
                }
            }
        }
        @$char_class
    );
    if ($has_minus) { $ere .= '-'; }
    if ($has_r_bracket) { $ere = "]$ere"; }
    return $ere;
}

sub _cc_to_perlre {
    my ($char_class) = @_;
    return join('',
        map {
            if ($$_[0] == $$_[1]) {
                my $c = chr($$_[0]);
                $c =~ /$PERLRE_char_class_special/o ?  "\\$c" : $c;
            }
            else {
                my ($c1, $c2) = (chr($$_[0]), chr($$_[1]));
                ($c1 =~ /$PERLRE_char_class_special/o ?  "\\$c1" : $c1)
              . ($$_[0] + 1 < $$_[1] ? '-' : '')
              . ($c2 =~ /$PERLRE_char_class_special/o ?  "\\$c2" : $c2)
            }
        } @$char_class
    );
}


##############################################################################
# $nfa
##############################################################################

=back

=head2 Nfa


WARNING: C<nfa_xxx()> routines are destructive,
the C<$nfa> references given as arguments will not be valid C<$nfa> any more.
Furthermore, the same C<$nfa> reference must be used only once as argument.
For instance, for concatenating a C<$nfa> with itself, C<nfa_concat(nfa, nfa)>
does not work; instead, C<nfa_concat($nfa, nfa_clone($nfa))> must be used;
or even C<nfa_concat(nfa_clone($nfa), nfa_clone($nfa)> if the original
C<$nfa> is to be used further.

  $nfa = [ $state_0, $state_1, ... ]

  $state = [
      $accepting
    , $transitions
  ]

  $transitions = [
      [ $char_class_0 => $state_ind_0 ]
    , [ $char_class_1 => $state_ind_1 ]
    , ...
  ]

In the same C<$transition>, C<$state_ind_i> are pairwise different and are
valid indexes of C<@$nfa>. There is exactly one initial state at index 0.

=over 4

=item C<nfa_clone(@nfas)>

Maps each of the given C<@nfas> to a clone.

=cut

sub nfa_clone {
    return
        map { [
            map { [
                $$_[0]                         # accepting
              , [ map { [ @$_ ] } @{$$_[1]} ]  # transitions
            ] }
            @$_  # states of the $nfa
        ] } @_   # list of $nfas
    ;
}

sub _transitions_is_subset {
    my ($transitions_0, $transitions_1, $state_ind_map) = @_;
    my %state_ind_to_t_1
        = map {(
                $state_ind_map && exists($$state_ind_map{$$_[1]})
              ? $$state_ind_map{$$_[1]}
              : $$_[1]
           => $_
          )}
          @$transitions_1
    ;
    for my $t_0 (@$transitions_0) {
        my $state_ind_0
          = $state_ind_map && exists($$state_ind_map{$$t_0[1]})
          ? $$state_ind_map{$$t_0[1]}
          : $$t_0[1]
        ;
        if (!exists($state_ind_to_t_1{$state_ind_0})) { return 0; }
        my $t_1 = $state_ind_to_t_1{$state_ind_0};
        if (!cc_is_subset($$t_0[0], $$t_1[0])) { return 0; }
    }
    return 1;
}

# The keys of %$state_ind_to_equiv are state_inds of @$nfa to be removed.
# State indexes in transitions are remapped following %$state_ind_to_equiv.
# A state index mapped to itself denotes an unreachable state index.
sub _nfa_shrink_equiv {
    my ($nfa, $state_ind_to_equiv) = @_;
    my $i = 0;
    my %compact_map
      = map { ($_ => $i++) }
        my @active_state_inds
      = grep { !exists($$state_ind_to_equiv{$_}) }
        (0..$#$nfa)
    ;

    my %equiv_index_to_char_classes;
    my %plain_index_to_char_class;
    for (@$nfa = @$nfa[@active_state_inds]) {

        # update $state_ind
        #      -> $compact_map{$state_ind}
        #      or $compact_map{$$state_ind_to_equiv{$state_ind}}
        %equiv_index_to_char_classes = ();
        %plain_index_to_char_class = ();
        for (@{$$_[1]}) { # transition list
            if (exists($$state_ind_to_equiv{$$_[1]})) {
                push(
                    @{$equiv_index_to_char_classes{
                        $$_[1]
                      = $compact_map{$$state_ind_to_equiv{$$_[1]}}
                    }}
                  , $$_[0]
                );
            }
            else {
                $plain_index_to_char_class{
                    $$_[1]
                  = $compact_map{$$_[1]}
                } = $$_[0];
            }
        }
        # merge char_classes to the same state index
        if (keys(%equiv_index_to_char_classes)) {
            @{$$_[1]} = ((
                map {[
                    exists($equiv_index_to_char_classes{$_})
                      ? cc_union(
                            $plain_index_to_char_class{$_}
                          , @{$equiv_index_to_char_classes{$_}}
                        )
                      : $plain_index_to_char_class{$_}
                  , $_
                ]}
                keys(%plain_index_to_char_class)
            ) , (
                map {[
                    @{$equiv_index_to_char_classes{$_}} == 1
                      ? $equiv_index_to_char_classes{$_}[0]
                      : cc_union(@{$equiv_index_to_char_classes{$_}})
                  , $_
                ]}
                grep { !exists($plain_index_to_char_class{$_}) }
                keys(%equiv_index_to_char_classes)
            ))
        }
    }
    return $nfa;
}

=item C<nfa_quant($in_nfa, $min, $max, $prev_has_suffix, $next_has_prefix)>

Precondition: C<0 <= $min && ( $max eq '' || $min <= $max)>

Returns C<$out_nfa>, a C<$nfa> computed from C<$in_nfa>.

Let L be the language accepted by C<$in_nfa> and M the language accepted
by C<$out_nfa>. Then a word m belongs to M if and only if and ordered list
(l_1, ..., l_r) of words belonging to L exists such that:

    $min <= r
and ($max eq '' or r <= $max)
and m is the concatenation of (l_1, ..., l_r)

Examples with C<$in_nfa> being a C<$nfa> accepting C<'^a$'>:

    nfa_quant($in_nfa, 2, 4 ) accepts '^a{2,4}$'
    nfa_quant($in_nfa, 0, '') accepts '^a{0,}$' (i.e. '^a*$')

C<$pref_has_prefix> and C<$next_has_prefix> are hints for dispatching C<$min>,
for example:

    'a+'    => 'a*a'  (!$prev_has_suffix &&  $next_has_prefix)
    'a+'    => 'aa*'  ( $prev_has_suffix && !$next_has_prefix)
    'a{2,}' => 'aa*a' ( $prev_has_suffix &&  $next_has_prefix)

=cut

sub nfa_quant {
    my ($nfa, $min, $max, $prev_has_suffix, $next_has_prefix) = @_;
    my @quant_parts;
    my $optional_part;

    # dispatch min left and right: a+b => a*ab, ba+ => baa*
    use integer;
    my ($min_left, $min_right)
      =
        # no suffix, no prefix
        $min == 0                                    ? (0         , 0     )

        # no suffix, maybe prefix
      : !($next_has_prefix && _nfa_has_suffix($nfa)) ? ($min      , 0     )

        # suffix, no prefix
      : !($prev_has_suffix && _nfa_has_prefix($nfa)) ? (0         , $min  )

        # suffix and prefix
      :                                                (($min+1)/2, $min/2)
    ;

    if ($min_left > 0) {
        push(@quant_parts, nfa_concat(nfa_clone(($nfa) x $min_left)));
    }
    if (length($max) == 0 || $max > $min) {
        if ($$nfa[0][0]) {
            # initial state already accepting
            ($optional_part) = nfa_clone($nfa);
        }
        elsif (
            !grep { $$_[1] == 0 }
            map { @{$$_[1]} }
            @$nfa
        ) {
            # initial state not accepting and unreachable
            ($optional_part) = nfa_clone($nfa);
            $$optional_part[0][0] = 1;
        }
        else {
            # initial state not accepting and reachable
            $optional_part = [
                # additional root initial state accepting state
                [
                    1                                            # accepting
                  , [ map {[$$_[0] , $$_[1]+1]} @{$$nfa[0][1]} ] # transitions
                ]
                # original states with offset 1
              , map { [
                    $$_[0]                                       # accepting
                  , [ map {[ $$_[0], $$_[1]+1 ]} @{$$_[1]} ]     # transitions
                ] }
                @$nfa
             ];
        }
    }
    if (length($max) == 0) {

        # starify optional part

        my %root_index_to_char_class
          = map { ($$_[1] => $$_[0]) }
            @{$$optional_part[0][1]}
        ;

        my $state_ind_to_equiv = {};
        # loop over accepting state indexes
        for (grep { $$optional_part[$_][0] } (1..$#$optional_part)) {
            if (
                _transitions_is_subset(
                    $$optional_part[$_][1]
                  , $$optional_part[0][1]
                  , { $_ => 0 }
                )
            ) {
                # Accepting states whose transitions are
                # a subset of the transitions of the initial state
                # are equivalent to the initial state.
                $$state_ind_to_equiv{$_} = 0;
            }
            else {
                if (
                    grep { exists($root_index_to_char_class{$_}) }
                    map { $$_[1] }
                    @{$$optional_part[$_][1]}
                ) {
                    # merge char classes to the same state index
                    my %new_index_to_char_classes
                      = map { ($$_[1] => [$$_[0]]) }
                        @{$$optional_part[$_][1]}
                    ;
                    for (keys(%root_index_to_char_class)) {
                        push (
                            @{$new_index_to_char_classes{$_}}
                          , $root_index_to_char_class{$_}
                        );
                    }
                    @{$$optional_part[$_][1]}
                      = map {[
                            @{$new_index_to_char_classes{$_}} == 1
                              ? $new_index_to_char_classes{$_}[0]
                              : cc_union(@{$new_index_to_char_classes{$_}})
                          , $_
                        ]}
                        keys(%new_index_to_char_classes)
                    ;
                }
                else {
                    push(
                        @{$$optional_part[$_][1]}
                      , map { [@$_] } @{$$optional_part[0][1]}
                    );
                }
            }
        }
        push(@quant_parts,
            keys(%$state_ind_to_equiv)
          ?  _nfa_shrink_equiv($optional_part, $state_ind_to_equiv)
          :  $optional_part
        );
    }
    elsif ($max > $min) {

        # concatenate optional_part $max - $min times

        push(@quant_parts, _nfa_concat(1, nfa_clone(
            ($optional_part) x ($max - $min)
        )));
    }
    if ($min_right > 0) {
        push(@quant_parts, nfa_concat(nfa_clone(($nfa) x $min_right)));
    }
    return @quant_parts == 1 ? $quant_parts[0] : nfa_concat(@quant_parts);
}

=item C<nfa_concat(@in_nfas)>

Returns C<$out_nfa>, a C<$nfa> computed from C<@in_nfas>.

Let r be the number of given C<@in_nfas>,
L_i the language accepted by C<$in_nfas[$i]> and M the language accepted
by C<$out_nfa>. Then a word m belongs to M if and only if an ordered list
(l_1, ..., l_r) of words exists, l_i belonging to L_i, such that
m is the concatenation of (l_1, ..., l_r).

=cut

sub nfa_concat {
    _nfa_concat(0, @_);
}

sub _nfa_concat {
    my $starifying = shift(@_);
    if (!@_) {
        return [[1, []]];  # neutral element: accepting empty string
    }
    my $concat = shift(@_); # result, to be extended
    my @accepting_state_inds = grep { $$concat[$_][0] } (0..$#$concat);
    my $state_ind_to_equiv = {};
    my (
        $state
      , $init_state_ind
      , $init_reachable
      , $init_equiv_reachable
      , $init_skipped
      , @new_accepting_state_inds
    );
    # extend @$concat
    for my $nfa (@_) {
        $init_state_ind = @$concat;
        $init_reachable = 0;
        $init_equiv_reachable = 0;
        $init_skipped = 0;
        @new_accepting_state_inds
          = map { $_ + $init_state_ind }
            grep { $$nfa[$_][0] }
            (0..$#$nfa)
        ;

        # renumber states, count states with transition to the initial state
        for (map { @{$$_[1]} } @$nfa) {
            ($$_[1] += $init_state_ind) == $init_state_ind
         && $init_reachable++;
        }
        # join old accepting states with new initial state
        for my $acc_ind (@accepting_state_inds) {
            $state = $$concat[$acc_ind]; # old accepting state
            $$state[0] = $$nfa[0][0]; # overwrite accepting
            if (
                @{$$state[1]} == 0 # no transition
             || @{$$state[1]} == 1 # one transition
             && _transitions_is_subset(
                    $$state[1]   # transition of the old accepting state
                  , $$nfa[0][1]  # transitions of the new initial state
                  , { $acc_ind => $init_state_ind }
                )
            ) {

                # Old accepting states whose transitions are
                # a subset of the transitions of the new initial state
                # are equivalent to the initial state.
                #
                # Note that such an old accepting states can have either
                # no transition or one self-transition;
                # the case that the old accepting state has no transition
                # occurs very often.
                #
                # %$state_ind_to_equiv gets extended by
                #
                #     $acc_ind (old accepting state) => $init_state_ind
                #
                # But the keys and the values of %$state_ind_to_equiv
                # MUST remain disjoint (except for pairs key = val).
                #
                # Since $init_state_index are growing
                # and $acc_ind < $init_state_index:
                #   - the new value does not belong the the keys
                #   - the new key may belong to the vals,
                #     such values must be updated.
                #
                # Example:
                #     0 => 1   ( %$state_ind_to_equiv )
                #     1 => 2   ( $acc_ind => $init_state_index )
                # %$state_ind_to_equiv must be updated to
                #     0 => 2
                # before being extended by
                #     1 => 2
                for (grep { $_ == $acc_ind } values(%$state_ind_to_equiv)) {
                    $_ = $init_state_ind;
                }
                $$state_ind_to_equiv{$acc_ind} = $init_state_ind;
                $init_equiv_reachable++;
            }
            elsif (
                $init_reachable == 1
             && (grep { $$_[1] == $init_state_ind } @{$$nfa[0][1]})
             && cc_is_subset(

                    # char_class of the self-transition
                    # of the new initial state
                    (
                        map { $$_[0] }
                        grep { $$_[1] == $init_state_ind }
                        @{$$nfa[0][1]}
                    )

                    # char_class of the self-transition
                    # of the old accepting state
                  , (
                        map { $$_[0] }
                        grep { $$_[1] == $acc_ind }
                        @{$$state[1]}
                    )
                )
            ) {
                # If the self-transitions of the new init state are
                # a subset of the transitions of the old accepting state,
                # the new state is not needed for looping;
                # the transition to the new init state can be skipped.
                #
                # Example 1:
                #     [ab]*a*
                #     the state for a* is superfluous.
                # Example 2:
                #     ( x[ab]* | y[ac]* | z[bc]* ) a* c
                #     the state for a* is only needed after [bc]*
                #     the regular expression is equivalent to:
                #     x[ab]*c | y[ac]*c | z[bc]*a*c
                #
                # Note that this one-letter-star optimization is
                # probably not very useful for practical purposes;
                # more general equivalences like (abc)*(abc)* ~ (abc)*
                # are not caught up, while the focused use cases
                # of prefix and suffix recognition require no star at all.
                #
                # It is merely a toy optimization for solving some exercises
                # of an introductory course on regexs.
                #
                push(@{$$state[1]},
                    map { [ @$_ ] }
                    grep { $$_[1] != $init_state_ind}
                    @{$$nfa[0][1]})
                ;
                $init_skipped++;
            }
            else {
                push(@{$$state[1]},
                    map { [ @$_ ] }
                    @{$$nfa[0][1]})
                ;
            }
        }
        if (
            !$init_reachable && !$init_equiv_reachable
         || $init_skipped == @accepting_state_inds
        ) {
            # for being removed by _nfa_shrink_equiv()
            $$state_ind_to_equiv{$init_state_ind} = $init_state_ind;
        }

        if (!$$nfa[0][0]) {
            @accepting_state_inds = ();
        }
        elsif ($starifying) {
            # $starifying set for optimizing x{n,m}.
            # The old accepting states are redundant,
            # since reachable iff the newer ones are.
            for (@accepting_state_inds[1..$#accepting_state_inds]) {
                $$concat[$_][0] = 0;
            }
            if (!$init_reachable) {
                $$nfa[0][0] = 0;
                shift(@new_accepting_state_inds);
            }
            @accepting_state_inds = (0);
        }
        else {
            @accepting_state_inds
              = grep { !exists($$state_ind_to_equiv{$_}) }
                @accepting_state_inds
            ;
        }

        push(@$concat, @$nfa);
        push(@accepting_state_inds, @new_accepting_state_inds);
    }
    if (keys(%$state_ind_to_equiv)) {
        return _nfa_shrink_equiv($concat, $state_ind_to_equiv);
    }
    else {
        return $concat;
    }
}

=item C<nfa_union(@in_nfas)>

Returns C<$out_nfa>, a C<$nfa> computed from C<@in_nfas>.

C<$out_nfa> accepts a word w if and only if at least one of C<@in_nfas>
accepts w.

=cut

# Adds the total number of states
sub nfa_union {
    my $union = [[0, []]]; # root, neutral element: accepting nothing
    my $state_ind_to_equiv = {};
    my $first_trivial_accepting_state_ind;
    my (
        $nfa
      , $init_state_ind
      , $init_reachable
      , $orig_state
    );

    for $nfa (@_) {

        # merge initial $accepting
        $$union[0][0] ||= $$nfa[0][0];
        if (@$nfa == 1 && @{$$nfa[0][1]} == 0) {
            next;
            # Must be skipped because such a trivial state
            # would be removed below (!$init_reachable)
            # although it may be the $first_trivial_accepting state.
            #
            # On the other side, a well defined $nfa
            # with a single state and with a non-empty transition list
            # must loop to itself, thus $init_reachable.
        }

        $init_state_ind = @$union;
        $init_reachable = 0;
        for (0..$#$nfa) {
            $orig_state = $$nfa[$_];
            if (
                $$orig_state[0]          # accepting
             && !@{$$orig_state[1]}      # trivial
            ) {
                if (defined($first_trivial_accepting_state_ind)) {
                    $$state_ind_to_equiv{$_ + $init_state_ind}
                      = $first_trivial_accepting_state_ind;
                }
                else {
                    $first_trivial_accepting_state_ind
                  = $_ + $init_state_ind;
                }
            }
            else {
                for ( @{$$orig_state[1]} ) { # transition list
                    ($$_[1] += $init_state_ind) == $init_state_ind
                 && ($init_reachable ||= 1);
                }
            }
        };
        push(@$union, @$nfa);

        # merge initial $transitions
        push(@{$$union[0][1]}, map { [ @$_ ] } @{$$nfa[0][1]});
        if (!$init_reachable) {
            # for being removed by _nfa_shrink_equiv()
            $$state_ind_to_equiv{$init_state_ind} = $init_state_ind;
        }
    };
    if (keys(%$state_ind_to_equiv)) {
        return _nfa_shrink_equiv($union, $state_ind_to_equiv);
    }
    else {
        return $union;
    }
}

{

    my %cached_cc_inter2;

=item C<nfa_inter(@in_nfas)>

Returns C<$out_nfa>, a $C<$nfa> computed from C<@in_nfas>.

C<$out_nfa> accepts a word w if and only if each of C<@in_nfas> accepts w.

=cut

    sub nfa_inter {
        my ($inter, @nfas) = sort { @$a <=> @$b } @_;
        for (@nfas) { $inter = nfa_inter2($inter, $_); }
        return
            $inter
         || [[1, [[$cc_any, 0]]]] # neutral element: accepting anything
        ;
    }

    # Multiplies the total number of states
    sub nfa_inter2 {
        my ($nfa_0, $nfa_1) = @_;

        # computed states
        my @todo = (0);
        my %todo_seen; # set of state_inds
        my %done;      # key-subset of %todo_seen (values are states)
        # After the following while, %done are %todo_seen the same set.

        # dead end detection
        my %path_tr;
        my @cur_livings;
        my %livings;

        # tmp variables
        my (
            $from_state_ind, $to_state_ind
          , $nfa_0_accepting, $nfa_0_transitions
          , $nfa_1_accepting, $nfa_1_transitions
          , $t_0, $t_1
          , $char_class
          , $accepting
          , @keys_path_to_state_ind
        );

        my $nfa_1_len = @$nfa_1;

        while (@todo) {
            $todo_seen{$from_state_ind} = $from_state_ind = pop(@todo);

            ($nfa_0_accepting, $nfa_0_transitions)
              = @{$$nfa_0[$from_state_ind / $nfa_1_len]}; # i-th state
            ($nfa_1_accepting, $nfa_1_transitions)
              = @{$$nfa_1[$from_state_ind % $nfa_1_len]}; # j-th state

            my $new_transitions = [];
            for $t_0 (@$nfa_0_transitions) {
                for $t_1 (@$nfa_1_transitions) {

                    if (
                        (
                            $char_class
                              = $cached_cc_inter2{$$t_0[0]}{$$t_1[0]}
                            ||= &cc_inter2($$t_0[0], $$t_1[0])
                        ) != $cc_none
                    ) {
                        push (@$new_transitions, [
                            $char_class
                          , $to_state_ind = $$t_0[1] * $nfa_1_len + $$t_1[1]
                        ]);
                        if (!exists($todo_seen{$to_state_ind})) {
                            push(@todo,
                                $todo_seen{$to_state_ind} = $to_state_ind);
                        }
                        $path_tr{$to_state_ind}{$from_state_ind} = undef;
                    }
                }
            }
            if ($accepting = $nfa_0_accepting && $nfa_1_accepting) {
                push(@cur_livings, $from_state_ind);
            }
            $done{$from_state_ind} = [
                $accepting
              , $new_transitions
            ];
        }

        # remove dead ends
        %livings = map { ($_ => $_) } @cur_livings;
        while (@cur_livings) {
            push(@cur_livings,
                map { $livings{$_} = $_ }
                grep { !exists($livings{$_}) }
                keys(%{$path_tr{pop(@cur_livings)}})
           );
        }

        if (keys(%livings) == 0) {
            return [[0, []]];
        }

        # compact renumbering
        my @sorted_keys;
        my $inter = [@done{
            @sorted_keys = sort { $a <=> $b } keys(%livings)
        }];
        my $i = 0;
        my %compact_map = map { ($_ => $i++) } @sorted_keys;

        for (
            map {
                @{$$_[1]}
              = grep { exists($compact_map{$$_[1]}) }
                @{$$_[1]}
            }
            @$inter
        ) {
            $$_[1] = $compact_map{$$_[1]};
        }
        return $inter;
    }
}

sub nfa_resolve_anchors {
    my ($nfa) = @_;

    # find state_inds reachable from the root by begin-anchor transitions
    my %begs = (0 => undef);
    my @todo = (0);
    while (defined(my $beg = pop(@todo))) {
        for (
            map { $$_[1] }               # state_ind
            grep { $$_[0][0][1] == -1 }  # begin-anchor
            @{$$nfa[$beg][1]}
        ) {
            if (!exists($begs{$_})) {
                $begs{$_} = undef;
                push(@todo, $_);
            }
        }
    }

    # find state_inds leading to an accepting state by end-anchor transitions
    my @cur_livings;
    my %path_tr;
    for my $from_state_ind (0..$#$nfa) {
        for (@{$$nfa[$from_state_ind][1]}) {
            $path_tr{$$_[1]}{$from_state_ind} = $$_[0];
        }
        if ($$nfa[$from_state_ind][0]) {
            push(@cur_livings, $from_state_ind);
        }
    }
    my %livings = map {($_ => undef)} @cur_livings;
    while (defined(my $end = pop(@cur_livings))) {
        for (
            grep {
                $path_tr{$end}{$_}[0][0] == -3;  # end-anchor
            }
            keys(%{$path_tr{$end}})
        ) {
            if (!exists($livings{$_})) {
                push(@cur_livings, $livings{$_} = undef);
                $$nfa[$_][0] = 1;
            }
        }
    }

    my $accept_empty;
    if (!($accept_empty = scalar(grep {$$nfa[$_][0]} keys(%begs)) ? 1 : 0)) {
        # special case for $^ for and the like: empty string matches
        my %begends;
        my @todo = keys(%begs);
        while (defined(my $begend = pop(@todo))) {
            for (
                map { $$_[1] }             # state_ind
                grep { $$_[0][0][1] < 0 }  # anchor
                @{$$nfa[$begend][1]}
            ) {
                if (!exists($begs{$_}) && !exists($begends{$_})) {
                    if ($$nfa[$_][0]) {
                        $accept_empty = 1;
                        @todo = ();
                        last;
                    }
                    $begends{$_} = undef;
                    push(@todo, $_);
                }
            }
        }
    }

    # remove anchors
    for my $from_state_ind (
        grep {
            grep { $$_[0][0][0] < 0 }  # anchor
            @{$$nfa[$_][1]}            # transitions
        }
        (0..$#$nfa)
    ) {
        my $state = $$nfa[$from_state_ind];
        $$state[1] = [
            map {
                if ($$_[0][0][0] >= 0) {
                    $_;
                }
                elsif ( @{$$_[0]} == 1 ) {
                    delete($path_tr{$$_[1]}{$from_state_ind});
                    ();
                }
                else {
                    $path_tr{$$_[1]}{$from_state_ind}
                  = $$_[0]
                  = interval_list_to_cc(@{$$_[0]}[1..$#{$$_[0]}]);
                    $_;
                }
            }
            @{$$state[1]}  # transitions
        ];
    }

    # ensure that the initial state cannot be reached
    if (@{$$nfa[0][1]}) {
        # proper init transitions (clone of the initial state needed)

        # replace transitions to the initial state
        # with transitions to the cloned initial state
        my $new_state_ind = @$nfa;
        my $clone_reachable;
        for my $transition (
            grep { $$_[1] == 0 }  # to initial state
            map { @{$$_[1]} }     # transitions
            @$nfa
        ) {
            $$transition[1] = $new_state_ind;
            $clone_reachable = 1;
        }

        if ($clone_reachable) {
            my $new_state = [
                $$nfa[0][0]
              , [@{$$nfa[0][1]}]
            ];
            push(@$nfa, $new_state);
            $path_tr{$new_state_ind} = $path_tr{0};
            for (@{$$nfa[0][1]}) {
                $path_tr{$$_[1]}{$new_state_ind} = $$_[0];
            }
            if ($$nfa[0][0]) {
                $livings{$new_state_ind} = undef;
            }
        }
    }
    else {
        # no proper init transitions

        # drop transitions to the initial state
        for my $state (@$nfa) {
            @{$$state[1]} = grep { $$_[1] != 0 } @{$$state[1]};
        }
    }
    delete($path_tr{0});

    # extend initial state (merge all initial states of %begs)
    if (keys(%begs) > 1) {
        my %state_ind_to_char_classes;
        for ( map { @{$$nfa[$_][1]} } keys(%begs) ) {
            push(@{$state_ind_to_char_classes{$$_[1]}}, $$_[0]);
        }
        @{$$nfa[0][1]}
          = map { [
                $path_tr{$_}{0} = cc_union(@{$state_ind_to_char_classes{$_}})
              , int($_)
            ] }
            keys(%state_ind_to_char_classes)
        ;
    }
    if ($$nfa[0][0] = $accept_empty) {
        $livings{0} = undef;
    }

    # remove unreachable states
    my @cur_reachables = (0);
    my %reachables = (0 => 0);
    while (@cur_reachables) {
        my $from_state_ind = shift(@cur_reachables);
        for (
            map { $$_[1] }
            @{$$nfa[$from_state_ind][1]}
        ) {
            if (!exists($reachables{$_})) {
                push(@cur_reachables, $reachables{$_} = $_);
            }
        }
    }

    # remove dead ends
    delete(@livings{grep { !exists($reachables{$_}) } keys(%livings)});
    @cur_livings = keys(%livings);
    while (@cur_livings) {
        for (
            grep { exists($reachables{$_}) }
            keys(%{$path_tr{pop(@cur_livings)}})
        ) {
            if (!exists($livings{$_})) {
                push(@cur_livings, $_);
                $livings{$_} = undef;
            }
        }
    }

    if (keys(%livings) == 0) {
        return [[0, []]];
    }
    elsif (keys(%livings) == @$nfa) {
        return $nfa;
    }

    # compact renumbering
    my @sorted_keys = sort { $a <=> $b } keys(%livings);
    my $i = 0;
    my %compact_map = map { ($_ => $i++) } @sorted_keys;

    return [
        map {
            @{$$_[1]}
              = map {
                    $$_[1] = $compact_map{$$_[1]};
                    $_;
                }
                grep { exists($compact_map{$$_[1]}) }
                @{$$_[1]}
            ;
            $_;
        }
        @$nfa[@sorted_keys]
    ];
}

=item C<nfa_match($in_nfa, $str)>

Returns true if and only if C<$in_nfa> accepts C<$str>.

=cut

sub nfa_match {
    my ($nfa, $str) = @_;

    my %state_inds = (0 => 0);
    for my $c ( map { ord($_) } split('', $str) ) {
        %state_inds
          = map { $$_[1] => $$_[1] }
            grep { cc_match($$_[0], $c) }  # matching transition list
            map { @{$$_[1]} }              # all transition list
            @$nfa[values(%state_inds)]     # current states
        ;
    }

    return grep { $$_[0] } @$nfa[values(%state_inds)];
}

sub nfa_dump {
    my ($nfa) = @_;
    my $dump = '';
    for my $i (0..$#$nfa) {
        $dump
         .= "$i:"
          . ($$nfa[$i][0] ? " (accepting)" : "")
          . "\n"
        ;
        for my $transition (@{$$nfa[$i][1]}) {
            $dump
         .= "    "
          . cc_to_regex($$transition[0]) . " => $$transition[1]\n";
        }
    }
    return $dump;
}

=item C<nfa_isomorph($nfa1, $nfa2)>

Returns true if and only if the labeled graphs represented by C<$nfa1>
and C<$nfa2> are isomorph. While isomorph C<$nfa>s accept the same language,
the converse is not true.

=cut

sub nfa_isomorph {
    my ($nfa1, $nfa2) = @_;

    my %nfa1_nfa2_indexes = (0 => 0);
    my %nfa2_nfa1_indexes = (0 => 0);
    my @nfa1_index_todo = (0);

    while (defined(my $nfa1_index = pop(@nfa1_index_todo))) {

        my $state1 = $$nfa1[$nfa1_index];
        my $state2 = $$nfa2[$nfa1_nfa2_indexes{$nfa1_index}];

        # accepting
        if ($$state1[0] != $$state2[0]) {
            return 0;
        }

        # transitions
        my $transitions1 = [sort { $$a[0] <=> $$b[0] } @{$$state1[1]}];
        my $transitions2 = [sort { $$a[0] <=> $$b[0] } @{$$state2[1]}];
        if (@$transitions1 != @$transitions2) {
            return 0;
        }
        for my $i (0..$#$transitions1) {
            my ($cc1, $next_index1) = @{$$transitions1[$i]};
            my ($cc2, $next_index2) = @{$$transitions2[$i]};
            if ($cc1 ne $cc2) {
                return 0;
            }
            if (exists($nfa1_nfa2_indexes{$next_index1})) {
                if ($nfa1_nfa2_indexes{$next_index1} != $next_index2) {
                    return 0;
                }
            }
            elsif (exists($nfa2_nfa1_indexes{$next_index2})) {
                # $nfa2_nfa1_indexes{$next_index2} != $next_index1
                # because
                #   - !exists($nfa1_nfa2_indexes{$next_index1})
                #   - $nfa1_nfa2_indexes and $nfa2_nfa1_indexes
                #     are reverse to each other by construction
                return 0;
            }
            else {
                $nfa1_nfa2_indexes{$next_index1} = $next_index2;
                $nfa2_nfa1_indexes{$next_index2} = $next_index1;
                push(@nfa1_index_todo, $next_index1);
            }
        }
    }
    return 1;
}


##############################################################################
# $dfa
##############################################################################

# input X:
#     Arbitrary list of intervals.
# output Y:
#     List of pairwise disjoint intervals spanning the same subset such that
#     for any intersections/unions of intervals of X
#     an equal union of intervals of Y exists.
#     In short, all boundaries of X are preserved.
#
# Motivation:
#     nfas use character classes as alphabet (instead of single code points).
#     dfa operations needs a common refinement of sets of character classes.
#
# Example:
#     interval_cases( [ [0, 5], [2, 8] ] )
#   = [ [0, 1], [2, 5], [6, 8] ]
#
#     X: |0 1 2 3 4 5|
#            |2 3 4 5 6 7 8|
#     Y: |0 1|2 3 4 5|6 7 8|
#
sub interval_cases {
    my ($interval_list) = @_;
    my @sorted
      = sort {
            $$a[0] <=> $$b[0]
         || $$b[1] <=> $$a[1]
        }
        @$interval_list
    ;
    my %los;
    my %his;
    my $i = 0;
    while ($i < @sorted) {
        $los{$sorted[$i][0]} = undef;
        $his{$sorted[$i][1]} = undef;
        my $j = $i + 1;
        while (
            $j < @sorted
         && $sorted[$j][0] == $sorted[$i][0]
         && $sorted[$j][1] == $sorted[$i][1]
        ) {
            # $sorted[$i]  ---------
            # $sorted[$j]  ---------
            $j++;
        }
        while (
            $j < @sorted
         && $sorted[$j][0] == $sorted[$i][0]
         && $sorted[$j][1] < $sorted[$i][1]
        ) {
            # $sorted[$i]  ---------
            # $sorted[$j]  -----
            $his{$sorted[$j][1]} = undef;
            $los{$sorted[$j][1]+1} = undef;
            $j++;
        }
        # $sorted[$j][0] > $sorted[$i][0]
        while (
            $j < @sorted
         && $sorted[$j][1] < $sorted[$i][1]
        ) {
            # $sorted[$i]  ---------
            # $sorted[$j]    -----
            $his{$sorted[$j][0]-1} = undef;
            $los{$sorted[$j][0]} = undef;
            $his{$sorted[$j][1]} = undef;
            $los{$sorted[$j][1]+1} = undef;
            $j++;
        }
        if (
            $j < @sorted
         && $sorted[$j][0] <= $sorted[$i][1]
        ) {
            #     $sorted[$j][0] > $sorted[$i][0]
            #  && $sorted[$j][0] <= $sorted[$i][1]
            #  && $sorted[$j][1] >= $sorted[$i][1]
            #
            # $sorted[$i]  ---------
            # $sorted[$j]         -----
            $his{$sorted[$j][0]-1} = undef;
            if ($sorted[$i][1] != $sorted[$j][1]) {
                $los{$sorted[$i][1]+1} = undef;
            }
        }
        $i = $j;
    }
    my @sorted_los = sort( { $a <=> $b } keys(%los));
    my @sorted_his = sort( { $a <=> $b } keys(%his));
    return [ map { [$sorted_los[$_], $sorted_his[$_]] } (0..$#sorted_los) ];
}

=item C<nfa_to_dfa($in_nfa)>

Compute a deterministic finite automaton from C<$in_nfa>
(powerset construction).

The data structure of a deterministic finite automaton (dfa) is
the same as that of a non-deterministic one, but it is further constrained:
For each state and each unicode character there exist exactly one transition
(i.e. a pair C<($char_class, $state_index)>) matching this character.

Note that the following constraint hold for both a C<$dfa> and a C<$nfa>:
For each pair of state p1 and p2, there exists at most one transition
from p1 to p2 (artefact of this implementation).

=cut

sub nfa_to_dfa {
    my ($nfa) = @_;
    my $dfa = [];
    if (!@$nfa) {
        return [[0, [$cc_any, 0]]];
    }
    my $trap_needed = 0;
    my $dfa_size = 0;
    my %dfa_indexes = ("0" => $dfa_size++);
    my @todo = ([0]);
    while (@todo) {
        my $nfa_indexes = pop(@todo);
        my $dfa_index = $dfa_indexes{join('.', @$nfa_indexes)};
        my @nfa_states = @$nfa[@$nfa_indexes];

        # accepting
        $$dfa[$dfa_index][0] = scalar(grep { $$_[0] } @nfa_states) ? 1 : 0;

        # transitions
        my $cases = interval_cases([
            map { @{$$_[0]} }
            map { @{$$_[1]} }
            @nfa_states
        ]);
        my %dfa_index_to_intervals;
        for my $interval (@$cases) {
            my @next_nfa_indexes
              = sort(keys(%{ {
                    map { ($$_[1] => undef) }
                    grep { cc_match($$_[0], $$interval[0]) }
                    map { @{$$_[1]} }
                    @nfa_states
                } }))
            ;
            my $next_index_key = join('.', @next_nfa_indexes);
            if (!exists($dfa_indexes{$next_index_key})) {
                $dfa_indexes{$next_index_key} = $dfa_size++;
                push(@todo, \@next_nfa_indexes);
            }
             push(@{$dfa_index_to_intervals{$dfa_indexes{$next_index_key}}},
                 $interval
             );
        }

        my @any_ccs;
        $$dfa[$dfa_index][1] = [
            map {
                my $cc = interval_list_to_cc($dfa_index_to_intervals{$_});
                push(@any_ccs, $cc);
                [$cc, $_ ];
            }
            sort(keys(%dfa_index_to_intervals))
        ];
        if ((my $all_cc = cc_union(@any_ccs)) != $cc_any) {
            $trap_needed = 1;
            push(@{$$dfa[$dfa_index][1]},
                [ cc_neg($all_cc), -1 ]
            );
        }
    }

    if ($trap_needed) {
        for (
            grep { $$_[1] == -1 }
            map { @{$$_[1]} }
            @$dfa
        ) {
            $$_[1] = $dfa_size;
        }
        $$dfa[$dfa_size] = [0, [[$cc_any, $dfa_size]]];
    }

    return $dfa;
}


=item C<dfa_to_min_dfa($in_dfa)>


Computes a minimal deterministic C<$dfa> from the given C<$in_dfa>
(Hopcroft's algorithm).

Note that the given C<$in_dfa> must be a C<$dfa>, as
returned from C<nfa_to_dfa()>, and not a mere C<$nfa>.

Myhill-Nerode theorem: two minimal dfa accepting
the same language are isomorph (i.e. C<nfa_isomorph()> returns true).

=cut

sub dfa_to_min_dfa {
    my ($dfa) = @_;
    my @acceptings;
    my @non_acceptings;
    my @intervals;
    for my $index (0..$#$dfa) {
        if ($$dfa[$index][0]) {
            push(@acceptings, $index);
        }
        else {
            push(@non_acceptings, $index);
        }
        push(@intervals, map { @{$$_[0]} } @{$$dfa[$index][1]})
    }
    my $partition;
    if (@non_acceptings) {
        $partition = [\@non_acceptings, \@acceptings];
        my %todo = (join('.', @non_acceptings) => \@non_acceptings);
        my $cases = interval_cases(\@intervals);
        while (my ($todo_key) = keys(%todo)) {
            my %indexes = map { ($_ => undef) } @{delete($todo{$todo_key})};
            for my $interval (@$cases) {
                my %prev_inds = (
                    map { ($_ => undef) }
                    grep {
                        my $i = $_;
                        grep {
                            exists($indexes{$$_[1]})
                         && cc_match($$_[0], $$interval[0])
                        }
                        @{$$dfa[$i][1]}
                    }
                    (0..$#$dfa)
                );
                my $refined_partition;
                for my $partition_indexes (@$partition) {
                    my (@inter, @diff);
                    for (@$partition_indexes) {
                        if (exists($prev_inds{$_})) {
                            push(@inter, $_);
                        }
                        else {
                            push(@diff, $_);
                        }
                    }
                    if (!@inter || !@diff) {
                        push(@$refined_partition, $partition_indexes);
                    }
                    else {
                        push(@$refined_partition, \@inter, \@diff);
                        my $prev_inds_key = join('.', sort(keys(%prev_inds)));
                        if ($todo{$prev_inds_key}) {
                            delete($todo{$prev_inds_key});
                            $todo{join('.', @diff)} = \@diff;
                            $todo{join('.', @inter)} = \@inter;
                        }
                        elsif (@diff < @inter) {
                            $todo{join('.', @diff)} = \@diff;
                        }
                        else {
                            $todo{join('.', @inter)} = \@inter;
                        }
                    }
                }
                $partition = $refined_partition;
            }
        }
    }
    else {
        $partition = [\@acceptings];
    }
    my $state_ind_to_equiv;
    for (grep { @$_ != 1 } @$partition) {
        @$state_ind_to_equiv{@$_[1..$#$_]} = ($$_[0]) x $#$_;
    }
    return _nfa_shrink_equiv($dfa, $state_ind_to_equiv);
}


##############################################################################
# $tree
##############################################################################

=back

=head2 Tree

  $tree = [ $star, [ $alt_0, $alt_1, ... ] ]
       or $char_class # ref($char_class) eq CHAR_CLASS
       or undef # accepting nothing
  $alt = [ $tree_0, $tree_1, ... ]

A C<$tree> is a hierarchical data structure used as intermediate form for
regular expression generation routines.

Similar to a parse tree, except that the C<$tree>s described here are not the
direct result of the parsing routines C<ere_to_xxx()>; indeed, the parsing
routines generate a C<$nfa>, which then can be converted to a C<$tree>.

A string is spanned by C<$tree = [$star, [ $alt_0, $alt_1, ... ] ]> if it is
spanned by one of the C<$alt_i> (if C<$star> is false) of a repetition thereof
(if C<$star> is true).

A string is spanned by C<$alt = [ $tree_0, $tree_1, ...]> if it is the
concatenation of C<@substrings>, each C<$substrings[$i]> being spanned by
C<$$alt[$i]>.

=over 4

=item C<nfa_to_tree($nfa)>

Converts a C<$nfa> to a C<$tree>.
Returns C<undef> if the C<$nfa> accepts nothing (not even the empty string).

=cut

sub nfa_to_tree {
    my ($nfa) = @_;

    # Warshall algorithm (Kleene's theorem)
    # with preliminary computations:
    #   - words-paths (unbranched paths) are shrunken
    #   - unique accepting state is ensured
    #   - branches (with single parent) are skipped

    my $path = {};
    my $path_tr = {};
    my %accepting_state_inds;

    # Initialization of the paths

    for my $i (0..$#$nfa) {
        if ($$nfa[$i][0]) {
            $accepting_state_inds{$i} = $i;
        }
        for (@{$$nfa[$i][1]}) {
            $$path{$i}{$$_[1]}
          = $$path_tr{$$_[1]}{$i}
          = $$_[0];
        }
    }

if (TRACE_NFA_TO_TREE) {
    print STDERR "before word shrink\n";
    for my $i (sort {$a <=> $b} (keys(%$path))) {
    for my $j (sort {$a <=> $b} (keys(%{$$path{$i}}))) {
        print STDERR "$i $j: " . cc_to_regex($$path{$i}{$j}) . "\n";
    }}
}

    my @tree_list;
    my @state_ind_path;

    # word-paths (unbranched paths) are shrunken
    for my $first (0..$#$nfa) {
        if (!exists($$path{$first})) { next; }
        my @todo
          = sort {
                keys(%{$$path_tr{$b}}) <=> keys(%{$$path_tr{$a}})
             || $b <=> $a
            }
            grep { $_ != $first }
            keys(%{$$path{$first}})
        ;
        my %todo_ctrl;
        my $todo_sorted = 1;
        while (
            @todo
         && (
                !$todo_sorted
             || keys(%{$$path_tr{$todo[-1]}}) == 1
            )
        ) {
            $todo_ctrl{my $i = pop(@todo)} = undef;
            if (keys(%{$$path_tr{$i}}) != 1) {
                if ($i != $first && !$todo_sorted && @todo) {
                    @todo
                      = sort {
                            keys(%{$$path_tr{$b}}) <=> keys(%{$$path_tr{$a}})
                         || $b <=> $a
                        }
                        keys(%{ { map { ($_ => undef) } (@todo, $i) } })
                    ;
                    $todo_sorted = 1;
                }
                next;
            }
            $todo_sorted = 0;

            my @tree_list = ($$path{$first}{$i});
            my @state_ind_path = ($i);

            while (
                keys(%{$$path{$i}}) == 1
             && (my $j = (keys(%{$$path{$i}}))[0]) != $first
            ) {
                push(@tree_list, $$path{$i}{$j});
                push(@state_ind_path, $i = $j);
                if (keys(%{$$path_tr{$j}}) != 1) {
                    last;
                }
            }

if (TRACE_NFA_TO_TREE) {
    print STDERR "first, state_ind_path: $first, @state_ind_path\n";
}

            if (@state_ind_path > 1) {

if (TRACE_NFA_TO_TREE) {
    print STDERR "delete head $first -> $state_ind_path[0]\n";
}
                delete($$path{$first}{$state_ind_path[0]});
                for (@state_ind_path[0..$#state_ind_path-1]) {
                    delete($$path{$_});
                    delete($$path_tr{$_});
if (TRACE_NFA_TO_TREE) {
    print STDERR "delete path $_ -> *\n";
    print STDERR "delete path * <- $_\n";
}
                }
                delete($$path_tr{$state_ind_path[-1]}{$state_ind_path[-2]});
                if (!exists($todo_ctrl{$state_ind_path[-1]})) {
                    $todo_ctrl{$state_ind_path[-1]} = undef;
                    push(@todo, $state_ind_path[-1]);
                }
if (TRACE_NFA_TO_TREE) {
    print STDERR "delete tail $state_ind_path[-1] <- $state_ind_path[-2]\n";
}


                # $first -> $last
                my $last = $state_ind_path[-1];
                $$path{$first}{$last}
              = $$path_tr{$last}{$first}
              = exists($$path{$first}{$last})
                  ? tree_alt(
                        $$path{$first}{$last}
                      , tree_concat(@tree_list)
                    )
                  : tree_concat(@tree_list)
                ;

if (TRACE_NFA_TO_TREE) {
    print STDERR
        "$first -> $last created (first ->last): "
      . join('', map {_tree_to_regex($_)} @tree_list)  . "\n";
}

                for (0..$#state_ind_path-1) {

                    # $first -> accepting
                    if ($accepting_state_inds{
                        my $state_ind = $state_ind_path[$_]
                    }) {
                        $$path{$first}{$state_ind}
                      = $$path_tr{$state_ind}{$first}
                      = exists($$path{$first}{$state_ind})
                          ? tree_alt(
                                $$path{$first}{$state_ind}
                              , tree_concat(@tree_list[0..$_])
                            )
                          : tree_concat(@tree_list[0..$_])
                        ;
if (TRACE_NFA_TO_TREE) {
    print STDERR
        "$first -> $state_ind created (first -> accepting): "
      . join('', map {_tree_to_regex($_)} @tree_list[0..$_])  . "\n";
}
                    }
                }
            }
        }
    }

if (TRACE_NFA_TO_TREE) {
    print STDERR "after word shrink\n";
    for my $i (sort {$a <=> $b} (keys(%$path))) {
    for my $j (sort {$a <=> $b} (keys(%{$$path{$i}}))) {
        print STDERR "$i $j: " . tree_dump($$path{$i}{$j}) . "\n";
    }}
    for my $j (sort {$a <=> $b} (keys(%$path_tr))) {
    for my $i (sort {$a <=> $b} (keys(%{$$path_tr{$j}}))) {
        print STDERR "$j <- $i: " . tree_dump($$path_tr{$j}{$i}) . "\n";
    }}
}

    # unique accepting state is ensured
    # (pseudo-unique: the initial state may additionally be accepting)
    my $unique_accepting_state_ind = @$nfa;
    if (
        keys(%accepting_state_inds) == 1
    ) {
        $unique_accepting_state_ind = (keys(%accepting_state_inds))[0];
    }
    elsif (
        keys(%accepting_state_inds) == 2
     && exists($accepting_state_inds{0})
    ) {
        $unique_accepting_state_ind
      = (grep {$_} keys(%accepting_state_inds))[0];
    }
    else {
        $unique_accepting_state_ind = @$nfa;
        for my $to_state_ind (keys(%accepting_state_inds)) {
            for my $from_state_ind (keys(%{$$path_tr{$to_state_ind}})) {
                push(
                    @{$$path_tr{$unique_accepting_state_ind}{$from_state_ind}}
                  , $$path_tr{$to_state_ind}{$from_state_ind}
                );
            }
        }
        for my $from_state_ind (
            keys(%{$$path_tr{$unique_accepting_state_ind}})
        ) {
            $$path_tr{$unique_accepting_state_ind}{$from_state_ind}
          = $$path{$from_state_ind}{$unique_accepting_state_ind}
          = tree_alt(
                @{$$path_tr{$unique_accepting_state_ind}{$from_state_ind}}
            );
        }
    }

if (TRACE_NFA_TO_TREE) {
    print STDERR "after unique state addition\n";
    for my $i (sort {$a <=> $b} (keys(%$path))) {
    for my $j (sort {$a <=> $b} (keys(%{$$path{$i}}))) {
        print STDERR "$i $j: " . tree_dump($$path{$i}{$j}) . "\n";
    }}
    for my $j (sort {$a <=> $b} (keys(%$path_tr))) {
    for my $i (sort {$a <=> $b} (keys(%{$$path_tr{$j}}))) {
        print STDERR "$j <- $i: " . tree_dump($$path_tr{$j}{$i}) . "\n";
    }}
}

    for my $reversed (0, 1) {
        my ($tmp_path, $tmp_path_tr)
          = $reversed
          ? ($path_tr, $path)
          : ($path, $path_tr)
        ;

        # branches (with single parent) are skipped
        my @branch_inds
          = $reversed
          ? sort {$a <=> $b} (keys(%$tmp_path))
          : sort {$b <=> $a} (keys(%$tmp_path))
        ;
        while (@branch_inds) {
            my $branch = pop(@branch_inds);
            if  (
                !exists($$tmp_path{$branch})
                # root cannot be un-branched
             || $branch == 0
                # accepting states cannot be un-branched
             || $branch == $unique_accepting_state_ind
                # single parent (non-root have one or more parents)
             || keys(%{$$tmp_path_tr{$branch}}) != 1
            ) {
                next;
            }

if (TRACE_NFA_TO_TREE) {
    print STDERR "branch at $branch\n";
}
            my ($parent) = keys(%{$$tmp_path_tr{$branch}}); # single parent
            if (
                ref($$tmp_path{$parent}{$branch}) ne CHAR_CLASS
             && (
                    # starified parent
                    $$tmp_path{$parent}{$branch}[0]
                    # parent containing several paths
                 || @{$$tmp_path{$parent}{$branch}[1]} > 1
                )
            ) {
                next;
            }

            my (@children) = keys(%{$$tmp_path{$branch}});

            for my $child (@children) {
                $$tmp_path{$parent}{$child}
              = $$tmp_path_tr{$child}{$parent}
              = exists($$tmp_path{$parent}{$child})
                  ? tree_alt(
                         $$tmp_path{$parent}{$child}
                      , tree_concat2(
                            $reversed
                          ? (
                                $$tmp_path{$branch}{$child}
                              , $$tmp_path{$parent}{$branch}
                            )
                          : (
                                $$tmp_path{$parent}{$branch}
                              , $$tmp_path{$branch}{$child}
                            )
                        )
                    )
                  : tree_concat2(
                            $reversed
                          ? (
                                $$tmp_path{$branch}{$child}
                              , $$tmp_path{$parent}{$branch}
                            )
                          : (
                                $$tmp_path{$parent}{$branch}
                              , $$tmp_path{$branch}{$child}
                            )
                    )
                ;
                delete($$tmp_path_tr{$child}{$branch});

if (TRACE_NFA_TO_TREE) {
    print STDERR
        "parent -> branch: "
      . tree_dump($$tmp_path{$parent}{$branch}) . "\n";
    print STDERR
        "branch -> child : "
      . tree_dump($$tmp_path{$branch}{$child}) . "\n";
    print STDERR
        "$parent -> $child created (un-branch): "
      . tree_dump($$tmp_path{$parent}{$child})
      . ($reversed ? " (reversed)" : "" )  . "\n";
    print STDERR
        "delete $child <- $branch\n";
}

            }
            delete($$tmp_path{$parent}{$branch});
            delete($$tmp_path{$branch});
            delete($$tmp_path_tr{$branch});

if (TRACE_NFA_TO_TREE) {
    print STDERR "delete $parent -> $branch\n";
    print STDERR "delete $branch -> *\n";
    print STDERR "delete $branch <- *\n";
}

            push(@branch_inds, $parent);
        }

if (TRACE_NFA_TO_TREE) {
    print STDERR "after branch skip\n";
    for my $i (sort {$a <=> $b} (keys(%$tmp_path))) {
    for my $j (sort {$a <=> $b} (keys(%{$$tmp_path{$i}}))) {
        if ($reversed) {
            print STDERR "$j $i: " . tree_dump($$tmp_path{$i}{$j}) . "\n";
        }
        else {
            print STDERR "$i $j: " . tree_dump($$tmp_path{$i}{$j}) . "\n";
        }
    }}
    for my $j (sort {$a <=> $b} (keys(%$tmp_path_tr))) {
    for my $i (sort {$a <=> $b} (keys(%{$$tmp_path_tr{$j}}))) {
        print STDERR
            ($reversed ? "$i <- $j: " : "$j <- $i:")
          . tree_dump($$tmp_path_tr{$j}{$i}) . "\n";
    }}
}

    }


    # starify diagonal
    for (grep { exists($$path{$_}{$_}) } keys(%$path)) {
        $$path{$_}{$_}
      = $$path_tr{$_}{$_}
      = tree_starify($$path{$_}{$_});
    }

if (TRACE_NFA_TO_TREE) {
    print STDERR "after diagonal starification\n";
    for my $i (sort {$a <=> $b} (keys(%$path))) {
    for my $j (sort {$a <=> $b} (keys(%{$$path{$i}}))) {
        print STDERR "$i $j: ";
        print STDERR tree_dump($$path{$i}{$j}) . "\n";
    }}
}

    # Warshall algorithm (Kleene's theorem)
    my %updates;
    my %weight = map {
        my $w = 0;
        for (values(%{$$path{$_}})) { $w += _tree_weight($_) }
        ($_ => $w);
    } keys(%$path);
    my @ks = sort { $weight{$a} <=> $weight{$b} || $a <=> $b } keys(%$path);
    # note that keys(%$path_tr) are not additionally needed
    # case i == k && k == j: nothing to do
    # case i != k && k != j: $$path{$k}{$j} must exist
    # case i == k && k != j: $$path{$k}{$k} must exist
    # case i != k && k == j: $$path{$k}{$k} must exist
    for my $k (@ks) {
        for my $i (keys(%{$$path_tr{$k}})) {   # i -> k
            for my $j (keys(%{$$path{$k}})) {  # k -> j
                if ($i == $k && $k == $j) { next; }
                my @trees;
                if (
                    exists($$path{$i}{$j})
                 && ($i != $k && $k != $j)
                ) {
                    push(@trees, $$path{$i}{$j});
                }
                my $new_tree
                  = exists($$path{$k}{$k})
                  ? tree_concat(
                        (
                            $i != $k
                          ? $$path{$i}{$k}
                          : ()
                        )
                      , $$path{$k}{$k}
                      , (
                            $k != $j
                          ? $$path{$k}{$j}
                          : ()
                        )
                    )
                  : tree_concat2($$path{$i}{$k}, $$path{$k}{$j})
                ;
                push(@trees, $i == $j ? tree_starify($new_tree) : $new_tree);

                if (@trees == 1) {
                    $updates{$i}{$j} = $trees[0];
                }
                else {
                    $updates{$i}{$j} = tree_alt(@trees);
                }
            }
        }
        for my $i (keys(%updates)) {
            for my $j (keys(%{$updates{$i}})) {
                $$path{$i}{$j} = $$path_tr{$j}{$i} = $updates{$i}{$j};
            }
        }

if (TRACE_NFA_TO_TREE) {
    my $num_of_updates = map {keys(%{$updates{$_}})} keys(%updates);
    print STDERR "k = $k ($num_of_updates updates)\n";
    if ($num_of_updates) {
        for my $i (sort {$a <=> $b} (keys(%$path))) {
        for my $j (sort {$a <=> $b} (keys(%{$$path{$i}}))) {
            print STDERR "$i $j: ";
            print STDERR tree_dump($$path{$i}{$j}) . "\n";
        }}
    }
}

        %updates = ();
    }

    my $tree;

    # accepting empty init
    if ($$nfa[0][0]) {

        my $path_0_0 = exists($$path{0}{0}) ? $$path{0}{0} : $cc_none;

        if ($unique_accepting_state_ind == 0) {
            $tree = $path_0_0;
        }
        else {
            my $path_0_end = $$path{0}{$unique_accepting_state_ind};

            if (
                $path_0_0 == $cc_none
             && ref($path_0_end) ne CHAR_CLASS
             && $$path_0_end[0]
            ) {
                # starified expression e* does not need (|e*)
                $tree = $path_0_end;
            }
            else {
                # non-starified expression e needs (|e)
                $tree = tree_alt($path_0_0, $path_0_end);
            }
        }
    }
    else {
        $tree = $$path{0}{$unique_accepting_state_ind};
    }

if (TRACE_NFA_TO_TREE) {
    print STDERR "tree: " . tree_dump($tree) . "\n";
}

    _tree_factorize_fixes($tree);

if (TRACE_NFA_TO_TREE) {
    print STDERR "tree (after factorization): " . tree_dump($tree) . "\n";
}
    return $tree;
}


# Recursively (bottom up) factorizes prefixes and suffixes out from
# alternations if at least one of them contains a sub-tree.
#
# Example 1: (ab1cd|ab2cd|ab3*cd) -> ab(1|2|3*)cd
# Example 2: (ab1cd|ab2cd|ab3cd) remains the same (no sub-tree)
#
# Example 2 does not need to be factorized
# because it can be represented by a drop-down list,
# which is the primary purpose of this module;
# in this case, a factorization may lead to counter-intuitive results,
# like words cut in the middle.
#
# But example 1 (less common) could only be represented as mere free-text
# if the common pre- and suf-fixes were not factorized out,
# thus loosing information for the input helper (xxx_to_input_constraints).
#
# This behavior can be changed by setting our $FULL_FACTORIZE_FIXES = 1;
# in this case, Example 2 would produce ab(1|2|3)cd.
#
# Modifies $tree in place
#
sub _tree_factorize_fixes {
    my ($tree) = @_;
    if (
        !defined($tree)
     || ref($tree) eq CHAR_CLASS
     || @{$$tree[1]} == 0
     || !$FULL_FACTORIZE_FIXES
     && (
            @{$$tree[1]} == 1
         || !grep { ref($_) ne CHAR_CLASS } map { @$_ } @{$$tree[1]}
        )
    ) {
        return $tree;
    }
    else {
        for (grep { grep { ref($_) ne CHAR_CLASS } @$_ } @{$$tree[1]} ) {
            my $tmp_tree =
                tree_concat(map { _tree_factorize_fixes($_) } @$_)
            ;
            if (
                ref($tmp_tree) eq CHAR_CLASS
             || $$tmp_tree[0]
             || @{$$tmp_tree[1]} > 1
            ) {
                $_ = [$tmp_tree];
            }
            else {
                $_ = $$tmp_tree[1][0];
            }
        }

        # flatten
        @{$$tree[1]} = map {
            [map {
                ref($_) ne CHAR_CLASS
             && !$$_[0] && @{$$_[1]} == 1
              # non-starified with single alternation
              ? @{$$_[1][0]}
              : $_
            } grep { defined($_) } @$_]
        } @{$$tree[1]};

        if (@{$$tree[1]} == 1) {
            return $tree;
        }

        my $fst_len = @{$$tree[1][0]};
        my ($pre_len, $suf_len) = (0, 0);
        for (1, 0) {
            my ($len_ref, @range)
              = $_
              ? (\$pre_len, (0..$fst_len-1))
              : (\$suf_len, map {-$_} (1..$fst_len-$pre_len))
            ;
            for my $i (@range) {
                if (
                    grep {
                        $i >= @$_
                     || ref($$_[$i]) ne CHAR_CLASS
                     || $$tree[1][0][$i] != $$_[$i]
                    }
                    @{$$tree[1]}[1..$#{$$tree[1]}]
                ) {
                    last;
                }
                $$len_ref++;
            }
        }
        if ($pre_len == 0 && $suf_len == 0) {
            return $tree;
        }

        my $empty_seen = 0;
        my $mid_tree = [
            0
          , [
                map {
                    if ($pre_len <= $#$_ - $suf_len) {
                        [ @$_[$pre_len..$#$_-$suf_len] ];
                    }
                    elsif (!$empty_seen++) {
                        [];
                    }
                    else {
                        ();
                    }
                }
                @{$$tree[1]}
            ]
        ];
        $$tree[1] = [[
              @{$$tree[1][0]}[0..$pre_len-1]
            , $empty_seen == @{$$tree[1]} ? () : $mid_tree
            , @{$$tree[1][0]}[$fst_len-$suf_len..$fst_len-1]
        ]];
        return $tree;
    }
}

=item C<tree_to_regex($tree, $to_perlre)>

Converts a C<$tree> to an C<$ere> (if C<$to_perlre> is false)
or to a C<$perlre> (if C<$to_perlre> is true).

=cut

sub tree_to_regex {
    my $re = defined($_[0]) ? &_tree_to_regex : '$.';
    return $_[1] ? qr/\A$re\z/ms : "^$re\$";
}

{
    my %cc_to_regex_cache;

    sub _tree_to_regex {
        my ($tree, $to_perlre) = (@_, 0);
        if (ref($tree) eq CHAR_CLASS) {
            return
                $cc_to_regex_cache{$tree.$to_perlre}
            ||= cc_to_regex($tree, $to_perlre)
            ;
        }
        elsif (@{$$tree[1]} == 0) {
            return '';
        }
        elsif (
            @{$$tree[1]} == 1       # single alteration
         && @{$$tree[1][0]} == 1    # single atom
        ) {
            my $atom = $$tree[1][0][0];
            if (ref($atom) eq CHAR_CLASS) {
                return join('',
                    $cc_to_regex_cache{$atom.$to_perlre}
                ||= cc_to_regex($atom, $to_perlre)
                  , $$tree[0] ? '*' : ()
                );
            }
            else {
                return _tree_to_regex(
                    [$$tree[0] || $$atom[0], $$atom[1]]
                  , $to_perlre
                );
            }
        }
        else {
            my $needs_parenthesis
              = @{$$tree[1]} > 1                  # (a|...)
             || $$tree[0] && @{$$tree[1][0]} > 1  # (ab...)*
            ;

            return join(''
              , ($needs_parenthesis ? ($to_perlre ? '(?:' : '(') : ())
              , (
                    join('|',
                        map {
                            join('',
                                map {
                                    ref($_) eq CHAR_CLASS
                                  ? $cc_to_regex_cache{$_.$to_perlre}
                                    ||= cc_to_regex($_, $to_perlre)
                                  : _tree_to_regex($_, $to_perlre)
                                }
                                @$_ # alternation
                            )
                        }
                        @{$$tree[1]}
                    )
                )
              , ($needs_parenthesis ? ')' : ())
              , ($$tree[0] ? '*' : ())
            );
        }
    }
}

# starification (regex)*
sub tree_starify {
    my ($tree) = @_;
    if (ref($tree) eq CHAR_CLASS) {
        return [1, [[$tree]]];
    }
    else {
        return [1, $$tree[1]];
    }
}

# The behavior of tree_concat2 can be altered
# by setting $TREE_CONCAT_FULL_EXPAND = 1;
sub tree_concat2 {
    my ($tree_0, $tree_1) = @_;
    my $concat;

    # main criteria:
    #     CHAR_CLASS
    #     @{$$tree_n[1]} == 0
    #     $$tree_n[0]
    #     @{$$tree_n[1]} == 1

    if (ref($tree_0) eq CHAR_CLASS) {
        if (@$tree_0 == 0) {
            if (
                ref($tree_1) ne CHAR_CLASS
             && @{$$tree_1[1]} == 0
            ) {
                # <empty> ()  ->  empty
                $concat = $cc_none;
            }
            else {
                # <empty> <any>  ->  <any>
                $concat = $tree_1;
            }
        }
        elsif (ref($tree_1) eq CHAR_CLASS) {
            if (@$tree_1 == 0) {
                # a <empty>  ->  a
                $concat = $tree_0;
            }
            else {
                # a b  ->  (ab)
                $concat = [0, [[ $tree_0, $tree_1 ]]];
            }
        }
        elsif (@{$$tree_1[1]} == 0) {
            # a ()  ->  a
            $concat = $tree_0;
        }
        elsif ($$tree_1[0]) {
            # a (b)*  ->  (a(b)*)
            $concat = [0, [[ $tree_0, $tree_1 ]]];
        }
        else {
            if (
                $FULL_FACTORIZE_FIXES
             || grep { ref($_) ne CHAR_CLASS && $$_[0] }
                map {@$_} @{$$tree_1[1]}
            ) {
                # a (bc|de) -> (a(bc|de))
                # one of bcde is starified
                $concat = [0, [[ $tree_0, $tree_1 ]]];
            }
            else {
                # a (bc|de) -> (abc|ade)
                # none of bcde is starified
                $concat = [
                    0
                  , [ map { [ $tree_0, @$_ ] } @{$$tree_1[1]} ]
                ];
            }
        }
    }
    elsif (@{$$tree_0[1]} == 0) {
        if (
            ref($tree_1) ne CHAR_CLASS
         && @{$$tree_1[1]} == 0
        ) {
            # () ()  ->  empty
            $concat = $cc_none;
        }
        else {
            # () <any>  ->  <any>
            $concat = $tree_1;
        }
    }
    elsif ($$tree_0[0]) {
        if (ref($tree_1) eq CHAR_CLASS) {
            if (@$tree_1 == 0) {
                # (a)* <empty>  -> (a)*
                $concat = $tree_0;
            }
            else {
                # (a)* b  -> ((a)*b)
                $concat = [0, [[ $tree_0, $tree_1 ]]];
            }
        }
        elsif (@{$$tree_1[1]} == 0) {
            # (a)* ()  ->  (a)*
            $concat = $tree_0;
        }
        elsif ($$tree_1[0]) {
            # (a)* (b)*  ->  ((a)*(b)*)
            $concat = [0, [[ $tree_0, $tree_1 ]]];
        }
        elsif (@{$$tree_1[1]} == 1) {
            # (a)* (bcd)  -> ((a)*bcd)
            $concat = [
                0
              , [[ $tree_0, @{$$tree_1[1][0]} ]]
            ];
        }
        else {
            # (a)* (b|c)  -> ((a)*(b|c))
            $concat = [0, [[ $tree_0, $tree_1 ]]];
        }
    }
    elsif (@{$$tree_0[1]} == 1) {
        if (ref($tree_1) eq CHAR_CLASS) {
            if (@$tree_1 == 0) {
                # (ab) <empty>  -> (ab)
                $concat = $tree_0;
            }
            else {
                # (ab) c  -> (abc)
                $concat = [
                    0
                  , [[ @{$$tree_0[1][0]}, $tree_1 ]]
                ];
            }
        }
        elsif (@{$$tree_1[1]} == 0) {
            # (ab) ()  ->  (ab)
            $concat = $tree_0;
        }
        elsif ($$tree_1[0]) {
            # (ab) (c)*  ->  (ab(c)*)
            $concat = [0, [[@{$$tree_0[1][0]}, $tree_1]]];
        }
        elsif (@{$$tree_1[1]} == 1) {
            # (ab) (cd)  -> (abcd)
            $concat = [
                0
              , [[ @{$$tree_0[1][0]}, @{$$tree_1[1][0]} ]]
            ];
        }
        elsif (
            !grep { ref($_) ne CHAR_CLASS } @{$$tree_0[1][0]}
        ) {
            if (
                $FULL_FACTORIZE_FIXES
             || grep { ref($_) ne CHAR_CLASS && $$_[0] }
                map {@$_} @{$$tree_1[1]}
            ) {
                # (ab) (cd|ef)  -> (ab(cd|ef))
                # neither a nor b is a tree
                # one of cdef is starified
                $concat = [0, [[@{$$tree_0[1][0]}, $tree_1]]];
            }
            else {
                # (ab) (cd|ef)  -> (abcd|abef)
                # neither a nor b is a tree
                # none of cdef is starified
                $concat = [
                    0
                  , [ map { [ @{$$tree_0[1][0]}, @$_ ] } @{$$tree_1[1]} ]
                ];
            }
        }
        else {
            # (ab) (cd|ef)  -> (ab(cd|ef))
            # a or b is a tree
            $concat = [0, [[@{$$tree_0[1][0]} , $tree_1 ]]];
        }
    }
    else {
        if (ref($tree_1) eq CHAR_CLASS) {
            if (@$tree_1 == 0) {
                # (ab|cd) <empty>  -> (ab|cd)
                $concat = $tree_0;
            }
            else {
                if (
                    $FULL_FACTORIZE_FIXES
                 || grep { ref($_) ne CHAR_CLASS && $$_[0] }
                    map {@$_} @{$$tree_0[1]}
                ) {
                    # (ab|cd) e  -> ((ab|cd)e)
                    # one of abcd is starified
                    $concat = [0, [[ $tree_0, $tree_1 ]]];
                }
                else {
                    # (ab|cd) e  -> (abe|cde)
                    # none of abcd is starified
                    $concat = [
                        0
                      , [ map { [@$_, $tree_1] } @{$$tree_0[1]} ]
                    ];
                }
            }
        }
        elsif (@{$$tree_1[1]} == 0) {
            # (ab|cd) ()  ->  (ab|cd)
            $concat = $tree_0;
        }
        elsif ($$tree_1[0]) {
            # (ab|cd) (e)*  ->  ((ab|cd)(e)*)
            $concat = [0, [[ $tree_0, $tree_1 ]]];
        }
        elsif (
            @{$$tree_1[1]} == 1
        ) {
            if (!grep { ref($_) ne CHAR_CLASS } @{$$tree_1[1][0]}) {
                if (
                    $FULL_FACTORIZE_FIXES
                 || grep { ref($_) ne CHAR_CLASS && $$_[0] }
                    map {@$_} @{$$tree_0[1]}
                ) {
                    # (ab|cd) (ef)  -> ((ab|cd)ef)
                    # e and f both CHAR_CLASS
                    # one of abcd is starified
                    $concat = [0, [[$tree_0, @{$$tree_1[1][0]}]]];
                }
                else {
                    # (ab|cd) (ef)  -> (acef|cdef)
                    # e and f both CHAR_CLASS
                    # none of abcd is starified
                    $concat = [
                        0
                      , [ map { [@$_, @{$$tree_1[1][0]}] } @{$$tree_0[1]} ]
                    ];
                }
            }
            else {
                # (ab|cd) (ef)  -> ((ab|cd)ef)
                # e or f is a tree
                $concat = [0, [[$tree_0, @{$$tree_1[1][0]}]]];
            }
        }
        elsif ($TREE_CONCAT_FULL_EXPAND) {
            # (ab|cd) (ef|gh)  -> (abef|abgh|cdef|cdgh)
            $concat = [
                0
              , [
                    map {
                       my $alt_0 = $_;
                       map { [@$alt_0, @$_] }
                       @{$$tree_1[1]}
                    }
                    @{$$tree_0[1]}
                ]
            ];
        }
        else {
            # (ab|cd) (ef|gh)  -> ((ab|cd)(ef|gh))
            $concat = [0, [[ $tree_0, $tree_1 ]]];
        }
    }
    return $concat;
}

# concatenation regex0regex1...
sub tree_concat {
    if (@_ == 0) {
        return $cc_none; # neutral element: accepting empty string
    }
    elsif (@_ == 1) {
        return $_[0];
    }
    elsif (grep {!defined($_)} @_) {
        return undef; # one accepting nothing -> concat accepting nothing
    }

    # resolve words first
    my @word;
    my @trees;
    for (@_) {
        if (ref($_) eq CHAR_CLASS) {
            push(@word, $_);
        }
        else {
            if (@word > 1) {
                push(@trees, [0, [[ @word ]] ] );
                @word = ();
            }
            elsif (@word) {
                push(@trees, $word[0]);
                @word = ();
            }
            push(@trees, $_);
        }
    }
    if (@word > 1) {
        push(@trees, [0, [[ @word ]] ] );
    }
    elsif (@word) {
        push(@trees, $word[0]);
    }

    my $concat = $trees[0];
    for my $tree (@trees[1..$#trees]) {
        $concat = tree_concat2($concat, $tree);
    }

    return $concat;
}

# alternation regex0|regex1|...
sub tree_alt {
    my @starified_alts;
    my @non_starified_alts;
    my $has_empty;

    for (grep { defined($_) } @_) {
        if (ref($_) eq CHAR_CLASS) {
            push(@non_starified_alts, [$_]);
        }
        elsif (!@{$$_[1]}) {
            $has_empty = 1;
        }
        elsif ($$_[0]) {
            push(@starified_alts, @{$$_[1]});
        }
        else {
            push(@non_starified_alts, @{$$_[1]});
        }
    }

    if (!@starified_alts) {
        if (
            @non_starified_alts > 1
         || $has_empty
         || @non_starified_alts && @{$non_starified_alts[0]} > 1
        ) {
            return [
                0
              , [
                    @non_starified_alts
                  , ($has_empty ? [[0, []]] : ())
                ]
            ];
        }
        elsif (!@non_starified_alts) {
            return undef; # neutral element: accepting nothing
        }
        else {
            return $non_starified_alts[0][0];
        }

    }
    elsif (!@non_starified_alts) {
        return [1, \@starified_alts];
    }
    else {
        return [
            0
          , [
                @non_starified_alts
              , [[1, \@starified_alts]]
            ]
        ];
    }
}


# returns an unanchored $ere having exactly the same structure
# as the given $tree. Intended for tracing/debugging.
sub tree_dump {
    my ($tree) = @_;
    if (!defined($_[0])) {
        # nothing accepted (not even the empty string)
        return '$.';
    }
    if (ref($tree) eq CHAR_CLASS) {
        return cc_to_regex($tree);
    }
    elsif (@{$$tree[1]} == 0) {
        return '()';
    }
    else {
        return join(''
          , '('
          , (
                join('|',
                    map {
                        my $alt = $_;
                        join('',
                            map {
                                my $atom = $_;
                                if (ref($atom) eq CHAR_CLASS) {
                                    cc_to_regex($atom);
                                }
                                else {
                                    tree_dump($atom);
                                }
                            }
                            @$alt
                        )
                    }
                    @{$$tree[1]}
                )
            )
          , ')'
          , ($$tree[0] ? '*' : ())
        );
    }
}

# Heuristic weight function for the processing order of the warshall algorithm
sub _tree_weight {
    my ($tree) = @_;
    my $weight = 0;
    if (ref($tree) eq CHAR_CLASS) {
        for (@$tree) {
            $weight += ($$_[0] == $$_[1] ? 1 : 2);
        }
    }
    elsif (defined($tree)) {
        for (map { @$_ } @{$$tree[1]}) {
            $weight += _tree_weight($_);
        }
    }
    return $weight;
}


##############################################################################
# $input_constraints
##############################################################################

use constant {
    FREE_TEXT => 'free text'
};

=back

=head2 Input constraints

  $input_constraints = [ $input_constraint_0, $input_constraint_1, ... ]
  $input_constraint  = [ 'word_0', 'word_1', ... ]  (drop down)
                    or 'free_text'                  (free text)


=over 4

=item C<tree_to_input_constraints($tree)>

Converts a C<$tree> to a pair C<($input_constraints, $split_str)>.

C<$split_perlre> is a compiled perl regular expression splitting a string
accordingly to C<$input_constraints>. This C<$perlre> matches if and only if
each drop down can be assigned a value; then C<$str =~ $perlre> in list
context returns as many values as C<@$input_constraints>.

=cut

sub tree_to_input_constraints {
    my ($input_constraints, $perlres) = &_tree_to_input_constraints;

    # concatenate free texts and stronger underlying regexs
    my @previous_undefs;
    my @kept;
    for my $i (0..$#$input_constraints) {
        if ($$input_constraints[$i] eq FREE_TEXT) {
            push(@previous_undefs, $i);
        }
        else {
            if (@previous_undefs) {
                push(@kept, $i-1);
                if (@previous_undefs > 1) {
                    $$perlres[$i-1] = join('',
                        map { '(?:' . $$perlres[$_] . ')' }
                        @previous_undefs
                    );
                }
                @previous_undefs = ();
            }
            push(@kept, $i);
        }
    }
    if (@previous_undefs) {
        push(@kept, $#$input_constraints);
        if (@previous_undefs > 1) {
            $$perlres[$#$input_constraints] = join('',
                map { '(?:' . $$perlres[$_] . ')' }
                @previous_undefs
            );
        }
    }
    @$input_constraints = @$input_constraints[@kept];
    @$perlres = @$perlres[@kept];

    # sort words, remove duplicates
    for (grep { $_ ne FREE_TEXT } @$input_constraints) {
        $_ = [ sort(keys(%{ { map { ($_ => $_) } @$_ } })) ];
    }

    # remove empty words
    # concatenate single words
    my @previous_singles;
    @kept = ();
    for my $i (0..$#$input_constraints) {
        if (
            $$input_constraints[$i] eq FREE_TEXT
         || @{$$input_constraints[$i]} > 1
        ) {
            if (@previous_singles) {
                push(@kept, $i-1);
                if (@previous_singles > 1) {
                    $$perlres[$i-1] = join('',
                        map { $$perlres[$_] }
                        @previous_singles
                    );
                    $$input_constraints[$i-1] = join('',
                        map { $$input_constraints[$_][0] }
                        @previous_singles
                    );
                }
                @previous_singles = ();
            }
            push(@kept, $i);
        }
        elsif (
            @{$$input_constraints[$i]} == 1
         && length($$input_constraints[$i][0])
        ) {
            push(@previous_singles, $i);
        }
    }
    if (@previous_singles) {
        push(@kept, $#$input_constraints);
        if (@previous_singles > 1) {
            $$perlres[$#$input_constraints] = join('',
                map { $$perlres[$_] }
                @previous_singles
            );
            $$input_constraints[$#$input_constraints] = join('',
                map { $$input_constraints[$_][0] }
                @previous_singles
            );
        }
    }
    @$input_constraints = @$input_constraints[@kept];
    @$perlres = @$perlres[@kept];

    if (!@$input_constraints) {
        @$input_constraints = (['']);
        @$perlres = ('');
    }

    my $split_perlre
      = join('',
            map {
                $$input_constraints[$_] eq FREE_TEXT
                  ? "($$perlres[$_]|.*?)"
                  : "($$perlres[$_])"
            }
            (0..$#$perlres)
        )
    ;
    return ($input_constraints, qr/\A$split_perlre\z/ms);
}

{

    my %cc_to_input_constraint_cache;

    # returns ($input_constraints, $perlres)
    # two references to arrays of the same size.
    sub _tree_to_input_constraints {
        my ($tree) = @_;
        my $input_constraints;
        my $perlres;
        if (!defined($tree)) {
            # regex accepting nothing -> free text (always rejected)

            $input_constraints = [FREE_TEXT];
            $perlres = ['$.'];
        }
        elsif (ref($tree) eq CHAR_CLASS) {
            # single character class -> drop down

            $input_constraints = [
                $cc_to_input_constraint_cache{$tree}
            ||= cc_to_input_constraint($tree)
            ];
            $perlres = [_tree_to_regex($tree, 1)];
        }
        elsif (@{$$tree[1]} == 0) {
            # no top-level alternation

            $input_constraints = [['']];
            $perlres = [_tree_to_regex($tree, 1)];
        }
        elsif ($$tree[0]) {
            # starified regex -> free text

            $input_constraints = [FREE_TEXT];
            $perlres = [_tree_to_regex($tree, 1)];
        }
        elsif (@{$$tree[1]} == 1) {
            # single top-level alternation -> mixed results
            # example: ab*c(d|e)f

            $input_constraints = [];
            $perlres = [];

            my $i = 0;
            while ($i != @{$$tree[1][0]}) {
                my $beg = $i;
                my @expanded_words = ('');
                my $cc;
                while (
                    $i != @{$$tree[1][0]}
                 && ref($cc = $$tree[1][0][$i]) eq CHAR_CLASS
                 && (!@$cc || $$cc[-1][1] != MAX_CHAR)
                ) {
                    my $input_constraint
                      = $cc_to_input_constraint_cache{$cc}
                    ||= cc_to_input_constraint($cc)
                    ;

                    @expanded_words
                      = map {
                            my $letter = $_;
                            map { $_ . $letter }
                            @expanded_words
                        }
                        @$input_constraint
                    ;
                    $i++;
                }
                if ($beg < $i && length($expanded_words[0])) {
                    my $wrd_perlre = _tree_to_regex(
                        [
                            0
                          , [[ @{$$tree[1][0]}[$beg..$i-1] ]]
                        ]
                      , 1
                    );
                    push(@$input_constraints, \@expanded_words);
                    push(@$perlres, $wrd_perlre);
                }
                if ($i < @{$$tree[1][0]}) {
                    my ($sub_input_constraints, $sub_perlres)
                      = _tree_to_input_constraints($$tree[1][0][$i]);
                    if (
                        @$sub_input_constraints
                     && (
                            $$sub_input_constraints[0] eq FREE_TEXT
                         || grep { length($_) } @{$$sub_input_constraints[0]}
                        )
                    ) {
                        push(@$input_constraints, @$sub_input_constraints);
                        push(@$perlres, @$sub_perlres);
                    }
                    $i++;
                }
            }
        }
        else {
            # multiple top-level alternations

            if (
                grep { grep {
                    ref($_) ne CHAR_CLASS
                 || (@$_ && $$_[$#$_][1] == MAX_CHAR)
                } @$_ }
                @{$$tree[1]}
            ) {
                # some alternation contains a sub-tree -> mixed results
                # example: abd|ab*d
                # common pre/suf-fixes are factorized out
                # example: a(bd|b*)d

                my $fst_len = @{$$tree[1][0]};
                my ($pre_len, $suf_len) = (0, 0);
                for (1, 0) {
                    my ($len_ref, @range)
                      = $_
                      ? (\$pre_len, (0..$fst_len-1))
                      : (\$suf_len, map {-$_} (1..$fst_len-$pre_len))
                    ;
                    for my $i (@range) {
                        if (
                            grep {
                                $i >= @$_
                             || ref($$_[$i]) ne CHAR_CLASS
                             || $$tree[1][0][$i] != $$_[$i]
                            }
                            @{$$tree[1]}[0..$#{$$tree[1]}]
                        ) {
                            last;
                        }
                        $$len_ref++;
                    }
                }
                if ($pre_len) {
                    my ($pre_input_constraints, $pre_perlres)
                  = _tree_to_input_constraints(
                        [
                            0
                          , [[ @{$$tree[1][0]}[0..$pre_len-1] ]]
                        ]
                    );
                    push(@$input_constraints, @$pre_input_constraints);
                    push(@$perlres, @$pre_perlres);
                }

                if (
                    my @mid_alts
                  = map { [ @$_[$pre_len..$#$_-$suf_len] ] }
                    @{$$tree[1]}
                ) {
                    push(@$input_constraints, FREE_TEXT);
                    push(@$perlres, _tree_to_regex([ 0, \@mid_alts ] , 1));
                }

                if ($suf_len) {
                    my ($suf_input_constraints, $suf_perlres)
                  = _tree_to_input_constraints(
                        [
                            0
                          , [[
                                @{$$tree[1][0]}
                                [$fst_len-$suf_len..$fst_len-1]
                            ]]
                        ]
                    );
                    push(@$input_constraints, @$suf_input_constraints);
                    push(@$perlres, @$suf_perlres);
                }
            }
            else {
                # each alternation contains only non negated char classes
                # -> drop down

                $perlres = [_tree_to_regex($tree, 1)];
                for my $word (@{$$tree[1]}) {
                    my @expanded_words = ('');
                    for my $input_constraint (
                        map {
                            $cc_to_input_constraint_cache{$_}
                        ||= cc_to_input_constraint($_);
                        }
                        @$word
                    ) {
                        if (@$input_constraint == 1) {
                            for (@expanded_words) {
                                $_ .= $$input_constraint[0];
                            }
                        }
                        else {
                            @expanded_words
                              = map {
                                    my $letter = $_;
                                    map { $_ . $letter }
                                    @expanded_words
                                }
                                @$input_constraint
                            ;
                        }
                    }
                    push(@{$$input_constraints[0]}, @expanded_words);
                }
            }
        }
        return ($input_constraints, $perlres);
    }
}

sub cc_to_input_constraint {
    my ($cc) = @_;
    if (@$cc == 0) {
        return [''];
    }
    elsif ($$cc[$#$cc][1] == MAX_CHAR) {
        return FREE_TEXT;
    }
    else {
        return [
            map { map { chr($_) } ($$_[0]..$$_[1]) }
            @$cc
        ];
    }
}


##############################################################################
# $ere
##############################################################################

=back

=head2 Ere

An C<$ere> is a perl string.

The syntax an C<$ere> is assumed to follow is based on POSIX ERE
(else the C<ere_to_xxx()> routines will C<die()>).

Unsupported POSIX features:
back-references,
equivalence classes C<[[=a=]]>,
character class C<[[:digit:]]>,
collating symbols C<[[.ch.]]>.

C<)> is always a special character. POSIX says that C<)> is a normal
character if there is no matching C<(>.

There is no escape sequences such as C<\t> for tab or C<\n> for line feed.
POSIX does not specify such escape sequences neither.

C<\> before a non-special character is ignored
(except in bracket expressions). POSIX does not allow it.

The empty string is legal in alternations (C<(|a)> is equivalent to C<(a?)>).
POSIX does not allow it.
The C<(|a)> form is generated by the C<xxx_to_ere()> routines
(avoiding quantifiers other than C<*>).

C<[a-l-z]> is interpreted as C<([a-l] | - | z)> (but it is discouraged to
rely upon this implementation artefact). POSIX says that the interpretation
of this construct is undefined.

In bracket expressions, C<\> is a normal character,
thus C<]> as character must occur first, or second after a C<^>
(POSIX compliant, but possibly surprising for perl programmers).

All unicode characters supported by perl are allowed as literal characters.

=over 4

=item C<ere_to_nfa($ere)>

Parses an C<$ere> to a C<$nfa>.

WARNING: the parsing routines, in particular C<ere_to_xxx()>,
C<die()> on syntax errors; thus the caller may want to eval-trap such errors.

=cut

sub ere_to_nfa {
    my ($ere, $has_anchor_ref) = @_;

    # optimize very first and very last anchors
    my $has_beg_anchor = $ere =~ s/^\^+//;
    my $has_end_anchor = $ere =~ s/\$+$//;

    $$has_anchor_ref = 0;
    my @alternation_nfas;
    do {
        push(@alternation_nfas, parse_alternation(\$ere, $has_anchor_ref));
    } while($ere =~ /\G \| /xmsgc);

    if ((pos($ere) || 0) != length($ere)) {
        parse_die("unexpected character", \$ere);
    }

    my $nfa;
    if (!$has_beg_anchor && !$has_end_anchor) {
        # a|b|c => ^.*(a|b|c).*$

        $nfa = nfa_concat(
            [[1, [[$cc_any, 0]]]]
          , @alternation_nfas == 1
              ? $alternation_nfas[0]
              : nfa_union(@alternation_nfas)
          , [[1, [[$cc_any, 0]]]]
        );
    }
    else {
        for my $alternation_nfa (@alternation_nfas[1..$#alternation_nfas-1]) {
            $alternation_nfa = nfa_concat(
                [[1, [[$cc_any, 0]]]]
              , $alternation_nfa
              , [[1, [[$cc_any, 0]]]]
            );
        }
        if (!$has_beg_anchor || @alternation_nfas > 1) {
            $alternation_nfas[0] = nfa_concat(
                !$has_beg_anchor ? [[1, [[$cc_any, 0]]]] : ()
              , $alternation_nfas[0]
              , @alternation_nfas > 1 ? [[1, [[$cc_any, 0]]]] : ()
            );
        }
        if (!$has_end_anchor || @alternation_nfas > 1) {
            $alternation_nfas[-1] = nfa_concat(
                @alternation_nfas > 1 ? [[1, [[$cc_any, 0]]]] : ()
              , $alternation_nfas[-1]
              , !$has_end_anchor ? [[1, [[$cc_any, 0]]]] : ()
            );
        }
        $nfa
          = @alternation_nfas == 1
          ? $alternation_nfas[0]
          : nfa_union(@alternation_nfas)
        ;
    }

    return $$has_anchor_ref ? nfa_resolve_anchors($nfa) : $nfa;
}

sub _ere_to_nfa {
    my ($str_ref, $has_anchor_ref) = @_;

    my @alternation_nfas;
    do {
        push(@alternation_nfas, parse_alternation($str_ref, $has_anchor_ref));
    } while($$str_ref =~ /\G \| /xmsgc);

    return
        @alternation_nfas == 1
      ? $alternation_nfas[0]
      : nfa_union(@alternation_nfas)
    ;
}

sub bracket_expression_to_cc {
    my ($str_ref) = @_;
    my $neg = $$str_ref =~ /\G \^/xmsgc;
    my $interval_list = [];

    # anything is allowed a first char, in particular ']' and '-'
    if ($$str_ref =~ /\G (.) - ([^]]) /xmsgc) {
        push(@$interval_list, [ord($1), ord($2)]);
    }
    elsif ($$str_ref =~ /\G (.) /xmsgc) {
        push(@$interval_list, [ord($1), ord($1)]);
    }

    my $loop = 1;
    while ($loop) {
        if ($$str_ref =~ /\G ([^]]) - ([^]]) /xmsgc) {
            push(@$interval_list, [ord($1), ord($2)]);
        }
        elsif ($$str_ref =~ /\G ([^]]) /xmsgc) {
            push(@$interval_list, [ord($1), ord($1)]);
        }
        else {
            $loop = 0;
        }
    }

    return
        $neg
      ? cc_neg(interval_list_to_cc($interval_list))
      : interval_list_to_cc($interval_list)
    ;
}

# Returns:
#   - the empty list iff no quantification has been parsed
#   - a 2-tuple ($min, $max)
#         either $max is the empty string
#         or $min <= $max
sub parse_quant {
    my ($str_ref) = @_;
    if ($$str_ref =~ /\G \* /xmsgc) {
        return (0, '');
    }
    elsif ($$str_ref =~ /\G \+ /xmsgc) {
        return (1, '');
    }
    elsif ($$str_ref =~ /\G \? /xmsgc) {
        return (0, 1);
    }
    elsif ($$str_ref =~ /\G \{ /xmsgc) {
        my ($min, $max);
        if ($$str_ref =~ /\G ( [0-9]+ ) /xmsgc) {
            $min = $1;
            if ($$str_ref =~ /\G , ([0-9]*) /xmsgc) {
                $max = $1; # may be ''
                if (length($max) && $min > $max) {
                    parse_die("$min > $max", $str_ref);
                }
            }
            else {
                $max = $min;
            }
        }
        else {
            parse_die('number expected', $str_ref);
        }

        if ($$str_ref !~ /\G \} /xmsgc) {
            parse_die('} expected', $str_ref);
        }
        return ($min, $max);
    }
    else {
        return;
    }
}

=item quote($string)

Returns $string with escaped special characters.

=cut

sub quote {
    my ($str) = @_;
    $str =~ s/([.\[\\(*+?{|^\$])/\\$1/xsmg;
    return $str;
}

{
    my %char_to_cc_cache;
    sub parse_alternation {
        my ($str_ref, $has_anchor_ref) = @_;
        my @all_nfas;
        my $loop;
        my @quants;
        do {
            $loop = 0;
            my $nfa = [];
            my $next_state_index = 1;
            while (1) {
                if ($$str_ref =~ /\G ( $ERE_literal + ) /xmsogc) {
                    push(@$nfa,
                        map {
                            [ 0, [[
                                $char_to_cc_cache{$_} ||= char_to_cc($_)
                              , $next_state_index++
                            ]]]
                        }
                        split('', $1)
                    );
                }
                elsif ($$str_ref =~ /\G ( \. + ) /xmsgc) {
                    push(@$nfa,
                        map {
                            [ 0, [[
                                $cc_any
                              , $next_state_index++
                            ]]]
                        }
                        (1..length($1))
                    );
                }
                elsif ($$str_ref =~ /\G ( \[ ) /xmsgc) {
                    push(@$nfa,
                        [ 0, [[
                            bracket_expression_to_cc($str_ref)
                          , $next_state_index++
                        ]]]
                    );
                    if ($$str_ref !~ /\G ] /xmsgc) {
                        parse_die('] expected', $str_ref);
                    }
                }
                elsif ($$str_ref =~ /\G \\ (.) /xmsgc) {
                    push(@$nfa,
                        [ 0, [[
                            $char_to_cc_cache{$1} ||= char_to_cc($1)
                          , $next_state_index++
                        ]]]
                    );
                }
                elsif ($$str_ref =~ /\G \^ /xmsgc) {
                    push(@$nfa,
                        [ 0, [[
                            $cc_beg
                          , $next_state_index++
                        ]]]
                    );
                    $$has_anchor_ref ||= 1;
                }
                elsif ($$str_ref =~ /\G \$ /xmsgc) {
                    push(@$nfa,
                        [ 0, [[
                            $cc_end
                          , $next_state_index++
                        ]]]
                    );
                    $$has_anchor_ref ||= 1;
                }
                else {
                    last;
                }
            }

            if (@$nfa) {
                if ($$str_ref =~ /\G (?= [*+?{] ) /xmsgc) {
                    my $last_char_class = $$nfa[$#$nfa][1][0][0];
                    if (@$nfa > 1) {
                        @{$$nfa[$#$nfa]} = (1, []);
                        push(@all_nfas, $nfa);
                    }
                    push(@quants, [scalar(@all_nfas), parse_quant($str_ref)]);
                    push(@all_nfas, [[0, [[$last_char_class, 1 ]]], [1, []]]);
                    $loop = 1;
                }
                else {
                    push(@$nfa, [1, []]);
                    push(@all_nfas, $nfa);
                }
            }

            if ($$str_ref =~ /\G \( /xmsgc) {
                $nfa = _ere_to_nfa($str_ref, $has_anchor_ref);
                if ($$str_ref !~ /\G \) /xmsgc) {
                    parse_die(') expected', $str_ref);
                }
                if ($$str_ref =~ /\G (?= [*+?{] ) /xmsgc) {
                    push(@quants, [scalar(@all_nfas), parse_quant($str_ref)]);
                }
                push(@all_nfas, $nfa);
                $loop = 1;
            }
        } while ($loop);

        for (@quants) {
            my ($i, $min, $max) = @$_;
            $all_nfas[$i] = nfa_quant(
                $all_nfas[$i]
              , $min, $max
              , $min && $i != 0          && _nfa_has_suffix($all_nfas[$i-1])
              , $min && $i != $#all_nfas && _nfa_has_prefix($all_nfas[$i+1])
            );
        }

        if (@all_nfas > 1) {
            return nfa_concat(@all_nfas);
        }
        elsif (@all_nfas) {
            return $all_nfas[0];
        }
        else {
            return [[1, []]];
        }
    }
}

sub _nfa_has_prefix {
    my ($nfa) = @_;
    # initial state non-accepting or no loop back to it
    !$$nfa[0][0] || !grep { $$_[1] == 0 } map { @{$$_[1]} } @$nfa;
}

sub _nfa_has_suffix {
    my ($nfa) = @_;
    # all accepting states are final
    !grep { $$_[0] && @{$$_[1]} } @$nfa
}

sub parse_die {
    my ($msg, $str_ref) = @_;
    die("malformed regex: $msg at "
      . (pos($$str_ref) || 0) . " in $$str_ref");
}


##############################################################################
# Shorthands
##############################################################################

=back

=head2 Shorthands

=over 4

=item C<ere_to_tree($ere)>
 := C<nfa_to_tree(ere_to_nfa($ere))>

=cut

sub ere_to_tree {
    my ($ere) = @_;
    return nfa_to_tree(ere_to_nfa($ere));
}

=item C<ere_to_regex($ere, $to_perlre)>
 := C<tree_to_regex(ere_to_tree($ere), $to_perlre)>

=cut

sub ere_to_regex {
    my ($ere, $to_perlre) = (@_, 0);
    return tree_to_regex(ere_to_tree($ere), $to_perlre);
}

=item C<nfa_to_regex($nfa, $to_perlre)>
 := C<tree_to_regex(nfa_to_tree($nfa), $to_perlre)>

=cut

sub nfa_to_regex {
    my ($nfa, $to_perlre) = (@_, 0);
    return tree_to_regex(nfa_to_tree($nfa), $to_perlre);
}

=item C<ere_to_input_constraints($ere)>
 := C<tree_to_input_constraints(ere_to_tree($ere))>

=cut

sub ere_to_input_constraints {
    my ($ere) = @_;
    return tree_to_input_constraints(ere_to_tree($ere));
}

=item C<nfa_to_input_constraints($nfa)>
 := C<tree_to_input_constraints(nfa_to_tree($nfa))>

=cut

sub nfa_to_input_constraints {
    my ($nfa) = @_;
    return tree_to_input_constraints(nfa_to_tree($nfa));
}

=item C<nfa_to_min_dfa($nfa)>
 := C<dfa_to_min_dfa(nfa_to_dfa($nfa))>

=cut

sub nfa_to_min_dfa {
    my ($nfa) = @_;
    return dfa_to_min_dfa(nfa_to_dfa($nfa));
}

1;

=back

=head1 AUTHOR

Loïc Jonas Etienne <loic.etienne@tech.swisssign.com>

=head1 COPYRIGHT and LICENSE

Artistic License 2.0
http://www.perlfoundation.org/artistic_license_2_0
