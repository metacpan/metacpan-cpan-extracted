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

done_testing;

