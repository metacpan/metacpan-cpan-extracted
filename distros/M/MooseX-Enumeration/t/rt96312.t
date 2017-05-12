=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::Enumeration works with Type::Tiny type constraints.

=head1 AUTHOR

Jason McIntosh E<lt>jmac@jmac.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Jason McIntosh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 1;

{
	package Stoplight;
	
	use Moose;
	use Moose::Util::TypeConstraints;
	use MooseX::Enumeration;
	
	enum 'StoplightColor', [qw(
		red
		yellow
		green
	)];
	
	has 'color' => (
		is => 'ro',
		isa => 'StoplightColor',
		traits => [ 'Enumeration' ],
		handles => 1,
		lazy_build => 1,
	);
	
	sub _build_color {
		return 'green';
	}
}

my $stoplight = Stoplight->new;

ok $stoplight->is_green;
