# perl-Quant-Framework
A framework of objects upon which to build Financial Derivatives Pricing code.

This framework contains modules for different market data that will be needed to price a derivative contract. These market-data modules will need an instance of `Data::Chronicle::Reader` to read data from storage or `Data::Chronicle::Writer` to write data to storage.

Also note that in all `Quant::Framework` modules you can pass a `for_date` parameter when creating the module to read historical information. In case no `for_date` is provided, modules will work with latest information.

Below is a list of supported modules.

##Quant::Framework::CorporateAction
Represents the corporate actions data of an underlying from database. 

To read actions for a company:
```
my $corp = Quant::Framework::CorporateAction->new(symbol => $symbol,
            chronicle_reader => $reader);
my $actions = $corp->actions;
```
To save actions for a company:
```
#when creating an instance of this module, actions is a hash-ref where key is action identifier (some unique identifier),
and value is a hash-ref containing information about the corporate action.
my $corp = Quant::Framework::CorporateAction
        ->new(symbol => $symbol, 
            chronicle_writer => $writer,
            actions => {
                1234 => {
                    monitor_date => "2014-02-07",
                    type => "ACQUIS",
                    description => "Acquisition",
                    effective_date => "15-Jul-15",
                    flag => "N", #N means new action, U means updated action, D means cancelled action
                }});
$corp->save();
```
##Quant::Framework::InterestRate

Interest rate is the amount of interest paid for deposit money. This can be defined for different periods and different currencies. So we can have different interest rates for each combination of currency and period. Usually interest rates are described as a percentage. For example a 1% interest rate for a period of 1 year for USD currency means you will get 1.01 times your initial deposit money after one year. For more information please refer to [Interest rate](https://en.wikipedia.org/wiki/Interest_rate).

This module helps you save/load interest rates to/from a `Data::Chronicle` storage system. When creating an instance of this module you will need to specify symbol (The name of the currency for which you want to save/load interest rate) and a hash-ref named rates. Rates is a hash-table where key is duration (period in days) and the corresponding value is the interest rate percentage paid for that duration.

To save interest rates:

```
#Here USD is the currency, "7, 30 and 90" are durations and 
#corresponding values "0.5, 1.2 and 2.4" are interest rates

my $ir_data = Quant::Framework::InterestRate->new(
            symbol => 'USD',
            rates => { 
                        7 => 0.5, 
                        30 => 1.2, 
                        90 => 2.4 
                     },
            chronicle_writer => $chronicle_w);
            
$ir_data->save;
```

To load interest rates for a currency:

```
my $ir_data = Quant::MarketData::InterestRate->new(
            symbol => 'USD'
            chronicle_reader => $chronicle_r);

my $rates = $ir_data->rates;
```
 
##Quant::Framework::ImpliedRate

Implied interest rate is the interest rate for a currency which is implied from :
* Forward price for the currency pair
* Interest rate of the counter-party currency

For example if we have Forward rate for EUR/USD and interest rate for USD, we can calculate implied interest rate for EUR, using the Spot-Forward price relationship.

This module helps you save/load implied interest rates to/from a `Data::Chronicle` storage system. When creating an instance of this module you will need to specify combined symbol (The name of the currency for which you want to save/load implied interest rate and the currency from which you have implied this rates) and a hash-ref named rates. Rates is a hash-table where key is duration (period in days) and the corresponding value is the interest rate percentage paid after that duration.

```
my $ir_data = Quant::Framework::ImpliedRate->new(
            symbol => 'USD-EUR',
            rates => { 
                        7 => 0.5, 
                        30 => 1.2, 
                        90 => 2.4 
                     },
            chronicle_writer => $chronicle_w);
            
$ir_data->save;
```

To read implied interest rates for a currency:

```
my $ir_data = Quant::Framework::ImpliedRate->new(
            symbol => 'USD-EUR',
            chronicle_reader => $chronicle_r);

my $rates = $ir_data->rates;
``` 
 
##Quant::Framework::Currency

The representation of currency. You can use this module to query for a currency's interest rates, holidays and query for already saved implied interest rates. This module relies on `Quant::Framework::Holiday` to fetch holiday information for it's currency.

Below example shows how to create instances of this module and query information from that module:

```
my $currency = Quant::Framework::Currency->new(
            symbol => 'AUD',
            chronicle_reader => $chronicle_r);

#here $time_in_years is the duration for which we need to get dividend rates.
my $rates = $currency->rate_for($time_in_years);

#this call will return a hash-reference whose keys are number of days since epoch and value is description 
#of the holiday.
my $holidays = $currency->holidays;

#this will return a floating number (0 if the days is holiday, 0.5 if it's a pseudo-holiday 
# and 1 if it's a normal trading day)
my $weight = $currency->weight_on(Date::Utility->new('2016-03-21'));

my $is_holiday = $currency->has_holiday_on(Date::Utility->new('2016-1-1');
```

##Quant::Framework::CorrelationMatrix

Correlation matrix is a 2-D array which shows correlation between indices and currencies for different time periods.
Rows of the matrix represent different currencies (e.g. AUD, USD, ...). Columns represent indices (e.g. DJI) and for each cell of the matrix, there is a list of correlations for different time period (e.g. 3 months, 6 months, ...).

This modules is used to load/save a correlation matrix and query for correlations. It relies on `Quant::Framework::ExpiryConventions` to do its calculations.

To save a correlation matrix:

```
my $matrix = Quant::Framework::CorrelationMatrix->new(
            symbol => 'indices',
            chronicle_writer => $chronicle_w);
            
#Input data for correlation matrix should be initialized like this:
my $data = ();

$data->{'DJI'}->{'AUD'}->{'3M'} = 0.3;
$data->{'DJI'}->{'JPY'}->{'6M'} = 0.12;
$data->{'DJI'}->{'GBP'}->{'12M'} = 0.83;

$matrix->correlations($data);
$matrix->save;

```

To load correlation matrix and query information:

```
my $matrix = Quant::Framework::CorrelationMatrix->new(
            symbol => 'indices',
            chronicle_reader => $chronicle_r);
            
my $time_in_years = 0.5;

#This will return a floating number representing the correlation between DJI index and AUD currency
#over a 6-month period.
my $correlation = $matrix->correlation_for('DJI', 'AUD', $time_in_years, $expiry_conventions);

```

##Quant::Framework::Asset

Dividend is the capital gains for an underlying after a period of time. For more information please refer to [Dividend](https://en.wikipedia.org/wiki/Dividend).

This module saves/loads dividends data to/from Chronicle and query dividend rates for a specific period of time. 

To save dividends for an underlying:

```
my $dividends = Quant::Framework::Asset->new(
            symbol => $symbol,
            rates => { 
                        1 => 0, 
                        2 => 1, 
                        3 => 0.04 
                     },
            discrete_points => 
                     { 
                        '2015-04-24' => 0, 
                        '2015-09-09' => 0.134 
                     },
            chronicle_writer => $chronicle_w);
$dividends->save;
```

To read dividends information and query rates for an underlying:

```
my $dividends = Quant::Framework::Asset->new(
            symbol => $symbol,
            chronicle_reader => $chronicle_r);

my $rates = $dividends->rates;

my $time_in_years = 0.5;
my $sixmonth_rate = $dividends->rate_for($time_in_years);
```

##Quant::Framework::EconomicEventsCalendar

Represents a calendar of important economic announcement made by central banks (e.g. Unemployment Rate or CPI) or other major player in the financial markets.
An instance of this module will contain all current economic announcement for all underlyings.

To save economic events:

```
my $calendar = Quant::Framework::EconomicEventCalendar->new({
            recorded_date => $dt,
            #events is a list of hash-refs each containing an economic event
            events => [
            {
                source => 'net',
                event_name => 'Labor Market Conditions Index m/m',
                symbol => 'USD',
                release_date => 1465221600, #this is epoch of the release date-time
                recorded_date => Date::Utility->new->epoch, #this is epoch of the time when this record is being saved
                impact => 1  #importance of this event (1 = low impact, 3 = medium impact, 5 = high impact)
            },
            {
                source => 'net',
                event_name => 'Cash Rate',
                symbol => 'AUD',
                release_date => 1465273800,
                recorded_date => Date::Utility->new->epoch, 
                impact => 3
            },
            {
                source => 'net',
                event_name => 'Announcement1',
                symbol => 'JPY',
                release_date => 1465273600,
                recorded_date => Date::Utility->new->epoch, 
                impact => 5,
                is_tentative => 1,
            },
            ],
            chronicle_writer => $chronicle_w
});
$calendar->save;
```

To read an economic event calendar:

```
my $calendar = Quant::Framework::EconomicEventCalendar->new(
            chronicle_reader => $chronicle_r
            );
my @events = @{$calendar->events};
#first_event will be a hash-ref with same structure as the one we used to save economic events.
my $first_event = $events[0];

#here we fetch all economic events whose release_date lies inside the given time period
my $events = $calendar->get_latest_events_for_period({
            from => Date::Utility->new('2015-01-10'),
            to => Date::Utility->new('2015-01-20')});

#get a list of tentative economic events
my $tentatives = $calendar->get_tentative_events;
            
```

##Quant::Framework::Exchange

Each underlying can only be traded in a specific exchange. As a result of this, some properties of the exchange (e.g. opening or closing time or holidays) will affect when/how an underlying is being traded.

This module represents basic information about an exchange. More specific information about an exchange (including open/close times) can be get using `TradingCalendar` module. The information you get from this module are stored in the `exchange.yml` file stored in `share` directory of this repository.

To read information about an exchange:

```
my $exchange = Quant::Framework::Exchange->new(
            symbol => 'NASDAQ',
);

my $name = $exchange->display_name;
my $currency = $exchange->currency;
my $timezone = $exchange->trading_timezone;

#value of trading_days can be:
# everyday -> 7 days a week
# weekdays -> 5 week-days of week (excluding weekends)
# sun_thru_thu -> from Sunday to Thursday
my $trading_days = $exchange->trading_days;

```

##Quant::Framework::Holiday

This module stored information regarding holidays for exchanges or currencies. Each exchange around the world is closed at certain days through a year same holds for countries. Underlyings whose currency or exchange are closed cannot be traded. So we need these information to make a decision about whether or not offer an underlying.

This module can be used to save/load holiday information and query whether a symbol has a holiday on a certain date.

To save holidays:
```
my $holidays = Quant::Framework::Holiday->new(
            #calendar is a hash-ref whose keys are epochs of the holiday and value is a list of holidays on that day.
            #Each holiday in the list is represented using a hash-ref (key is name of the holiday and value is 
            #    an array containing name of exchanges or currencies which are affected by that holiday).
            calendar => {
                1456790400 => [ 'Independence Movement Day' => [ 'KRX' ],
                              [ 'Independence Day' => ['KRW'] ],
                1472428800 => [ 'Summer Bank Holiday' => [ 'LSE', 'ICE_LIFFE', 'GBP' ] ]
            },
            chronicle_writer => $chronicle_w,
);

$holidays->save;
```

To read holiday information and do queries:

```
my $holidays = Quant::Framework::Holiday->new(
            chronicle_reader => $chronicle_r);
            
my $calendar = $holidays->calendar;
#this will return all holidays for USD
my $holiday_info = Quant::Framework::Holiday::get_holidays_for($chronicle_r, 'USD');
```

##Quant::Framework::PartialTrading

Partial trading means times when an exchange is opened later than usual (late open) or closed earlier than usual (early close). This modules lets you save information about partial trading calendar or query partial trading calendar for a specific exchange.

To save partial trading data:
```
my $partial_trading = Quant::Framework::PartialTrading->new(
            type => 'late_opens',  #this can be either 'late_opens' or 'early_closes'
            #calendar is a hash-ref where keys are epoch denoting the day for partial-trading
            #value is a hash-ref too where key is late opening time (in this case) and value is array
            #of affected exchanges. For opening time of 2h30m means exchange will be opened later 
            #than usual at 2:30 GMT.
            calendar => {
                        1293148800 => { 2h30m => [ 'HKSE' ] },
                        1388620800 => { 9h => [ 'EURONEXT' ] },
            },
            chronicle_writer => $chronicle_w);

$partial_trading->save();
```

To query partial trading information:

```
my $partial_trading = Quant::Framework::PartialTrading->new(
            type => 'early_closes',
            chronicle_reader => $chronicle_r);

my $calendar = $partial_trading->get_partial_trading_for('HKSE');

#here we query early closing time for HKSE exchange at 3rd of Jan 2016. 
#$early_close_time will have same format as to when we store data (2h30m representing 02:30 GMT)
my $early_close_time = $calendar->{Date::Utility->new('2016-01-03')->epoch};
```

##Quant::Framework::TradingCalendar

This module is responsible for everything related to time-based status of an exchange (whether exchange is open/closed, has holiday, is partially open, ...)
Plus all related helper modules (trading days between two days where exchange is open, trading breaks, DST effect, open/close time, ...).
One important feature of this module is that it is designed for reading information not writing. It relies on the data which is already saved by `Quant::Framework::Holiday` and `Quant::Framework::PartialTrading`.

You can query different time-based information using this module. Below is an example. For more information refer to POD documentation of the module.

```
my $calendar = Quant::Framework::TradingCalendar->new(
            'LSE',
            $chronicle_r);

my $is_traded = $calendar->trades_on(Date::Utility->new('2015-09-29'));
my $is_in_break = $calendar->is_in_trading_break(Date::Utility->new('2016-03-09 12:20')->epoch);

#does the exchnage close early today?
my $is_closing_early = $calendar->closes_early_on(Date::Utility->new);
```

##Quant::Framework::ExpiryConventions

This module is used to convert tenor from a volsurface or correlation matrix to an actual date based on respective market conventions. After initializing this module with required inputs, you can invoke its `vol_expiry_date` and `forward_expiry_date` functions.

To use this module:
```
my $expiry_conventions = Quant::Framework::ExpiryConventions->new(
    chronicle_reader => $chronicle_r,
    is_forex_market  => 1,
    symbol           => 'frxEURUSD',
    asset            => $asset,
    quoted_currency  => $quoted_currency,
    asset_symbol     => 'EUR',
    calendar         => $trading_calendar);
    
my $expiry_date = $expiry_conventions->vol_expiry_date({
    from => Date::Utility->new,
    term => '1W'
);

my $expiry_date2 = $expiry_conventions->forward_expiry_date({
    from => $date,
    term => '1W'
});
```

##Quant::Framework::VolSurface

A Volatility Surface is a two dimensional matrix which represents variance in the price of an underlying for different time periods (rows of the matrix) and different strikes (columns of the matrix). These time periods are called tenor. As per market convention, we manage two type of surfaces: Delta (used for Foreign Exchange underlyings) and Moneyness (used for Stocks and Indices). Each row of a Volatility Surface depicts volatility across various strikes/delta points. For more information about Volatility Surface and Smile please refer to (Volatility smile)[https://en.wikipedia.org/wiki/Volatility_smile].

This module is the parent of two other modules: `Quant::Framework::VolSurface::Delta` and `Quant::Framework::VolSurface::Moneyness`. You can store, fetch and query a Volatility Surface using these modules.

To work with these modules you have to first initialize an instance of `Quant::Framework::Utils::UnderlyingConfig`. This module is used to store basic information for an underlying (symbol name, volatility surface type, exchange name, asset symbol name, etc.). For more information about attributes of this module please refer to POD documentation for this module.

To save a volatility surface:
```
#note that to create a Moneyness surface , you will also need to (Moneyness is defined as Strike/Spot) provide a spot_reference parameter #which denotes the spot price reference using which respective strikes/barriers are calculated.
my $surface = Quant::Framework::VolSurface::Delta->new(
            underlying_config => $eurusd_underlying_config,
            surface => {
                            1 => {
                                tenor => 'ON',
                                vol_spread => {
                                    25 => 0.04,
                                    50 => 0.029,
                                    75 => 0.042
                                },
                                smile => {
                                    25 => 0.11,
                                    50 => 0.113,
                                    75 => 0.116
                                }
                            },
                            7 => {
                                tenor => '1W',
                                vol_spread => {
                                    25 => 0.05,
                                    50 => 0.039,
                                    75 => 0.048
                                },
                                smile => {
                                    25 => 0.12,
                                    50 => 0.123,
                                    75 => 0.126
                                }
                            }
                       },
            chronicle_writer => $chronicle_w
);
$surface->save;
```

To fetch and query a volatility surface:

```
my $surface = Quant::Framework::VolSurface::Delta->new(
    underlying_config => $eurusd_underlying_config,
    chronicle_reader => $chronicle_r
);

#fetch value of Volatility Smile for a given period and 25 delta
my $vol = $surface->get_volatility(
    {
        delta => 25,
        from  => $from, # Date::Utility object
        to    => $to    # Date::Utility object
    });
```
##Quant::Framework::Spot

This module is responsible for storage and retrieval of spot prices for different underlyings. The spot price is stored in local Redis (on default port) for fast retrieval. For historical data, a database handle is expected as input which will be used to fetch historical spot and OHLC values. 

There are some naming conventions in this module which user of the module needs to obey in order to use provided utilities. These conventions determine naming of tables and functions in the database. The tables and their structure are designed to match general layout of database tables which store ticks. For example a table `feed.tick` is expected to be in the database where it contains underlying name, timestamp and spot value. 

If you don't have a table with the same name in your DB system, you can easily create a view with the expected name and structure `tick`. If your DBMS does not support schemas or you are not using this feature, you can replace `default_prefix` argument in the `Quant::Framework::Spot::DatabaseAPI` with your desired value. In order to do this, you will need to setup an instance of `underlying_config`, pass it to `Builder` module and then call it's `build_feed_api` method. For example:

```
my $db_args = { handle => $dbh, underlying => 'frxEURUSD', default_prefix => undef };

$underlying_config->{spot_db_args} = $db_args;
my $builder = Quant::Framework::Utils::Builder->new(chronicle_reader => $c_r, underlying_config => underlying_config);

my $database_api = $builder->build_feed_api;
```

You can also create the `DatabaseAPI` module directly. For example:

```
use Quant::Framework::Spot::DatabaseAPI;

$db_api = Quant::Framework::Spot::DatabaseAPI->new({
    use_official_ohlc => 1,
    dbh               => $handle,
    inverted          => 1,
});

```

`dbh` is a handle to the database. You can pass a db handler or a sub-routine which will return handle.

If `inverted` argument is set, all tick values returned from this module will be inverted (`1/x` instead of `x`). This is
useful when you have quotes for `EURUSD` but want to read values for `USDEUR`.

This module contains some utility methods, most important of which are, `tick_at` and `ohlc_start_end`.

```
my $db = Quant::Framework::Spot::DatabaseAPI->new({
    use_official_ohlc => 0,
    dbh               => $db_handle,
});

my $spot = $db->tick_at({ 
    end_time => $timestamp,
    allow_inconsistent => 1,
});

my $ohlc = $db->ohlc_start_end({
    start_time  => $start_ts,
    end_time    => $end_ts,
    aggregation_period => $num_seconds_per_ohlc_instance
});

my @ohlc_bars = @{$ohlc};
```

The first call above, request for latest tick at given time (`$timestamp`) and the second one asks
for daily OHLC values at given time.

`allow_inconsistent` parameters determines how the case should be handled when there is no tick at the 
exact requested timestamp. If value of this parameter is `1`, then the code will return tick at or before the given timestamp.
If it is passed as `0`, the code will return a tick at or before given timestamp if we have a tick after the given timestamp.

To work with the Spot module:

```
use Quant::Framework::Spot;

my $spot = Quant::Framework::Spot->new({
    symbol            => 'frxEURUSD',
    calendar          => $calendar,
    for_date          => Date::Utility->new('2016-01-01 12:15:39'),
    use_official_ohlc => 0,
    feed_api          => $builder->build_feed_api,
});

my $tick = $spot->spot_tick;
my $quote = $spot->spot_quote;

```

Note that in above sample, `for_date` is optional and if missing means we need latest spot information for current time.
The `calendar` argument is an instance of `Quant::Framework::TradingCalendar` which will be used to calculate
trading times for cases where `use_official_ohlc` is enabled. 

You can also instantiate `Spot` using `Builder`: 

```
my $builder = Quant::Framework::Utils::Builder->new(chronicle_reader => $c_r, underlying_config => underlying_config);

my $spot_source = $builder->build_spot;
```

There are some utility methods in `Quant::Framework::Spot` to help you get spot information (e.g. `spot_quote`, `spot_time`, `spot_age`).
When there is a request for latest spot tick (`spot_tick` method), local Redis cache is queried for a pattern like `PREFIX::frxEURUSD` to retrieve tick data, where `PREFIX` is the value of `default_redis_key` field in the `Spot` module. 

You can call `set_spot_tick` to set tick for an underlying (This should normally be called when a new tick is received in the system). 

When requesting for historical tick, database query is used through `DatabaseAPI`. This module expects `feed_api` parameter which is used for this purpose. This will be an instance of `Quant::Framework::Spot::DatabaseAPI` which you can create according to instructions mentioned before.`feed_api` is used to interact with Feed database and extract historical spot ticks. Even if you don't need historical spot prices, you will need to pass this argument because it will be used in the case RedisDB lacks the required information.  

There is also two data-only modules (`Quant::Framework::Spot::Tick` and `Quant::Framework::OHLC`) which hold information regarding a tick or a OHLC bar. Normally you don't need to create instances of these modules. They are return value of spot-related functions.

###DB requirements for Quant::Framework::Spot
Spot module assumes existence of a PostgreSQL database with below specifications:

- `feed.tick`: This table contains (underlying, ts, quote) columns indicating underlying symbol, timestamp and correcponding spot value at the time of `ts`.
- `tick_at_for_interval(underlying, start, end, interval)`: This function will returns list of ticks at the given period (start, end).
- `ticks_start_end(underlying, start, end)`: This function will return list of ticks inside the given period. 
- `ticks_start_limit(underlying, start, limit)`: This function returns `limit` number of ticks starting from `start` time.
- `ticks_end_limit(underlying, end, limit)`: This function will return last `limit` number of ticks ending at `end` time.
- `tick_at_or_before(underlying, timestamp)`: This function will return last tick before given timestamp.
- `consistent_tick_at_or_before(underlying, timestamp)`: This function will return a tick at or after given timestamp.
- `tick_after(underlying, time)`: This will return first tick after given time.
- `ticks_start_end_with_limit_for_charting(underlying, start, end, limit)`: This will return a list of at most `limit` latest ticks inside (start, end) period.
- `ohlc_start_end(underlying, period, start, end, official)`: This will returns a list of OHLC (Open, High, Low, Close) values for the market inside (start, end) period, aggregating `period` minutes into one OHLC data. If `official` parameter is set, it will lookup for official OHLC values.
- `ohlc_daily_list(underlying, start, end , official)`: This will return daily OHLC values inside given period (start, end).
- `ohlc_start_end_with_limit_for_charting(underlying, period, start, end, official, limit)`: This function is same as `ohlc_start_end` with the exception that it accepts a `limit` parameter which can be useful for charting purposes. This parameter will limit number of output items.
