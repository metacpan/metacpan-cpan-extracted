=head1 PURPOSE

Check that functions installed by Scalar::Does are removed by
L<namespace::clean>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 2;

{
	package Local::Foo;
	use Scalar::Does;
	sub check_does {
		my ($class, $thing, $role) = @_;
		does($thing, $role);
	}
}

ok(
	!Local::Foo->can('does'),
	"does is cleaned up",
);

ok(
	Local::Foo->check_does( [] => 'ARRAY' ),
	"does still works",
);
