package PPIx::EditorTools::IntroduceTemporaryVariable;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Introduces a temporary variable using PPI
$PPIx::EditorTools::IntroduceTemporaryVariable::VERSION = '0.20';
use 5.008;
use strict;
use warnings;
use Carp;

use base 'PPIx::EditorTools';
use Class::XSAccessor accessors => {
	'start_location' => 'start_location',
	'end_location'   => 'end_location',
	'expression'     => 'expression',
	'location'       => 'location',
};


sub introduce {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);
	my $start_loc = $args{start_location} or croak "start_location required";
	my $end_loc   = $args{end_location}   or croak "end_location required";
	my $varname   = $args{varname};
	$varname = 'tmp'          if not defined $varname;
	$varname = '$' . $varname if $varname !~ /^[\$\@\%]/;

	my $ppi = $self->ppi;
	$ppi->flush_locations;

	my $token = PPIx::EditorTools::find_token_at_location( $ppi, $start_loc );
	$ppi->flush_locations;
	die "no token" unless $token;

	my $statement = $token->statement();
	die "no statement" unless $statement;

	# walk up the PPI tree until we reach a sort of structure that's not a statement.
	# FIXME: This may or may not be robust. A PPI::Statement claims to be what's
	#        defined as "statements" in perlsyn, but it's not! perlsyn says all statements
	#        end in a semicolon unless at the end of a block.
	#        For PPI, Statements can be part of others and thus don't necessarily have
	#        a semicolon.
	while (1) {
		my $parent = $statement->statement();
		last if not defined $parent;
		if ( $parent eq $statement ) { # exactly the same object, ie. is a statement already
			$parent = $statement->parent(); # force the parent
			last
				if not $parent              # stop if we're at a block or at the document level
					or $parent->isa('PPI::Structure::Block')
					or $parent->isa('PPI::Structure::Document');
			$parent = $parent->statement(); # force it to be a statement
		}
		last if not $parent                 # stop if the parent isn't a statement
				or not $parent->isa('PPI::Statement');
		$statement = $parent;
	}
	my $location_for_insert = $statement->location;
	$self->location($location_for_insert);

	# TODO: split on a look behind \n so we keep the \n
	my @code = map {"$_\n"} split( /\n/, $ppi->serialize );

	my $expr;
	for my $line_num ( $start_loc->[0] .. $end_loc->[0] ) {
		my $line = $code[ $line_num - 1 ];  # 0 based index to 1 base line numbers

		substr( $line, $end_loc->[1] ) = '' if $line_num == $end_loc->[0];
		substr( $line, 0, $start_loc->[1] - 1 ) = ''
			if $line_num == $start_loc->[0];

		$expr .= $line;
	}

	$self->expression($expr);

	my $indent = '';
	$indent = $1 if $code[ $location_for_insert->[0] - 1 ] =~ /^(\s+)/;

	my $place_holder = 'XXXXX_PPIx_EDITOR_PLACE_HOLDER_XXXXX';
	substr(
		$code[ $location_for_insert->[0] - 1 ],
		$location_for_insert->[1] - 1, 0
	) = sprintf( "my %s = %s;\n%s", $varname, $place_holder, $indent );

	# TODO: need to watch for word boundries etc...
	my $code = join( '', @code );
	$code =~ s/\Q$expr\E/$varname/gm;
	$code =~ s/\Q$place_holder\E/$expr/gm;

	return PPIx::EditorTools::ReturnObject->new(
		code    => $code,
		element => sub {
			PPIx::EditorTools::find_token_at_location(
				shift->ppi,
				$location_for_insert
			);
		}
	);
}

1;

=pod

=encoding UTF-8

=head1 NAME

PPIx::EditorTools::IntroduceTemporaryVariable - Introduces a temporary variable using PPI

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    my $munged = PPIx::EditorTools::IntroduceTemporaryVariable->new->introduce(
        code           => "use strict; BEGIN {
	$^W = 1;
}\n\tmy $x = ( 1 + 10 / 12 ) * 2;\n\tmy $y = ( 3 + 10 / 12 ) * 2;\n",
        start_location => [ 2, 19 ],
        end_location   => [ 2, 25 ],
        varname        => '$foo',
    );
    my $modified_code_as_string = $munged->code;
    my $location_of_new_var_declaration = $munged->element->location;

=head1 DESCRIPTION

Given a region of code within a statement, replaces all occurrences of
that code with a temporary variable. Declares and initializes the
temporary variable right above the statement that included the
selected expression.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item find( ppi => PPI::Document, start_location => Int, end_location => Int, varname => Str )

=item find( code => Str, start_location => Int, end_location => Int, varname => Str )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.

Given the region of code specified by start_location and end_location,
replaces that code with a temporary variable with the name given
in varname (defaults to C<tmp>). Declares and initializes
the temporary variable right above the statement that included the
selected expression.

Returns a C<PPIx::EditorTools::ReturnObject> with the modified code
as a string available via the C<code> accessor (or as a C<PPI::Document>
via the C<ppi> accessor), and the C<PPI::Token> where the new variable
is declared available via the C<element> accessor.

Croaks with a "no token" exception if no token is found at the location.
Croaks with a "no statement" exception if unable to find the statement.

=back

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller C<smueller@cpan.org>

=item *

Mark Grimes C<mgrimes@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo  <gabor@szabgab.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2014, 2012 by The Padre development team as listed in Padre.pm..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
