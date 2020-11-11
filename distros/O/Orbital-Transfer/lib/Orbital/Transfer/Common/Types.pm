use Orbital::Transfer::Common::Setup;
package Orbital::Transfer::Common::Types;
# ABSTRACT: Type library
$Orbital::Transfer::Common::Types::VERSION = '0.001';
use Type::Library 0.008 -base,
	-declare => [qw(
	)];
use Type::Utils -all;

# Listed here so that scan-perl-deps can find them
use Types::Path::Tiny      ();
use Types::URI             ();
use Types::Standard        qw();
use Types::Common::Numeric qw();

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

Orbital::Transfer::Common::Types - Type library

=head1 VERSION

version 0.001

=head1 TYPE LIBRARIES

=for :list * L<Types::Standard>
* L<Types::Path::Tiny>
* L<Types::URI>
* L<Types::Common::Numeric>

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
