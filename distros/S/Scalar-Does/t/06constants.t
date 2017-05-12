=head1 PURPOSE

Check that Scalar::Does exports constants for built-in roles, and that they
work.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use Scalar::Does -constants;

my $var = "Hello world";

ok does(\$var, SCALAR);
ok does([], ARRAY);
ok does(+{}, HASH);
ok does(sub {0}, CODE);
ok does(\*STDOUT, GLOB);
ok does(\(\"Hello"), REF);
ok does(\(substr($var,0,1)), LVALUE);
ok does(\*STDOUT, IO);
ok does(qr{x}, REGEXP);
ok does(1, BOOLEAN);
ok does(1, STRING);
ok does(1, NUMBER);
ok does(1, SMARTMATCH);

if ($] >= 5.012)
{
	ok does(\v1.2.3, VSTRING);
}
else
{
	pass( "VSTRING test skipped on older Perls" );
}

done_testing;

