# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

package Task::Cpanel;
{
  $Task::Cpanel::VERSION = '11.36.001';
}

use strict;
use warnings;

=head1 NAME

Task::Cpanel - Brings in all Perl modules which are RPM packaged and shipped with B<cPanel & WHM> and B<EasyApache>.

=head1 VERSION

version 11.36.001

=head1 SYNOPSIS

    cpan Task::Cpanel;

=head1 DESCRIPTION

Installation of this package brings in all Perl modules which are RPM packaged and shipped with B<cPanel & WHM> and B<EasyApache>.

The first two numbers of this version (eg: 11.36) refer to the major version of B<cPanel & WHM> it applies to.

=head2 MODULES NEEDED

=over

=item L<Task::Cpanel::3rdparty|Task::Cpanel::3rdparty>

Modules requested by 3rdparty integrators

=cut

use Task::Cpanel::3rdparty;

=item L<Task::Cpanel::Catalyst|Task::Cpanel::Catalyst>

Modules provided for Catalyst support

=cut

use Task::Cpanel::Catalyst;

=item L<Task::Cpanel::Core|Task::Cpanel::Core>

Modules provided for core cPanel support

=cut

use Task::Cpanel::Core;

=item L<Task::Cpanel::Internal|Task::Cpanel::Internal>

Modules provided for B<cPanel & WHM> development by cPanel

=cut

use Task::Cpanel::Internal;

=item L<Task::Cpanel::Kensho|Task::Cpanel::Kensho>

All modules provided by Task::Kensho

=cut

use Task::Cpanel::Kensho;

=back

=head1 AUTHOR

cPanel, C<< <cpanel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-cpanel at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Cpanel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Cpanel>

=item * Meta CPAN

L<http://metacpan.org/module/Task-Cpanel>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.                  

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Task::Cpanel
