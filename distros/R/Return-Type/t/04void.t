=pod

=encoding utf-8

=head1 PURPOSE

Test C<< :ReturnType(Void) >>.

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
use Test::Fatal;

use Return::Type;
use Types::Standard -types;

sub foo :ReturnType(Void) {
	return 42;
}

is(
	exception { foo(); undef; },
	undef,
	'called in void context; no exception'
);

like(
	exception { my $x = foo(); },
	qr/did not pass type constraint/,
	'called in scalar context; exception'
);

like(
	exception { my @x = foo(); },
	qr/did not pass type constraint/,
	'called in list context; exception'
);

done_testing;
