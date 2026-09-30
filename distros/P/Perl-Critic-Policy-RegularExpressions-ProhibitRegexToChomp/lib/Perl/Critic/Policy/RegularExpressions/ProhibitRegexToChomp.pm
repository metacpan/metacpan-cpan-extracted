package Perl::Critic::Policy::RegularExpressions::ProhibitRegexToChomp 0.001;

# ABSTRACT: Take a trailing newline off with chomp, not with a substitution.

use strict;
use warnings FATAL => 'all';

use 5.014;

use re '/aa';

use Readonly;
use PPIx::Regexp;

use Perl::Critic::Utils qw{ :severities };
use parent              qw{Perl::Critic::Policy};


Readonly::Scalar my $DESC => q{Substitution used to remove a trailing newline};
Readonly::Scalar my $EXPL => q{Use chomp()};

Readonly::Scalar my $NEWLINE => 10;

Readonly::Hash my %END => map { $_ => 1 } ( '\z', '\Z', '$' );

# The quantifiers that still mean "the newlines at the end": none, one, or all.
Readonly::Hash my %QUANTIFIER => map { $_ => 1 } qw{ ? * + };


sub supported_parameters { return () }
sub default_severity     { return $SEVERITY_MEDIUM }
sub default_themes       { return qw{ performance maintenance } }
sub applies_to           { return 'PPI::Token::Regexp::Substitute' }


sub violates {
    my ( $self, $elem, undef ) = @_;

    return unless $elem->get_substitute_string eq q{};

    my $regexp = PPIx::Regexp->new( $elem->content ) or return;
    my $re     = $regexp->regular_expression         or return;
    my @parts =
      grep { !$_->isa('PPIx::Regexp::Token::Whitespace') && !$_->isa('PPIx::Regexp::Token::Comment') } $re->children;

    my %modifiers = $elem->get_modifiers;
    return unless _is_trailing_newline( \@parts, $modifiers{m} );
    return $self->violation( $DESC, $EXPL, $elem );
}

# Whether @$parts is a newline, then at most one of ? * or +, then the end.
sub _is_trailing_newline {
    my ( $parts, $multiline ) = @_;

    my @parts = @$parts;
    return unless _is_newline( shift @parts );

    my $end = pop @parts;
    return unless $end && $end->isa('PPIx::Regexp::Token::Assertion') && $END{ $end->content };
    return if $multiline && $end->content eq '$';

    return 1 unless @parts;
    my ( $quantifier, $greediness, @rest ) = @parts;
    return if @rest;
    return unless $quantifier->isa('PPIx::Regexp::Token::Quantifier') && $QUANTIFIER{ $quantifier->content };
    return !$greediness || $greediness->isa('PPIx::Regexp::Token::Greediness');
}

# Whether $part matches a newline and nothing else: the character itself, in
# any spelling, or a class that holds only it.
sub _is_newline {
    my ($part) = @_;

    return unless $part;
    if ( $part->isa('PPIx::Regexp::Structure::CharClass') ) {
        return if $part->negated;
        my @members = $part->children;
        return unless @members == 1;
        $part = $members[0];
    }
    return $part->isa('PPIx::Regexp::Token::Literal') && ( $part->ordinal // -1 ) == $NEWLINE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitRegexToChomp - Take a trailing newline off with chomp, not with a substitution.

=head1 VERSION

version 0.001

=head1 Perl::Critic::Policy::RegularExpressions::ProhibitRegexToChomp

A substitution that deletes a newline at the end of a string is C<chomp>.
C<chomp> says what it does in one word, and it does it without compiling a
pattern and running it:

    $line =~ s/\n\z//;                     # reported
    chomp $line;

    my $message = $p{message} =~ s/\n+\z//r;   # reported
    chomp( my $message = $p{message} );

=head2 PROHIBITED

    s/\n\z//                # \z, \Z and $ all count as the end
    s/\n$//r                # /r: chomp a copy instead
    s/\n+\z//               # a quantified newline, see CAVEATS
    s/\n?\z//               # ? is what chomp does anyway
    s/[\n]*\Z//             # a class of one newline is a newline
    s/\x0a\z//              # any spelling of the character
    s/ \n \z //x            # whitespace under /x is not text

=head2 ALLOWED

    s/\r?\n\z//             # chomp leaves the carriage return
    s/\s+\z//               # trailing whitespace, not a newline
    s/\n//                  # the first newline, wherever it is
    s/\n$//m                # /m: $ is the end of a line
    s/\n\z/;/               # a replacement
    s/\n{2,}\z//            # a counted quantifier
    s/$eol\z//              # interpolation

=head2 CAVEATS

C<\n+> and C<\n*> take off every newline at the end, and C<chomp> takes off one.
Text that genuinely ends in more than one newline, and wants all of them gone,
is rare enough that the policy reports it anyway.  When it is the point, keep
the regex and say C<## no critic (ProhibitRegexToChomp)> and why.

C<chomp> takes off C<$/>, which is C<"\n"> unless the code around it changed
it.  After C<local $/;>, to read a whole file, C<chomp> takes off nothing.

C<chomp> changes its argument and returns how many characters it removed, not
the string.  Where the substitution had C</r>, copy first:
C<chomp( my $copy = $original )>.

A modifier turned on by C<use re> is not seen, only one written on the
substitution.  So under a global C</m>, C<s/\n$//> is reported although C<$>
means the end of a line there.

=head2 METHODS

=head3 supported_parameters

=head3 default_severity

=head3 default_themes

=head3 applies_to

=head3 violates

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/perl-critic-policy-prohibitregextochomp/issues>

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
