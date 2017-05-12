=head1 PURPOSE

Check that the constructor is strict (throws an error if it sees unknown
attributes).

This test is currently disabled, as the constructor is no longer strict.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More skip_all => 'no longer valid';
use MooX::Struct Thingy => [qw/ $x /];

ok not eval { my $thingy = Thingy->new(y => 1) };
