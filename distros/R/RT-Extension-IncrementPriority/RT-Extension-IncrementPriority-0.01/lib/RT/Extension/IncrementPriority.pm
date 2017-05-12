use strict;
use warnings;
package RT::Extension::IncrementPriority;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-IncrementPriority - adds action RT::Action::IncrementPriority 
to increment a ticket's priority by one each time it is run.

=head1 DESCRIPTION

This extension adds a new Action called RT::Action::IncrementPriority 
which ignores ticket due dates and simply increments Priority by one 
(unless the ticket has already reached or exceeded FinalPriority in 
which case it does nothing). This is in contrast to 
RT::Action::LinearEscalate and RT::Action::EscalatePriority which 
both update priority based on due date. 

This is useful when tickets do not have due dates but for which it is 
nonetheless desirable to periodically increment the priority, especially 
when updates are based on some search criteria (which can be specified 
in the call to rt-crontool). 

For example, one could increment the priority of all 'new' or 'open' 
(but perhaps not 'stalled') by running rt-crontool on an hourly basis 
like this:

    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority

Like RT::Action::LinearEscalate, RT::Action::IncrementPriority can also 
be run silently (i.e. without creating a transaction or updating the 
LastUpdated timestamp). This can be accomplished by adding the argument 
UpdateLastUpdated set to 0. For example: 

    rt-crontool --search RT::Search::FromSQL \
    --search-arg "(Status='new' OR Status='open')" \
    --action RT::Action::IncrementPriority \
    --action-arg "UpdateLastUpdated: 0"

=head1 RT VERSION

Works with RT 4.0 and 4.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::IncrementPriority');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::IncrementPriority));

or add C<RT::Extension::IncrementPriority> to your existing C<@Plugins> line.

=item Restart your webserver

=back

=head1 AUTHORS

Joshua C. Randall E<lt>jcrandall@alum.mit.eduE<gt>

Kevin Riggle E<lt>kevinr@bestpractical.comE<gt>

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-IncrementPriority@rt.cpan.org|mailto:bug-RT-Extension-IncrementPriority@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-IncrementPriority>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 Genome Research Ltd.

Copyright (c) 1996-2014 Best Practical Solutions, LLC
                        <sales@bestpractical.com>

This work is made available to you under the terms of Version 2 of
the GNU General Public License. A copy of that license should have
been provided with this software, but in any event can be snarfed
from www.gnu.org.

This work is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 or visit their web page on the internet at
http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.

=cut

1;
