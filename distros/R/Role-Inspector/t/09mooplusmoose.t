=pod

=encoding utf-8

=head1 PURPOSE

Test that Role::Inspector works with Moo::Role and Moose::Role,
when both are loaded into memory.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern -requires => { 'Moose' => '2.0600', 'Moo' => '1.000000' };

use Role::Inspector "does_role", get_role_info => { no_meta => 1 };

is_deeply(
	get_role_info('Local::MooRole'),
	+{
		name     => 'Local::MooRole',
		type     => 'Moo::Role',
		api      => [sort qw( attr set_attr clear_attr _assert_attr delegated meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( attr set_attr clear_attr _assert_attr delegated meth )],
	},
	'can inspect Moo roles',
) or diag explain(get_role_info('Local::MooRole'));

is_deeply(
	get_role_info('Local::MooseRole'),
	+{
		name     => 'Local::MooseRole',
		type     => 'Moose::Role',
		api      => [sort qw( meta attr set_attr clear_attr delegated meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( meta attr set_attr clear_attr delegated meth )],
	},
	'can inspect Moose roles',
) or diag explain(get_role_info('Local::MooseRole'));

is_deeply(
	do {
		my $info = get_role_info('Local::MooRole3');
		delete $info->{type};
		$info;
	},
	+{
		name     => 'Local::MooRole3',
		# type     => 'Moo::Role',
		api      => [sort qw( attr _assert_attr set_attr clear_attr delegated meth meth2 req req2 )],
		requires => [sort qw( req req2 )],
		provides => [sort qw( attr _assert_attr set_attr clear_attr delegated meth meth2 )],
	},
	'can inspect Moo roles which compose Moose roles',
) or diag explain(get_role_info('Local::MooRole3'));

is_deeply(
	get_role_info('Local::MooseRole3'),
	+{
		name     => 'Local::MooseRole3',
		type     => 'Moose::Role',
		api      => [sort qw( meta attr _assert_attr set_attr clear_attr delegated meth meth2 req req2 )],
		requires => [sort qw( req req2 )],
		provides => [sort qw( meta attr _assert_attr set_attr clear_attr delegated meth meth2 )],
	},
	'can inspect Moose roles which compose Moo roles',
) or diag explain(get_role_info('Local::MooseRole3'));

ok(
	does_role('Local::MooseRole3', 'Local::MooseRole3'),
	'does_role($x, $x) where $x is a Moose role',
);

ok(
	does_role('Local::MooseRole3', 'Local::MooRole'),
	'does_role($x, $y) where $x is a role that consumes $y, and $x is a Moose role, and $y is a Moo role',
);

ok(
	does_role('Local::MooseClass2', 'Local::MooRole3'),
	'does_role($x, $y) where $x is a Moose class that consumes Moo role $y directly',
);

ok(
	does_role('Local::MooseClass2', 'Local::MooseRole'),
	'does_role($x, $y) where $x is a Moose class that consumes Moose role $y indirectly',
);

ok(
	!does_role('Local::MooseRole', 'Local::MooseRole3'),
	'!does_role($x, $y) where $x is a role that consumes $y',
);


ok(
	does_role('Local::MooRole3', 'Local::MooRole3'),
	'does_role($x, $x) where $x is a Moo role',
);

ok(
	does_role('Local::MooRole3', 'Local::MooseRole'),
	'does_role($x, $y) where $x is a role that consumes $y, and $x is a Moo role, and $y is a Moose role',
);

ok(
	does_role('Local::MooClass2', 'Local::MooseRole3'),
	'does_role($x, $y) where $x is a Moo class that consumes Moose role $y directly',
);

ok(
	does_role('Local::MooClass2', 'Local::MooRole'),
	'does_role($x, $y) where $x is a Moo class that consumes Moo role $y indirectly',
);

ok(
	!does_role('Local::MooRole', 'Local::MooRole3'),
	'!does_role($x, $y) where $x is a role that consumes $y',
);


done_testing;
