=pod

=encoding utf-8

=head1 PURPOSE

Test that Switcheroo works nicely with L<Smart::Match>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Smart::Match' => '0.007' };

use Switcheroo;
use Smart::Match qw( range at_least );

sub nummer
{
	my $value = shift;
	
	switch ($value) {
		case range(0, 10):    "small";
		case range(11, 100):  "medium";
		case at_least(101):   "large";
		default:              undef;
	}
}

is( nummer(4), "small" );
is( nummer(12), "medium" );
is( nummer(9000), "large" );
is( nummer(-4), undef );

done_testing;

