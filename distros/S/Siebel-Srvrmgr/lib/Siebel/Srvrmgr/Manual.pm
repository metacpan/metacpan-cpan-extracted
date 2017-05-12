package Siebel::Srvrmgr::Manual;
use warnings;
use strict;
our $VERSION = '0.29'; # VERSION

=head1 NAME

Siebel::Srvrmgr::Manual - general instructions how to use this distribution

=head1 DESCRIPTION

After some feedback from users of this distribution, I decided that only the Pod available is not enough, end
users require some introductory guidance to know what to look for.

Assuming that the reader already knows what this distribution is about, for any interaction that you need to have
with Siebel Server Manager (srvrmgr), you will need to use this general receipt:

=over

=item 1.

Decide if you need to connect or not to the Siebel Enterprise.

If you want to connect, it is a matter of choice to
use L<Siebel::Srvrmgr::Daemon::Heavy> or L<Siebel::Srvrmgr::Daemon::Light>. The later should be your initial choice if
you're not really sure what to use.

If you already have a sample output file saved with C<spool> command from srvrmgr, you might want to use L<Siebel::Srvrmgr::Daemon::Offline>.

=item 2.

Decide what data you need from srvrmgr.

For that, you must have clear definition of your objectives: do you want to check Siebel components state? Check how long tasks are taking to finish?

This will define the next step.

=item 3.

Knowing the desired data, you now have to decide what to do with it.

For each command you execute on srvrmgr (L<Siebel::Srvrmgr::Daemon::Command>), you must define which action (L<Siebel::Srvrmgr::Daemon::Action>) to execute with it's output.

There are plently of subclasses from L<Siebel::Srvrmgr::Daemon::Action> already available, or you may want to write your own. In most cases you might start with
L<Siebel::Srvrmgr::Daemon::ActionStash> and later define if you can restrict your activities inside your own subclass.

=item 4.

Create an instance of a subclass of L<Siebel::Srvrmgr::Daemon> (with your definitions from the steps above) and execute it (invoke the C<run> method). For classes that require a connection, you will need to pass
a instance of L<Siebel::Srvrmgr::Connection> to the C<run> method.

That's it. There are examples of implementations on the distribution unit tests if you want to check. There is also an integration test in the "xt" (extended) tests directory that you could use with
your environment. Be sure to check those tests and read L<Test::Fixtures> module under this directory.

There is also other distributions based on L<Siebel::Srvrmgr> that you may want to check before start writing your own:

=over

=item *

L<Siebel::Params::Checker>

=item *

L<Siebel::Srvrmgr::Exporter>

=item *

L<Siebel::Lbconfig>

=back

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
