package RT::Extension::StallFutureTicket;

use 5.010;
use warnings;
use strict;

our $VERSION = '0.3';


=head1 NAME

RT::Extension::StallFutureTicket - Stall a new ticket automatically when start
time is set to a future date


=head1 DESCRIPTION

This RT Extension allows to automatically stall created tickets with a start
time in the future.


=head1 INSTALLATION

This extension based on the following modules:

    RT >= 4.0.0
    Date::Manip >= 6.25

To install this extension, run the following commands:

    perl Makefile.PL
    make
    make test
    make install


=head1 CONFIGURATION


=head2 RT SITE CONFIGURATION

To enable this extension edit the RT site configuration located in
C<$RT_HOME/etc/RT_SiteConfig.pm> (where C<$RT_HOME> is the path to your RT
installation):

    Set(@Plugins,qw(RT::Extension::StallFutureTicket));

You must allow to set new tickets to C<stalled>:

    Set(%Lifecycles,
        default => {

            [...]

            transitions => {
                ''       => [qw(new open resolved stalled)],
                [...]
            }
            [...]
        }
    );

This is just an abbreviation taken from RT's main configuration file under
C<$RT_HOME/etc/RT_Config.pm>. Note the added C<stalled>.

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

    perldoc RT::Extension::StallFutureTicket

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-StallFutureTicket/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-StallFutureTicket>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-StallFutureTicket>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-StallFutureTicket>

=back


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.


=head1 COPYRIGHT AND LICENSE

Copyright 2011 synetics GmbH, E<lt>http://i-doit.org/E<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=cut

1;
