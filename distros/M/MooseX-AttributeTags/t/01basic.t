=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::AttributeTags compiles and works.

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
	package Foo;
	use Moose;
	use MooseX::AttributeTags (
		'Foo',
		'Bar' => [
			quux    => [ is => 'ro', default => 666 ],
			quuux   => [ is => 'ro', default => 999 ],
			xyzzy   => sub { 42 },
		],
		'Baz' => [
			barry   => [ is => 'ro', required => 1 ],
		],
	);
	
	has munchkin1 => (
		traits     => [ Foo, Bar ],
		is         => 'ro',
		quux       => 777,
	);
	
	::like(
		::exception {
			has munchkin2 => (
				traits     => [ Baz ],
				is         => 'ro',
			);
		},
		qr{\AAttribute .?barry.? is required},
	);
}

my $m1 = 'Foo'->meta->get_attribute('munchkin1');

ok $m1->does(Foo::Foo);
ok $m1->does(Foo::Bar);

can_ok($m1, qw/quux quuux xyzzy/);

is($m1->quux, 777);
is($m1->quuux, 999);
is($m1->xyzzy, 42);

done_testing;
