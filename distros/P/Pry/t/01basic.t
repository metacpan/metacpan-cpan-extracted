=pod

=encoding utf-8

=head1 PURPOSE

Test that Pry compiles.

If you set the EXTENDED_TESTING environment variable to true, this file
will also perform an interactive test to determine if Pry is working.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Pry') };

if ( $ENV{EXTENDED_TESTING} and not $ENV{NONINTERACTIVE_TESTING} ) {
	my $x = 1;
	diag("==============================================================");
	diag("YOU MUST TYPE ++\$x, PRESS ENTER, THEN CTRL+D TO PASS THE TEST");
	diag("==============================================================");
	pry;
	is($x, 2);
}

done_testing;
