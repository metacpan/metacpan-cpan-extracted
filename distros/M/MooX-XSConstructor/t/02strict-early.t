=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::XSConstructor works with MooX::StrictConstructor.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warnings;
use Test::Requires 'MooX::StrictConstructor::Role::Constructor';

{
	package Foo;
	use Moo;
	use MooX::StrictConstructor;
	use MooX::XSConstructor;
	has [ 'foo', 'bar' ] => ( is => 'ro' );
}

ok(
	!MooX::XSConstructor::is_xs(\&Foo::new),
	'Foo::new is not XS'
);

is_deeply(
	Foo->new( foo => 66, bar => 99 ),
	bless( { foo => 66, bar => 99 }, 'Foo' ),
	'is_deeply',
);

like(
	exception { Foo->new( foo => 66, baz => 99 ) },
	qr/Found unknown attribute/,
	'exception',
);

done_testing;