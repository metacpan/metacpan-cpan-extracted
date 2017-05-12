# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.
package Task::Cpanel::Kensho;
{
  $Task::Cpanel::Kensho::VERSION = '11.36.001';
}

use strict;

=head1 NAME

Task::Cpanel::Kensho - Provides all of Task::Kensho bundles including ones considered optional.

=head1 VERSION

version 11.36.001

=head1 SYNOPSIS

    cpan Task::Cpanel::Kensho

=head1 DESCRIPTION

By installing Task::Cpanel::Kensho, these Task::Kensho module bundles are installed.
This module exists becuase not all L<Task::Kensho> modules default to enabled. This
module forces them all on without any interactivity during the install process.

=over

=item L<Task::Kensho::Async|Task::Kensho::Async>

A Glimpse at an Enlightened Perl (Async)

=cut

use Task::Kensho::Async;

=item L<Task::Kensho::CLI|Task::Kensho::CLI>

A Glimpse at an Enlightened Perl (CLI)

=cut

use Task::Kensho::CLI;

=item L<Task::Kensho::Config|Task::Kensho::Config>

A Glimpse at an Enlightened Perl (Config)

=cut

use Task::Kensho::Config;

=item L<Task::Kensho::DBDev|Task::Kensho::DBDev>

A Glimpse at an Enlightened Perl (DBDev)

=cut

use Task::Kensho::DBDev;

=item L<Task::Kensho::Dates|Task::Kensho::Dates>

A Glimpse at an Enlightened Perl (Dates)

=cut

use Task::Kensho::Dates;

=item L<Task::Kensho::Email|Task::Kensho::Email>

A Glimpse at an Enlightened Perl (Email)

=cut

use Task::Kensho::Email;

=item L<Task::Kensho::ExcelCSV|Task::Kensho::ExcelCSV>

A Glimpse at an Enlightened Perl (ExcelCSV)

=cut

use Task::Kensho::ExcelCSV;

=item L<Task::Kensho::Exceptions|Task::Kensho::Exceptions>

A Glimpse at an Enlightened Perl (Exceptions)

=cut

use Task::Kensho::Exceptions;

=item L<Task::Kensho::Hackery|Task::Kensho::Hackery>

A Glimpse at an Enlightened Perl (Hackery)

=cut

use Task::Kensho::Hackery;

=item L<Task::Kensho::Logging|Task::Kensho::Logging>

A Glimpse at an Enlightened Perl (Logging)

=cut

use Task::Kensho::Logging;

=item L<Task::Kensho::ModuleDev|Task::Kensho::ModuleDev>

A Glimpse at an Enlightened Perl (ModuleDev)

=cut

use Task::Kensho::ModuleDev;

=item L<Task::Kensho::OOP|Task::Kensho::OOP>

A Glimpse at an Enlightened Perl (OOP)

=cut

use Task::Kensho::OOP;

=item L<Task::Kensho::Scalability|Task::Kensho::Scalability>

A Glimpse at an Enlightened Perl (Scalability)

=cut

use Task::Kensho::Scalability;

=item L<Task::Kensho::Testing|Task::Kensho::Testing>

A Glimpse at an Enlightened Perl (Testing)

=cut

use Task::Kensho::Testing;

=item L<Task::Kensho::Toolchain|Task::Kensho::Toolchain>

A Glimpse at an Enlightened Perl (Toolchain)

=cut

use Task::Kensho::Toolchain;

=item L<Task::Kensho::WebCrawling|Task::Kensho::WebCrawling>

A Glimpse at an Enlightened Perl (WebCrawling)

=cut

use Task::Kensho::WebCrawling;

=item L<Task::Kensho::WebDev|Task::Kensho::WebDev>

A Glimpse at an Enlightened Perl (WebDev)

=cut

use Task::Kensho::WebDev;

=item L<Task::Kensho::XML|Task::Kensho::XML>

A Glimpse at an Enlightened Perl (XML)

=cut

use Task::Kensho::XML;

=back

=head1 AUTHOR

cPanel, C<< <cpanel at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-cpanel-kensho at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Cpanel-Kensho>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Cpanel::Kensho


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Cpanel-Kensho>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Cpanel-Kensho>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Cpanel-Kensho>

=item * Meta CPAN

L<http://metacpan.org/module/Task-Cpanel-Kensho>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 cPanel.

All rights reserved

http://cpanel.net

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Task::Cpanel::Kensho
