package Quant::Framework::PartialTrading;

use Moose;
use List::MoreUtils qw(uniq);
use List::Util qw(first);
use Date::Utility;
use Carp qw(croak);

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head2 type

Partial trading means times when an exchange is opened later than usual (late_open) or closed earlier than usual (early_close).

=cut

has type => (
    is       => 'ro',
    required => 1,
);

has [qw(calendar recorded_date)] => (
    is => 'ro',
);

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

=head2 save

Save given calendar into Chronicle for partial-trading (either early-close or late-open).
This calendar will specify partial-trading dates for a number of symbols at the same time.

=cut

sub save {
    my $self = shift;

    croak "calendar and recorded_date are required when pass in either." if $self->calendar xor $self->recorded_date;
    die "Invalid partial-trading type" if $self->type ne 'early_closes' and $self->type ne 'late_opens';

    my $cached_data = $self->chronicle_reader->get('partial_trading', $self->type);
    my $recorded_epoch = $self->recorded_date->truncate_to_day->epoch;
    my %relevant_dates =
        map { $_ => $cached_data->{$_} }
        grep { $_ >= $recorded_epoch } keys %$cached_data;
    my %calendar = map { Date::Utility->new($_)->truncate_to_day->epoch => $self->calendar->{$_} } keys %{$self->calendar};

    foreach my $epoch (keys %calendar) {
        unless ($relevant_dates{$epoch}) {
            $relevant_dates{$epoch} = $calendar{$epoch};
            next;
        }
        foreach my $close_time (keys %{$calendar{$epoch}}) {
            my @symbols_to_save = uniq(@{$relevant_dates{$epoch}{$close_time}}, @{$calendar{$epoch}{$close_time}});
            $relevant_dates{$epoch}{$close_time} = \@symbols_to_save;
        }
    }

    return $self->chronicle_writer->set('partial_trading', $self->type, \%relevant_dates, $self->recorded_date);
}

=head2 get_partial_trading_for

Returns a hash-ref for partial-tradings of the given type for a specific symbol. 
You can also query historical data using this function.

=cut

sub get_partial_trading_for {
    my ($self, $symbol, $for_date) = @_;

    my $cached =
          $for_date
        ? $self->chronicle_reader->get_for('partial_trading', $self->type, $for_date)
        : $self->chronicle_reader->get('partial_trading', $self->type);

    my %partial_tradings;
    foreach my $epoch (keys %$cached) {
        foreach my $close_time (keys %{$cached->{$epoch}}) {
            my $symbols = $cached->{$epoch}{$close_time};
            $partial_tradings{$epoch} = $close_time
                if (first { $symbol eq $_ } @$symbols);
        }
    }

    return \%partial_tradings;
}

__PACKAGE__->meta->make_immutable;
1;
