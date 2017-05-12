package PPIx::EditorTools::FindUnmatchedBrace;

# ABSTRACT: PPI-based unmatched-brace-finder

use 5.008;
use strict;
use warnings;
use Carp;

use base 'PPIx::EditorTools';
use Class::XSAccessor accessors => {};

use PPI;

our $VERSION = '0.18';

=pod

=head1 NAME

PPIx::EditorTools::FindUnmatchedBrace - PPI-based unmatched-brace-finder

=head1 SYNOPSIS

  my $brace = PPIx::EditorTools::FindUnmatchedBrace->new->find(
        code => "package TestPackage;\nsub x { 1;\n"
      );
  my $location = $brace->element->location;

=head1 DESCRIPTION

Finds the location of unmatched braces in a C<PPI::Document>.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item find( ppi => PPI::Document $ppi )
=item find( code => Str $code )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Finds the location of unmatched braces. Returns a
C<PPIx::EditorTools::ReturnObject> with the unmatched brace (a
C<PPI::Structure::Block>) available via the C<element> accessor.
If there is no unmatched brace, returns undef.

=back

=cut

sub find {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);

	my $ppi = $self->ppi;

	my $where = $ppi->find( \&PPIx::EditorTools::find_unmatched_brace );
	if ($where) {
		@$where = sort {
			       PPIx::EditorTools::element_depth($b) <=> PPIx::EditorTools::element_depth($a)
				or $a->location->[0] <=> $b->location->[0]
				or $a->location->[1] <=> $b->location->[1]
		} @$where;

		return PPIx::EditorTools::ReturnObject->new(
			ppi     => $ppi,
			element => $where->[0]
		);
	}
	return;
}

1;

__END__

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=cut

# Copyright 2008-2009 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
