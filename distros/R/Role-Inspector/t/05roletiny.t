=pod

=encoding utf-8

=head1 PURPOSE

Test that Role::Inspector works with Role::Tiny.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern -requires => { 'Role::Tiny' => '1.000000' };

use Role::Inspector qw( get_role_info );

is_deeply(
	get_role_info('Local::RoleTiny'),
	+{
		name     => 'Local::RoleTiny',
		type     => 'Role::Tiny',
		api      => [sort qw( meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( meth )],
	},
	'can inspect Role::Tiny roles',
) or diag explain(get_role_info('Local::RoleTiny'));

is_deeply(
	get_role_info('Local::RoleTiny2'),
	+{
		name     => 'Local::RoleTiny2',
		type     => 'Role::Tiny',
		api      => [sort qw( meth meth2 req req2 )],
		requires => [sort qw( req req2 )],
		provides => [sort qw( meth meth2 )],
	},
	'can inspect Role::Tiny roles that consume other roles',
) or diag explain(get_role_info('Local::RoleTiny2'));

is_deeply(
	get_role_info('Local::RoleTiny3'),
	+{
		name     => 'Local::RoleTiny3',
		type     => 'Role::Tiny',
		api      => [sort qw( meth3 mod req req_list1 req_list2 req_list3 req_array_ref1 req_array_ref2 )],
		requires => [sort qw( mod req req_list1 req_list2 req_list3 req_array_ref1 req_array_ref2 )],
		provides => [sort qw( meth3 )],
	},
	'can inspect Role::Tiny which uses method modifiers',
) or diag explain(get_role_info('Local::RoleTiny3'));

done_testing;

