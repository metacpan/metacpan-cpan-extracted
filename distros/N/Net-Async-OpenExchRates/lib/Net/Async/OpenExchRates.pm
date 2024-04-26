package Net::Async::OpenExchRates;

# ABSTRACT: Interaction with OpenExchangeRates API

use v5.26;

use warnings;
use Object::Pad 0.800;

class Net::Async::OpenExchRates :isa(IO::Async::Notifier);

our $VERSION = 0.004;

our $AUTHORITY = 'cpan:VNEALV'; # AUTHORITY

=head1 NAME

C<Net::Async::OpenExchRates> - interact with L<OpenExchangeRates API|https://openexchangerates.org/> via L<IO::Async>

=head1 SYNOPSIS

 use Future::AsyncAwait;
 use IO::Async::Loop;
 use Net::Async::OpenExchRates;

 my $loop = IO::Async::Loop->new();
 my $exch = Net::Async::OpenExchRates->new(
    app_id => 'APP_ID',
 );
 $loop->add( $exch );

 my $latest = await $exch->latest();

=head1 DESCRIPTION

This module is a simple L<IO::Async::Notifier> wrapper class with a L<Net::Async::HTTP> object constructed using L<Object::Pad>.
Made to communicate with I<OpenExchangeRates API> providing all its available endpoints as methods to be called by a program.

Acting as an active Asynchronous API package for L<Open Exchange Rates|https://openexchangerates.org/>
following its L<API docs|https://docs.openexchangerates.org> along with providing extra functionalities
like pre-validation, local caching and respecting API update frequency depending on your C<APP_ID> subscription plan.

For examples and more ways to use this package, please check Examples directory in L<package distribution page|https://metacpan.org/dist/Net-Async-OpenExchRates>

=head1 CONSTRUCTOR

=head2 new

 $exch = Net::Async::OpenExchRates->new( %args );

Returns a new C<Net::Async::OpenExchRates> instance,
which is a C<IO::Async::Notifier> too,
where one argument is required with others being optional, detailed as so:

=over 4

=item app_id => STRING (REQUIRED)

The only required argument to be passed.
Can be obtained from I<OpenExchangeRates> L<Account page|https://openexchangerates.org/account/app-ids>.

=item base_uri => STRING

C<default: 'https://openexchangerates.org'>

The URL to be used as the base to form API request URI.

=item use_cache => BOOL

C<default: 1>

Toggle to enable/disable the use of L<Cache::LRU> to have the response locally available
for repeated requests only if the API responded with C<304 HTTP> code for a previously cached request.
As I<OpenExchangeRates API> offers L<Cache Control|https://docs.openexchangerates.org/reference/etags>
utilizing ETag identifiers.
Having this enabled is effective for saving on network bandwidth and faster responses,
but not much on API usage quota as it will still be counted as a resource request.

=item cache_size => INT

C<default: 1024>

The size limit for the L<Cache::LRU> object.
The maximum number of previous requests responses to be kept in memory.

=item respect_api_frequency => BOOL

C<default: 1>

As every I<OpenExchangeRates API> L<subscription plan|https://openexchangerates.org/signup> comes with
its own number of permitted requests per month and resources update frequency. This option is made purely
to allow your program to query repeated requests without overwhelming API. If the request is already cached meaning we already have its
response from a previous request invocation, it will check on the current resources C<update_frequency> from C<usage.json>
API call, if the C<Last-Modified> timestamp HTTP header that is attached with our existing response compared to current time is less
than C<update_frequency> then most probably even if we call the API it will return C<304 HTTP>, hence in this case
respect the API and instead of requesting it to confirm, return the response we already have without requesting again.

Suitable for repeated requests, and using a restricted subscription plan.


=item enable_pre_validation => BOOL

C<default: 1>

Mainly requested currencies, date/time values along with other limitations for some endpoints.
These options are here to toggle whether to validate those parameters before requesting them or not.

=item local_conversion => BOOL

C<default: 1>

Given that C<convert> API endpoint is only available for Unlimited subscription plan,
this option is to allow your program to perform conversion function locally, without applying any formatting
to calculated amount. Not that if you want to use the API instead for L</convert> method you need to pass this as C<0>

=item keep_http_response => BOOL

C<default: 1>

Used to allow your program to access the complete L<HTTP::Response> from the last
API request made through L</last_http_response>. If turned of by passing C<0> last_http_response will stay empty.

=back

=cut

use Future::AsyncAwait;
use Syntax::Keyword::Try;
#use Syntax::Keyword::Dynamically;
use Log::Any qw($log);
use Net::Async::HTTP;
use URI;
use JSON::MaybeUTF8 qw(:v1);
use Digest::MD5 ();
use Time::Moment;
use feature qw(current_sub);

field $_app_id :param :accessor;
field $_base_uri :param = 'https://openexchangerates.org';
field $_use_cache :param = 1;
field $_cache_size :param = 1024;
field $_respect_api_frequency :param = 1;
field $_enable_pre_validation :param = 1;
field $_local_conversion :param = 1;
field $_keep_http_response :param = 1;
field $_api_query_params :accessor = [qw(base symbols show_bid_ask show_alternative prettyprint callback show_inactive start end period)];
# fields be populated from API response rather than hardcoded here.
# qw(name quota features update_frequency)
field $_app_plan_keys :accessor;
# qw(daily_average days_elapsed requests_remaining requests days_remaining requests_quota)
field $_app_usage_keys :accessor;
# qw(bid-ask time-series ohlc convert base symbols spot experimental)
field $_app_features_keys :accessor;
field $_usage;
field $_currencies;
# control fields
field $_last_http_response :accessor;
field $_http;
field $_cache;
# helper fields
field $_m_hash = {jan => 1, feb => 2, mar => 3, apr => 4, may => 5, jun => 6, jul => 7, aug => 8, sep => 9, oct => 10, nov => 11, dec => 12};
field $_flatten_out_list = sub {
    return map {
        ref($_) eq 'ARRAY' ? __SUB__->(@$_) : split(',', $_)
    } @_;
};
field $_date_validation = sub {
    my $date = shift;
    my %date_validation;
    @date_validation{qw(year month day)} =  map { $_ + 0 } $date =~ /^([0-9]{4})-([1-9]|1[012]|0[1-9])-([1-9]|[12][0-9]|3[01]|0[1-9])$/;
    Future::Exception->throw("Wrong date format $date", 'DATE FORMAT', $date, %date_validation)
        if grep { ! defined } values %date_validation;
    return %date_validation;
};
field $_time_obj_from_date_str = sub{
    my $date_str = shift;
    my ($day, $month, $year, $time) =
        $date_str =~ m/^[a-zA-Z]{3},\s([1-9]|[12][0-9]|3[01]|0[1-9])\s([A-Za-z]{3})\s(\d{4})\s(\d{2}:\d{2}:\d{2}\s\w{3})/;
    my $date;
    try {
        my @defined = grep { defined $_ } ($year, $month, $day, $time);
        die if scalar(@defined) < 4;
        $date = Time::Moment->from_string(sprintf('%04d-%02d-%02d %s', $year, $_m_hash->{lc$month}, $day, $time), lenient => 1);
    } catch ($error) {
        $log->warnf('Unable to create time object from date string. %s %s', $date_str, $error);
        $date = undef;
    }
    return $date;
};


method configure_unknown(%args) {}
ADJUST {
    if ($_use_cache) {
        $log->tracef('Setting up LRU Cache object with size: %s', $_cache_size);
        use Cache::LRU;
        $_cache = Cache::LRU->new(size => $_cache_size);
    }
}

method _add_to_loop($loop) {
    $self->add_child($_http = Net::Async::HTTP->new(
            fail_on_error            => 1,
            close_after_request      => 0,
            max_connections_per_host => 2,
            pipeline                 => 1,
            max_in_flight            => 4,
            decode_content           => 1,
            stall_timeout            => 15,
            user_agent               => 'Mozilla/4.0 (perl; Net::Async::OpenExchRates; VNEALV@cpan.org)',
            require_SSL              => 1,
            +headers                 => {
                authorization => join(' ', 'Token', $_app_id),
                accept_encoding => 'application/json'
            },
        ));
}

async method $cache_get($key) {
    if ( $_use_cache ) {
        # no point in hashing anything if we are not using cache
        $key = Digest::MD5::md5_hex($key);
        my $v = $_cache->get($key);
        if ($v) {
            $log->tracef('cache hit %s, ETag: %s', $key, $v->[0]);
            return ($key, $v->[0], $v->[1], $v->[2]);
        }
    }
    return ($key);
}

method $parse_response($request) {
    my $e_tag = $request->header('ETag');
    my $date_tag = $request->header('Last-Modified');
    my $response;
    try {
        $response = decode_json_utf8($request->decoded_content);
    } catch($error) {
        $log->warnf('Failed to parse response: %s | %s', $request, $error);
        return (undef);
    }
    return (
        $response,
        $request->header('ETag'),
        $request->header('Last-Modified'),
    );
}

async method $within_plan_update_freq($date_tag) {
    my $update_frequency = await $self->plan_update_frequency();
    my $last_modified = $_time_obj_from_date_str->($date_tag);
    return 0 unless $last_modified;
    return $last_modified->delta_seconds(Time::Moment->now()) < $update_frequency;
}

=head1 METHODS

All available methods are C<async/await> following L<Future::AsyncAwait> and L<Future>



=head2 do_request

   await $exch->do_request($page, %args);

The generic method to perform HTTP request for any I<OpenExchangeRates API> endpoint.
It has the gist of the logic, from trying to check Cache if the request has been made before
to actually triggering the request and parse its response. Takes to main arguments:

=over 4

=item $page

as in the endpoint name that needs to be requested.

=item %args

A hash containing the named parameters to be passed as query parameters to the API call URI.

=back

use only when you want parse the complete request yourself, you should be able to get all whats needed from API
using other methods.

=cut

async method do_request($page, %params) {
    my ( $headers, $response, $cache_key );

    ($cache_key, $headers->{if_none_match}, $headers->{if_modified_since}, $response) = await $self->$cache_get(join('|', $page, map { $params{$_} || () } @$_api_query_params));

    if ( $_respect_api_frequency && defined $response && defined $headers->{if_modified_since} ) {
        my $within_freq = await $self->$within_plan_update_freq($headers->{if_modified_since});
        $log->tracef('respecting API  , within api freq: %s', $within_freq);
        return $response if $within_freq;
    }

    my $url = URI->new(join '/', $_base_uri, 'api', $page);
    $url->query_form(map {defined $params{$_} ? ($_ => $params{$_}) : ()} @$_api_query_params);

    my $request;
    try {
        $request = await $_http->do_request(
            method => 'GET',
            uri => $url,
            headers => $headers,
        );
        $log->tracef('Page (%s) requested: %s', $page, $request->status_line);
        $_last_http_response = $request if $_keep_http_response;
    } catch($error) {
        my ($r) = $error->details;
        my $content;
        $content = decode_json_utf8($r->content) if ref $r eq 'HTTP::Response';
        my $message = defined $content ? $content->{message} : $error->message;
        Future::Exception->throw( $message, 'API CALL FAILED', $content, $error->details);
    }

    if ($request->code == 200) {
        my ($res, $e_tag, $date_tag) = $self->$parse_response($request);
        if ( defined $e_tag && defined $date_tag && $_use_cache ) {
            $log->tracef('Setting cache: %s', $cache_key);
            $_cache->set($cache_key => [$e_tag, $date_tag, $res]);
        }
        $response = $res;

    } elsif ($request->code == 304) {
        $log->tracef('Not modified, using cached value for response for page: %s', $page);
    }
    return $response;
}


async method validate_symbols_list(@symbols) {
    @symbols = map { uc $_ } $_flatten_out_list->(@symbols);
    await $self->currencies unless defined $_currencies;
    foreach (@symbols) {
        Future::Exception->throw("Wrong Currency symbol requested ($_)", 'WRONG CURRENCY', {requested => [@symbols], allowed => $_currencies})
            unless exists $_currencies->{$_};
    }
    return @symbols;
}

=head2 latest

   await $exch->latest();
   await $exch->latest('USD', 'CAD', ['JPY']);

To request L<latest.json enpoint|https://docs.openexchangerates.org/reference/latest-json> from API.
It accepts a list, C<ARRAYref> or a mixture of both for currencies as an argument where:

=over 4

=item $base currency

as the B<first> param where its C<default: 'USD'>

=item @symbols

the rest of the list as symbols to be filtered.

=back

Note that C<show_alternative> is always passed as C<true> to the API.

=cut

async method latest($base = 'USD', @sym) {
    @sym = map { uc $_ } $_flatten_out_list->(@sym);
    await $self->validate_symbols_list(@sym) if $_enable_pre_validation;
    await $self->do_request(
        'latest.json',
        @sym ? (symbols => join(',', @sym)) : (),
        base => $base,
        show_alternative => 'true'
    );
}

=head2 historical

   await $exch->historical($date, $base, @symbols);
   await $exch->historical('2024-04-04', 'CAD');

To request L<historical/*.json endpoint|https://docs.openexchangerates.org/reference/historical-json> from API.
Used to retrieve old rates, takes multiple parameters:

=over 4

=item $date

required parameter; scalar string following a date format C<YYYY-MM-DD>

=item $base

base currency to be used with the request, C<default: 'USD'>.

=item @symbols

the rest of parameters will be taken the list of symbols to be filtered out.
Can be passed as a flat list, an C<ARRAYref> or mix of both.

=back

note that show alternative is always on.

=cut

async method historical($date, $base = 'USD', @sym) {
    $_date_validation->($date);
    @sym = map { uc $_ } $_flatten_out_list->(@sym);
    await $self->validate_symbols_list(@sym) if $_enable_pre_validation;
    await $self->do_request(
        sprintf('historical/%s.json', $date),
        @sym ? (symbols => join(',', @sym)) : (),
        base => $base,
        show_alternative => 'true'
    );
}

=head2 currencies

   await $exch->currencies();
   # to list inactive currencies
   await $exch->currencies(0, 1);

To request L<currencies.json endpoint|https://docs.openexchangerates.org/reference/currencies-json> from API.
it mainly returns list of offered currencies by I<OpenExchangeRates API>.
takes two optional parameters:

=over 4

=item $show_alternative

passed as C<0> or C<1>, donating to include alternative currencies or not.

=item $show_inactive

passed as C<0> or C<1>, donating to list inactive currencies or not.

=back

=cut

async method currencies($show_alternative = 1, $show_inactive = 0) {
    my $currencies = await $self->do_request('currencies.json', show_alternative => $show_alternative, show_inactive => $show_inactive);
    # only update $_currencies when show_alternative is enabled
    # since we will use it to validate other requests params
    $_currencies = $currencies if ( $show_alternative && !$show_inactive );
    return $currencies;
}

=head2 time_series

   await $exch->time_series($start, $end, $base, @symbols);
   await $exch->time_series('2024-04-02', '2024-04-04');

To request L<time-series.json endpoint|https://docs.openexchangerates.org/reference/time-series-json> from API.
Essentially its multiple historical requests just handled by I<OpenExchangeRates API> itself. Takes a couple of
parameters:

=over 4

=item $start

Required start date of the period needed. Following C<YYYY-MM-DD> format.

=item $end

Required end date of the period needed. Following C<YYYY-MM-DD> format.

=item $base

Base currency for the prices requested. C<default: 'USD'>

=item @symbols

Symbols to be filtered out, can be passed as a flat list list or an C<ARRAYref>

=back

=cut

async method time_series($start, $end, $base = 'USD', @sym) {
    $_date_validation->($start);
    $_date_validation->($end);
    @sym = map { uc $_ } $_flatten_out_list->(@sym);
    await $self->validate_symbols_list(@sym) if $_enable_pre_validation;
    await $self->do_request(
        'time-series.json',
        start => $start,
        end => $end,
        @sym ? (symbols => join(',', @sym)) : (),
        base => $base,
        show_alternative => 'true'
    );
}

=head2 convert

   await $exch->convert($value, $from, $to, $reverse_convert);
   await $exch->convert(22, 'USD', 'CAD');
   await $exch->convert(22, 'JPY', 'USD', 1);

To request L<convert endpoint|https://docs.openexchangerates.org/reference/convert> from API.
This endpoint is only available in Unlimited subscription plan, however you can enable L</local_conversion>
which will allow you to perform conversion operation locally, applying a simple math equation with no formatting to returned value
so make sure to apply your own decimal point limit to returned value. Accepts these parameters:

=over 4

=item $value

The amount you'd like to be converted. keep in mind that I<OpenExchangeRates API> only accepts C<INT> values.
However enabling L</local_conversion> will accept none integer values too and be able to convert it.

=item $from

The currency of the C<$value> passed above, passed as three characters.

=item $to

The currency to be converted to.

=item $reverse_convert

This is used when L</local_conversion> is enabled, in order to overcome another restriction on API.
Which is to get the prices of base currencies other than C<USD>. Set it to C<1> when you want to make it to use C<$to>
for base to convert, and let it be as C<default: 0> to use C<$from> currency as the base to convert.

=back

In order for L</local_conversion> to work properly with Free subscription plans, one of the currencies has to be C<USD>
where you'd set L</$reverse_convert> to C<1> when you are converting C<$to> C<USD> rather than C<$from>.

=cut

async method convert($value, $from, $to, $reverse_convert = 0) {
    ($value) = $value =~ /(\d+)/;
    ($from, $to) = await $self->validate_symbols_list($from, $to) if $_enable_pre_validation;
    if ($_local_conversion) {
        unless ($reverse_convert) {
            # use From currency for conversion. Typically USD
            my $latest = await $self->latest($from);
            return $value * $latest->{rates}{$to};
        } else {
            # use To currency for conversion. Typically USD
            my $latest = await $self->latest($to);
            return $value / $latest->{rates}{$from};
        }

    } else {
        await $self->do_request(
            join('/', 'convert', $value, $from, $to)
        );
    }
}

=head2 ohlc

   await $exch->ohlc($date, $time, $period, $base, @symbols);
   await $exch->ohlc('2024-04-04', '02:00', '2m');

To request L<ohlc.json endpoint|https://docs.openexchangerates.org/reference/ohlc-json> from API.
Retrieving OHLC data requires some parameters to be present which are:

=over 4

=item $date

Date for selection timeframe needed, follows C<YYYY-MM-DD> format.

=item $time

Time for selection timeframe needed, follows C<hh:mm> or C<h:m>.
All timings would be based on UTC, as thats what API supports.

=item $period

Period of OHLC needed, like: C<'1m'>, C<'12h>, C<'1d'>, and so on.

=item $base

Optional base currency, C<default: 'USD'>

=item @symbols

Optional list of symbols to filter result based on.

=back

=cut

async method ohlc($date, $time, $period, $base = 'USD', @sym) {

    my %date = $_date_validation->($date);
    my ($h, $m) = $time =~ /^([0-9][0-9]|[0-9]):?([0-9][0-9]|[0-9])?/;
    my $start = Time::Moment->from_string(sprintf('%s%s%sT%s%s00Z',
        @date{qw(year month day)},
        $h, ($m || '00')
    ));
    Time::Moment->new()->strftime('YYYY-MM-DDThh:mm:ssZ');
    await $self->do_request(
        'ohlc.json',
        start => $start->strftime('YYYY-MM-DDThh:mm:ssZ'),
        period => $period,
        @sym ? (symbols => join(',', @sym)) : (),
        base => $base,
        show_alternative => 'true'
    );
}

=head2 usage

   await $exch->usage();

To request L<usage.json endpoint|https://docs.openexchangerates.org/reference/usage-json> from API.
returning both subscription plan details and app_id API usage so far, along with current app status.

=cut

async method usage() {
    $_usage = await $self->do_request('usage.json');
    try {
        $_app_plan_keys = [ keys $_usage->{data}{plan}->%* ];
        $_app_usage_keys = [ keys $_usage->{data}{usage}->%* ];
        $_app_features_keys = [ keys $_usage->{data}{plan}{features}->%* ];
    } catch ($error) {
        $log->warnf('Unable to parse usage.json response and set internal params. %s', $error);
    }
    return $_usage;
}

=head2 app_plan

   await $exch->app_plan();
   await $exch->app_plan($key);

Retrieves only the subscription plan details from L</usage> call, with the possibility of passing:

=over 4

=item $key

to get a specific key value from subscription plan details.

=back

=cut

async method app_plan($key = undef) {
    await $self->usage() unless defined $_usage;
    my $key_exists = ( defined $key && grep { $_ eq $key } @$_app_plan_keys ) ?
        1 : 0;
    return $key_exists ?
        $_usage->{data}{plan}{$key} :
        $_usage->{data}{plan};
}

=head2 app_usage

   await $exch->app_usage();
   await $exch->app_usage($key);

Retrieves only the application current API usage section from L</usage> method.

=over 4

=item $key

A specific key to get value for from API usage.

=back

=cut

async method app_usage($key = undef) {
    # always refresh usage for newer stats
    await $self->usage();
    my $key_exists = ( defined $key && grep { $_ eq $key } @$_app_usage_keys ) ?
        1 : 0;
    return $key_exists ?
        $_usage->{data}{usage}{$key} :
        $_usage->{data}{usage};
}

=head2 app_features

   await $exch->app_features();
   await $exch->app_features($key);

Retrieves the features that are currently enabled for current C<app_id>, accepts:

=over 4

=item $key

as a specific feature, in order to know whether its enabled or not by API

=back

=cut

async method app_features($key = undef) {
    await $self->usage() unless defined $_usage;
    my $key_exists = ( defined $key && grep { $_ eq $key } @$_app_features_keys ) ?
        1 : 0;
    return $key_exists ?
        $_usage->{data}{plan}{features}{$key} :
        $_usage->{data}{plan}{features};
}

=head2 app_status

   await $exch->app_status();

Gets the current C<app_id> status on the API, originally in L</usage> call.

=cut

async method app_status() {
    # always refresh usage for newer stats
    await $self->usage();
    return $_usage->{data}{status};
}

=head2 plan_update_frequency

   await $open_exch_api->plan_update_frequency();

used in order to specifically retrieve the subscription plan update_frequency in seconds.
Which is the rate that data are refreshed on current active plan.

=cut

async method plan_update_frequency() {
    my ($update_frequency) = (await $self->app_plan('update_frequency')) =~ m/(\d+)s/;
    unless ($update_frequency) {
        $log->warnf('Unable to obtain API subscription plan update frequency. Usage: %s', $_usage);
        $update_frequency = 0;
    }
    return $update_frequency;
}

=head1 FIELD ACCESSORS

No real difference between the other typical methods except that they are not async/await.
Also for most of them they will only be populated after the first request.

=head2 last_http_response

   $exch->last_http_response();

Used to access the complete L<HTTP::Response> for the last request that has been made.

=head2 app_id

   $exch->app_id();

The current C<APP_ID> that is registered with this instance.

=head2 api_query_params

   $exch->api_query_params();

Referenece of the list of parameters accepted by API.

=head2 app_plan_keys

   $exch->app_plan_keys();

To get list of subscription plan response hash keys from L</usage> call.

=head2 app_usage_keys

   $exch->app_usage_keys();

To get list of current API usage response hash keys from L</usage> call.

=head2 app_features_keys

   $exch->app_features_keys();

To get list of available API features.

=cut

1;
