use 5.008001;
use strict;
use warnings;

package Local::StdTests;

use Test::Modern;

sub arrayref_coercion_tests
{
	my ($type1, $type2) = @_;
	
	is_deeply(
		$type1->assert_coerce([1,2,3]),
		[1,2,3],
		'$type1->coerce(\@array)',
	);
	
	is_deeply(
		$type1->assert_coerce('1:2:3'),
		[1,2,3],
		'$type1->coerce($str)',
	);

	is_deeply(
		$type1->assert_coerce('5'),
		[5],
		'$type1->coerce($num)',
	);

	ok(
		exception { $type1->assert_coerce({}) },
		'$type1->assert_coerce(\%hash) throws',
	);
	
	is_deeply(
		$type2->assert_coerce([1,2,3]),
		[1,2,3],
		'$type2->coerce(\@array)',
	);
	
	is_deeply(
		$type2->assert_coerce('1:2:3'),
		[1,2,3],
		'$type2->coerce($str)',
	);
	
	is_deeply(
		$type2->assert_coerce(5),
		[undef, undef, undef, undef, undef],
		'$type2->coerce($num)',
	);
	
	ok(
		exception { $type2->assert_coerce({}) },
		'$type1->assert_coerce(\%hash) throws',
	);
};

1;

__END__

=pod

=encoding utf-8

=head1 PURPOSE

This module defines a test routine shared by several of the
MooseX-Types-MoreUtils testing scripts.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
