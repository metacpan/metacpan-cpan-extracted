use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Role::Pageable;
# ABSTRACT: Role for documents that have numbered pages
$Renard::Incunabula::Document::Role::Pageable::VERSION = '0.005';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(Bool);
use Renard::Incunabula::Document::Types qw(PageNumber PageCount);
use MooX::ShortHas;

has first_page_number => (
	is => 'ro',
	isa => PageNumber,
	default => 1,
);


has last_page_number => (
	is => 'lazy', # _build_last_page_number
	isa => PageNumber,
);

method is_valid_page_number( $page_number ) :ReturnType(Bool) {
	# uncoverable condition right
	PageNumber->check($page_number)
		&& $page_number >= $self->first_page_number
		&& $page_number <= $self->last_page_number
}

lazy number_of_pages => method() {
	(PageCount)->(
		$self->last_page_number - $self->first_page_number + 1
	);
}, isa => PageCount;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Role::Pageable - Role for documents that have numbered pages

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 first_page_number

A C<PageNumber> containing the first page number of the document.
This is always C<1>.

=head2 last_page_number

A C<PageNumber> containing the last page number of the document.

=head2 number_of_pages

  isa => PageCount

Calculates the number of pages between the C<first_page_number> and C<last_page_number>.

=head1 METHODS

=head2 is_valid_page_number

  method is_valid_page_number( $page_number ) :ReturnType(Bool)

Returns true if C<$page_number> is a valid C<PageNumber> and is between the
first and last page numbers inclusive.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
