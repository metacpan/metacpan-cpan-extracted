use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::ViewOptions::Zoom::Percentage;
# ABSTRACT: A set of options for zooming by a fixed amount
$Renard::Curie::Model::ViewOptions::Zoom::Percentage::VERSION = '0.005';
use Moo;
use Renard::Incunabula::Document::Types qw(ZoomLevel);

extends 'Renard::Curie::Model::ViewOptions::Zoom';

has zoom_level => (
	is => 'ro',
	required => 1,
	isa => ZoomLevel,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::ViewOptions::Zoom::Percentage - A set of options for zooming by a fixed amount

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Renard::Curie::Model::ViewOptions::Zoom>

=back

=head1 ATTRIBUTES

=head2 zoom_level

The amount to zoom as C<ZoomLevel>.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
