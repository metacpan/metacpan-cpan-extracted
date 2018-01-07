use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Role::Boundable;
# ABSTRACT: Role for documents where each page has bounds
$Renard::Incunabula::Document::Role::Boundable::VERSION = '0.004';
use Moo::Role;
use Renard::Incunabula::Common::Types qw(ArrayRef HashRef);

has identity_bounds => (
	is => 'lazy', # _build_identity_bounds
	isa => ArrayRef[HashRef],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Role::Boundable - Role for documents where each page has bounds

=head1 VERSION

version 0.004

=head1 ATTRIBUTES

=head2 identity_bounds

An C<ArrayRef[HashRef]> of data that gives information about the bounds of each page of
the document.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
