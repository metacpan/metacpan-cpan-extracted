package Regexp::Parsertron::Actions;

use v5.10;
use strict;
use warnings;
#use warnings qw(FATAL utf8); # Fatalize encoding glitches.

our $VERSION = '1.00';

# ------------------------------------------------

sub character_sequence
{
	my($self, $t) = @_;

	say 'character_sequence: ', $self -> decode_result($t);

	return $t;

} # End of character_sequence.

# ------------------------------------------------

sub named_capture_group
{
	my($self, $t) = @_;

	say 'named_capture_group: ', $self -> decode_result($t);

	return $t;

} # End of named_capture_group.

# ------------------------------------------------

sub named_capture_group_pattern
{
	my($self, $t) = @_;

	say 'named_capture_group_pattern: ', $self -> decode_result($t);

	return $t;

} # End of named_capture_group_pattern.

# ------------------------------------------------

sub parenthesis_pattern
{
	my($self, $t) = @_;

	say 'parenthesis_pattern: ', $self -> decode_result($t);

	return $t;

} # End of parenthesis_pattern.

# ------------------------------------------------

sub pattern_sequence
{
	my($self, $t) = @_;

	say 'pattern_sequence: ', $self -> decode_result($t);

	return $t;

} # End of pattern_sequence.

# ------------------------------------------------

sub decode_result
{
	my($result)   = @_;
	my(@worklist) = $result;

	my($obj);
	my($ref_type);
	my(@stack);

	do
	{
		$obj      = shift @worklist;
		$ref_type = ref $obj;

		if ($ref_type eq 'ARRAY')
		{
			unshift @worklist, @$obj;
		}
		elsif ($ref_type eq 'HASH')
		{
			push @stack, {%$obj};
		}
		elsif ($ref_type)
		{
			die "Unsupported object type $ref_type\n";
		}
		else
		{
			push @stack, $obj;
		}

	} while (@worklist);

	return join('', @stack);

} # End of decode_result.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<X500::DN::Marpa::Actions> - Methods triggered by 'action' clauses in the grammar

=head1 Synopsis

See L<X500::DN::Marpa/Synopsis>.

=head1 Description

C<X500::DN::Marpa::Action> provides a wrapper for actions which are called by Marpa as it
processes the grammar declared in L<X500::DN::Marpa>.

End users will never call methods in this module.

See instead L<X500::DN::Marpa/Description>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<X500::DN::Marpa> as you would any C<Perl> module:

Run:

	cpanm X500::DN::Marpa

or run:

	sudo cpan X500::DN::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Methods

=head2 attribute_type($t)

For a DN such as 'UID=12345, OU=Engineering, CN=Kurt Zeilenga+L=Redwood Shores', returns the
lower-case version of the attribute type, e.g. 'uid'.

Where the type is a standard long form, e.g. 'OrganizationalUnitName', returns the corresponding
abbreviation, here 'ou'.

=head2 attribute_value($t)

For a DN such as 'UID=12345, OU=Engineering, CN=Kurt Zeilenga+L=Redwood Shores', returns the
original-case version of the attribute value, e.g. 'Engineering'.

=head1 Functions

=head2 decode_result($result)

Returns a string.

Processes the $result passed by Marpa to both L</attribute_type($t)> and L</attribute_value($t)>,
which will be a structure of arbitrarily nested scalars, hashrefs and arrayrefs.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/X500-DN-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=X500::DN::Marpa>.

=head1 Author

L<X500::DN::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
