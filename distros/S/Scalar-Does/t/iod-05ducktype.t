=head1 PURPOSE

Test IO::Detect's C<ducktype> function.

This file originally formed part of the IO-Detect test suite.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 2;

use IO::Detect ducktype => { -as => 'can_dump', methods => ['Dump'] };

use Data::Dumper;
use IO::Handle;

ok  can_dump(Data::Dumper->new([]));
ok !can_dump(IO::Handle->new);

