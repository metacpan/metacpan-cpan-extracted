package RT::Extension::EscalationDates;

use 5.010;
use warnings;
use strict;

our $VERSION = '0.4';


=head1 NAME

C<RT::Extension::EscalationDates> - Set start and due time automatically when
creating a ticket


=head1 DESCRIPTION

This RT Extension sets start and due time when creating a ticket via the web
interface. It provides handling business hours defined in RT site configuration
file.


=head1 INSTALLATION

This extension based on the following modules:

    RT >= 4.0.0
    Date::Manip >= 6.25

To install this extension, run the following commands:

    perl Makefile.PL
    make
    make test
    make install
    make initdb

Note: Please read the following section before initiating the database.


=head1 CONFIGURATION


=head2 RT SITE CONFIGURATION

To enable this extension edit the RT site configuration located in
C<$RT_HOME/etc/RT_SiteConfig.pm> (where C<$RT_HOME> is the path to your RT
installation):

    Set(@Plugins,qw(RT::Extension::EscalationDates));

Note: If you use C<make initdb> during L<installation|/"INSTALLATION"> you'll
create a custom field with the name 'Priority' so it's unnecessary to
create one manually. This custom field provides the values 'A' till 'D'.

Add the custom field with your priorities to your configuration:

    Set($PriorityField, 'Priority');

Also you must define several priorities and relative dates for escalations:

    Set(%EscalateTicketsByPriority, ( 
        'A' => 'in 2 business hours',
        'B' => 'in 22 business hours',
        'C' => 'in 70 business hours',
        'D' => 'in 468 business hours'
    ));

Additionally you must define a default priority used when creating a ticket:

    Set($DefaultPriority, 'C');

Use only already configured priorities from C<%EscalateTicketsByPriority>, for
example C<C>.

To overwrite C<Date::Manip>'s default configuration you may set the following:

    Set(%DateManipConfig, (
        'WorkDayBeg', '9:00',
        'WorkDayEnd', '17:00', 
        #'WorkDay24Hr', '0',
        #'WorkWeekBeg', '1',
        #'WorkWeekEnd', '7'
    ));

You can find more information about the configurable parameters under
L<http://search.cpan.org/dist/Date-Manip/lib/Date/Manip/Config.pod#BUSINESS_CONFIGURATION_VARIABLES>.

After all your new configuration will take effect after restarting your RT
environment:

    rm -rf $RT_HOME/var/mason_data/obj/* && service apache2 restart

This is an example for deleting the mason cache and restarting the Apache HTTP
web server on a Debian GNU/Linux based operating system.


=head1 AUTHOR

Benjamin Heisig, E<lt>bheisig@synetics.deE<gt>


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the C<perldoc> command.

    perldoc RT::Extension::EscalationDates

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-EscalationDates/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-EscalationDates>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-EscalationDates>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-EscalationDates>

=back


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.


=head1 COPYRIGHT AND LICENSE

Copyright 2011 synetics GmbH, E<lt>http://i-doit.org/E<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=head1 SEE ALSO

    RT
    Date::Manip
    RT::Action::EscalationDates


=cut

1;
