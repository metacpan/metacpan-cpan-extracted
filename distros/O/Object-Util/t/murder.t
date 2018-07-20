=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_murder >>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;
use Object::Util;

my $destroyed;

{
	package Foo;
	sub new { my $class = shift; bless {@_}, $class }
	sub do_stuff { 1 }
	sub DESTROY { ++$destroyed }
}

my $foo = Foo->new( foo => 123, bar => 456 );

do {
	my $bar = $foo; # copy reference to object
	$bar->$_murder;
	
	is($bar, undef);
};

is($destroyed, 1);

my $e1 = exception { $foo->do_stuff(123) };
like($e1, qr/Can't call method .+ on reaped object/);

my $e2 = exception { $foo->can('do_stuff') };
like($e2, qr/Can't call method .+ on reaped object/);

ok !exists($foo->{foo});
ok !exists($foo->{bar});

done_testing;
