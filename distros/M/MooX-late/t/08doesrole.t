=pod

=encoding utf-8

=head1 PURPOSE

See if C<< does => $rolename >> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Bar;
	use Moo::Role;
}

{
	package Foo::Bar;
	use Moo;
	with 'Bar';
}

{
	package Foo::Baz;
	use Moo;
}

{
	package Quux;
	use Moo;
	use MooX::late;
	has xxx => (is => 'ro', does => 'Bar');
}

is(
	exception { Quux->new(xxx => Foo::Bar->new) },
	undef,
);

like(
	exception { Quux->new(xxx => Foo::Baz->new) },
	qr/did not pass type constraint/,
);

done_testing;
