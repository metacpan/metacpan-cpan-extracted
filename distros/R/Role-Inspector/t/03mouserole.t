=pod

=encoding utf-8

=head1 PURPOSE

Test that Role::Inspector works with Mouse::Role.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern -requires => { 'Mouse::Role' => '1.00' };

use Role::Inspector "does_role", get_role_info => { no_meta => 1 };

is_deeply(
	get_role_info('Local::MouseRole'),
	+{
		name     => 'Local::MouseRole',
		type     => 'Mouse::Role',
		api      => [sort qw( meta attr set_attr clear_attr delegated meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( meta attr set_attr clear_attr delegated meth )],
	},
	'can inspect Mouse roles',
) or diag explain(get_role_info('Local::MouseRole'));

is_deeply(
	get_role_info('Local::MouseRole2'),
	+{
		name     => 'Local::MouseRole2',
		type     => 'Mouse::Role',
		api      => [sort qw( meta attr set_attr clear_attr delegated meth meth2 req req2 )],
		requires => [sort qw( req req2 )],
		provides => [sort qw( meta attr set_attr clear_attr delegated meth meth2 )],
	},
	'can inspect Mouse roles that consume other roles',
) or diag explain(get_role_info('Local::MouseRole2'));

ok(
	does_role('Local::MouseRole', 'Local::MouseRole'),
	'does_role($x, $x)',
);

ok(
	does_role('Local::MouseRole2', 'Local::MouseRole'),
	'does_role($x, $y) where $x is a role that consumes $y',
);

ok(
	does_role('Local::MouseClass', 'Local::MouseRole2'),
	'does_role($x, $y) where $x is a class that consumes $y directly',
);

ok(
	does_role('Local::MouseClass', 'Local::MouseRole'),
	'does_role($x, $y) where $x is a class that consumes $y indirectly',
);

ok(
	!does_role('Local::MouseRole', 'Local::MouseRole2'),
	'!does_role($x, $y) where $x is a role that consumes $y',
);

is_deeply(
	get_role_info('Local::MouseRole3'),
	+{
		name     => 'Local::MouseRole3',
		type     => 'Mouse::Role',
		api      => [sort qw( meta meth3 mod req req_list1 req_list2 req_list3 req_array_ref1 req_array_ref2 )],
		requires => [sort qw( mod req req_list1 req_list2 req_list3 req_array_ref1 req_array_ref2 )],
		provides => [sort qw( meta meth3 )],
	},
	'can inspect Mouse role which uses method modifiers',
) or diag explain(get_role_info('Local::MouseRole3'));

done_testing;
