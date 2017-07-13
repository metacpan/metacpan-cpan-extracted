use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::MainWindow::Role::Outline;
# ABSTRACT: Role for outline
$Renard::Curie::Component::MainWindow::Role::Outline::VERSION = '0.003';
use Moo::Role;
use Renard::Curie::Component::Outline;
use Renard::Incunabula::Common::Types qw(InstanceOf DocumentModel);

use Glib 'TRUE', 'FALSE';

requires 'content_box';

has outline => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Component::Outline'],
);

after setup_window => method() {
	$self->content_box->pack_start( $self->outline , FALSE, TRUE, 0 );
};

after open_document => method( (DocumentModel) $doc ) {
	$self->outline->update( $doc );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::MainWindow::Role::Outline - Role for outline

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 outline

A L<Renard::Curie::Component::Outline> which makes up the outline sidebar for
this window.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
