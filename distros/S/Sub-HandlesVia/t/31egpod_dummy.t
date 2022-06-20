=pod

=encoding utf-8

=head1 PURPOSE

Simple test file that just calls _example() on all handlers
to ensure coverage.

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
use Test::Fatal;

my @categories = qw(
	Array
	Bool
	Code
	Counter
	Hash
	Number
	Scalar
	String
);

for my $c ( @categories ) {
	my $class = "Sub::HandlesVia::HandlerLibrary::$c";
	eval "require $class" or die($@);
	my @funcs = do { no strict 'refs'; @{"$class\::METHODS"} };
	
	for my $f ( @funcs ) {
		my $h = $class->$f;
		if ( $h->_examples ) {
			my $e = exception {
				my @eg = $h->_examples->( qw/ a b c / );
			};
			is( $e, undef, "$c->$f->_examples->( ... )" );
		}
		else {
			ok( 1, "$c->$f skipped" );
		}
	}
}

done_testing;
