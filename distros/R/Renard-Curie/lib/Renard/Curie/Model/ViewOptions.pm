use Renard::Incunabula::Common::Setup;
package Renard::Curie::Model::ViewOptions;
# ABSTRACT: A high-level set of options for generating a view
$Renard::Curie::Model::ViewOptions::VERSION = '0.005';
use Moo;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Renard::Curie::Model::ViewOptions::Grid;
use Renard::Curie::Model::ViewOptions::Zoom::Percentage;

with qw(MooX::Role::CloneSet);

has grid_options => (
	is => 'ro',
	default => sub {
		Renard::Curie::Model::ViewOptions::Grid->new(
			rows => 1, columns => 1,
		);
	},
	isa => InstanceOf['Renard::Curie::Model::ViewOptions::Grid'],
);

has zoom_options => (
	is => 'ro',
	default => sub {
		Renard::Curie::Model::ViewOptions::Zoom::Percentage->new(
			zoom_level => 1.0,
		);
	},
	isa => InstanceOf['Renard::Curie::Model::ViewOptions::Zoom'],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::ViewOptions - A high-level set of options for generating a view

=head1 VERSION

version 0.005

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 CONSUMES

=over 4

=item * L<MooX::Role::CloneSet>

=back

=head1 ATTRIBUTES

=head2 grid_options

A L<Renard::Curie::Model::ViewOptions::Grid>.

By default, this a grid option with C<< { rows => 1, columns => 1} >>
(i.e., a single page view, non-continuous).

=head2 zoom_options

A L<Renard::Curie::Model::ViewOptions::Zoom>.

By default, this is set to a L<Renard::Curie::Model::ViewOptions::Zoom::Percentage>
such that

  Renard::Curie::Model::ViewOptions::Zoom::Percentage->new(
    zoom_level => 1.0,
  );

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
