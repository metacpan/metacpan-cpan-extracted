package Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign;

use 5.006001;
use strict;
use warnings;

use base 'Perl::Critic::Policy';

use Carp;
use Perl::Critic::Utils;
use Readonly;
use Try::Tiny;


=head1 NAME

Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign - Use tabs for indenting, spaces for aligning.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 AFFILIATION

This is a standalone policy not part of a larger PerlCritic Policies group.


=head1 DESCRIPTION

Hard tabs are a perfectly fine way to indent code for accessibility and
usability purposes, allowing different users to tweak indentation settings to
suit their needs and habits. However, hard tabs should not be used for
formatting / aligning, as this makes the display dependent on the tab-to-space
ratio of the user.

C<Perl/Critic/Policy/CodeLayout/ProhibitHardTabs> has a setting that allows
leading tabs, but this not not fully represent the paradigm where tabs are
reserved for indenting and spaces for formatting/aligning. In particular, it
does not prevent indenting with spaces, while this module detects and prevents
it.

This Policy examines your source code, including POD, quotes, and HEREDOCs.
The contents of the C<__DATA__> section are not examined.


=head1 CONFIGURATION

There is no configuration option available for this policy.


=head1 NOTES

Beware that Perl::Critic may report the location of the string that contains the
tab, not the actual location of the tab, so you may need to do some hunting.

=cut

Readonly::Scalar my $DESCRIPTION => 'Non-leading tab.';
Readonly::Scalar my $EXPLANATION => 'Use tabs for indenting, spaces for formatting. Found a non-leading tab.';


=head1 FUNCTIONS

=head2 supported_parameters()

Return an array with information about the parameters supported.

	my @supported_parameters = $policy->supported_parameters();

=cut

sub supported_parameters
{
    return ();
}


=head2 default_severity()

Return the default severify for this policy.

	my $default_severity = $policy->default_severity();

=cut

sub default_severity
{
	return $Perl::Critic::Utils::SEVERITY_MEDIUM;
}


=head2 default_themes()

Return the default themes this policy is included in.

	my $default_themes = $policy->default_themes();

=cut

sub default_themes
{
	return qw( cosmetic );
}


=head2 applies_to()

Return the class of elements this policy applies to.

	my $class = $policy->applies_to();

=cut

sub applies_to
{
	return 'PPI::Token';
}


=head2 violates()

Check an element for violations against this policy.

	my $policy->violates(
		$element,
		$document,
	);

=cut

sub violates
{
	my ( $self, $element, undef ) = @_;

	# The __DATA__ element is exempt.
	return if $element->parent->isa('PPI::Statement::Data');

	my $violations =
	try
	{
		# Check comments and any kind of whitespace block.
		if ( $element->isa('PPI::Token::Comment') || $element->isa('PPI::Token::Whitespace') )
		{
			# Newlines can be included at the beginning / end of whitespace elements by
			# PPI, ignore those.
			my $content = $element->content();
			$content =~ s/^[\r\n]+//;
			$content =~ s/[\r\n]+$//;

			if ( $element->column_number() == 1 )
			{
				croak 'In comments and indentation, tabs are only allowed at the beginning of the string. Spaces are allowed but only after a non-space character.'
					if $content !~ /\A\t*(?:|\S[^\t]*)\z/;
			}
			else
			{
				# If it's not at the beginning of a line, just make sure we don't have
				# any tabs.
				croak 'Tabs are not allowed after non-whitespace on the line.'
					if $content =~ /\t/;
			}
		}
		# Check HereDoc separately, as the content for the object is accessed with
		# a special method.
		elsif ( $element->isa('PPI::Token::HereDoc') )
		{
			my $declaration = $element->content();
			croak 'The HereDoc declaration should not have any tabs.'
				if $declaration =~ /\t/;

			# The content of the HereDoc block should behave like a multiline string.
			my @heredoc = $element->heredoc();
			croak 'Tabs are not allowed after non-tab characters.' if _has_violations_in_multiline_string( join( "\n", @heredoc ) );

			my $terminator = $element->terminator();
			croak 'The HereDoc terminator should not have any tabs.'
				if $terminator =~ /\t/;
		}
		# Check everything else.
		else
		{
			my $content = $element->content();
			croak 'Tabs are not allowed after non-tab characters.' if _has_violations_in_multiline_string( $content );
		}

		return;
	}
	catch
	{
		return $_;
	};

	return $self->violation(
		$DESCRIPTION,
		$EXPLANATION,
		$element,
	) if defined( $violations ) && ( $violations ne '' );

	return;
}


=head2 _has_violations_in_multiline_string()

Return a boolean indicating if a multiline string has violations against this
policy.

	my $string_has_violations = _has_violations_in_multiline_string( $string );

=cut

sub _has_violations_in_multiline_string
{
	my ( $string ) = @_;

	foreach my $line ( split( /\r?\n/, $string ) )
	{
		# Don't allow tabs after non-tab characters on the same line.
		# However, a tab followed by a space is legit, unlike the rest of the code.
		next if $line !~ /[^\t]\t/;

		return 1;
	}

	return 0;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign


You can also look for information at:

=over 4

=item * GitHub (report bugs there)

L<https://github.com/guillaumeaubert/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign>

=item * MetaCPAN

L<https://metacpan.org/release/Perl-Critic-Policy-CodeLayout-TabIndentSpaceAlign>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 ACKNOWLEDGEMENTS

I originally developed this project for ThinkGeek
(L<http://www.thinkgeek.com/>). Thanks for allowing me to open-source it!


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
