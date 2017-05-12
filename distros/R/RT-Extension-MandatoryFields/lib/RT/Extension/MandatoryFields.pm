package RT::Extension::MandatoryFields;

use 5.008;
use warnings;
use strict;

our $VERSION = '0.6';


=head1 NAME

RT::Extension::MandatoryFields - Enforce users to fill standard fields when
creating a ticket


=head1 DESCRIPTION

This RT Extension enforces users to fill standard fields defined in RT site
configuration file when creating a ticket via the web interface. Filling can be
enforced on tickets created in specified queues only. 

Note: This extension does not take effect on custom fields. RT has already a
built-in feature to mark custom fields as mandatory.


=head1 INSTALLATION

This extension requires RT >= 4.0.0. To install this extension, run the
following commands:

    perl Makefile.PL
    make
    make test
    make install


=head1 CONFIGURATION


=head2 RT SITE CONFIGURATION

To enable this extension edit the RT site configuration located in
C<$RT_HOME/etc/RT_SiteConfig.pm> (where C<$RT_HOME> is the path to your RT
installation):

    Set(@Plugins,qw(RT::Extension::MandatoryFields));

To enforce users to fill the standard fields add them to C<%MandatoryFields>:

    Set(%MandatoryFields, (
        'Requestors' => 'true',
        'Cc' => 'true',
        'AdminCc' => 'true',
        'Subject' => 'true',
        'Content' => 'true',
        'Attach' => 'true',
        'Status' => 'true',
        'Queue' => 'true',
        'Owner' => 'true',
        'Priority' => 'true',
        'InitialPriority' => 'true',
        'FinalPriority' => 'true',
        'TimeEstimated' => 'true',
        'TimeWorked' => 'true',
        'TimeLeft' => 'true',
        'Starts' => 'true',
        'Due' => 'true',
        'new-DependsOn' => 'true',
        'DependsOn-new' => 'true',
        'new-MemberOf' => 'true',
        'MemberOf-new' => 'true',
        'new-RefersTo' => 'true',
        'RefersTo-new' => 'true'
    ));

Mark a mandatory field with C<true>, otherwise C<false>.

To specify the queues where fields are mandatory, list their identifiers in
C<%MandatoryFields>. The keyword C<all> has the same effect as C<true>:

    Set(%MandatoryFields, (
        'Requestors' => 'all',
        'Cc' => [1],
        'AdminCc' => [1, 2, 3]
    ));

Note: There are more than one way to create a new ticket. The default way is
C<Create>, but there are C<QuickCreate> on the home page and C<SelfService> for
unpreviledged users, too. This extension handles them all. If a formular doesn't
include one of the fields marked as mandatory (set to C<true> in the
configuration) it will be ignored. Don't get confused if you set a mandatory
field that won't show up on the web interface. The table below gives you a short
summarize which formular supports which mandatory field.

    Field             Create        QuickCreate     SelfService
    ----------------  ----------    --------------  --------------
    Requestors        included      included        included
    Cc                included      not included    included
    AdminCc           included      not included    not included
    Subject           included      included        included
    Content           included      included        included
    Attach            included      not included    included
    Queue             not editable  included        not editable
    Status            included      not included    not included
    Owner             included      included        not included
    Priority          included      not included    not included
    InitialPriority   included      not included    not included
    FinalPriority     included      not included    not included
    TimeEstimated     included      not included    not included
    TimeWorked        included      not included    not included
    TimeLeft          included      not included    not included
    Starts            included      not included    not included
    Due               included      not included    not included
    new-DependsOn     included      not included    not included
    (depends on)
    DependsOn-new     included      not included    not included
    (depended on by)
    new-MemberOf      included      not included    not included
    (parents)
    MemberOf-new      included      not included    not included
    (children)
    new-RefersTo      included      not included    not included
    (refers to)
    RefersTo-new      included      not included    not included
    (referred to by)

After all your new configuration will take effect after restarting your RT
environment:

    rm -rf $RT_HOME/var/mason_data/obj/* && service apache2 restart

This is an example for deleting the mason cache and restarting the Apache HTTP
web server on a Debian GNU/Linux based operating system.


=head1 AUTHOR

Benjamin Heisig, E<lt>bheisig@synetics.deE<gt>


=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the C<perldoc> command.

    perldoc RT::Extension::MandatoryFields

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-MandatoryFields/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-MandatoryFields>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-MandatoryFields>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-MandatoryFields>

=back


=head1 BUGS

Please report any bugs or feature requests to the L<author|/"AUTHOR">.


=head1 ACKNOWLEDGEMENTS

This extension is a fork of L<RT::Extension::MandatorySubject> written by
Emmanuel Lacour.

Thanks to  Davide Imbeni, E<lt>davide.imbeni@gmail.com<gt> for his great
contribution!


=head1 COPYRIGHT AND LICENSE

Copyright 2011 synetics GmbH, E<lt>http://i-doit.org/E<gt>

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Request Tracker (RT) is Copyright Best Practical Solutions, LLC.


=head1 SEE ALSO

    RT
    RT::Extension::MandatorySubject


=cut

1;
