package RT::Extension::HideWidgets;


use warnings;
use strict;

=head1 NAME

RT::Extension::HideWidgets - Allow admin to hide widgets per user, group and role.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use RT::System;

# TODO : use loc and create a po file

=head1 SYNOPSIS

The HideWidgets RT Extension allow admins to hide widgets per user, group and role.
Once installed, new rights will appear in the following administration panels:
- Administration->Global->Group Rights
- Administration->Global->Users Rights

=head1 AUTHOR

Neil Orley, C<< <neil.orley at oeris.fr> >>

=cut

# Fixed TT : [rt.cpan.org #97596] Unimplemented in RT::Extension::HideWidgets
#RT::System::AddRights(
#    OerisHideWidgetBasics       => "[".__PACKAGE__."] - Hide widget 'Basics' for 'Privileged' and 'SelfService' users",
#    OerisHideWidgetPeople       => "[".__PACKAGE__."] - Hide widget 'People' for 'Privileged' users",
#    OerisHideWidgetReminders    => "[".__PACKAGE__."] - Hide widget 'Reminders' for 'Privileged' users",
#    OerisHideWidgetDates        => "[".__PACKAGE__."] - Hide widget 'Dates' for 'Privileged' and 'SelfService' users",
#    OerisHideWidgetLinks        => "[".__PACKAGE__."] - Hide widget 'Links' for 'Privileged' users",
#    OerisHideWidgetAttach       => "[".__PACKAGE__."] - Hide widget 'Attachments' for 'Privileged' users",
#    OerisHideWidgetRequestor    => "[".__PACKAGE__."] - Hide widget 'Requestor' for 'Privileged' users"
#);

#RT::System::AddRightCategories(
#    OerisHideWidgetBasics       => 'General',
#    OerisHideWidgetPeople       => 'General',
#    OerisHideWidgetReminders    => 'General',
#    OerisHideWidgetDates        => 'General',
#    OerisHideWidgetLinks        => 'General',
#    OerisHideWidgetAttach       => 'General',
#    OerisHideWidgetRequestor    => 'General'
#);


# Work only for RT 4.2.5
'RT::System'->AddRight( General => OerisHideWidgetBasics       => "[".__PACKAGE__."] - Hide widget 'Basics' for 'Privileged' and 'SelfService' users");
'RT::System'->AddRight( General => OerisHideWidgetDates        => "[".__PACKAGE__."] - Hide widget 'Dates' for 'Privileged' and 'SelfService' users"); 
'RT::System'->AddRight( General => OerisHideWidgetPeople       => "[".__PACKAGE__."] - Hide widget 'People' for 'Privileged' users");
'RT::System'->AddRight( General => OerisHideWidgetReminders    => "[".__PACKAGE__."] - Hide widget 'Reminders' for 'Privileged' users"); 
'RT::System'->AddRight( General => OerisHideWidgetLinks        => "[".__PACKAGE__."] - Hide widget 'Links' for 'Privileged' users"); 
'RT::System'->AddRight( General => OerisHideWidgetAttach       => "[".__PACKAGE__."] - Hide widget 'Attachments' for 'Privileged' users");
'RT::System'->AddRight( General => OerisHideWidgetRequestor    => "[".__PACKAGE__."] - Hide widget 'Requestor' for 'Privileged' users");

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::HideWidgets');

For RT 3.8 and 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::HideWidgets));

or add C<RT::Extension::HideWidgets> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-rt-extension-hidewidgets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RT-Extension-HideWidgets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RT::Extension::HideWidgets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RT-Extension-HideWidgets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RT-Extension-HideWidgets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RT-Extension-HideWidgets>

=item * Search CPAN

L<http://search.cpan.org/dist/RT-Extension-HideWidgets/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Neil Orley.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of RT::Extension::HideWidgets
