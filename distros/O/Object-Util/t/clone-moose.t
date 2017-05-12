=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_clone >> using Moose objects.

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
use Test::Requires { Moose => '2.0000' };

use Object::Util;
use Scalar::Util qw(refaddr);

{
	package TestClass;
	use Moose;
	has [qw/ foo bar baz /] => (is => "rw");
}

my $test = 'TestClass'->new(foo => [1..3], bar => 666, baz => 999);
my $clone1 = $test->$_clone();
my $clone2 = $test->$_clone(baz => 42);

is_deeply(
	$clone1,
	$test,
	'clone with no args',
);

is_deeply(
	$clone2,
	'TestClass'->new(foo => [1..3], bar => 666, baz => 42),
	'clone with args',
);

is(
	refaddr($test->foo),
	refaddr($clone1->foo),
	'clone is shallow',
);

done_testing;
