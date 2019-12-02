=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::Enumeration works in Moose Roles

=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 2;

{
	package Local::Test::Role;
	use Moose::Role;

	has status => (
		is      => 'ro',
		enum    => [qw/ foo bar /],
		handles => 1,
		traits  => ['Enum'],
	);
}

{
	package Local::Test;
	use Moose;
	with 'Local::Test::Role';
}

ok( Local::Test->new( status => 'foo' )->is_foo, "handled is foo" );
like(
	eval { Local::Test->new( status => 'goo' )->is_bar } || $@,
	qr/(did|does) not pass (the )?type constraint/,
	"rejected bad input"
);


