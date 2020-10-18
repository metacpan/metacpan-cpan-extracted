use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::View::Grid::Subview;
# ABSTRACT: A subview for a grid-layout
$Renard::Curie::Model::View::Grid::Subview::VERSION = '0.005';
use Moo;
use Renard::Incunabula::Common::Types qw(InstanceOf);

has _grid_view => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Model::View::Grid']
);

has _grid_scheme => (
	is => 'ro',
	required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::View::Grid::Subview - A subview for a grid-layout

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
