=head1 PURPOSE

Check C<lazy_default> from C<MooX::Struct::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More;

use MooX::Struct::Util qw/ lazy_default /;
use MooX::Struct Point => [ '+x', '+y' ];
use MooX::Struct Line  => [ '$start' => lazy_default { Point[] }, '$end' ];

my $line = Line->new( end => Point[ 2, 3 ] );
is("$line", "0 0 2 3");

done_testing();