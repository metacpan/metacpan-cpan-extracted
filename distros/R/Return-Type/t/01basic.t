=pod

=encoding utf-8

=head1 PURPOSE

Test that Return::Type works.

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

use Types::Standard -types;

use_ok('Return::Type');

subtest "support for wantarray and caller" => sub
{
	my @caller;
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { @caller = (wantarray, (caller(1))[0..2]) },
		scalar => Any,
	);

#line 40 "01basic.t"
	is(scalar($wrapped->()), 4, 'scalar context');
	is_deeply(\@caller, [ !!0, 'main', '01basic.t', 40 ], 'scalar context');

#line 44 "01basic.t"
	is_deeply([$wrapped->()], [ !!1, 'main', '01basic.t', 44 ], 'list context');
	is_deeply(\@caller, [ !!1, 'main', '01basic.t', 44 ], 'list context');

#line 48 "01basic.t"
	$wrapped->();
	is_deeply(\@caller, [ undef, 'main', '01basic.t', 48 ], 'void context');
	
	done_testing;
};

subtest "type checks" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { wantarray ? @_ : $_[0] },
		scalar => Int,
	);
	
	is(scalar($wrapped->(42,43,44)), 42, 'checked passing value, scalar context');
	is_deeply([$wrapped->(42,43,44)], [42,43,44], 'checked passing value, list context');
	
	like(
		exception { my $x = $wrapped->("x",43,44) },
		qr{^Value "x" did not pass type constraint},
		'checked failing value, scalar context',
	);
	
	like(
		exception { my @x = $wrapped->(42,"x",44) },
		qr{^Reference .42,"x",44. did not pass type constraint},
		'checked failing value, list context',
	);
	
	ok(
		!exception { $wrapped->("x"); 1 },
		'checked void context',
	);
};

subtest "type checks - differing constraints for scalar/list context" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { wantarray ? @_ : $_[0] },
		scalar => Int,
		list   => Tuple[HashRef,ArrayRef],
	);
	
	is(scalar($wrapped->(42,43,44)), 42, 'checked passing value, scalar context');
	is_deeply([$wrapped->({}, [])], [{}, []], 'checked passing value, list context');
	
	like(
		exception { my $x = $wrapped->("x",43,44) },
		qr{^Value "x" did not pass type constraint},
		'checked failing value, scalar context',
	);
	
	like(
		exception { my @x = $wrapped->([], {}) },
		qr{^Reference \[\s*\[\s*\]\s*,\s*\{\s*\}\s*\] did not pass type constraint},
		'checked failing value, list context',
	);
};

subtest "hash context" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { @_ },
		scalar => Any,
		list   => HashRef,
	);
	
	is_deeply(
		[ $wrapped->(foo => 42) ],
		[ foo => 42 ],
		'called with even number of items',
	);
	
	like(
		exception { my @h = $wrapped->(foo => 42, 'bar') },
		qr{^Odd number of elements in anonymous hash},
		'called with odd number of items',
	);
};

subtest "coercion" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { $_[0] },
		scalar => Int->plus_coercions(Num, q[int($_)]),
		coerce => 1,
	);
	
	is(
		$wrapped->(3),
		3,
		'value not needing coercion',
	);
	
	is(
		$wrapped->(5.3),
		5,
		'value needing coercion',
	);
	
	like(
		exception { my $v = $wrapped->("x") },
		qr{^Value "x" did not pass type constraint "Int"},
		'value that cannot be coerced',
	);
	
	is_deeply(
		[$wrapped->(3)],
		[3],
		'value not needing coercion - list context',
	);
	
	is_deeply(
		[$wrapped->(5.3)],
		[5],
		'value needing coercion - list context',
	);
	
	like(
		exception { my @v = $wrapped->("x") },
		qr{^Reference \["x"\] did not pass type constraint "ArrayRef\[Int\]"},
		'value that cannot be coerced - list context',
	);
};

done_testing;
