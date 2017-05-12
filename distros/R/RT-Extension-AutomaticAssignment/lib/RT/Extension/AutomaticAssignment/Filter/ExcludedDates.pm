package RT::Extension::AutomaticAssignment::Filter::ExcludedDates;
use 5.10.1;
use strict;
use warnings;
use base 'RT::Extension::AutomaticAssignment::Filter';

sub _UserCF {
    my $class = shift;
    my $id    = shift;

    my $cf = RT::CustomField->new(RT->SystemUser);
    $cf->LoadByCols(
        id         => $id,
        LookupType => RT::User->CustomFieldLookupType,
    );
    if (!$cf->Id) {
        die "Unable to load User Custom Field '$id'";
    }
    return $cf;
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

    if ($config->{begin} && $config->{end}) {
        my $begin_cf = $class->_UserCF($config->{begin});
        my $end_cf = $class->_UserCF($config->{end});

        my @matches;

        for my $user (@$users) {
            my $begin = $user->FirstCustomFieldValue($begin_cf);
            my $end = $user->FirstCustomFieldValue($end_cf);

            # canonicalize to unix timestamp
            if ($begin) {
                my $date = RT::Date->new(RT->SystemUser);
                $date->Set(Format => 'unknown', Value => $begin);
                $begin = $date->Unix;
            }

            if ($end) {
                my $date = RT::Date->new(RT->SystemUser);
                $date->Set(Format => 'unknown', Value => $end);
                $end = $date->Unix;
            }

            if ($begin && $end) {
                next if $begin <= $time && $time <= $end;
            }
            elsif ($begin) {
                next if $begin <= $time;
            }
            elsif ($end) {
                next if $time <= $end;
            }
            else {
                # pass through any user with no dates
            }

            push @matches, $user;
        }

        return \@matches;
    }
    else {
        die "Unable to filter ExcludedDates; both 'begin' and 'end' must be provided.";
    }
}

sub Description { "Excluded Dates" }

sub CanonicalizeConfig {
    my $class = shift;
    my $input = shift;

    my $begin = $input->{begin} || 0;
    $begin =~ s/[^0-9]//g; # allow only numeric id

    my $end = $input->{end} || 0;
    $end =~ s/[^0-9]//g; # allow only numeric id

    return { begin => $begin, end => $end };
}

1;

