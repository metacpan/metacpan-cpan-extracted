=pod

=encoding utf-8

=head1 PURPOSE

Test that Role::Inspector works with p5-mop-redux.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern -requires => { 'mop' => '0.03' };

use Role::Inspector get_role_info => { no_meta => 1 };

is_deeply(
	get_role_info('Local::MopRole'),
	+{
		name     => 'Local::MopRole',
		type     => 'mop::role',
		api      => [sort qw( attr meth req )],
		requires => [sort qw( req )],
		provides => [sort qw( attr meth )],
	},
	'can inspect p5-mop-redux roles',
) or diag explain(get_role_info('Local::MopRole'));

done_testing;

