=pod

=encoding utf-8

=head1 PURPOSE

More complex coercion cases.

(Additionally, this test uses non-inlineable coercions.)

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

use constant Int1 => Int->plus_coercions(HashRef, sub {666});
use constant Int2 => Int->plus_coercions(HashRef, sub {999});

use_ok('Return::Type');

subtest "coerce only in scalar context" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { wantarray ? @_ : shift },
		scalar        => Int1,
		list          => ArrayRef[Int2],
		coerce_scalar => 1,
	);
	
	is( $wrapped->({}), 666 );
	ok exception { my @r = $wrapped->({}) };
};

subtest "coerce only in list context" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { wantarray ? @_ : shift },
		scalar        => Int1,
		list          => ArrayRef[Int2],
		coerce_list   => 1,
	);
	
	ok exception { my $r = $wrapped->({}) };
	is_deeply(
		[ $wrapped->({}) ],
		[ 999 ],
	);
};

subtest "coerce differently in each context" => sub
{
	my $wrapped = 'Return::Type'->wrap_sub(
		sub { wantarray ? @_ : shift },
		scalar        => Int1,
		list          => ArrayRef[Int2],
		coerce        => 1,
	);
	
	is( $wrapped->({}), 666 );
	is_deeply(
		[ $wrapped->({}) ],
		[ 999 ],
	);
};

done_testing;
