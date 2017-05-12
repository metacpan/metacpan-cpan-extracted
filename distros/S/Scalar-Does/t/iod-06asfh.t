=head1 PURPOSE

Test C<as_filehandle> works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use IO::Detect as_filehandle => { mode => "<:encoding(UTF-8)" };

my $fh = as_filehandle(__FILE__);

while (<$fh>) {
	pass("found COPYRIGHT line") if /COPYRIGHT [A][N][D] LICENCE/;
}

done_testing();
