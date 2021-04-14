=pod

=encoding utf-8

=head1 PURPOSE

Demonstrate that Mom ignores :rwp (RT134617)

=head1 AUTHOR

Brian Greenfield E<lt>briang at cpan dot orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Brian Greenfield.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
	package Foo;
	use Mom 'foo :rwp';
}

my $obj = Foo->new( foo => 1 );

is $obj->foo, 1, "can get a :rwp attribute";

my $e = exception {
	$obj->foo(2);
};

like( $e, qr/(read-only|^Usage)/, 'attempt to set :rwp attribute' );

done_testing;
