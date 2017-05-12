=head1 PURPOSE

Test the example from the L<MooseX::Does::Delegated> SYNOPSIS section.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use Test::More;

{
	package HttpGet;
	use Moose::Role;
	requires 'get';
};

{
	package UserAgent;
	use Moose;
	with qw( HttpGet );
	sub get { 1; };  # Changed from SYNOPSIS to get it to compile
};                  # in Perl before 5.12.

{
	package Spider;
	use Moose;
	has ua => (
		is         => 'ro',
		does       => 'HttpGet',
		handles    => 'HttpGet',
		lazy_build => 1,
	);
	sub _build_ua { UserAgent->new };
};

my $woolly = Spider->new;

# Note that the default Moose implementation of DOES
# ignores the fact that Spider has delegated the HttpGet
# role to its "ua" attribute.
#
ok(     $woolly->DOES('Spider') );
ok( not $woolly->DOES('HttpGet') );

Moose::Util::apply_all_roles(
	'Spider',
	'MooseX::Does::Delegated',
);

# Our reimplemented DOES pays attention to delegated roles.
#
ok( $woolly->DOES('Spider') );
ok( $woolly->DOES('HttpGet') );

done_testing;
