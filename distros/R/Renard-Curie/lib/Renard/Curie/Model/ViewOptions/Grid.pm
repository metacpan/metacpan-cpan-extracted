use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::ViewOptions::Grid;
# ABSTRACT: A set of options for grids
$Renard::Curie::Model::ViewOptions::Grid::VERSION = '0.003';
use Moo;
use MooX::Lsub;
use Renard::Incunabula::Common::Types qw(Maybe PositiveInt);
use Renard::Incunabula::Common::Error;

# Need to use the ::BuildArgs version since is_continuous_view is a lsub.
with qw(MooX::BuildArgs MooX::Role::CloneSet::BuildArgs);

has [ qw/rows columns/ ] => (
	is => 'ro',
	required => 1,
	isa => sub {
		( Maybe[PositiveInt] )->check($_[0]) or
			Renard::Incunabula::Common::Error::ViewOptions::InvalidGridOptions->throw(
				msg => 'Grid extent must be Maybe[PositiveInt]',
			);
	},
);

lsub is_continuous_view => method() {
	defined $self->rows xor
		defined $self->columns;
};

method BUILD() {
	unless( defined $self->rows or defined $self->columns ) {
		Renard::Incunabula::Common::Error::ViewOptions::InvalidGridOptions->throw({
			msg => "At least one of the grid extents must be defined",
		});
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::ViewOptions::Grid - A set of options for grids

=head1 VERSION

version 0.003

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<MooX::BuildArgs>

=item * L<MooX::BuildArgsHooks>

=item * L<MooX::Role::CloneSet::BuildArgs>

=back

=head1 ATTRIBUTES

=head2 rows

  Maybe[PositiveInt]

The number of rows for the grid (i.e., in the vertical direction)
or C<undef> if the number of rows is unspecified (see C<BUILD>).

=head2 columns

  Maybe[PositiveInt]

The number of columns for the grid (i.e., in the horizontal direction)
or C<undef> if the number of columns is unspecified (see C<BUILD>).

=head2 is_continuous_view

  Bool

A predicate that returns a true value if the view is a continuous view
(see C<BUILD>).

=head1 METHODS

=head2 BUILD

This class can only be constructed if at least one of C<rows> or C<columns> is
defined. If one is C<undef>, the associated grid view is continuous and the
non-C<undef> attribute is used to compute the C<undef> attribute.

=for Pod::Coverage BUILDARGS FINALIZE_BUILDARGS

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
