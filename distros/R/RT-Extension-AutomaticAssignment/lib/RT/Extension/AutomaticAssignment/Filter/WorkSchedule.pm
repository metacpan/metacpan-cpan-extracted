package RT::Extension::AutomaticAssignment::Filter::WorkSchedule;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Filter';
use Business::Hours;

sub _IsTimeWithinBusinessHours {
    my $class  = shift;
    my $time   = shift;
    my $config = shift;
    my $tz     = shift || $RT::Timezone;

    # closely modeled off of RT::SLA

    my $res = 0;

    my $ok = eval {
        local $ENV{'TZ'} = $ENV{'TZ'};

        if ($tz && $tz ne ($ENV{'TZ'}||'') ) {
            $ENV{'TZ'} = $tz;
            require POSIX; POSIX::tzset();
        }

        my $hours = Business::Hours->new;
        $hours->business_hours(%$config);

        $res = ($hours->first_after($time) == $time);

        1;
    };

    POSIX::tzset() if $tz && $tz ne ($ENV{'TZ'}||'');
    die $@ unless $ok;

    return $res;
}

sub FiltersUsersArray {
    return 1;
}

sub FilterOwnersForTicket {
    my $class   = shift;
    my $ticket  = shift;
    my $users   = shift;
    my $config  = shift;
    my $context = shift;

    my $time = $context->{time} // time;

    if ($config->{user_cf}) {
        my @eligible;
        for my $user (@$users) {
            my $schedule = $user->FirstCustomFieldValue($config->{user_cf});
            if (!$schedule) {
                RT->Logger->debug("No value for user CF '$config->{user_cf}' for user " . $user->Name . "; skipping from WorkSchedule automatic assignment");
                next;
            }

            my $args = $RT::ServiceBusinessHours{$schedule};
            if (!$args) {
                die "No ServiceBusinessHours config defined for schedule named '$schedule' for user " . $user->Name;
            }

            my $tz = $config->{user_tz} ? $user->Timezone : $RT::Timezone;

            push @eligible, $user
                if $class->_IsTimeWithinBusinessHours($time, $args, $tz);
        }
        return \@eligible;
    }
    else {
        die "Unable to filter WorkSchedule; no 'user_cf' provided.";
    }
}

sub Description { "Work Schedule" }

sub CanonicalizeConfig {
    my $class = shift;
    my $input = shift;

    my $cf = $input->{user_cf} || 0;
    $cf =~ s/[^0-9]//g; # allow only numeric id

    return { user_cf => $cf };
}

1;

