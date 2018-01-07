use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Document::Types;
# ABSTRACT: Type library for document types
$Renard::Incunabula::Document::Types::VERSION = '0.004';
use Type::Library 0.008 -base,
	-declare => [qw(
		DocumentModel
		PageNumber
		PageCount
		LaxPageNumber
		ZoomLevel
	)];
use Type::Utils -all;

use Types::Common::Numeric qw(PositiveInt PositiveOrZeroInt PositiveNum);

class_type "DocumentModel",
	{ class => "Renard::Incunabula::Document" };

declare "PageNumber", parent => PositiveInt;

declare "PageCount", parent => PositiveInt;

declare "LaxPageNumber", parent => PositiveOrZeroInt;

declare "ZoomLevel", parent => PositiveNum;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Document::Types - Type library for document types

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=back

=head1 TYPES

=head2 DocumentModel

A type for any reference that extends L<Renard::Incunabula::Document>.

=head2 PageNumber

An alias to L<PositiveInt> that can be used for document page number semantics.

=head2 PageCount

An alias to L<PositiveInt> that can be used for document page number count semantics.

=head2 LaxPageNumber

An alias to L<PositiveOrZeroInt> that can be used for document page number
semantics when the source data may contain invalid pages.

=head2 ZoomLevel

The amount to zoom in on a page. This is a multiplier such that

=over 4

=item *

when the value is C<1.0>, the page area is the standard area

=item *

when the value is C<2.0>, the page is C<4> times the standard area

=item *

when the value is C<0.5>, the page is C<0.25> times the standard area

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
