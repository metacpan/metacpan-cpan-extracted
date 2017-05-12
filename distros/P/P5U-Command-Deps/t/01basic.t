=head1 PURPOSE

Checks that P5U::Command::Deps compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 1;
BEGIN { use_ok('P5U::Command::Deps') };

use P5U::Command::Deps;
