=pod

=encoding utf-8

=head1 PURPOSE

Test that Sub::MultiMethod works with newer Type::Params features like
C<head> and C<tail>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires { 'Type::Params' => '1.012000' };


my $got;

{
	package My::Class;
	use Sub::MultiMethod multimethod => { -as => 'mm' };
	use Types::Standard -types;
	
	mm test1 => (
		named => 1,
		method => 1,
		signature => [
			{ head => [ ArrayRef ], tail => [ HashRef, HashRef ] },
			foo => Int,
		],
		code => sub {
			my ( $self, $aref, $args, $href1, $href2 ) = @_;
			$got = $args->foo;
		},
	);
}

My::Class->test1( [], foo => 42, {}, {} );

is( $got, 42 );

done_testing;

