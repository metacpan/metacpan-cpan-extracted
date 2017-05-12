package RT::Extension::ToggleSuperUser;

use warnings;
use strict;

=head1 NAME

RT::Extension::ToggleSuperUser - allow users with SuperUser right to quickly enable/disable this right.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This RT Extension allow users with SuperUser right to quickly enable/disable
this right with a simple link at the top of each page. This way, they can work
like standard users for day to day usage and enable SuperUser right only when
needed.

=head1 AUTHOR

Emmanuel Lacour, C<< <elacour at home-dn.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rt-extension-ToggleSuperUser at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RT-Extension-ToggleSuperUser>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RT::Extension::ToggleSuperUser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-ToggleSuperUser>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-ToggleSuperUser>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-ToggleSuperUser>

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-ToggleSuperUser>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Emmanuel Lacour, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.

=cut

1; # End of RT::Extension::ToggleSuperUser
