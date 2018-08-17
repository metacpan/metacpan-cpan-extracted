=pod

=encoding utf-8

=head1 PURPOSE

Check that error locations are correctly reported.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

eval q{
#line 29 "03errlocations.eval"
package Local::Foo;
use PerlX::Define;
define FOO => 1;
define FOO => 2;
};

like($@, qr/redefined at 03errlocations.eval line 3[123]/); # line 32, but be a little flexible

done_testing;
