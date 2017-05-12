package RT::Extension::FollowUp;

use warnings;
use strict;

=head1 NAME

RT::Extension::FollowUp - Allow RT users to quickly add
themself as Cc/AdminCc in the ticket action menu

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This RT Extension adds two actions to the ticket actions
menu to allow the connected user with enough rights to add
himself as a Cc or AdminCc for this ticket.

=head1 AUTHOR

Emmanuel Lacour, C<< <elacour at home-dn.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rt-extension-FollowUp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RT-Extension-FollowUp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RT::Extension::FollowUp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-FollowUp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-FollowUp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-FollowUp>

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-FollowUp>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013 Emmanuel Lacour, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.

=cut

1; # End of RT::Extension::FollowUp
