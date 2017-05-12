package Quant::Framework::Currency;

=head1 NAME

Quant::Framework::Currency

=head1 DESCRIPTION

The representation of currency within our system

my $currency = Quant::Framework::Currency->new({ symbol => 'AUD'});

=cut

use Carp;
use Moose;
use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

use Date::Utility;
use Data::Chronicle::Reader;
use Data::Chronicle::Writer;
use Quant::Framework::Holiday;
use Quant::Framework::InterestRate;
use Quant::Framework::ImpliedRate;

=head2 symbol
Represents currency symbol.
=cut

has symbol => (
    is       => 'ro',
    required => 1,
);

=head2 for_date
The Date::Utility wherein this underlying is fixed.
=cut

has 'for_date' => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

=head2 chronicle_reader and chronicle_writer

Used to work with Chronicle storage data.

=cut

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

has daycount => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_daycount {
    my $self = shift;

    return 360 if first { $self->symbol eq $_ } qw(AED CHF CZK EGP EUR IDR JPY MXN NOK SAR SEK USD XAG XAU TRY);
    return 365 if first { $self->symbol eq $_ } qw(AUD BRL CAD CNY GBP HKD INR KRW NZD PLN RUB SGD ZAR KWD);
    return;
}

has holidays => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_holidays {
    my $self = shift;

    my $holidays_ref = Quant::Framework::Holiday::get_holidays_for($self->chronicle_reader, $self->symbol, $self->for_date);
    my %holidays = map { Date::Utility->new($_)->days_since_epoch => $holidays_ref->{$_} } keys %$holidays_ref;
    my $year = $self->for_date ? $self->for_date->year : Date::Utility->new->year;
    # pseudo-holiday for country is on 24-Dec and 31-Dec annually
    $holidays{Date::Utility->new($_ . '-' . $year)->days_since_epoch} = 'pseudo-holiday' for qw(24-Dec 31-Dec);

    return \%holidays;
}

=head2 weight_on
Returns the weight assigned to the day of a given Date::Utility object. Return 0.0
for holidays and 1.0 if there is no weight set.
=cut

sub weight_on {
    my ($self, $when) = @_;
    my $weight = $self->holidays->{$when->days_since_epoch};
    return
          (!defined $weight)            ? 1.0
        : ($weight eq 'pseudo-holiday') ? 0.5
        :                                 0.0;
}

=head2 has_holiday_on
Returns true if the currency has a holiday on the day of a given Date::Utility
object. Holidays with weights are not considered real holidays, this sub will
return 0 for them.
=cut

sub has_holiday_on {
    my ($self, $when) = @_;
    my $weight = $self->holidays->{$when->days_since_epoch};
    return defined $weight && $weight ne 'pseudo-holiday';
}

=head2 interest
Returns an interest rates object
=cut

has interest => (
    is         => 'ro',
    isa        => 'Quant::Framework::InterestRate',
    lazy_build => 1,
);

sub _build_interest {
    my $self = shift;

    return Quant::Framework::InterestRate->new({
        symbol           => $self->symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });
}

=head2 rate_for
Returns market rate
=cut

sub rate_for {
    my ($self, $tiy) = @_;

    return $self->interest->rate_for($tiy);
}

# cache of implied rates object(s)
has _cached => (
    is      => 'rw',
    default => sub { return {} },
);

=head2 rate_implied_from
Returns rates implied from another currency
$usd->rate_implied_from('JPY',$tiy) # returns rate of usd implied from jpy for a specific term
=cut

sub rate_implied_from {
    my ($self, $implied_from, $tiy) = @_;

    my $implied_symbol = $self->symbol . '-' . $implied_from;
    return $self->_cached->{$implied_symbol}->rate_for($tiy)
        if $self->_cached->{$implied_symbol};

    $self->_cached->{$implied_symbol} = Quant::Framework::ImpliedRate->new({
        symbol           => $implied_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });

    return $self->_cached->{$implied_symbol}->rate_for($tiy);
}

has _build_time => (
    is      => 'ro',
    default => sub { time },
);

# we cache objects, when we're getting object from cache we should check if it isn't too old
# currently we allow age to be up to 30 seconds
sub _object_expired {
    return shift->_build_time + 30 < time;
}

=head1 METHODS

=head2 new($symbol)

Constructor. Should be used in the following ways:

Saving new interest rates:
  ->new(symbol => 'SYM', rates => {...}, date => Date::Utility->new);
  ->save;

Fetching the latest rates in DB:
  ->new('SYM');
  ->new(symbol => 'SYM');

Fetching historical rates:
  ->new(symbol => 'SYM', for_date => Date::Utility->new('some time in the past'));

=cut

my %_cached_objects;

sub new {
    my ($class, @given) = @_;
    my %args =
          (ref $given[0] eq 'HASH') ? %{$given[0]}
        : (scalar @given == 1) ? (symbol => $given[0])
        :                        @given;

    my $currency;

    # Shall we cache?
    if (exists $args{symbol} and scalar keys %args == 1) {
        my $symbol = $args{symbol};
        $currency = $_cached_objects{$symbol};
        if (not $currency or $currency->_object_expired) {
            $currency = $class->_new(%args);
            $_cached_objects{$symbol} = $currency
                if (scalar keys %{$currency->interest->document});
        }

    } else {
        $currency = $class->_new(%args);
    }

    return $currency;
}

no Moose;
__PACKAGE__->meta->make_immutable(
    constructor_name    => '_new',
    replace_constructor => 1
);

1;
