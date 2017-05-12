package RT::Extension::UserDetails;

use warnings;
use strict;

=head1 NAME

RT::Extension::UserDetails - allows to quickly display watchers personnal details on a ticket

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This RT Extension adds a button on each user listed in "Watcher" box of the
ticket display page. Clicking on this button shows a css window with
personnal informations about this users such as its Name, Email, ...

=head1 AUTHOR

Emmanuel Lacour, C<< <elacour at home-dn.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rt-extension-UserDetails at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RT-Extension-UserDetails>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RT::Extension::UserDetails


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-UserDetails>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-UserDetails>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-UserDetails>

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-UserDetails>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010-2014 Emmanuel Lacour, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.

=cut

1; # End of RT::Extension::UserDetails
