use Renard::Incunabula::Common::Setup;
package Renard::Curie::Component::Role::HasParentMainWindow;
# ABSTRACT: Role that links a component to the parent main window
$Renard::Curie::Component::Role::HasParentMainWindow::VERSION = '0.003';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(InstanceOf);

has main_window => (
	is => 'ro',
	required => 1,
	isa => InstanceOf['Renard::Curie::Component::MainWindow'],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::Role::HasParentMainWindow - Role that links a component to the parent main window

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 main_window

Links the component to the parent L<Renard::Curie::Component::MainWindow> component.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
