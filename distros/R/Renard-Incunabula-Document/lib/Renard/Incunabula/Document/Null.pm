use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Null;
# ABSTRACT: A null document
$Renard::Incunabula::Document::Null::VERSION = '0.004';
use Moo;
use Renard::Incunabula::Common::Types qw(ArrayRef InstanceOf);

has pages => (
	is => 'ro',
	isa => ArrayRef[InstanceOf['Renard::Incunabula::Page::Null']],
	required => 1,
);

method _build_last_page_number() {
	0 + @{ $self->pages };
}

extends qw(Renard::Incunabula::Document);

with qw(Renard::Incunabula::Document::Role::Pageable);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Null - A null document

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Renard::Incunabula::Document>

=back

=head1 CONSUMES

=over 4

=item * L<Renard::Incunabula::Document::Role::Pageable>

=back

=head1 ATTRIBUTES

=head2 pages

An C<ArrayRef[InstanceOf['Renard::Incunabula::Page::Null']]> of pages.

This attribute is required.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
