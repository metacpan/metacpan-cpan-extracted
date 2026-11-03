package Perl::Critic::Policy::RegularExpressions::ProhibitRegexToSplitAtDelimiter 0.001;

# ABSTRACT: Find the first literal separator with index and substr, not a regex.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{ any };
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Regex used to find the first literal separator};

# The replacement for each form, by whether it substitutes in place or in a
# copy, and then whether it captures.
Readonly::Hash my %EXPL => (
    match => {
        capture => q{Find the separator with index(), then take the text before it with substr()},
        none    => q{Ask whether the separator is there with index() >= 0},
    },
    substitute => {
        capture => q{Find the separator with index(), then take the text and the separator off with four-argument substr() and an empty replacement},
        none    => q{Find the separator with index(), then take everything up to and including it off with four-argument substr() and an empty replacement},
    },
    copy => {
        capture => q{Find the separator with index(), then take the text before it and the text after it with substr()},
        none    => q{Find the separator with index(), then take the text after it with substr()},
    },
);

Readonly::Scalar my $NEWLINE => 10;

# Modifiers that change what the pattern does in a way index cannot follow:
# /i compares without case, /g iterates.  /m is handled at the anchor, since
# it matters only to ^, and /s at the dot.
Readonly::Array my @EXEMPTING_MODIFIERS => qw{ i g };

# The quantifiers that still mean "all of it, up to the separator".
Readonly::Hash my %QUANTIFIER => map { $_ => 1 } qw{ * + };

# The controls that quote what is between them, which a separator may sit in.
Readonly::Hash my %QUOTING => map { $_ => 1 } ( '\Q', '\E' );


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw{ performance maintenance } }
sub applies_to           { return qw{ PPI::Token::Regexp::Match PPI::Token::Regexp::Substitute } }


sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $substitute = $elem->isa('PPI::Token::Regexp::Substitute');
    return if $substitute && $elem->get_substitute_string ne q{};

    # From the document rather than PPIx::Regexp->new, so that the modifiers of
    # a use re in scope are asserted as well as the ones written on the regex.
    my $regexp = $doc->ppix_regexp_from_element($elem) or return;
    return if any { $regexp->modifier_asserted($_) } @EXEMPTING_MODIFIERS;

    my $captures = $regexp->max_capture_number // 0;

    my $re    = $regexp->regular_expression or return;
    my @parts = _significant( $re->children );
    return unless _is_start( shift @parts );
    return unless $captures ? _captures_before_a_separator( \@parts ) : _runs_to_a_separator( \@parts );

    my $form = !$substitute ? 'match' : $regexp->modifier_asserted('r') ? 'copy' : 'substitute';
    my $expl = $EXPL{$form}{ $captures ? 'capture' : 'none' };
    return $self->violation( $DESC, $expl, $elem );
}

# Whether @$parts, after the anchor, is one capture of everything before the
# separator, and the separator, with nothing after it.
sub _captures_before_a_separator {
    my ($parts) = @_;

    my ( $capture, @separator ) = @$parts;
    return unless $capture && $capture->isa('PPIx::Regexp::Structure::Capture');

    my @ordinals = _literal_ordinals(@separator) or return;
    return _is_everything_before( [ _significant( $capture->children ) ], \@ordinals );
}

# Whether @$parts, after the anchor, is the same run of everything before the
# separator with no capture around it, and the separator.
sub _runs_to_a_separator {
    my ($parts) = @_;

    my ( $atom, $quantifier, @separator ) = @$parts;
    my @run = ( $atom, $quantifier );
    push @run, shift @separator if @separator && $separator[0]->isa('PPIx::Regexp::Token::Greediness');

    my @ordinals = _literal_ordinals(@separator) or return;
    return _is_everything_before( \@run, \@ordinals );
}

# Whether $part anchors the start of the string.  Under /m, ^ anchors any line.
sub _is_start {
    my ($part) = @_;

    return unless $part && $part->isa('PPIx::Regexp::Token::Assertion');
    my $anchor = $part->content;
    return 1 if $anchor eq '\A';
    return $anchor eq '^' && !$part->modifier_asserted('m');
}

# The characters @parts match, in order, if each part is one literal character
# or a class of one, between an optional \Q and \E; otherwise nothing.
sub _literal_ordinals {
    my (@separator) = @_;

    my @parts = grep { !( $_->isa('PPIx::Regexp::Token::Control') && $QUOTING{ $_->content } ) } @separator;

    my @ordinals = map { _ordinal($_) } @parts;
    return unless @ordinals && @ordinals == @parts;
    return @ordinals;
}

# The character $part matches, if it matches one character and only that one.
sub _ordinal {
    my ($part) = @_;

    if ( $part->isa('PPIx::Regexp::Structure::CharClass') ) {
        return if $part->negated;
        $part = _sole_member($part) or return;
    }
    return unless $part->isa('PPIx::Regexp::Token::Literal');
    return $part->ordinal // ();
}

# The one member of the character class $class, if it has exactly one.
sub _sole_member {
    my ($class) = @_;

    my @members = $class->children;
    return unless @members == 1;
    return $members[0];
}

# Whether @$body, the inside of the capture, takes everything up to the first
# occurrence of the separator in @$ordinals.  Either it is a run of anything but
# the separator's one character, with any greediness, or it is a lazy run of
# anything at all, which stops at the first occurrence of any separator.
sub _is_everything_before {
    my ( $body, $ordinals ) = @_;

    my ( $atom, $quantifier, $greediness, @rest ) = @$body;
    return if @rest;
    return unless $atom && $quantifier && $quantifier->isa('PPIx::Regexp::Token::Quantifier') && $QUANTIFIER{ $quantifier->content };
    return if $greediness && !$greediness->isa('PPIx::Regexp::Token::Greediness');

    my $excluded = _excluded_ordinal($atom);
    return @$ordinals == 1 && $ordinals->[0] == $excluded if defined $excluded;

    my $lazy = $greediness && $greediness->content eq '?';
    return $lazy && _is_anything($atom);
}

# The one character $atom refuses, if it matches every character but one: a
# negated class of one, \N, or a dot without /s.
sub _excluded_ordinal {
    my ($atom) = @_;

    if ( $atom->isa('PPIx::Regexp::Structure::CharClass') ) {
        return unless $atom->negated;
        my $member = _sole_member($atom) or return;
        return unless $member->isa('PPIx::Regexp::Token::Literal');
        return $member->ordinal;
    }
    return unless $atom->isa('PPIx::Regexp::Token::CharClass::Simple');
    return $NEWLINE if $atom->content eq '\N';
    return $NEWLINE if $atom->content eq '.' && !$atom->modifier_asserted('s');
    return;
}

# Whether $atom matches every character: a dot under /s.
sub _is_anything {
    my ($atom) = @_;

    return $atom->isa('PPIx::Regexp::Token::CharClass::Simple') && $atom->content eq '.' && $atom->modifier_asserted('s');
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

Perl::Critic::Policy::RegularExpressions::ProhibitRegexToSplitAtDelimiter - Find the first literal separator with index and substr, not a regex.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::RegularExpressions::ProhibitRegexToSplitAtDelimiter

Using regexes to do simple text manipulation in a loop is a common cause of
performance problems.  This can be prevented from happening by refraining
from doing so everywhere.  One pattern in that class is splitting at a delimiter without using C<split>.
This policy prevents doing just that with regexes.

Do C<index> + C<substr> to pick out what you are looking for, or C<split> when you
expect many matches, and can afford loading the entire string.

    # Reading buffer chunks till we get a full line to process w/ take()
    while ( $buffer =~ s/\A([^\n]*)\n// ) { take($1) }            # reported

    while ( ( my $at = index $buffer, "\n" ) >= 0 ) {             # OK!
        take( substr $buffer, 0, $at );
        substr $buffer, 0, $at + 1, q{};
    }

    # Parsing a key from a key=value config file
    my ($key) = $line =~ m/\A(.*?)=/s;                             # reported

    my $at  = index $line, '=';                                    # OK!
    my $key = $at >= 0 ? substr( $line, 0, $at ) : undef;

    my ($key,$value) = split(/=/, $line, 2);                       # OK!

The substitution takes the part before the separator off the string, together
with the separator.  Four-argument C<substr> with an empty replacement does
that.

Without a capture, the substitution only takes that much off, and the match
only asks whether the separator is there at all:

    $buffer =~ s/\A[^\n]*\n//;                                    # reported

    my $at = index $buffer, "\n";
    substr $buffer, 0, $at + 1, q{} if $at >= 0;

    next unless $line =~ m/\A[^=]*=/;                              # reported

    next unless index( $line, '=' ) >= 0;

Under C</r> the substitution leaves the string alone and returns what follows
the separator, which is C<< substr( $buffer, $at + 1 ) >>.

=head2 PROHIBITED

    s/\A([^\n]*)\n//          # the negated class of the separator
    m/\A([^=]+)=/             # one or more, see CAVEATS
    m/^([^:]*):/              # ^ without /m is the start of the string
    m/\A([^:]*):/m            # /m changes ^ and $, not \A
    m/\A(.*?)--/s             # a lazy dot under /s, before a string
    m/\A(.+?), /s             # one or more, see CAVEATS
    m/\A(.*?)\n/              # without /s, . is anything but a newline
    m/\A(.*)\n/               # so before a newline it can be greedy too
    m/\A(\N*)\n/              # and so can \N
    s/\A([^\n]*)\n//r         # /r: a copy
    m/\A(?<key>[^:]*):/       # a named capture
    s/\A([^\n]*)\x0a//        # any spelling of the character
    s/\A([^\n]*)[\n]//        # a class of one character is that character
    m/\A([^.]*)\./            # an escaped metacharacter is a character
    m/\A(.*?)\Q-.\E/s         # and so is anything between \Q and \E
    m/\A ( [^:]* ) : /x       # whitespace under /x is not text
    s/\A[^\n]*\n//            # no capture: the first line off
    s/\A.*?--//s              # and every other form above, so
    m/\A[^:]*:/               # a match without a capture is index >= 0

=head2 ALLOWED

    m/\A(.*?):/               # without /s, . refuses a newline before the :
    m/\A(.*):/s               # greedy: the last separator, which is rindex
    m/^([^:]*):/m             # /m: ^ is the start of any line
    m/([^:]*):/               # unanchored
    m/\G([^:]*):/gc           # \G is where the last match stopped
    m/\A([^:]*):/g            # /g
    s/\A([^\n]*)\n//g         # /g
    m/\A([^x]*)x/i            # /i: index compares case
    m/\A([^:;]*)[:;]/         # a class of several characters
    m/\A([^a]*)ab/            # the first a, which must be followed by b
    m/\A(.*?)\s/s             # \s, \R and the like are not literal text
    m/\A(.*?)(?:,|;)/s        # alternation
    m/\A(.*?)$sep/s           # interpolation
    s/\A([^\n]*)\n+//         # a quantified separator
    m/\A([^:]{2,}):/          # a counted quantifier
    m/\A(\w*):/               # a capture that checks what it captures
    m/\A([^:]*):(.*)\z/s      # two captures
    s/\A([^:]*):\s*//         # more pattern after the separator
    m/\A([^\n]*)\n\z/         # an anchor at the end as well
    s/\A([^\n]*)\n/$1 /       # a replacement
    qr/\A([^\n]*)\n/          # a compiled regex, which may be used elsewhere
    s/\A(?:[^\n]*)\n//        # a group that captures nothing

=head2 CAVEATS

C<[^X]+> and C<.+?> refuse a string that starts with the separator, and
C<index> finds it at position 0, with or without a capture.  When that check is the point, keep the regex
and say C<## no critic (ProhibitRegexToSplitAtDelimiter)> and why, or test
C<< $at > 0 >> instead of C<< $at >= 0 >>.

A match without a capture also sets C<$&>, C<@-> and C<@+>.  When the code
goes on to read C<$+[0]>, that is C<index> plus the length of the separator.

C<index> returns -1 when the separator is not there.  Test the position before
you take C<substr> of it: C<substr( $line, 0, -1 )> is the whole string less its
last character, not an error.

Modifiers turned on by C<use re> in the lexical scope of the regex count as if
they were written on it.  So under C<use re '/s'>, C<m/\A(.*?):/> is reported,
and under C<use re '/m'>, C<m/^([^:]*):/> is not.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitregextosplitatdelimiter/issues>

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
