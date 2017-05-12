=pod

=encoding utf-8

=head1 PURPOSE

Test that MooseX::Exception::Rot13 compiles.

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

like(
	exception {
		package Goose1;
		use Moose;
		has xxx => (is => 'yyy');
	},
	qr{\A(I do not understand this option)},
);

use_ok('MooseX::Exception::Rot13');

like(
	exception {
		package Goose2;
		use Moose;
		has xxx => (is => 'yyy');
	},
	qr{\A(V qb abg haqrefgnaq guvf bcgvba)},
);

done_testing;

