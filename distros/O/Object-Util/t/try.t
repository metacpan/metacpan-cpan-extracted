=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_try >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;

use Object::Util;

sub TestClass::survive { return $_[1] }
sub TestClass::fall    { die    $_[1] }

my $test = bless({ foo => [1..3], bar => 666, baz => 999 }, 'TestClass');

is(
	$test->survive(42),
	42,
	'$test->survive(42)',
);

like(
	exception { $test->fall(42) },
	qr/^42/,
	'$test->fall(42)',
);

is(
	$test->$_try(survive => 42),
	42,
	'$test->$_try(survive => 42)',
);

is(
	$test->$_try(fall => 42),
	undef,
	'$test->$_try(fall => 42)',
);

done_testing;
