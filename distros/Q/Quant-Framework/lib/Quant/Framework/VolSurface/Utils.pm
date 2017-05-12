package Quant::Framework::VolSurface::Utils;

=head1 NAME

Quant::Framework::VolSurface::Utils

=head1 DESCRIPTION

Some general vol-related utility functions.

=head1 SYNOPSIS

  my $utils = Quant::Framework::VolSurface::Utils->new;

=cut

use Moose;

use DateTime::TimeZone;
use Date::Utility;

=head2 NY1700_rollover_date_on

Returns (as a Date::Utility) the NY1700 rollover date for a given Date::Utility.

=cut

sub NY1700_rollover_date_on {
    my ($self, $date) = @_;

    return $date->truncate_to_day->plus_time_interval((17 - $date->timezone_offset('America/New_York')->hours) * 3600);
}

=head2 effective_date_for

Get the "effective date" for a given Date::Utility (stated in GMT).

This is the we should consider a volsurface effective for, and rolls over
every day at NY1700. If a volsurface is quoted at GMT2300, its effective
date is actually the next day.

This returns a Date::Utility truncated to midnight of the relevant day.

=cut

sub effective_date_for {
    my ($self, $date) = @_;

    return $date->plus_time_interval((7 + $date->timezone_offset('America/New_York')->hours) * 3600)->truncate_to_day;
}

=head2 is_before_rollover

Returns 1 if given date-time is before roll-over time.

=cut

sub is_before_rollover {
    my ($self, $date) = @_;

    return ($date->is_after($self->NY1700_rollover_date_on($date))) ? 0 : 1;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
