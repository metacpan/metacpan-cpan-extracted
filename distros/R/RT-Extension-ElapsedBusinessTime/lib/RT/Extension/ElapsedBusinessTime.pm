use warnings;
use strict;

package RT::Extension::ElapsedBusinessTime;

our $VERSION = '0.03';

=head1 NAME

RT-Extension-ElapsedBusinessTime - Calculate the elapsed business time that tickets are open

=head1 DESCRIPTION

This extension provides for new colummns in reports that display the elapsed
business time that a ticket has been open. Various items are configurable
to define what constitutes a business day.

=head1 RT VERSION

Works with RT 4.4.x, not tested with 4.6.x yet.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::ElapsedBusinessTime');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

The available configuration options, with their defaults are given here.

    Set( %ElapsedBusinessTime,
        Start   => '08:30',
        End     => '17:30',
        Country => undef,
        Region  => undef,
        'Exclude Days'   => [6, 7],
        'Exclude States' => ['stalled', 'blocked', 'resolved', 'rejected', 'deleted'],
    );
  
Options are:

=over

=item Start

The start of the business day.

=item End

The end of the business day.

=item Country

A country for which there is a Date::Holidays module which describes the
holidays for that country. If there isn't one, please consider writing one!
For example 'NZ' for New Zealand.

=item Region

Some country modules for Date::Holidays include regions for regional holidays.
For example 'Wellington' within New Zealand for Wellington Anniversary Day.

=item Excluded Days

Days which should not be considered working days. The day numbers are from
DateTime. For reference they are:

    1: Monday
    2: Tuesday
    3: Wednesday
    4: Thursday
    5: Friday
    6: Saturday
    7: Sunday

=item Excluded States

Which a ticket is in one of these states, then it is considered inactive
and the counter stops. This is to allow when a ticket is waiting on a
customers feedback, and for some businesses, that time shouldn't be added
to their ticket duration time.

=back

=head1 DISPLAY COLUMNS

There are three display columns which this extension adds, which all show
the same information, just in different formats:

=over

=item ElapsedBussinessHours

=item ElapsedBussinessMinutes

=item ElapsedBussinessTime

=back

=head1 AUTHOR

Andrew Ruthven, Catalyst Cloud Ltd E<lt>puck@catalystcloud.nzE<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-ElapsedBusinessTime@rt.cpan.org">bug-RT-Extension-ElapsedBusinessTime@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ElapsedBusinessTime">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-ElapsedBusinessTime@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-ElapsedBusinessTime

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Catalyst Cloud Ltd

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

use Set::Object;
use Try::Tiny;

my $ebt_config = RT->Config->Get('ElapsedBusinessTime') || {};
our $start_time = $ebt_config->{'Start'} || '08:30';
our $end_time   = $ebt_config->{'End'}   || '17:30';

# 6 = Saturday, 7 = Sunday, see DateTime
our $not_business_days = Set::Object->new(
  @{$ebt_config->{'Exclude Days'} || [6, 7]}
);

# Set no default!
our $country = $ebt_config->{'Country'};
our $region  = $ebt_config->{'Region'};

our $excluded_states = Set::Object->new(
  @{$ebt_config->{'Exclude States'} || ['stalled', 'blocked', 'resolved', 'rejected', 'deleted']}
);

our $dh = undef;
try {
    use Date::Holidays;
    $dh = Date::Holidays->new(
        countrycode => $country,
    );

    $dh->is_holiday(year => 2017, month => 1, day => 1);
} catch {
    RT->Logger->error("Unable to instantiate Date::Holidays: $_");
    $dh = undef;
};

sub calc {
    my $class = shift;
    my %args = (
        Ticket => undef,
        CurrentUser => undef,
        DurationAsString => 0,
        Show => 4,
        Short => 1,
        Units => 'Minute',
        @_
    );

    my $elapsed_business_time = 0;
    my $last_state_change = $args{Ticket}->CreatedObj;
    my $clock_running = 1;

    my $transactions = $args{Ticket}->Transactions;
    while (my $trans = $transactions->Next) {
#        RT->Logger->debug("Ticket: ", $trans->ObjectId, ", Transaction: ", $trans->id, ", Type: ". $trans->Type);
        if ($trans->Type eq 'Status') {
#            RT->Logger->debug("Field: ", $trans->Field, ", Old: ", $trans->OldValue, ", New: ". $trans->NewValue, ", Created: ", $trans->CreatedObj->W3CDTF);
            if ($clock_running && $excluded_states->includes($trans->NewValue)) {
#                RT->Logger->debug("  excluded state, stop the clock!");
                $clock_running = 0;

                $elapsed_business_time += calc_elapsed($last_state_change, $trans->CreatedObj)

            } elsif (! $clock_running && ! $excluded_states->includes($trans->NewValue)) {
#                RT->Logger->debug("  included state, start the clock!");
                $clock_running = 1;
                $last_state_change = $trans->CreatedObj;
            }
        }
    };

    if ($clock_running) {
#        RT->Logger->debug("  clock still running, but no more transactions, add to now");
        my $now = RT::Date->new($args{CurrentUser}->UserObj);
        $now->SetToNow;
#        RT->Logger->debug("  last_state_change: ", $last_state_change->W3CDTF, ", now: ", $now->W3CDTF);
        $elapsed_business_time += calc_elapsed($last_state_change, $now)
    }

    if ($args{DurationAsString}) {
        return $last_state_change->DurationAsString(
            $elapsed_business_time,
            Show => $args{Show},
            Short => $args{Short},
        );
    } else {
        if ($args{Unets} eq 'Hour') {
            return sprintf("%d:%02d", int($elapsed_business_time / 3600), ($elapsed_business_time % 3600) / 60);
        } elsif ($args{Units} eq 'Second') {
            return $elapsed_business_time;
        } else {
            return sprintf("%d:%02d", int($elapsed_business_time / 60), $elapsed_business_time % 60);
        }
    }
}

sub calc_elapsed {
    my ($last_state_change, $current_date) = @_;
    my $elapsed_business_time = 0;

    # Track the timezone so we can propogate it later.
    my $timezone = $current_date->Timezone('user');

    # Work out the difference between $last_state_change_time and $trans->Created counting only business hours and skipping weekends and holidays. How hard can that be?!;
    my $dt_current_date = $current_date->DateTimeObj;
    $dt_current_date->set_time_zone($timezone);

    my $dt_working = $last_state_change->DateTimeObj;
    $dt_working->set_time_zone($timezone);

    $last_state_change = $current_date;

#    RT->Logger->debug("trying to add time from ", $dt_working->strftime("%FT%T %Z"), " until ", $dt_current_date->strftime("%FT%T %Z"));

    while ($dt_working < $dt_current_date) {

        if ($not_business_days->includes($dt_working->day_of_week)) {
#            RT->Logger->debug("Not business day (", $dt_working->ymd, "), skip");
            next;
        }

        my ($year, $month, $day) = split(/-/, $dt_working->ymd);
        if (defined $dh && $dh->is_holiday(year => $year, month => $month, day => $day, region => $region)) {
#            RT->Logger->debug("holiday (", $dt_working->ymd, "), skip");
            next;
        }

        my $day_start;
        if (defined $start_time && $start_time =~ /^(\d+)(?::(\d+)(?::(\d+))?)?$/) {
            my $bus_start_time = $dt_working->clone;
         
            $bus_start_time->set_hour($1);
            $bus_start_time->set_minute($2 || 0);
            $bus_start_time->set_second($3 || 0);

            if ($dt_current_date <= $bus_start_time) {
#                RT->Logger->debug("end of work is before business day begins, skip");
                next;
            } elsif ($dt_working > $bus_start_time) {
#                RT->Logger->debug("start of work is after business day begins");
                $day_start = $dt_working;
            } else {
#                RT->Logger->debug("start of work is before business day begins");
                $day_start = $bus_start_time;
            }
        }

#        RT->Logger->debug("going to add time for: (", $dt_working->ymd, ")");

        my $day_end;
        if (defined $end_time && $end_time =~ /^(\d+)(?::(\d+)(?::(\d+))?)?$/) {
            my $bus_end_time = $dt_working->clone;

            $bus_end_time->set_hour($1);
            $bus_end_time->set_minute($2 || 0);
            $bus_end_time->set_second($3 || 0);

            if ($dt_current_date <= $bus_end_time) {
#                RT->Logger->debug("end of work is before business day ends");
                $day_end = $dt_current_date;
            } elsif (defined $day_start && $day_start > $bus_end_time && $dt_current_date > $bus_end_time) {
#                RT->Logger->debug("start and end of work is after business day ends, skip this change");
                next;
            } else {
#                RT->Logger->debug("end of work is after business day ends, or another day, use $end_time");
                $day_end = $bus_end_time;
            }
        }

        my $delta = $day_end - $day_start;
#        RT->Logger->debug("  day_start: ", $day_start->strftime("%FT%T %Z"), ", day_end: ", $day_end->strftime("%FT%T %Z"), ", delta: ", $delta->deltas, ", running elapsed_business_time: $elapsed_business_time");

        # We'll ignore leap seconds.
        my ($minutes, $seconds) = $delta->in_units('minutes', 'seconds');
        $elapsed_business_time += ($minutes * 60) + $seconds;
    } continue {
        $dt_working->add( days => 1 );
        $dt_working->set( hour => 0, minute => 0, second => 0 );
    }

    return $elapsed_business_time;
}

1;
