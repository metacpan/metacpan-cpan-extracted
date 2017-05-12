=head1 PURPOSE

Checks that MooX::Struct itself can be instantiated and works as expected.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

use MooX::Struct;

my $obj = MooX::Struct->new;
is($obj->TYPE, undef);
is_deeply([$obj->FIELDS], []);

done_testing;
