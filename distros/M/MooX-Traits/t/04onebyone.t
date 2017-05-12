=pod

=encoding utf-8

=head1 PURPOSE

Test that C<MooX::Traits::Util::new_class_with_traits_one_by_one> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More 0.96;
use Test::Requires { 'Test::Fatal' => 0 };

{
	package Foo;
	use Role::Tiny;
	sub foolishness { 1 };
	requires 'barbary_pirates';
}

{
	package Bar;
	use Role::Tiny;
	sub barbary_pirates { 2 };
	requires 'foolishness';
}

{
	package MyClass;
	sub new { bless [], shift }
}

use MooX::Traits::Util -all;

like(
	exception { new_class_with_traits_one_by_one( MyClass => qw(Foo Bar) ) },
	qr/barbary_pirates/,
	'Cannot compose Foo because missing Bar',
);

like(
	exception { new_class_with_traits_one_by_one( MyClass => qw(Bar Foo) ) },
	qr/foolishness/,
	'Cannot compose Bar because missing Foo',
);

my $class = 'MyClass';
is(
	exception { $class = new_class_with_traits( MyClass => qw(Foo Bar) ) },
	undef,
	'Can compose Foo and Bar simultaneously',
);

can_ok($class, qw( new foolishness barbary_pirates ));

done_testing;
