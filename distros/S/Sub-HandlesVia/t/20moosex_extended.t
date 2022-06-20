=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::HandlesVia works with MooseX::Extended's C<param>
and C<field> functions.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use 5.008;
use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require MooseX::Extended; 1 }
		or plan skip_all => 'test requires MooseX::Extended';
};

BEGIN {
	package Local::MyClass;
	
	use MooseX::Extended types => [ 'Str' ];
	use Sub::HandlesVia;
	
	has eg1 => (
		is => 'ro',
		isa => Str,
		handles_via => 'String',
		handles => { eg1_append => 'append...' },
	);
	
	field eg2 => (
		is => 'ro',
		isa => Str,
		handles_via => 'String',
		handles => { eg2_append => 'append...' },
		default => sub { 'eg2' },
	);
	
	param eg3 => (
		is => 'ro',
		isa => Str,
		handles_via => 'String',
		handles => { eg3_append => 'append...' },
	);
};

my $obj = Local::MyClass->new(
	eg1 => 'eg1',
#	eg2 => 'eg2',
	eg3 => 'eg3',
)->eg1_append( 'x' )->eg2_append( 'x' )->eg3_append( 'x' );

is( $obj->eg1, 'eg1x', 'has attribute' );
is( $obj->eg2, 'eg2x', 'field attribute' );
is( $obj->eg3, 'eg3x', 'param attribute' );

done_testing;
