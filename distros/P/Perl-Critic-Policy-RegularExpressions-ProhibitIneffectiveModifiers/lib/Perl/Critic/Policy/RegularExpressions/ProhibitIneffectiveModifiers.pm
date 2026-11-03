package Perl::Critic::Policy::RegularExpressions::ProhibitIneffectiveModifiers 0.001;

# ABSTRACT: Write a regex modifier only where it changes what the regex does.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{ any };
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $EXPL => q{Remove the modifier, which changes nothing here};

Readonly::Hash my %DESC => (
    g => q{Modifier /g on a regex that can match only once},
    i => q{Modifier /i on a regex with nothing that has a case},
    m => q{Modifier /m on a regex with no ^ or $},
    o => q{Modifier /o on a regex with nothing to interpolate},
);

Readonly::Scalar my $NEWLINE => 10;

# Larger ranges are taken to hold a character with a case, rather than read.
Readonly::Scalar my $RANGE_LIMIT => 1024;

Readonly::Hash my %START => map { $_ => 1 } ( '\A', '^' );

# Single-character classes that never match a newline, and so cannot be all of
# a second match before the final one.
Readonly::Hash my %NOT_A_NEWLINE => map { $_ => 1 } ( '\w', '\d', '\S', '\N', '\V', '\h' );

# The tokens that are the same with and without /i.
Readonly::Array my @CASELESS_TOKENS => map { "PPIx::Regexp::Token::$_" } qw{
  Assertion Quantifier Greediness Whitespace Comment Operator GroupType Structure Delimiter Modifier
};


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_LOW }
sub default_themes       { return qw{ maintenance } }
sub applies_to           { return qw{ PPI::Token::Regexp::Match PPI::Token::Regexp::Substitute PPI::Token::QuoteLike::Regexp } }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my %written = $elem->get_modifiers;
    return unless any { $written{$_} } keys %DESC;

    # From the document rather than PPIx::Regexp->new, so that a use re in
    # scope counts toward what ^, $ and . mean.
    my $regexp = $doc->ppix_regexp_from_element($elem) or return;
    my $re     = $regexp->regular_expression           or return;

    my $interpolates = $re->find_first('PPIx::Regexp::Token::Interpolation');
    my %ineffective  = (
        g => !!( !$interpolates && !$written{c} && _matches_once($re) ),
        i => !!( !$interpolates && _is_caseless($re) ),
        m => !!( !$interpolates && !_has_line_anchor($re) ),
        o => !$interpolates,
    );

    return map { $self->violation( $DESC{$_}, $EXPL, $elem ) } grep { $written{$_} && $ineffective{$_} } sort keys %DESC;
}

# Whether the pattern can match at most once: anchored at the start, or at an
# end that only one match can reach.
sub _matches_once {
    my ($re) = @_;

    my @parts = _significant( $re->children );
    return   if _alternates(@parts);
    return 1 if _is_start( $parts[0] );

    my $end = pop @parts;
    return unless $end && $end->isa('PPIx::Regexp::Token::Assertion');
    return _consumes( \@parts, \&_is_a_character ) if $end->content eq '\z';
    my $before_a_final_newline = $end->content eq '\Z' || ( $end->content eq '$' && !$end->modifier_asserted('m') );
    return unless $before_a_final_newline;
    return _consumes( \@parts, \&_is_not_a_newline );
}

# Whether $part anchors the start of the string.  Under /m, ^ anchors any line.
sub _is_start {
    my ($part) = @_;

    return unless $part && $part->isa('PPIx::Regexp::Token::Assertion') && $START{ $part->content };
    return $part->content eq '\A' || !$part->modifier_asserted('m');
}

# Whether some part of @$parts has to match at least once, and matches a
# character for which $matches is true.  A group counts if its own parts do.
sub _consumes {
    my ( $parts, $matches ) = @_;

    my @parts = @$parts;
    foreach my $at ( 0 .. $#parts ) {
        next if _may_repeat_zero( $parts[ $at + 1 ] );
        my $part = $parts[$at];
        if ( $part->isa('PPIx::Regexp::Structure::Capture') || $part->isa('PPIx::Regexp::Structure::Modifier') ) {
            my @inner = _significant( $part->children );
            return 1 if !_alternates(@inner) && _consumes( \@inner, $matches );
            next;
        }
        return 1 if $matches->($part);
    }
    return;
}

# Whether $next is a quantifier that lets the part before it match no times.
sub _may_repeat_zero {
    my ($next) = @_;

    return unless $next;
    return $next->content ne '+' if $next->isa('PPIx::Regexp::Token::Quantifier');
    return unless $next->isa('PPIx::Regexp::Structure::Quantifier');

    my ($least) = $next->content =~ m/\A[{]\s*(\d*)/sx;
    return !$least;
}

# Whether $part matches one character, whatever it is.
sub _is_a_character {
    my ($part) = @_;

    return any { $part->isa("PPIx::Regexp::$_") } qw{ Token::Literal Token::CharClass::Simple Structure::CharClass };
}

# Whether $part matches one character, and never a newline.
sub _is_not_a_newline {
    my ($part) = @_;

    return ( $part->ordinal // $NEWLINE ) != $NEWLINE if $part->isa('PPIx::Regexp::Token::Literal');
    return unless $part->isa('PPIx::Regexp::Token::CharClass::Simple');
    return 1 if $NOT_A_NEWLINE{ $part->content };
    return $part->content eq '.' && !$part->modifier_asserted('s');
}

# Whether nothing in the pattern is changed by /i.  Anything the policy does
# not know to be caseless is taken to have a case.
sub _is_caseless {
    my ($re) = @_;

    foreach my $range ( @{ $re->find('PPIx::Regexp::Node::Range') || [] } ) {
        my ( $from, $to ) = map { $_->ordinal } grep { $_->isa('PPIx::Regexp::Token::Literal') } $range->children;
        return if !defined $from || !defined $to || $to - $from >= $RANGE_LIMIT;
        return unless _all_caseless( $from .. $to );
    }

    foreach my $token ( $re->tokens ) {
        next if any { $token->isa($_) } @CASELESS_TOKENS;
        next if $token->isa('PPIx::Regexp::Token::Control')           && $token->content =~ m/\A\\[QE]\z/sx;
        next if $token->isa('PPIx::Regexp::Token::CharClass::Simple') && $token->content !~ m/\A\\[pP]/sx;
        return unless $token->isa('PPIx::Regexp::Token::Literal');
        my $ordinal = $token->ordinal;
        return unless defined $ordinal && _all_caseless($ordinal);
    }
    return 1;
}

# Whether each of the characters @ordinals is its own upper and lower case.
sub _all_caseless {
    my (@ordinals) = @_;

    foreach my $character ( map { chr } @ordinals ) {
        return if lc $character ne $character || uc $character ne $character;
    }
    return 1;
}

# Whether ^ or $ is anywhere in the pattern, which is all that /m changes.
sub _has_line_anchor {
    my ($re) = @_;

    return any { $_->content eq '^' || $_->content eq '$' } @{ $re->find('PPIx::Regexp::Token::Assertion') || [] };
}

# Whether @parts holds an alternation at its own level.
sub _alternates {
    my (@parts) = @_;

    return any { $_->isa('PPIx::Regexp::Token::Operator') && $_->content eq '|' } @parts;
}

# The parts of a pattern that match something: whitespace and comments under
# /x do not.
sub _significant {
    my (@parts) = @_;

    return grep { !$_->isa('PPIx::Regexp::Token::Whitespace') && !$_->isa('PPIx::Regexp::Token::Comment') } @parts;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitIneffectiveModifiers - Write a regex modifier only where it changes what the regex does.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::RegularExpressions::ProhibitIneffectiveModifiers

A reader takes each modifier on a regex as a statement about what it does.
C</g> says it can match more than once, C</i> that case matters to it, C</m>
that it anchors lines, and C</o> that it interpolates something that is
compiled once.  Where the pattern cannot do that, the modifier is a statement
that is not true, and the reader has to work out that it is not:

    $name =~ s/^\s+//g;                   # reported: ^ matches once
    $name =~ s/^\s+//;

    next unless $line =~ m/\A\d+\z/i;     # reported: digits have no case
    next unless $line =~ m/\A\d+\z/;

=head2 PROHIBITED

    s/^\s+//g             # /g, anchored at the start: it matches once
    s/\A\s+//g            # \A as well as ^
    m/\A(\w+)/g           # in a match as well
    s/\s+\z//g            # anchored at the end, and it cannot match empty
    s/x$//g               # $ without /m, and it cannot match a newline alone
    s/,\Z//g              # \Z is the same as $ without /m
    s/\A\s+//gm           # /m does not change \A, and has no ^ or $ to change
    m/\d+/i               # /i, and nothing has a case
    m/[!-@]/i             # nor does a range without a letter in it
    qr/\d/i               # a compiled regex keeps its own modifiers
    m/foo/m               # /m, and no ^ or $
    m/\Afoo\z/m           # \A, \z and \Z are not line anchors
    m/foo/o               # /o, and nothing to interpolate
    s/foo/$bar/o          # /o compiles the pattern, not the replacement

=head2 ALLOWED

    s/^\s+//gm            # ^ under /m is the start of every line
    m/^key: .*$/mg        # several lines of one form
    s/\s+$//g             # \s can match the final newline alone, see CAVEATS
    s/b*\z//g             # can match empty, so twice at the end
    s/$/!/g               # "a\n" has two places for $ without /m
    s/.$//sg              # . under /s can match the final newline alone
    m/\A\s*/gc            # /c keeps pos() for the next match
    m/\Ga/g               # \G is where the last match stopped
    s/\Aa|b//g            # alternation: b is not anchored
    s/\A$prefix//g        # interpolation may bring an alternation
    m/[!-~]/i             # a range with letters in it
    m/\x{df}/i            # sharp s matches SS under /i
    m/\p{Lu}/i            # a property matches the other case under /i
    m/(\d)\1/i            # a backreference compares without case
    m/$word/i             # interpolation may bring letters
    m/a(?=$)/m            # a line anchor anywhere counts
    m/$record/m           # interpolation may bring ^ and $
    m/$r/g                # where $r = qr/^key: .*$/m keeps its own /m
    m/$x/o                # /o with something to compile once
    m/a/s                 # /s, /x and /a are never reported, see CAVEATS

=head2 CAVEATS

C</s>, C</x>, C</xx>, C</a> and C</aa> are never reported.  The policies
C<RegularExpressions::RequireDotMatchAnything>,
C<RegularExpressions::RequireExtendedFormatting> and
C<RegularExpressions::RequireDefault> ask for them on every regex, so they are
written where they change nothing.
C<RegularExpressions::RequireLineBoundaryMatching> asks for C</m> in the same
way; with that policy on, turn this one off, or the two disagree
about every regex without C<^> or C<$>.

Only a modifier written on the regex is reported.  A modifier from C<use re>
in scope is a default for the file, not a choice made for this regex, so it is
not reported.  It still counts toward what the pattern means, so under
C<use re '/m'>, C<s/^\s+//g> is not reported.

C</g> at the end of the string is reported only where the policy can tell that
the pattern cannot match twice.  Before C<\z> that means it cannot match the
empty string, so something in it has to match at least one character.  Before
C<$>, or C<\Z>, without C</m>, there are two places to end, at the final newline
and after it, so something in it has to match a character that is not a
newline.  The policy does not reason about greediness, so C<s/\s+$//g>, which
matches once, is not reported.

C<m//g> in scalar context sets C<pos()> where it stops, and the next C<\G>
starts there.  When a match anchored at the start is there for that, write
C</gc>, which says so, or say C<## no critic (ProhibitIneffectiveModifiers)>.

A regex that interpolates a variable is not checked for C</g>, C</i> or C</m>.
The variable can bring an alternation, a letter or a line anchor, and the
policy cannot see what it holds.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitineffectivemodifiers/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 CONTRIBUTOR

=for stopwords troglodyne-bot

troglodyne-bot <morpheus@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
