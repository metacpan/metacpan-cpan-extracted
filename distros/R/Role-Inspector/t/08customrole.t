=pod

=encoding utf-8

=head1 PURPOSE

Test that Role::Inspector works with a custom implementation of roles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::Modern;

use Role::Inspector qw( get_role_info );

is_deeply(
	get_role_info('Local::CustomRole'),
	+{
		name     => 'Local::CustomRole',
		type     => 'Local::Implementation',
		api      => [sort qw( meth req )],
		requires => [qw( req )],
		provides => [qw( meth )],
	},
	'can inspect custom role implementations',
) or diag explain(get_role_info('Local::CustomRole'));

done_testing;

