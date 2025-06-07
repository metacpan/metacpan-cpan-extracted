# BEGIN BPS TAGGED BLOCK {{{
#
# COPYRIGHT:
#
# This software is Copyright (c) 1996-2015 Best Practical Solutions, LLC
#                                          <sales@bestpractical.com>
#
# (Except where explicitly superseded by other copyright notices)
#
#
# LICENSE:
#
# This work is made available to you under the terms of Version 2 of
# the GNU General Public License. A copy of that license should have
# been provided with this software, but in any event can be snarfed
# from www.gnu.org.
#
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301 or visit their web page on the internet at
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.html.
#
#
# CONTRIBUTION SUBMISSION POLICY:
#
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of
# the GNU General Public License and is only of importance to you if
# you choose to contribute your changes and enhancements to the
# community by submitting them to Best Practical Solutions, LLC.)
#
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with
# Request Tracker, to Best Practical Solutions, LLC, you confirm that
# you are the copyright holder for those contributions and you grant
# Best Practical Solutions,  LLC a nonexclusive, worldwide, irrevocable,
# royalty-free, perpetual, license to use, copy, create derivative
# works based on those contributions, and sublicense and distribute
# those contributions and any derivatives thereof.
#
# END BPS TAGGED BLOCK }}}

package RT::Dashboard::Mailer;
use strict;
use warnings;
no warnings 'redefine';

use RT::Interface::CLI qw( loc );

sub SendDashboard {
    my $self = shift;
    my %args = (
        CurrentUser  => undef,
        ContextUser  => undef,
        Email        => undef,
        Subscription => undef,
        DryRun       => 0,
        @_,
    );

    my $currentuser  = $args{CurrentUser};
    my $context_user = $args{ContextUser} || $currentuser;
    my $subscription = $args{Subscription};

    my $dashboard_content = $subscription->Content || {};
    my $rows = $dashboard_content->{'Rows'};

    my $DashboardId = $subscription->DashboardId;

    my $dashboard = $subscription->DashboardObj;

    # failed to load dashboard. perhaps it was deleted or it changed privacy
    if (!$dashboard->Id) {
        $RT::Logger->warning( "Unable to load dashboard $DashboardId of subscription "
                . $subscription->Id
                . " for user "
                . $currentuser->Name );
        return $self->ObsoleteSubscription(
            %args,
            Subscription => $subscription,
        );
    }

    $RT::Logger->debug('Generating dashboard "'.$dashboard->Name.'" for user "'.$context_user->Name.'":');

    if ($args{DryRun}) {
        print << "SUMMARY";
    Dashboard: @{[ $dashboard->Name ]}
    Subscription Owner: @{[ $currentuser->Name ]}
    Recipient: <$args{Email}>
SUMMARY
        return;
    }

    local $HTML::Mason::Commands::session{CurrentUser} = $currentuser;
    local $HTML::Mason::Commands::session{ContextUser} = $context_user;
    local $HTML::Mason::Commands::session{WebDefaultStylesheet} = 'elevator';
    local $RT::Config::OVERRIDDEN_OPTIONS{WebDefaultThemeMode}  = 'light';
    local $HTML::Mason::Commands::session{_session_id}; # Make sure to not touch sessions table
    local $HTML::Mason::Commands::r = RT::Dashboard::FakeRequest->new;

    my $HasResults = undef;

    my $content = RunComponent(
        '/Dashboards/Render.html',
        id         => $dashboard->Id,
        Preview    => 0,
        HasResults => \$HasResults,
    );

    if ($dashboard_content->{'SuppressIfEmpty'}) {
        # undef means there were no searches, so we should still send it (it's just portlets)
        # 0 means there was at least one search and none had any result, so we should suppress it
        if (defined($HasResults) && !$HasResults) {
            $RT::Logger->debug("Not sending because there are no results and the subscription has SuppressIfEmpty");
            return;
        }
    }

    my @attachments;
    my $send_msexcel = $dashboard_content->{'MSExcel'};

    if ( $send_msexcel
         and $send_msexcel eq 'selected') { # Send reports as MS Excel attachments?

        $RT::Logger->debug("Generating MS Excel reports for dashboard " . $dashboard->Name);

        $content = "<p>" . loc("Scheduled reports are attached for dashboard ")
        . $dashboard->Name . "</p>";

        my @searches = $dashboard->Searches();
        local $HTML::Mason::Commands::session{CurrentUser} = $context_user;
        # Run each search and push the resulting file into the @attachments array
        foreach my $search (@searches){
            my $search_content = $search->Content;
            my $xlsx;

            if ( ( $search_content->{SearchType} // '' ) eq 'Chart' ) {
                $xlsx = RunComponent(
                    '/Search/Chart.xlsx',
                    'Query'         => $search_content->{'Query'}         || '',
                    'GroupBy'       => $search_content->{'GroupBy'}       || '',
                    'ChartFunction' => $search_content->{'ChartFunction'} || '',
                    'Class'         => $search_content->{'Class'}         || 'RT::Tickets',
                );
            }
            else {
                $xlsx = RunComponent(
                    '/Search/Results.xlsx',
                    'Query'      => $search_content->{'Query'}   || '',
                    'Order'      => $search_content->{'Order'}   || '',
                    'OrderBy'    => $search_content->{'OrderBy'} || '',
                    'Format'     => $search_content->{'Format'}  || '',
                    'Class'      => 'RT::' . ( $search_content->{'SearchType'} || 'Ticket' ) . 's',
                    'ObjectType' => $search_content->{'ObjectType'} || '',
                );
            }

            # Grab Name for RT System saved searches
            my $search_name = $search->Name;

            push @attachments, {
                Content  => $xlsx,
                Filename => $search_name . '.xlsx',
                Type     => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            };
        }
    }
    else {
        if ( RT->Config->Get('EmailDashboardRemove') ) {
            for ( RT->Config->Get('EmailDashboardRemove') ) {
                $content =~ s/$_//g;
            }
        }
    }


    $RT::Logger->debug("Got ".length($content)." characters of output.");

    $content = HTML::RewriteAttributes::Links->rewrite(
        $content,
        RT->Config->Get('WebURL') . 'Dashboards/Render.html',
    );

    $self->EmailDashboard(
        %args,
        Dashboard => $dashboard,
        Content   => $content,
        Attachments => \@attachments,
    );
}


my $original_build_email = \&RT::Dashboard::Mailer::BuildEmail;

*BuildEmail = sub {

    # First process normally
    my $entity = &$original_build_email( @_ );

    # Now add an excel attachment, if we have one
    my $self = shift;
    my %args = (
        Content => undef,
        From    => undef,
        To      => undef,
        Subject => undef,
        Attachments => undef,
        @_,
    );

    if ( defined $args{'Attachments'} and @{$args{'Attachments'}} ){
        foreach my $attachment (@{$args{'Attachments'}}){
            $entity->attach(
                Type        => $attachment->{'Type'},
                Data        => $attachment->{'Content'},
                Filename    => $attachment->{'Filename'},
                Disposition => 'attachment',
            );
        }
    }

    return $entity;
};


1;

