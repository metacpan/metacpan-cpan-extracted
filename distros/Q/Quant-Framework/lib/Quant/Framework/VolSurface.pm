package Quant::Framework::VolSurface;

=head1 NAME

Quant::Framework::VolSurface

=head1 DESCRIPTION

Base class for all volatility surfaces.

=cut

use Moose;
use Try::Tiny;
use DateTime::TimeZone;
use List::MoreUtils qw(notall any);
use Scalar::Util qw( looks_like_number );
use List::Util qw( min max first );
use Number::Closest::XS qw(find_closest_numbers_around);
use Math::Function::Interpolator;
use Storable qw(dclone);

use Quant::Framework::Utils::Types;
use Quant::Framework::VolSurface::Utils;
use Quant::Framework::Utils::Builder;

=head2 for_date

The date for which we want to have the volatility surface data

=cut

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

=head2 type

Type of the surface, delta, moneyness or flat.

=cut

has type => (
    is       => 'ro',
    isa      => 'qf_surface_type',
    required => 1,
    init_arg => undef,
    default  => undef,
);

=head2 underlying_config

Contains underlying specific information

=cut

has underlying_config => (
    is       => 'ro',
    required => 1,
);

has document => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_document {
    my $self = shift;

    my $document = $self->chronicle_reader->get('volatility_surfaces', $self->symbol);
    if ($self->for_date and $self->for_date->epoch < Date::Utility->new($document->{date})->epoch) {
        $document = $self->chronicle_reader->get_for('volatility_surfaces', $self->symbol, $self->for_date->epoch);
    }

    die('Document is undefined for ' . $self->symbol) unless $document;

    return $document;
}

=head2 effective_date

Surfaces roll over at 5pm NY time, so the vols of any surfaces recorded after 5pm NY but
before GMT midnight are effectively for the next GMT day. This attribute holds this
effective date.

=cut

has effective_date => (
    is         => 'ro',
    isa        => 'Date::Utility',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_effective_date {
    my $self = shift;

    return Quant::Framework::VolSurface::Utils->new->effective_date_for($self->recorded_date);
}

has calendar => (
    is         => 'ro',
    isa        => 'Quant::Framework::TradingCalendar',
    lazy_build => 1,
);

sub _build_calendar {
    my $self = shift;

    return $self->builder->build_trading_calendar;
}

has builder => (
    is         => 'ro',
    isa        => 'Quant::Framework::Utils::Builder',
    lazy_build => 1,
);

sub _build_builder {
    my $self = shift;

    return Quant::Framework::Utils::Builder->new({
        for_date          => $self->for_date,
        chronicle_reader  => $self->chronicle_reader,
        chronicle_writer  => $self->chronicle_writer,
        underlying_config => $self->underlying_config,
    });
}

=head2 surface

Volatility surface in a hash reference.

=cut

has surface => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_surface {
    my $self = shift;

    my %surface_data       = %{$self->surface_data};
    my $expiry_conventions = $self->builder->build_expiry_conventions;
    my $effective_date     = $self->effective_date;

    # If the smile's day is given as a tenor, we convert
    # it to a day and add the tenor to the smile:
    foreach my $maturity (keys %surface_data) {
        # if there's no data, delete it.
        if (
            not(   (exists $surface_data{$maturity}{smile} and %{$surface_data{$maturity}{smile}})
                or (exists $surface_data{$maturity}{vol_spread} and %{$surface_data{$maturity}{vol_spread}})))
        {
            delete $surface_data{$maturity};
            next;
        }
        if ($maturity =~ /^(?:ON|\d{1,2}[WMY])$/) {
            my $vol_expiry_date = $expiry_conventions->vol_expiry_date({
                from => $effective_date,
                term => $maturity
            });
            my $day = $vol_expiry_date->days_between($effective_date);

            $surface_data{$day} = delete $surface_data{$maturity};
            $surface_data{$day}{tenor} = $maturity;
        } elsif ($maturity !~ /^\d+$/) {
            # Don't die here. This surface will be invalidated later.
            warn("Unknown tenor[$maturity] found on volatility surface for " . $self->symbol);
        }
    }

    return \%surface_data;
}

=head1 ATTRIBUTES

=head2 symbol

The symbol of the underlying that this surface is for (e.g. frxUSDJPY)

=cut

has symbol => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_symbol {
    my $self = shift;

    return $self->underlying_config->system_symbol;
}

=head2 recorded_date

The date (and time) that the surface was recorded, as a Date::Utility.

=cut

has recorded_date => (
    is         => 'ro',
    isa        => 'Date::Utility',
    lazy_build => 1,
);

sub _build_recorded_date {
    my $self = shift;

    return Date::Utility->new($self->document->{date});
}

=head2 smile_points

The points across a smile.

It can be delta points, moneyness points or any other points that we might have in the future.

=cut

has smile_points => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_smile_points {
    my $self = shift;

    # Default to the point found in the first day we find
    # in $self->surface that has a smile. As long as each smile
    # has the same points, this works. If each smile has different
    # points, the Validator is going to give you trouble!
    my $surface = $self->surface;
    my $suitable_day = first { exists $surface->{$_}->{smile} } @{$self->term_by_day};

    return [sort { $a <=> $b } keys %{$surface->{$suitable_day}->{smile}}] if $suitable_day;
    return [];
}

=head2 spread_points

This will give an array-reference containing volatility spreads for first tenor which has a volatility spread (or ATM if none).
=cut

has spread_points => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_spread_points {
    my $self = shift;

    # Default to the point found in the first day we find
    # in $self->surface that has a volspread. As long as each volspread
    # has the same points, this works. If each smile has different
    # points, the Validator is going to give you trouble!
    my $surface = $self->surface;
    my $suitable_day = first { exists $surface->{$_}->{vol_spread} } keys %{$surface};

    return [sort { $a <=> $b } keys %{$surface->{$suitable_day}{vol_spread}}] if $suitable_day;
    return [];
}

=head2 term_by_day

Get all the terms in a surface in ascending order.

=cut

has term_by_day => (
    is         => 'ro',
    isa        => 'ArrayRef',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_term_by_day {
    my $self = shift;

    return [sort { $a <=> $b } keys %{$self->surface}];
}

=head2 original_term

The terms we were originally supplied for this surface.

=cut

has original_term => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_original_term {
    my $self = shift;

    # this is from original surface data.
    my $surface     = $self->surface;
    my @days        = map { /^(?:ON|\d{1,2}[WMY])$/ ? $self->get_day_for_tenor($_) : $_ } keys %{$self->surface_data};
    my @vol_spreads = grep { exists $surface->{$_}{vol_spread} } @days;
    my @smiles      = grep { exists $surface->{$_}{smile} } @days;

# We must have at least 2 atm_spreads if this is a valid surface with multiple smiles.
# Set the end points to the default if they are unset to make up any difference.
    if (scalar @vol_spreads < min(2, scalar @smiles)) {
        foreach my $end_index (0, -1) {
            my $day = $days[$end_index];
            next if exists $surface->{$day}{vol_spread};
            $surface->{$day}{vol_spread} = {$self->atm_spread_point => 0.1};
            push @vol_spreads, $day;
        }
    }

    return +{
        vol_spread => \@vol_spreads,
        smile      => \@smiles,
    };

}

=head2 original_term_for_smile

The original term structure we have for smiles on a surface

=cut

has original_term_for_smile => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_original_term_for_smile {
    my $self = shift;

    return [sort { $a <=> $b } @{$self->original_term->{smile}}];
}

=head2 original_term_for_spread

The original term structure we have for spreads on a surface

=cut

has original_term_for_spread => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_original_term_for_spread {
    my $self = shift;

    return [sort { $a <=> $b } @{$self->original_term->{vol_spread}}];
}

# PRIVATE ATTRIBUTES:

# will probably remove this in the future. I don't see a difference between this and expiry convention.
has _ON_day => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

#Returns the day for over-night tenor of this surface
#ON = over-night
sub _build__ON_day {
    my $self = shift;

    return $self->calendar->calendar_days_to_trade_date_after($self->effective_date);
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my %args  = (ref $_[0] eq 'HASH') ? %{$_[0]} : @_;

    if ($args{surface} or $args{recorded_date} or $args{surface_data}) {
        $args{surface_data} = $args{surface} if $args{surface} and not $args{surface_data};
        delete $args{surface};    # surface will always be built from surface_data.
        die('Must pass both "surface_data" and "recorded_date" if passing either.') if (not($args{surface_data} and $args{recorded_date}));
    }

    # symbol will be built from underlying_config
    delete $args{symbol};

    return $class->$orig(%args);
};

=head2 get_spread

Spread is ask-bid difference which can be stored for different tenor and atm/max.
This is value could be adjusted for pricing under certain conditions.

USAGE:

    my $spread = $volsurface->get_spread({sought_point=> 'atm', day=> 7});
    will return the atm spread for the day.

   my $spread = $volsurface->get_spread({sought_point=> 'max', day=> 7});
    will return the max spread for the day.

=cut

sub get_spread {
    my ($self, $args) = @_;

    my $sought_point = $args->{sought_point};
    my $day          = $args->{day};
    $day = $self->get_day_for_tenor($day)
        if ($day =~ /^(?:ON|\d[WMY])$/);    # if day looks like tenor

    my $surface = $self->surface;
    # prevent autovivification
    my $smile_spread = (exists $surface->{$day} and exists $surface->{$day}{vol_spread}) ? $surface->{$day}{vol_spread} : +{};
    $smile_spread = $self->get_smile_spread($day) unless %$smile_spread;

    my $spread;
    if ($sought_point eq 'atm') {
        $spread = $smile_spread->{$self->atm_spread_point};
    } elsif ($sought_point eq 'max') {
        $spread = max(values %$smile_spread);
    } else {
        die 'Unrecognized spread type ' . $sought_point;
    }

    return $spread + $self->min_vol_spread if ($self->can('min_vol_spread') and $day < 30 and $spread < $self->min_vol_spread);
    return $spread;
}

=head2 get_smile_spread

Returns the ask/bid spread for smile of this volatility surface
This is the raw spread.

=cut

sub get_smile_spread {
    my ($self, $day) = @_;

    my $surface = $self->surface;

    # autovivification
    return $surface->{$day}{vol_spread} if (exists $surface->{$day} and exists $surface->{$day}{vol_spread});
    return $self->_compute_and_set_smile_spread($day);
}

sub _compute_and_set_smile_spread {
    my ($self, $day) = @_;

    my $surface      = $self->surface;
    my $spread_terms = $self->original_term_for_spread;
    my @points       = $self->_get_points_to_interpolate($day, $spread_terms);

    if (not $self->_is_between($day, \@points)) {
        my $index = $day > $spread_terms->[-1] ? $spread_terms->[-1] : $spread_terms->[0];
        return $surface->{$index}{vol_spread};
    }

    my %smile_spread = map {
        $_ => Math::Function::Interpolator->new(
            points => {
                $points[0] => $surface->{$points[0]}->{vol_spread}->{$_},
                $points[1] => $surface->{$points[1]}->{vol_spread}->{$_},
            }
            )->linear($day)
    } @{$self->spread_points};

    $self->surface->{$day}{vol_spread} = \%smile_spread;

    return \%smile_spread;
}

sub _get_points_to_interpolate {
    my ($self, $seek, $available_points) = @_;
    die('Need 2 or more term structures to interpolate.')
        if scalar @$available_points <= 1;

    return @{find_closest_numbers_around($seek, $available_points, 2)};
}

sub _is_between {
    my ($self, $seek, $points) = @_;

    my @points = @$points;

    die('some of the points are not defined')
        if (notall { defined $_ } @points);
    die('less than two available points')
        if (scalar @points < 2);

    return if $seek > max(@points) or $seek < min(@points);
    return 1;
}

=head2 get_day_for_tenor

USAGE:

    my $day = $volsurface->get_day_for_tenor('1W');

Get the corresponding day for a given tenor, if one exists.

=cut

sub get_day_for_tenor {
    my ($self, $tenor) = @_;

    my $surface_data = $self->surface;
    my $day          = first {
        $surface_data->{$_}->{tenor} && $surface_data->{$_}->{tenor} eq $tenor;
    }
    @{$self->term_by_day};

    # If tenor doesn't already exist on surface, get $days via the vol expiry date.
    if (not $day) {
        $day = $self->builder->build_expiry_conventions->vol_expiry_date({
                from => $self->effective_date,
                term => $tenor,
            })->days_between($self->effective_date);
    }

    return $day;
}

=head2 get_rr_bf_for_smile

Return the rr and bf values for a given smile
For more info see: https://en.wikipedia.org/wiki/Risk_reversal and https://en.wikipedia.org/wiki/Butterfly_(options)

=cut

sub get_rr_bf_for_smile {
    my ($self, $market_smile) = @_;

    my $result = {
        ATM   => $market_smile->{50},
        RR_25 => $market_smile->{25} - $market_smile->{75},
        BF_25 => ($market_smile->{25} + $market_smile->{75}) / 2 - $market_smile->{50},
    };
    if (exists $market_smile->{10}) {
        $result->{RR_10} = $market_smile->{10} - $market_smile->{90};
        $result->{BF_10} = ($market_smile->{10} + $market_smile->{90}) / 2 - $market_smile->{50};
    }

    return $result;
}

=head2 is_valid

Does this volatility surface pass our validation.

=cut

sub is_valid {
    my $self = shift;

    my @validation_methods = $self->_validation_methods;

    try {
        $self->$_ for ($self->_validation_methods);
    }
    catch {
        $self->validation_error($_);
    };

    return !$self->validation_error;
}

sub _validate_age {
    my $self = shift;

    if (time - $self->recorded_date->epoch > 4 * 3600) {
        die('Volatility surface from provider for ' . $self->symbol . ' is more than 4 hours old.');
    }

    return;
}

sub _validate_structure {
    my $self = shift;

    my $surface_hashref = $self->surface;
    my $system_symbol   = $self->symbol;

    # Somehow I do not know why there is a limit of term on delta surface, but
    # for moneyness we might need at least up to 2 years to get the spread.
    my $type = $self->type;

    my $extra_allowed = $self->underlying_config->extra_vol_diff_by_delta || 0;
    my $max_vol_change_by_delta = 0.4 + $extra_allowed;

    my @days = sort { $a <=> $b } keys %{$surface_hashref};

    if (@days < 2) {
        die('Must be at least two maturities on vol surface for ' . $self->symbol . '.');
    }

    if ($days[-1] > $self->_max_allowed_term) {
        die("Day[$days[-1]] in volsurface for underlying[$system_symbol] greater than allowed[" . $self->_max_allowed_term . "].");
    }

    if ($self->underlying_config->market_name eq 'forex' and $days[0] > 7) {
        die("ON term is missing in volsurface for underlying $system_symbol, the minimum term is $days[0].");
    }

    foreach my $day (@days) {
        if ($day !~ /^\d+$/) {
            die("Invalid day[$day] in volsurface for underlying[$system_symbol]. Not a positive integer.");
        }
    }

    foreach my $day (grep { exists $surface_hashref->{$_}->{smile} } @days) {
        my $smile = $surface_hashref->{$day}->{smile};
        my @volatility_level = sort { $a <=> $b } keys %$smile;

        for (my $i = 0; $i < $#volatility_level; $i++) {
            my $level = $volatility_level[$i];

            if ($level !~ /^\d+\.?\d+$/) {
                die("Invalid vol_point[$level] for underlying[$system_symbol].");
            }

            my $next_level = $volatility_level[$i + 1];
            if (abs($level - $next_level) > $self->_max_difference_between_smile_points) {
                die("Difference between point $level and $next_level is too great for days $day.");
            }

            if (not $self->_is_valid_volatility_smile($smile)) {
                die("Invalid smile volatility on $day for $system_symbol");
            }

            if (abs($smile->{$level} - $smile->{$next_level}) > $max_vol_change_by_delta * $smile->{$level}) {
                die(      "Invalid volatility points: too big jump from "
                        . "$level:$smile->{$level} to $next_level:$smile->{$next_level}"
                        . "for maturity[$day], underlying[$system_symbol]");
            }
        }
    }

    return;
}

sub _is_valid_volatility_smile {
    my ($self, $smile) = @_;

    foreach my $vol (values %$smile) {
        # sanity check on volatility. Cannot be more than 500% and must be a number.
        return if ($vol !~ /^\d?\.?\d*$/ or $vol > 5);
    }

    return 1;
}

sub _validate_identical_surface {
    my $self = shift;

    my $existing = $self->new({
        underlying_config => $self->underlying_config,
        chronicle_reader  => $self->chronicle_reader,
        chronicle_writer  => $self->chronicle_writer,
    });

    my $existing_surface_data = $existing->surface;
    my $new_surface_data      = $self->surface;

    my @existing_terms = sort { $a <=> $b } grep { exists $existing_surface_data->{$_}{smile} } keys %$existing_surface_data;
    my @new_terms      = sort { $a <=> $b } grep { exists $new_surface_data->{$_}{smile} } keys %$new_surface_data;

    return if @existing_terms != @new_terms;
    return if any { $existing_terms[$_] != $new_terms[$_] } (0 .. $#existing_terms);

    foreach my $term (@existing_terms) {
        my $existing_smile = $existing_surface_data->{$term}->{smile};
        my $new_smile      = $new_surface_data->{$term}->{smile};
        return if (scalar(keys %$existing_smile) != scalar(keys %$new_smile));
        return if (any { $existing_smile->{$_} != $new_smile->{$_} } keys %$existing_smile);
    }

    my $existing_surface_epoch = Date::Utility->new($self->document->{date})->epoch;

    if (time - $existing_surface_epoch > 15000 and not $self->underlying_config->quanto_only) {
        die('Surface data has not changed since last update [' . $existing_surface_epoch . '] for ' . $self->symbol . '.');
    }

    return;
}

sub _validate_volatility_jumps {
    my $self = shift;

    my $existing = $self->new({
        underlying_config => $self->underlying_config,
        chronicle_reader  => $self->chronicle_reader,
        chronicle_writer  => $self->chronicle_writer,
    });

    my @terms           = @{$self->original_term_for_smile};
    my @new_expiry      = @{$self->get_smile_expiries};
    my @existing_expiry = @{$existing->get_smile_expiries};

    my @points = @{$self->smile_points};
    my $type   = $self->type;

    for (my $i = 1; $i <= $#new_expiry; $i++) {
        for (my $j = 0; $j <= $#points; $j++) {
            my $sought_point = $points[$j];
            my $new_vol      = $self->get_volatility({
                $type => $sought_point,
                from  => $self->recorded_date,
                to    => $new_expiry[$i],
            });
            my $existing_vol = $existing->get_volatility({
                $type => $sought_point,
                from  => $existing->recorded_date,
                to    => $existing_expiry[$i],
            });
            my $diff = abs($new_vol - $existing_vol);
            if ($diff > 0.03 and $diff > $existing_vol) {
                die('Big difference found on term[' . $terms[$i - 1] . '] for point [' . $sought_point . '] with absolute diff [' . $diff . '].');
            }
        }
    }

    return;
}

has validation_error => (
    is      => 'rw',
    default => '',
);

=head2 save
Saves current surface using given chronicle writer.
=cut

sub save {
    my $self = shift;

    return $self->chronicle_writer->set('volatility_surfaces', $self->symbol, $self->_document_content, $self->recorded_date);
}

=head2 get_surface_smile

Returns the smile on the surface.
Returns an empty hash reference if not present.

=cut

sub get_surface_smile {
    my ($self, $days) = @_;

    return $self->surface->{$days}->{smile} // {};
}

=head2 get_surface_volatility

Returns the volatility point based on the raw volatility surface data.
Returns undef if requested smile is not present.
Returns the interpolated/raw volatility point across smile if requested smile is present.

=cut

sub get_surface_volatility {
    my ($self, $days, $smile_point) = @_;

    die('[days] and [smile_point] are required.') if (not($days and $smile_point));

    my $smile = $self->get_surface_smile($days);

    return if not keys %$smile;
    return $smile->{$smile_point} if $smile->{$smile_point};

    return $self->interpolate({
        smile        => $smile,
        sought_point => $smile_point,
    });
}

=head2 clone

USAGE:

  my $clone = $s->clone({
    surface_data => $surface_data,
  });

Returns a new Quant::Framework::VolSurface instance. You can pass overrides to override an attribute value as it is on the original surface.

=cut

sub clone {
    my ($self, $args) = @_;

    my %clone_args;
    %clone_args = %$args if $args;

    # moneyness has spot_reference.
    if ($self->can('spot_reference') and not exists $clone_args{spot_reference}) {
        $clone_args{spot_reference} = $self->spot_reference;
    }

    foreach my $att (qw(underlying_config recorded_date chronicle_reader chronicle_writer)) {
        if (not exists $clone_args{$att}) {
            $clone_args{$att} = $self->$att;
        }
    }

    if (not exists $clone_args{surface_data}) {
        $clone_args{surface_data} = dclone($self->surface_data);
    }

    return $self->new(\%clone_args);
}

sub _clean {
    my ($self, $surface) = @_;

    # For backward compatibility in volatility spread,
    # we will convert the legacy structure to the new structure here.
    foreach my $tenor (keys %$surface) {
        if (exists $surface->{$tenor}{atm_spread}) {
            my $spread = delete $surface->{$tenor}{atm_spread};
            $surface->{$tenor}{vol_spread} = {$self->atm_spread_point => $spread};
        }
    }

    return $surface;
}

sub _document_content {
    my $self = shift;

    my %structure = (
        surface => $self->surface,
        date    => $self->recorded_date->datetime_iso8601,
        symbol  => $self->symbol,
        type    => $self->type,
    );

    $structure{spot_reference} = $self->spot_reference if ($self->can('spot_reference'));

    return \%structure;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
