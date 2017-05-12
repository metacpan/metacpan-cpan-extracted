package Test::Count::Lib;

use strict;
use warnings;

sub perl_plan_prefix_regex
{
    return
    qr{(?:(?:use Test.*\btests)|(?:\s*plan tests))\s*=>\s*};
}

1;

=encoding utf8

=head1 NAME

Test::Count::Lib - various commonly used routines.

=head1 FUNCTIONS

=head2 perl_plan_prefix_regex()

The regex for the perl plan. (B<Internal use.>)

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-count-parser at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Count>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Count

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Count>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Count>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Count>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Count>

=back

=head1 SEE ALSO

L<Test::Count>, L<Test::Count::Parser>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2011 Shlomi Fish.

This program is released under the following license: MIT X11.

=cut

1; # End of Test::Count::Lib
