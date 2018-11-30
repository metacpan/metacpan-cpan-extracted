package Perl::Critic::Policy::RegularExpressions::RequireDefault;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.00';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/a" or "/aa" flag};
Readonly::Scalar my $EXPL => q{Use regular expression "/a" or "/aa" flag};
Readonly::Scalar my $TRUE => 1;
Readonly::Scalar my $FALSE => 0;

#-----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw< security > }

sub applies_to {
    return qw<
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
        PPI::Statement::Include
    >;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( _pragma_enabled($elem) ) {
        return;    # ok!;
    }

    my $re = $doc->ppix_regexp_from_element($elem)
        or return;

    $re->modifier_asserted('a')
        or $re->modifier_asserted('aa')
        or return $self->violation( $DESC, $EXPL, $elem );

    return;        # ok!;
}

sub _correct_modifier {
    my $elem = shift;

    if ( $elem->arguments eq 'a' or $elem->arguments eq 'aa' ) {
        return $TRUE;
    }

    return $FALSE;
}

sub _pragma_enabled {
    my $elem = shift;

    if (    $elem->can('type')
        and $elem->type() eq 'use'
        and $elem->pragma() eq 're'
        and _correct_modifier($elem) )
    {

        return $TRUE;
    }

    return $FALSE;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireDefault - Always use the C</a> or C</aa> modifier with regular expressions.

=head1 VERSION

This documentation describes version 1.00

=head1 AFFILIATION

This policy has no affiliation

=head1 DESCRIPTION

This poliy aims to help enforce using Perl's protective measures against security vulnerabilities related to Unicode, such as:

=over

=item * Visual Spoofing

=item * Character and String Transformation Vulnerabilities

=back

The C</a> and C</aa> modifiers standing for ASCII-restrict or ASCII-safe, provides protection for applications that do not need to be exposed to all of Unicode and possible security issues with Unicode.

C</a> causes the sequences C<\d>, C<\s>, C<\w>, and the Posix character classes to match only in the ASCII range. Meaning:

=over

=item * C<\d> means the digits C<0> to C<9>

    my $ascii_letters =~ m/[A-Z]*/i;  # not ok
    my $ascii_letters =~ m/[A-Z]*/a;  # ok
    my $ascii_letters =~ m/[A-Z]*/aa; # ok

=item * C<\s> means the five characters C<[ \f\n\r\t]>, and starting in Perl v5.18, also the vertical tab

    my $characters =~ m/[ \f\n\r\t]*/;   # not ok
    my $characters =~ m/[ \f\n\r\t]*/a;  # ok
    my $characters =~ m/[ \f\n\r\t]*/aa; # ok

=item * C<\w> means the 63 characters C<[A-Za-z0-9_]> and all the Posix classes such as C<[[:print:]]> match only the appropriate ASCII-range characters

    my $letters =~ m/[A-Za-z0-9_]*/;   # not ok
    my $letters =~ m/[A-Za-z0-9_]*/a;  # ok
    my $letters =~ m/[A-Za-z0-9_]*/aa; # ok

=back

The policy also supports the pragma:

    use re 'a';

and:

    use re 'aa';

Which mean it will not evaluate the regular expressions any further:

    use re 'a';
    my $letters =~ m/[A-Za-z0-9_]*/;   # ok

Do note that the C</a> and C</aa> modifiers require Perl 5.14, so by using the recommended modifiers you indirectly introduct a requirement for Perl 5.14.

This policy is inspired by L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting|https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting> and many implementation details was lifted from this particular distribution.

=head1 CONFIGURATION AND ENVIRONMENT

This policy is not configurable at this time. Please see the TODO L</section>.

=head1 INCOMPATIBILITIES

This distribution holds no known incompatibilities at this time, please see L</DEPENDENCIES AND REQUIREMENTS> for details on version requirements.

=head1 BUGS AND LIMITATIONS

=over

=item * The pragma handling does not take into consideration of a pragma is disabled.

=item * The pragma handling does not take lexical scope into consideration properly and only detects the definition once

=back

This distribution holds no other known limitations or bugs at this time, please refer to the L<the issue listing on GitHub|https://github.com/jonasbn/perl-critic-policy-regularexpressions-requiredefault/issues> for more up to date information.

=head1 BUG REPORTING

Please report bugs via L<GitHub|https://github.com/jonasbn/perl-critic-policy-regularexpressions-requiredefault/issues>.

=head1 TEST AND QUALITY

This distribution aims to adhere to the Perl::Critic::Policy standards and Perl best practices and recommendations.

=head1 DEPENDENCIES AND REQUIREMENTS

This distribution requires:

=over

=item * Perl 5.14

=item * Carp

=item * Readonly

=item * Perl::Critic::Policy

=item * Perl::Critic::Utils

=back

Please see the listing in the file: F<cpanfile>, included with the distribution for a complete listing and description for configuration, test and development.

=head1 TODO

Ideas and suggestions for improvements and new features are listed in GitHub and are marked as C<enhancement>.

=over

=item * Please see L<the issue listing on GitHub|https://github.com/jonasbn/perl-critic-policy-regularexpressions-requiredefault/issues>

=back

=head1 SEE ALSO

=over

=item * L<Perl regular expression documentation: perlre|https://perldoc.perl.org/perlre.html>

=item * L<Perl delta file describing introduction of modifiers in Perl 5.14|https://perldoc.pl/perl5140delta#%2Fd%2C-%2Fl%2C-%2Fu%2C-and-%2Fa-modifiers>

=item * L<Unicode Security Issues FAQ|http://www.unicode.org/faq/security.html>

=item * L<Unicode Security Guide|http://websec.github.io/unicode-security-guide/>

=item * L<Perl::Critic|https://metacpan.org/pod/Perl::Critic>

=item * L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting|https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting>

=back

=head1 MOTIVATION

The motivation for this Perl::Critic policy came from a L<tweet|https://mobile.twitter.com/jmaslak/status/1008896883169751040> by L<@joel|https://mobile.twitter.com/jmaslak>

    | Perl folk: Looking for a PR challenge task? Check for \d in regexes
    | that really should be [0-9] or should have the /a regex modifier.
    | Perl is multinational by default! #TPCiSLC

=head1 AUTHOR

=over

=item * jonasbn <jonasbn@cpan.org>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * L<Joelle Maslak (@joel)|https://twitter.com/jmaslak> / L<JMASLAK|https://metacpan.org/author/JMASLAK> for the initial idea, see link to original tweet under L</MOTIVATION>

=item * L<Dan Book (@Grinnz)|https://github.com/Grinnz> / L<DBOOK|https://metacpan.org/author/DBOOK|> for information on Pragma and requirement for Perl 5.14, when using the modifiers handled and mentioned by this policy

=back

=head1 LICENSE AND COPYRIGHT

Perl::Critic::Policy::RegularExpressions::RequireDefault is (C) by jonasbn 2018

Perl::Critic::Policy::RegularExpressions::RequireDefault is released under the Artistic License 2.0

Please see the LICENSE file included with the distribution of this module

=cut
