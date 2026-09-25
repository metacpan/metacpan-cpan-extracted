package Perl::Critic::Policy::RegularExpressions::ProhibitRegexToStripAffix 0.001;

# ABSTRACT: Take a known prefix or suffix off a string without a regex capture.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use List::Util qw{ any all };
use Readonly;
use PPIx::Regexp;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Regex used to strip a literal prefix or suffix};
Readonly::Scalar my $EXPL => q{Check the literal with substr() or index(), and take the rest with substr()};

# Modifiers that change what the pattern means in a way substr cannot follow:
# /i compares without case, /g iterates.  /m is handled beside the anchors,
# since it matters only to ^ and $.
Readonly::Array my @EXEMPTING_MODIFIERS => qw{ i g };

Readonly::Hash my %START => map { $_ => 1 } ( '\A', '^' );
Readonly::Hash my %END => map { $_ => 1 } ( '\z', '\Z', '$' );

# A capture that runs to the end of the string it is anchored away from, so
# that end needs no anchor of its own.
Readonly::Hash my %TO_THE_END => map { $_ => 1 } ( '(.*)', '(.+)' );


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw{ performance } }
sub applies_to           { return 'PPI::Token::Regexp::Match' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    my %modifiers = $elem->get_modifiers;
    return if any { $modifiers{$_} } @EXEMPTING_MODIFIERS;

    my $regexp = PPIx::Regexp->new( $elem->content ) or return;
    return unless ( $regexp->max_capture_number // 0 ) == 1;

    my $re = $regexp->regular_expression or return;
    my @parts =
      grep { !$_->isa('PPIx::Regexp::Token::Whitespace') && !$_->isa('PPIx::Regexp::Token::Comment') } $re->children;

    return unless _strips_an_affix( \@parts, $modifiers{m} );
    return $self->violation( $DESC, $EXPL, $elem );
}

# Whether @$parts is an anchor, a run of literals and one capture, in either
# order, with the capture's own end anchored too unless it runs there anyway.
sub _strips_an_affix {
    my ( $parts, $multiline ) = @_;

    my @parts = @$parts;
    my $start = _anchor( $parts[0], \%START, $multiline )          ? shift @parts : undef;
    my $end   = @parts && _anchor( $parts[-1], \%END, $multiline ) ? pop @parts   : undef;
    return unless $start || $end;

    my ( $capture, $literals );
    if ( @parts && $parts[0]->isa('PPIx::Regexp::Structure::Capture') ) {

        # A suffix: the capture comes first, and has to reach the start.
        $capture  = shift @parts;
        $literals = \@parts;
        return unless $end && ( $start || $TO_THE_END{ $capture->content } );
    }
    elsif ( @parts && $parts[-1]->isa('PPIx::Regexp::Structure::Capture') ) {

        # A prefix: the capture comes last, and has to reach the end.
        $capture  = pop @parts;
        $literals = \@parts;
        return unless $start && ( $end || $TO_THE_END{ $capture->content } );
    }
    else {
        return;
    }

    return unless @$literals;
    return all { $_->isa('PPIx::Regexp::Token::Literal') } @$literals;
}

# Whether $part is one of the anchors in %$which.  Under /m, ^ and $ anchor
# lines rather than the string, so only \A, \z and \Z count.
sub _anchor {
    my ( $part, $which, $multiline ) = @_;

    return unless $part && $part->isa('PPIx::Regexp::Token::Assertion');

    my $anchor = $part->content;
    return if $multiline && ( $anchor eq '^' || $anchor eq '$' );
    return $which->{$anchor};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitRegexToStripAffix - Take a known prefix or suffix off a string without a regex capture.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::RegularExpressions::ProhibitRegexToStripAffix

A match that anchors a run of literal text to one end of the string and
captures the rest is taking a prefix or a suffix off.  C<substr> does that
without compiling a pattern, running it, and copying out a capture:

    my ($name) = $file =~ m/\A(\w+)\.pm\z/;                       # reported

    my $name = substr( $file, -3 ) eq '.pm' ? substr( $file, 0, -3 ) : undef;

    my ($rest) = $line =~ m/\Aprefix-(.*)\z/;                     # reported

    my $rest = index( $line, 'prefix-' ) == 0 ? substr( $line, 7 ) : undef;

=head2 PROHIBITED

    m/\A(\w+)\.pm\z/              # a suffix, anchored at both ends
    m/^(.*)\.tar\.gz$/            # $ and ^ as well as \A and \z
    m/(.+)\.bak\z/                # .* or .+ reaches the start on its own
    m/\Aprefix-(.*)\z/            # a prefix
    m/\Afoo:(.*)/                 # a prefix, and .* reaches the end on its own
    m/\A(\w+) \. pm\z/x           # whitespace under /x is not text

=head2 ALLOWED

    m/(\w+)\.pm\z/                # unanchored: the last run of word characters
    m/\A(\w+)\.(pm|pl)\z/         # alternation, and two captures
    m/\A(\w+)\.pm\z/i             # /i: substr's comparison is case sensitive
    m/^(.*)\.pm$/m                # /m: ^ and $ are line anchors
    m/\A(\w+)\.pm\z/g             # /g
    m/\A(\w+)[.]pm\z/             # a character class is not literal text
    m/\A(\w+)$ext\z/              # interpolation
    m/\A(\w+)\z/                  # nothing to strip
    s/\.pm\z//                    # a substitution
    qr/\A(\w+)\.pm\z/             # a compiled regex, which may be used elsewhere

=head2 CAVEATS

A capture of anything but C<.*> or C<.+> also checks what it captures:
C<m/\A(\w+)\.pm\z/> refuses C<foo-bar.pm>, and C<substr> takes the suffix off
whatever is in front of it.  When that check is the point, keep the regex and
say C<## no critic (ProhibitRegexToStripAffix)> and why.

C<$> and C<\Z> also match before a newline at the end of the string, and C<.>
does not match a newline without C</s>.  C<substr> knows nothing of lines, so
for text that can end in a newline, C<chomp> it first.

A modifier turned on by C<use re> is not seen, only one written on the match.
The scenarios in which you turn on global C</img> are quite rare, and you should
simply not use this policy if your code does this.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitregextostripaffix/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

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
