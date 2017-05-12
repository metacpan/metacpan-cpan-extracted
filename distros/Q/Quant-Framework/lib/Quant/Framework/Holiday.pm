package Quant::Framework::Holiday;

use Moose;
use Carp qw(croak);
use Date::Utility;
use List::Util qw(first);
use List::MoreUtils qw(uniq);

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head1 NAME

Quant::Framework::Holiday - A module to save/load market holidays

=head1 DESCRIPTION

This module saves/loads holidays to/from Chronicle. 

=cut

around BUILDARGS => sub {
    my $orig   = shift;
    my $class  = shift;
    my %params = ref $_[0] ? %{$_[0]} : @_;

    if ($params{calendar} xor $params{recorded_date}) {
        croak "calendar and recorded_date are required when pass in either.";
    }

    return $class->$orig(@_);
};

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

has [qw(calendar recorded_date)] => (
    is => 'ro',
);

=head2 save

Updates the current holiday calendar with the new inserts.
It trims the calendar by removing holiday before the recorded_date.

=cut

sub save {
    my $self = shift;

    my $cached_holidays = $self->chronicle_reader->get('holidays', 'holidays');
    my $recorded_date = $self->recorded_date->truncate_to_day->epoch;
    delete @{$cached_holidays}{grep { $_ < $recorded_date } keys %$cached_holidays};
    my $calendar = $self->calendar;

    foreach my $new_holiday (keys %$calendar) {
        my $epoch = Date::Utility->new($new_holiday)->truncate_to_day->epoch;
        unless ($cached_holidays->{$epoch}) {
            $cached_holidays->{$epoch} = $calendar->{$new_holiday};
            next;
        }
        foreach my $new_holiday_desc (keys %{$calendar->{$new_holiday}}) {
            my $new_symbols = $calendar->{$new_holiday}{$new_holiday_desc};
            my $symbols_to_save = [uniq(@{$cached_holidays->{$epoch}{$new_holiday_desc}}, @$new_symbols)];
            $cached_holidays->{$epoch}{$new_holiday_desc} = $symbols_to_save;
        }
    }

    return $self->chronicle_writer->set('holidays', 'holidays', \%{$cached_holidays}, $self->recorded_date);
}

=head2 get_holidays_for

This method looks for holidays of the given symbol (at the optional given time) using
chronicle_reader object passed to it. Note that this method needs a chronicle reader 
because it is not part of the Holiday class.

=cut

sub get_holidays_for {
    my ($reader, $symbol, $for_date) = @_;

    my $calendar =
        ($for_date)
        ? $reader->get_for('holidays', 'holidays', $for_date)
        : $reader->get('holidays', 'holidays');
    my %holidays;
    foreach my $date (keys %$calendar) {
        foreach my $holiday_desc (keys %{$calendar->{$date}}) {
            $holidays{$date} = $holiday_desc if (first { $symbol eq $_ } @{$calendar->{$date}{$holiday_desc}});
        }
    }

    return \%holidays;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
