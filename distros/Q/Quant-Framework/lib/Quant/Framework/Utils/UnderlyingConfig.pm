package Quant::Framework::Utils::UnderlyingConfig;

=head1 NAME

Quant::Framework::Utils::UnderlyingConfig

=head1 DESCRIPTION

This is a data-only module to store static data related to a symbol/underlying
(e.g. Forex, Stocks, Indices, ...)

=cut

use strict;
use warnings;
use 5.010;

use Moose;

=head2 symbol

Symbol name (e.g. frxEURUSD)

=cut

has symbol => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 system_symbol

The symbol used by the system to look up data.  May be different from symbol, particularly on inverted forex pairs (EURUSD/USDEUR)

=cut

has system_symbol => (
    is  => 'ro',
    isa => 'Str',
);

=head2 market_name

Name of the market. Can be one of:
 - forex
 - indices
 - commodities

=cut

has market_name => (
    is  => 'ro',
    isa => 'Str',
);

=head2 market_prefer_discrete_dividend

Should this financial market use discrete dividend

=cut

has market_prefer_discrete_dividend => (
    is => 'ro',
);

=head2 quanto_only

Specifies if this underlying is quanto-only

=cut

has quanto_only => (
    is => 'ro',
);

=head2 rate_to_imply_from 

Name of the underlying to imply interest rates from, when calculating implied interest rate

=cut

has rate_to_imply_from => (
    is  => 'ro',
    isa => 'Str',
);

=head2 volatility_surface_type

Type of volatility surface (moneyness, delta, flat)

=cut

has volatility_surface_type => (
    is  => 'ro',
    isa => 'Str',
);

=head2 exchange_name

Name of the exchange

=cut

has exchange_name => (
    is  => 'ro',
    isa => 'Str',
);

=head2 uses_implied_rate

Whether this underlying uses implied rate or no.

=cut

has uses_implied_rate => (
    is  => 'ro',
    isa => 'Maybe[Bool]',
);

=head2 asset_symbol

Symbol name of the asset (Asset or Currency)

=cut

has asset_symbol => (
    is  => 'ro',
    isa => 'Str',
);

=head2 uses_implied_rate_for_asset

Can we use implied rate for asset symbol?

=cut

has uses_implied_rate_for_asset => (
    is  => 'ro',
    isa => 'Str',
);

=head2 quoted_currency_symbol

Quoted currency of the underlying

=cut

has quoted_currency_symbol => (
    is  => 'ro',
    isa => 'Str',
);

=head2 uses_implied_rate_for_quoted_currency

Can we use implied rate from quoted currency symbol?

=cut

has uses_implied_rate_for_quoted_currency => (
    is  => 'ro',
    isa => 'Str',
);

=head2 extra_vol_diff_by_delta

Volatility difference allowed for this symbol between two consecutive vol-surfaces.
This is used when validating a volatility-surface for this underlying.

=cut

has extra_vol_diff_by_delta => (
    is => 'ro',
);

=head2 market_convention

Returns a hashref. Keys and possible values are:

=over 4

=item * atm_setting

Value can be one of:
    - atm_delta_neutral_straddle
    - atm_forward
    - atm_spot

=item * delta_premium_adjusted

Value can be one of:
    - 1
    - 0

=item * delta_style

Value can be one of:
    - spot_delta
    - forward_delta

=item * rr (Risk Reversal)

Value can be one of:
    - call-put
    - put-call

=item * bf (Butterfly)

Value can be one of:
    - 2_vol

=back

=cut

has market_convention => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        return {
            delta_style            => 'spot_delta',
            delta_premium_adjusted => 0,
        };
    },
);

=head2 default_dividend_rate 

Default dividend of this underlying (If this is not set, Quant::Framework::Dividend will be 
used to lookup dividend)

=cut

has default_dividend_rate => (
    is      => 'ro',
    default => undef,
);

=head2 default_volatility_duration

Default duration for this underlying when getting volatility.

=cut

has default_volatility_duration => (
    is      => 'ro',
    default => undef,
);

=head2 asset_class

Type of asset for this underlying (can be either 'currency' or 'asset')

=cut

has asset_class => (
    is  => 'ro',
    isa => 'Str',
);

has use_official_ohlc => (
    is => 'ro',
);

has spot_db_args => (
    is => 'ro',
);

1;
