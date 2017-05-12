package Quant::Framework::Spot::DatabaseAPI;

=head1 NAME

Quant::Framework::Spot::DatabaseAPI

=head1 DESCRIPTION

The API class which we can query feed database.

This class acts as a facade to the functions available in the DB. That is to say that that actual API is expressed by the functions in the DB. 

Each function available here has a function with same name inside the db.

If any of the functions fail due to any reason it will cause an exception thrown straight from DBI layer.

=cut

use Moose;
use DateTime;
use Date::Utility;
use Quant::Framework::Spot::Tick;
use Quant::Framework::Spot::OHLC;

has db_handle => (
    is       => 'ro',
    required => 1,
);

=head2 default_prefix

The prefix used to create name of the table `feed.tick` which will contain spot, timestamp and underlying columns.

=cut

has default_prefix => (
    is      => 'ro',
    default => 'feed.',
);

=head2 dbh

Return database handle. If db_handle is a normal reference, it will be used directly.
If it is a code-ref, it will be invoked to get the database handle.

=cut

sub dbh {
    my $self = shift;

    if (ref($self->db_handle) eq 'CODE') {
        return $self->db_handle->();
    }

    return $self->db_handle;
}

=head2 underlying

The underlying symbol for which this API will fetch data

=cut

has underlying => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 invert_values

If this argument is set, all tick and OHLC data will have their value inverted. This is useful when we have EURUSD feeds information but
want to have data for USDEUR underlying.

=cut

has 'invert_values' => (
    is => 'ro',
);

=head2 use_official_ohlc

In case there are official and non-official OHLC values for an underlying, this flag specifies which type of data we want

=cut

has use_official_ohlc => (
    is => 'ro',
);

=head2 tick_at_for_interval

Returns ticks in the given interval.

=cut

sub tick_at_for_interval {
    my $self = shift;
    my $args = shift;

    my $start_time = $args->{start_date}->datetime_yyyymmdd_hhmmss;
    my $end_time   = $args->{end_date}->datetime_yyyymmdd_hhmmss;
    my $interval   = $args->{interval_in_seconds};

    my $statement = $self->dbh->prepare_cached('SELECT * FROM tick_at_for_interval($1, $2, $3, $4)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $start_time);
    $statement->bind_param(3, $end_time);
    $statement->bind_param(4, $interval);

    return $self->_query_ticks($statement);
}

=head1 METHODS

=head2 ticks_start_end

get ticks from feed db filtered by
    - start_time, end_time - All ticks between <start_time> and <end_time>

Returns
     ArrayRef[Quant::Framework::Spot::Tick]

=cut

sub ticks_start_end {
    my $self = shift;
    my $args = shift;

    my $start_time;
    my $end_time;
    $start_time = Date::Utility->new($args->{start_time})->datetime_yyyymmdd_hhmmss
        if ($args->{start_time});

    $end_time = Date::Utility->new($args->{end_time})->datetime_yyyymmdd_hhmmss
        if ($args->{end_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ticks_start_end($1, $2, $3)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $start_time);
    $statement->bind_param(3, $end_time);

    return $self->_query_ticks($statement);
}

=head2 get_first_tick

Find the first tick which breaches a barrier

=cut

sub get_first_tick {
    my ($self, %args) = @_;

    my $underlying_symbol = $args{underlying};
    my $system_symbol     = $args{system_symbol};
    my $pip_size          = $args{pip_size};
    my $start_time        = Date::Utility->new($args{start_time})->db_timestamp;
    my $end_time          = Date::Utility->new($args{end_time} // time)->db_timestamp;

    unless ($args{higher} || $args{lower}) {
        die "At least one of higher or lower must be specified";
    }

    my $statement = $self->dbh->prepare_cached('SELECT * FROM get_first_tick($1, $2, $3, $4, $5)', {}, 5);

    $statement->bind_param(1, $system_symbol);
    $statement->bind_param(2, $start_time);
    $statement->bind_param(3, $end_time);
    if ($args{lower}) {
        $statement->bind_param(4, $args{lower} + $pip_size / 2);
    } else {
        $statement->bind_param(4, undef);
    }
    if ($args{higher}) {
        $statement->bind_param(5, $args{higher} - $pip_size / 2);
    } else {
        $statement->bind_param(5, undef);
    }

    my $tick;
    if (my ($epoch, $quote) = $self->dbh->selectrow_array($statement)) {
        $tick = Quant::Framework::Spot::Tick->new({
            symbol => $underlying_symbol,
            epoch  => $epoch,
            quote  => $quote,
        });
    }

    $tick->invert_values if ($tick and $self->invert_values);

    return $tick;
}

=head2 ticks_start_limit

get ticks from feed db filtered by
    - start_time, limit - <limit> number of ticks starting from <start_time>

Returns
     ArrayRef[Quant::Framework::Spot::Tick]

=cut

sub ticks_start_limit {
    my $self = shift;
    my $args = shift;

    my $start_time;
    $start_time = Date::Utility->new($args->{start_time})->datetime_yyyymmdd_hhmmss
        if ($args->{start_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ticks_start_limit($1, $2, $3)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $start_time);
    $statement->bind_param(3, $args->{limit});

    my $ticks = $self->_query_ticks($statement);

    # It would probably be more efficient to do this at the db level, but
    # I don't have that luxury at present.
    if ($args->{end_time}) {
        my $end_epoch = Date::Utility->new($args->{end_time})->epoch;
        $ticks = [grep { $_->epoch <= $end_epoch } @{$ticks}];
    }

    return $ticks;
}

=head2 ticks_end_limit

get ticks from feed db filtered by
    - end_time, limit - <limit> number ticks before <end_time>

Returns
     ArrayRef[Quant::Framework::Spot::Tick]

=cut

sub ticks_end_limit {
    my $self = shift;
    my $args = shift;

    my $end_time;
    $end_time = Date::Utility->new($args->{end_time})->datetime_yyyymmdd_hhmmss
        if ($args->{end_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ticks_end_limit($1, $2, $3)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $end_time);
    $statement->bind_param(3, $args->{limit});

    return $self->_query_ticks($statement);
}

=head2 tick_at

get a valid tick at time given or not a valid tick before a given time. Accept argument
    - end_time - Time at which we want the tick
    - allow_inconsistent - if this is passed then we get the last available tick, we do not care if its a valid ick or not.

Returns
     Quant::Framework::Spot::Tick

=cut

sub tick_at {
    my $self = shift;
    my $args = shift;
    my $tick;

    return unless ($args->{end_time});
    my $end_time = Date::Utility->new($args->{end_time});

    my $sql =
        ($args->{allow_inconsistent})
        ? 'SELECT * FROM tick_at_or_before($1, $2::TIMESTAMP)'
        : 'SELECT * FROM consistent_tick_at_or_before($1, $2::TIMESTAMP)';
    my $statement = $self->dbh->prepare_cached($sql, {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $end_time->db_timestamp);

    return $self->_query_single_tick($statement);
}

=head2 tick_after

get tick from feed db after the time given.
    - start_time - the first tick after <start_time>

Returns
     ArrayRef[Quant::Framework::Spot::Tick]

=cut

sub tick_after {
    my $self = shift;
    my $time = shift;
    return unless ($time);

    $time = Date::Utility->new($time);

    my $statement = $self->dbh->prepare_cached('SELECT * FROM tick_after($1, $2)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $time->datetime_yyyymmdd_hhmmss);

    return $self->_query_single_tick($statement);
}

=head2 ticks_start_end_with_limit_for_charting

get ticks from feed db filtered by
    - start_time, end_time, limit - all ticks between <start_time> and <end_time> and limit to <limit> entries.
This method is appropriate for charting applications where a limited number of prices are going to be displayed.

Returns
     ArrayRef[Quant::Framework::Spot::Tick]

=cut

sub ticks_start_end_with_limit_for_charting {
    my $self = shift;
    my $args = shift;

    my $start_time;
    my $end_time;
    $start_time = Date::Utility->new($args->{start_time})->datetime_yyyymmdd_hhmmss
        if ($args->{start_time});
    $end_time = Date::Utility->new($args->{end_time})->datetime_yyyymmdd_hhmmss
        if ($args->{end_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ticks_start_end_with_limit_for_charting($1, $2, $3, $4)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $start_time);
    $statement->bind_param(3, $end_time);
    $statement->bind_param(4, $args->{limit});

    return $self->_query_ticks($statement);
}

=head2 $self->ohlc_start_end(\%args)

This method returns reference to the list of OHLC for the specified period.
Accepts following arguments:

=over 4

=item B<start_time>

Compute OHLC starting from the specified time. Note, that if I<start_time> is
not at the beginning of the unit used by the source table (minutes, hour, or
days depending on I<aggregation_period>) it will be aligned to the start of the
next unit. But timestamp of the returned OHLC may be pointing to earlier moment
of time, e.g. for weekly and monthly OHLC it will point to the start of week or
month, even though actual OHLC value may be computed from the middle of week or
month.

=item B<end_time>

Compute OHLC till specified time. Note, that it will be aligned so timestamp
would be multiple of I<aggregation_period>.

=item B<aggregation_period>

Compute OHLCs for periods of the specified duration.

=over 4

=item *

if period is less than a minute, then feed.tick table is used a the source

=item *

if period is from one minute and less than an hour, then feed.ohlc_minutely is
used as source. Using period that is not multiple of a minute is not wise as
returned data may not make much sense.

=item *

if period is one hour or more, but less than a day, then feed.ohlc_hourly is
used as source of data. Don't use intervals that not multiple of an hour.

=item *

if period is a day or more, then ohlc_daily is used as the source of data.
Don't use intervals that are not multiple of a day. If number of days is 7 then
I<end_time> will be aligned to the end of the week, and all intevals will start
at the start of the week (first interval may not actually start at the start of
the week, although timestamp in OHLC will indicate that it is). If number of
days is 30 then I<end_time> will be aligned to the end of the month and all
intervals will start at the start of the month (except maybe the first one).

=back

=back

If interval is multiple of a day, than method will use official daily OHLC if
underlying has daily OHLC. It will never set I<official> property or returned
OHLC objects though.

Method returns reference to a list of
L<Quant::Framework::Spot::OHLC>

=cut

sub ohlc_start_end {
    my $self = shift;
    my $args = shift;

    my $start_time;
    my $end_time;
    $start_time = Date::Utility->new($args->{start_time})->datetime_yyyymmdd_hhmmss
        if ($args->{start_time});
    $end_time = Date::Utility->new($args->{end_time})->datetime_yyyymmdd_hhmmss
        if ($args->{end_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ohlc_start_end($1, $2, $3, $4, $5)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $args->{aggregation_period});
    $statement->bind_param(3, $start_time);
    $statement->bind_param(4, $end_time);
    $statement->bind_param(5, $self->use_official_ohlc ? 'TRUE' : 'FALSE');

    return $self->_query_ohlc($statement);
}

=head2 $self->ohlc_daily_list(\%args)

This method returns reference to list of daily OHLC for the specified period.
First and last OHLC maybe computed for the part of the day using ticks in
feed.tick table and not precomputed daily OHLC, so these two are non-official
OHLC. The rest of OHLCs may be official, but I<official> attribute won't be set
on them. Method accepts the following parameters:

=over 4

=item B<start_time>

Compute OHLCs starting from the specified time

=item B<end_time>

Compute OHLCs till the specified moment of time

=back

Method returns reference to a list of L<Quant::Framework::Spot::OHLC> objects

=cut

sub ohlc_daily_list {
    my $self = shift;
    my $args = shift;

    my $start_time;
    my $end_time;
    $start_time = Date::Utility->new($args->{start_time})->datetime_yyyymmdd_hhmmss
        if ($args->{start_time});
    $end_time = Date::Utility->new($args->{end_time})->datetime_yyyymmdd_hhmmss
        if ($args->{end_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ohlc_daily_list($1, $2, $3, $4)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $start_time);
    $statement->bind_param(3, $end_time);
    $statement->bind_param(4, $self->use_official_ohlc ? 'TRUE' : 'FALSE');

    return $self->_query_ohlc($statement);
}

=head2 ohlc_start_end_with_limit_for_charting

Returns OHLC in the given start/end period

=cut

sub ohlc_start_end_with_limit_for_charting {
    my $self = shift;
    my $args = shift;

    my $start_time;
    my $end_time;
    $start_time = Date::Utility->new($args->{start_time})->datetime_yyyymmdd_hhmmss
        if ($args->{start_time});
    $end_time = Date::Utility->new($args->{end_time})->datetime_yyyymmdd_hhmmss
        if ($args->{end_time});

    my $statement = $self->dbh->prepare_cached('SELECT * FROM ohlc_start_end_with_limit_for_charting ($1, $2, $3, $4, $5, $6)', {}, 3);
    $statement->bind_param(1, $self->underlying);
    $statement->bind_param(2, $args->{aggregation_period});
    $statement->bind_param(3, $start_time);
    $statement->bind_param(4, $end_time);
    $statement->bind_param(5, $self->use_official_ohlc ? 'TRUE' : 'FALSE');
    $statement->bind_param(6, $args->{limit});

    return $self->_query_ohlc($statement);
}

=head2 ohlc_daily_until_now_for_charting

Returns daily OHLC values for the period starting from given date till today.

=cut

sub ohlc_daily_until_now_for_charting {
    my ($self, $args) = @_;
    my $limit = $args->{limit};

    my $query_ohlc = {
        limit              => $limit,
        aggregation_period => 86400
    };

    #estimate begin time and end time(crazy stuff)
    my $now = DateTime->now();
    $now->add(days => 1);
    $query_ohlc->{end_time} = $now->ymd('-') . ' ' . $now->hms;
    $now->subtract(days => ($limit + 1));
    $query_ohlc->{start_time} = $now->ymd('-') . ' ' . $now->hms;

    return $self->ohlc_start_end_with_limit_for_charting($query_ohlc);
}

sub _query_ticks {
    my $self      = shift;
    my $statement = shift;

    my $symbol = $self->underlying;

    my @ticks;
    if ($statement->execute()) {
        my ($epoch, $quote, $bid, $ask);
        $statement->bind_col(1, \$epoch);
        $statement->bind_col(2, \$quote);
        $statement->bind_col(3, undef);
        $statement->bind_col(4, \$bid);
        $statement->bind_col(5, \$ask);

        while ($statement->fetch()) {
            my $tick_compiled = Quant::Framework::Spot::Tick->new({
                symbol => $symbol,
                epoch  => $epoch,
                quote  => $quote,
                bid    => $bid,
                ask    => $ask,
            });
            $tick_compiled->invert_values if ($self->invert_values);
            push @ticks, $tick_compiled;
        }
    }

    return \@ticks;
}

sub _query_single_tick {
    my $self      = shift;
    my $statement = shift;
    my $tick_compiled;
    if ($statement->execute()) {
        my ($epoch, $quote, $bid, $ask);
        $statement->bind_col(1, \$epoch);
        $statement->bind_col(2, \$quote);
        $statement->bind_col(3, undef);
        $statement->bind_col(4, \$bid);
        $statement->bind_col(5, \$ask);

        # At least one db function (tick_at_or_before) returns a data type
        # instead of a table, which means fetch will always get 1 row result
        # but all fields are null. So we check whether the epoch returned is
        # anything truish before assuming we got good data back.
        if ($statement->fetch() and $epoch) {
            $tick_compiled = Quant::Framework::Spot::Tick->new({
                symbol => $self->underlying,
                epoch  => $epoch,
                quote  => $quote,
                bid    => $bid,
                ask    => $ask,
            });
        }
    }

    $tick_compiled->invert_values
        if ($tick_compiled and $self->invert_values);
    return $tick_compiled;
}

sub _query_ohlc {
    my $self      = shift;
    my $statement = shift;

    my @ohlc_data;
    if ($statement->execute()) {
        my ($epoch, $open, $high, $low, $close);
        $statement->bind_col(1, \$epoch);
        $statement->bind_col(2, \$open);
        $statement->bind_col(3, \$high);
        $statement->bind_col(4, \$low);
        $statement->bind_col(5, \$close);

        while ($statement->fetch()) {
            my $ohlc_compiled = Quant::Framework::Spot::OHLC->new({
                epoch => $epoch,
                open  => $open,
                high  => $high,
                low   => $low,
                close => $close,
            });
            $ohlc_compiled->invert_values if ($self->invert_values);
            push @ohlc_data, $ohlc_compiled;
        }
    }

    return \@ohlc_data;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
