use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Role::Outlineable;
# ABSTRACT: Role that provides an outline for a document
$Renard::Incunabula::Document::Role::Outlineable::VERSION = '0.005';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(InstanceOf);

has outline => (
	is => 'lazy', # _build_outline
	isa => InstanceOf['Renard::Incunabula::Outline'],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Role::Outlineable - Role that provides an outline for a document

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 outline

Returns a L<Renard::Incunabula::Outline> which represents the outline for
this document.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
