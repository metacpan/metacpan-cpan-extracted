package String::InterpolatedVariables;

use strict;
use warnings;

use Readonly;


=head1 NAME

String::InterpolatedVariables - Extract variable names from interpolated strings.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';


=head1 SYNOPSIS

	use String::InterpolatedVariables;

	my $variables = String::InterpolatedVariables::extract(
		'A $test->{string} from a PPI::Token::Quote::Double $object.'
	);

	# $variables now contains:
	# [
	#     '$test->{string}',
	#     '$object',
	# ]


=head1 DESCRIPTION

String::InterpolatedVariables offers a way to extract the name of the variables
that are present in interpolated strings.

This is particularly useful if you are using L<PPI> to parse Perl documents,
and you want to know what variables would be interpolated inside the
L<PPI::Token::Quote::Double> and L<PPI::Token::Quote::Interpolate> objects you
find there. A practical example of this use can be found in
L<Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection>.

=cut

Readonly::Scalar my $VARIABLES_REGEX => qr/
	# Ignore escaped sigils, since those wouldn't get interpreted as variables to interpolate.
	(?<!\\)
	# Allow literal, non-escapy backslashes.
	(?:\\\\)*
	(
		# The variable needs to start with a sigil.
		[\$\@]
		# Account for the dereferencing, such as "$$" or "@$".
		\$?
		# Variable name.
		(?:
			# Note: include '::' to support package variables here.
			\{(?:\w+|::)\} # Explicit {variable} name.
			|
			(?:\w|::)+     # Variable name.
		)
		# Catch nested data structures.
		(?:
			# Allow for a dereferencing ->.
			(?:->)?
			# Can be followed by either a hash or an array.
			(?:
				\{(?:\w+|'[^']+'|"[^"]+")\}  # Hash element.
				|
				\[['"]?\d+['"]?\]            # Array element.
			)
		)*
	)
/x;


=head1 FUNCTIONS

=head2 extract()

Extract variables from interpolated strings.

	my $variables = String::InterpolatedVariables::extract(
		'A $test->{string} from a PPI::Token::Quote::Double $object.'
	);

	# $variables now contains:
	# [
	#     '$test->{string}',
	#     '$object',
	# ]

Note that you need to pass the text of the string, even if the string itself is
destined to be interpolated. In other words, passing C<"Test $test"> would not
find any variables, as C<$test> would get interpolated by Perl before the
string is passed to the C<extract()> function. This function is thus more
useful if you are using using a tool such as L<PPI> to read Perl code, since
PPI will give you access to the text of the string itself for strings that
would otherwise be interpolated during execution.

=cut

sub extract
{
	my ( $string ) = @_;

	my $variables = [];
	while ( my ( $variable ) = $string =~ $VARIABLES_REGEX )
	{
		push( @$variables, $variable );
		$string =~ s/\Q$variable\E//g;
	}

	return $variables;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/String-InterpolatedVariables/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc String::InterpolatedVariables


You can also look for information at:

=over 4

=item * GitHub (report bugs there)

L<https://github.com/guillaumeaubert/String-InterpolatedVariables/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-InterpolatedVariables>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-InterpolatedVariables>

=item * MetaCPAN

L<https://metacpan.org/release/String-InterpolatedVariables>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2014-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
