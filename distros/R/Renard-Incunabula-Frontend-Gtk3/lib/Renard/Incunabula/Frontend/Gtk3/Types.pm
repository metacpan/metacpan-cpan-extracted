use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Frontend::Gtk3::Types;
# ABSTRACT: Type library for Gtk3
$Renard::Incunabula::Frontend::Gtk3::Types::VERSION = '0.004';
use Type::Library 0.008 -base,
	-declare => [qw(
		SizeRequest
	)];
use Type::Utils -all;

# Listed here so that scan-perl-deps can find them
use Types::Standard        qw(Tuple);
use Types::Common::Numeric qw(PositiveInt);

declare "SizeRequest",
	parent => Tuple[PositiveInt,PositiveInt];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Frontend::Gtk3::Types - Type library for Gtk3

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=back

=head1 TYPES

=head2 SizeRequest

A tuple that represents a size request for a widget.

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
