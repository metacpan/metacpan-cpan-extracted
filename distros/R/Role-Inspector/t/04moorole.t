=pod

=encoding utf-8

=head1 PURPOSE

Test that Role::Inspector works with Moo::Role, and
continues to work with Role::Tiny when Moo is loaded into memory.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern -requires => { 'Moo::Role' => '1.000000' };

use Role::Inspector qw( get_role_info does_role );

is_deeply(
	do {
		my $got = get_role_info('Local::MooRole');
		delete($got->{type});
		$got;
	},
	+{
		name     => 'Local::MooRole',
		# type     => 'Moo::Role',
		api      => [sort qw( attr set_attr clear_attr _assert_attr delegated meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( attr set_attr clear_attr _assert_attr delegated meth )],
	},
	'can inspect Moo roles',
) or diag explain(get_role_info('Local::MooRole'));

is_deeply(
	do {
		my $got = get_role_info('Local::RoleTiny');
		delete($got->{type});
		$got;
	},
	+{
		name     => 'Local::RoleTiny',
		# type     => 'Role::Tiny',
		api      => [sort qw( meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( meth )],
	},
	'can inspect Role::Tiny roles',
) or diag explain(get_role_info('Local::RoleTiny'));

is_deeply(
	do {
		my $got = get_role_info('Local::MooRole2');
		delete($got->{type});
		$got;
	},
	+{
		name     => 'Local::MooRole2',
		# type     => 'Moo::Role',
		api      => [sort qw( attr set_attr clear_attr _assert_attr delegated meth meth2 req req2 )],
		requires => [sort qw( req req2 )],
		provides => [sort qw( attr set_attr clear_attr _assert_attr delegated meth meth2 )],
	},
	'can inspect Moo roles what consume other roles',
) or diag explain(get_role_info('Local::MooRole2'));

ok(
	does_role('Local::MooRole', 'Local::MooRole'),
	'does_role($x, $x)',
);

ok(
	does_role('Local::MooRole2', 'Local::MooRole'),
	'does_role($x, $y) where $x is a role that consumes $y',
);

ok(
	does_role('Local::MooClass', 'Local::MooRole2'),
	'does_role($x, $y) where $x is a class that consumes $y directly',
);

ok(
	does_role('Local::MooClass', 'Local::MooRole'),
	'does_role($x, $y) where $x is a class that consumes $y indirectly',
);

ok(
	!does_role('Local::MooRole', 'Local::MooRole2'),
	'!does_role($x, $y) where $x is a role that consumes $y',
);

done_testing;
