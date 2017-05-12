=pod

=encoding utf-8

=head1 PURPOSE

Test that Switcheroo works nicely with L<Type::Tiny>.

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
use Test::Requires { 'Types::Standard' => '0.001' };

use Switcheroo;
use Types::Standard -types;

sub my_ref
{
	my $value = shift;
	
	switch ($value) {
		case ArrayRef:  "ARRAY";
		case HashRef:   "HASH";
		case ScalarRef: "SCALAR";
		default:        undef;
	}
}

is( my_ref([]), "ARRAY" );
is( my_ref({}), "HASH" );
is( my_ref(\1), "SCALAR" );
is( my_ref(undef), undef );

done_testing;

