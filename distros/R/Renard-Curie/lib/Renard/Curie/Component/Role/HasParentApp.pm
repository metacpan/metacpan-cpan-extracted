use Renard::Curie::Setup;
package Renard::Curie::Component::Role::HasParentApp;
# ABSTRACT: Role that links a component to the parent application
$Renard::Curie::Component::Role::HasParentApp::VERSION = '0.002';
use Moo::Role;
use Renard::Curie::Types qw(InstanceOf);

has app => (
	is => 'ro',
	isa => InstanceOf['Renard::Curie::App'],
	required => 1,
	weak_ref => 1
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Component::Role::HasParentApp - Role that links a component to the parent application

=head1 VERSION

version 0.002

=head1 ATTRIBUTES

=head2 app

Links the component to the parent L<Renard::Curie::App> application.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
