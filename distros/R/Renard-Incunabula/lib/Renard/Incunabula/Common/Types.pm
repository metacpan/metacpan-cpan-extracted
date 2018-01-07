use Renard::Incunabula::Common::Setup;
package Renard::Incunabula::Common::Types;
# ABSTRACT: Type library
$Renard::Incunabula::Common::Types::VERSION = '0.004';
use Type::Library 0.008 -base,
	-declare => [qw(
	)];
use Type::Utils -all;

# Listed here so that scan-perl-deps can find them
use Types::Path::Tiny      ();
use Types::URI             ();
use Types::Standard        ();
use Types::Common::Numeric ();

use Type::Libraries;
Type::Libraries->setup_class(
	__PACKAGE__,
	qw(
		Types::Standard
		Types::Path::Tiny
		Types::URI
		Types::Common::Numeric
	)
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Renard::Incunabula::Common::Types - Type library

=head1 VERSION

version 0.004

=head1 EXTENDS

=over 4

=item * L<Type::Library>

=item * L<Type::Library>

=back

=head1 TYPE LIBRARIES

=over 4

=item *

L<Types::Standard>

=item *

L<Types::Path::Tiny>

=item *

L<Types::URI>

=item *

L<Types::Common::Numeric>

=back

=head1 AUTHOR

Project Renard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Project Renard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
