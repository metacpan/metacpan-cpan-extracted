package Perl::Critic::Policy::RegularExpressions::RequireExtendedFormattingExceptForSplit;

# ABSTRACT: Always use the C</x> modifier with regular expressions, except when the regex is used

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.117';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/x" flag - but not for split};
Readonly::Scalar my $EXPL => [ 236 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'minimum_regex_length_to_complain_about',
            description        =>
                q<The number of characters that a regular expression must contain before this policy will complain.>,
            behavior           => 'integer',
            default_string     => '0',
            integer_minimum    => 0,
        },
        {
            name               => 'strict',
            description        =>
                q<Should regexes that only contain whitespace and word characters be complained about?>,
            behavior           => 'boolean',
            default_string     => '0',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw<reneeb> }
sub applies_to           {
    return qw<
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
    >;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $match = $elem->get_match_string();
    return if length $match <= $self->{_minimum_regex_length_to_complain_about};
    return if not $self->{_strict} and $match =~ m< \A [\s\w]* \z >xms;

    return if _is_used_to_split( $elem );

    my $re = $doc->ppix_regexp_from_element( $elem )
        or return;
    $re->modifier_asserted( 'x' )
        or return $self->violation( $DESC, $EXPL, $elem );

    return; # ok!;
}

sub _is_used_to_split {
    my ($elem) = @_;

    my $is_to_split = _elem_has_split_as_sibling( $elem );

    if ( !$is_to_split && $elem->parent->isa( 'PPI::Statement::Expression' ) ) {
        my $grandparent = $elem->parent->parent;
        $is_to_split    = _elem_has_split_as_sibling( $grandparent );
    }

    return $is_to_split;
}

sub _elem_has_split_as_sibling {
    my ($elem) = @_;

    my $has_sibling;
    while ( my $sib = $elem->sprevious_sibling ) {
        if ( "$sib" eq 'split' ) {
            $has_sibling = 1;
            last;
        }

        $elem = $sib;
    }

    return $has_sibling;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireExtendedFormattingExceptForSplit - Always use the C</x> modifier with regular expressions, except when the regex is used

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Extended regular expression formatting allows you mix whitespace and
comments into the pattern, thus making them much more readable.

    # Match a single-quoted string efficiently...

    m{'[^\\']*(?:\\.[^\\']*)*'};  #Huh?

    # Same thing with extended format...

    m{
        '           # an opening single quote
        [^\\']      # any non-special chars (i.e. not backslash or single quote)
        (?:         # then all of...
            \\ .    #    any explicitly backslashed char
            [^\\']* #    followed by an non-special chars
        )*          # ...repeated zero or more times
        '           # a closing single quote
    }x;

=head1 CONFIGURATION

You might find that putting a C</x> on short regular expressions to be
excessive.  An exception can be made for them by setting
C<minimum_regex_length_to_complain_about> to the minimum match length
you'll allow without a C</x>.  The length only counts the regular
expression, not the braces or operators.

    [RegularExpressions::RequireExtendedFormatting]
    minimum_regex_length_to_complain_about = 5

    $num =~ m<(\d+)>;              # ok, only 5 characters
    $num =~ m<\d\.(\d+)>;          # not ok, 9 characters

This option defaults to 0.

Because using C</x> on a regex which has whitespace in it can make it
harder to read (you have to escape all that innocent whitespace), by
default, you can have a regular expression that only contains
whitespace and word characters without the modifier.  If you want to
restrict this, turn on the C<strict> option.

    [RegularExpressions::RequireExtendedFormattingExceptForSplit]
    strict = 1

    $string =~ m/Basset hounds got long ears/;  # no longer ok

This option defaults to false.

=head1 NOTES

For common regular expressions like e-mail addresses, phone numbers,
dates, etc., have a look at the L<Regexp::Common|Regexp::Common> module.
Also, be cautions about slapping modifier flags onto existing regular
expressions, as they can drastically alter their meaning.  See
L<http://www.perlmonks.org/?node_id=484238> for an interesting
discussion on the effects of blindly modifying regular expression
flags.

=head1 TO DO

Add an exemption for regular expressions that contain C<\Q> at the
beginning and don't use C<\E> until the very end, if at all.

=for Pod::Coverage supported_parameters

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

#-----------------------------------------------------------------------------


