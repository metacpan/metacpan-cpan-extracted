use Renard::Curie::Setup;
package Renard::Curie::Model::Document::Role::Pageable;
# ABSTRACT: Role for documents that have numbered pages
$Renard::Curie::Model::Document::Role::Pageable::VERSION = '0.001';
use Moo::Role;
use Renard::Curie::Types qw(PageNumber);

has first_page_number => (
	is => 'ro',
	isa => PageNumber,
	default => 1,
);


has last_page_number => (
	is => 'lazy', # _build_last_page_number
	isa => PageNumber,
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Curie::Model::Document::Role::Pageable - Role for documents that have numbered pages

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 first_page_number

A C<PageNumber> containing the first page number of the document.
This is always C<1>.

=head2 last_page_number

A C<PageNumber> containing the last page number of the document.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
