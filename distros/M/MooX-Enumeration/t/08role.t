=pod

=encoding utf-8

=head1 PURPOSE

Test that MooX::Enumeration works in Moo Roles

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 Diab Jerius.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008001;
use strict;
use warnings;
use Test::More tests => 3;

{
	package Local::Test::Role;
	use Test::More;
	use Moo::Role;

	ok (eval 'use MooX::Enumeration; 1;', 'loaded into role')
		or BAIL_OUT($@);

	has status => (
		is      => 'ro',
		enum    => [qw/ foo bar /],
		handles => 1,
	);
}

{
	package Local::Test;
	use Moo;
	with 'Local::Test::Role';
}

ok( Local::Test->new( status => 'foo' )->is_foo, "handled is foo" );
like(
	eval { Local::Test->new( status => 'goo' )->is_bar } || $@,
	qr/did not pass type constraint/,
	"rejected bad input"
);


