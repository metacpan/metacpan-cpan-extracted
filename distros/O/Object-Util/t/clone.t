=pod

=encoding utf-8

=head1 PURPOSE

Tests for C<< $_clone >>.

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
use Scalar::Util qw(refaddr);

sub TestClass::new {
	my $class = shift;
	bless +{ @_==1 ? %{$_[0]} : @_ }, $class
}

my $test = bless({ foo => [1..3], bar => 666, baz => 999 }, 'TestClass');
my $clone1 = $test->$_clone();
my $clone2 = $test->$_clone(baz => 42);

is_deeply(
	$clone1,
	$test,
	'clone with no args',
);

is_deeply(
	$clone2,
	bless({ foo => [1..3], bar => 666, baz => 42 }, 'TestClass'),
	'clone with args',
);

is(
	refaddr($test->{foo}),
	refaddr($clone1->{foo}),
	'clone is shallow',
);

@TestClass2::ISA = qw( TestClass );
sub TestClass2::clone {
	my ($self, %args) = @_;
	ref($self)->new({ %$self, %args, parent => $self });
}

my $test2 = bless({ foo => [1..3], bar => 666, baz => 999 }, 'TestClass2');
is_deeply(
	$test2->$_clone(quux => 42),
	bless(
		{ foo => [1..3], bar => 666, baz => 999, quux => 42, parent => $test2 },
		'TestClass2',
	),
	'cloning a class that provides a clone method',
);

like(
	exception { my $x = []; $x->$_clone },
	qr/^Cannot call/,
	'$_clone on unblessed ref (exception)',
);

like(
	exception { my $x = bless([], 'TestClass3'); $x->$_clone },
	qr/^Object does not provide/,
	'$_clone on basic non-hashref object (exception)',
);

done_testing;
