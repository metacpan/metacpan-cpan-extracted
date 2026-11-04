# Net::IPData

Perl client for the [ipdata.co](https://ipdata.co/) IP geolocation and threat intelligence API.

## Features

- **Full API coverage** -- single IP lookup, bulk lookup (up to 100 IPs), field filtering, single-field queries
- **Threat intelligence** -- TOR, proxy, datacenter, VPN, and botnet detection
- **Rich data** -- geolocation, ASN, company, carrier, currency, timezone, and language info
- **EU endpoint** -- route requests through EU-only servers for GDPR compliance
- **Zero non-core dependencies** -- uses only `HTTP::Tiny` and `JSON::PP` (core since Perl 5.14)
- **Connection reuse** -- one persistent HTTPS connection per client object (HTTP/1.1 keep-alive), so only the first request pays the TLS handshake
- **Certificate verification** -- the API server's TLS certificate is verified with every `HTTP::Tiny` version (`verify_ssl => 0` turns it off)
- **Production ready** -- input validation, structured error handling, configurable timeouts

## Installation

From CPAN:

```sh
cpanm Net::IPData
```

Or manually:

```sh
perl Makefile.PL
make
make test
make install
```

## Quick Start

```perl
use Net::IPData;

my $ipdata = Net::IPData->new(api_key => 'YOUR_API_KEY');

my $result = $ipdata->lookup('8.8.8.8');
printf "%s is in %s, %s\n",
    $result->{ip},
    $result->{city},
    $result->{country_name};
```

Get a free API key (1,500 requests/day) at [ipdata.co](https://ipdata.co/).

## Usage

### Single IP Lookup

```perl
my $result = $ipdata->lookup('8.8.8.8');

printf "IP:        %s\n", $result->{ip};
printf "City:      %s\n", $result->{city};
printf "Region:    %s\n", $result->{region};
printf "Country:   %s (%s)\n", $result->{country_name}, $result->{country_code};
printf "Continent: %s\n", $result->{continent_name};
printf "Coords:    %.4f, %.4f\n", $result->{latitude}, $result->{longitude};
printf "ASN:       %s (%s)\n", $result->{asn}{asn}, $result->{asn}{name};
printf "Timezone:  %s\n", $result->{time_zone}{name};
printf "Currency:  %s (%s)\n", $result->{currency}{name}, $result->{currency}{code};
printf "EU:        %s\n", $result->{is_eu} ? 'Yes' : 'No';
printf "Threat:    %s\n", $result->{threat}{is_threat} ? 'Yes' : 'No';
printf "Satellite: %s\n", $result->{is_satellite} ? 'Yes' : 'No';   # key present only when true
printf "Anycast:   %s\n", $result->{is_anycast} ? 'Yes' : 'No';     # key present only when true
```

### Look Up Your Own IP

```perl
my $me = $ipdata->lookup_mine();
printf "My IP: %s\n", $me->{ip};
```

### Field Filtering

Request only the fields you need to reduce response size and improve performance:

```perl
my $partial = $ipdata->lookup('8.8.8.8', fields => [qw(ip country_name asn)]);
printf "Country: %s, ASN: %s\n",
    $partial->{country_name},
    $partial->{asn}{name};
```

Fields can also be passed as a comma-separated string:

```perl
my $partial = $ipdata->lookup('8.8.8.8', fields => 'ip,country_name,asn');
```

### Bulk Lookup

Look up to 100 IP addresses in a single request:

```perl
my $results = $ipdata->bulk(['8.8.8.8', '1.1.1.1', '9.9.9.9']);

for my $r (@$results) {
    printf "%s -> %s, %s\n", $r->{ip}, $r->{city}, $r->{country_name};
}

# With field filtering
my $results = $ipdata->bulk(
    ['8.8.8.8', '1.1.1.1'],
    fields => [qw(ip country_name threat)],
);
```

### Single-Field Shortcuts

Retrieve individual fields directly without downloading the full response:

```perl
my $asn     = $ipdata->asn('8.8.8.8');          # hashref
my $threat  = $ipdata->threat('8.8.8.8');        # hashref
my $carrier = $ipdata->carrier('8.8.8.8');       # hashref
my $tz      = $ipdata->time_zone('8.8.8.8');     # hashref
my $curr    = $ipdata->currency('8.8.8.8');      # hashref
my $langs   = $ipdata->languages('8.8.8.8');     # arrayref

my $country = $ipdata->country_name('8.8.8.8');  # string
my $code    = $ipdata->country_code('8.8.8.8');  # string
my $eu      = $ipdata->is_eu('8.8.8.8');         # boolean
my $sat     = $ipdata->is_satellite('8.8.8.8');  # boolean
my $anycast = $ipdata->is_anycast('8.8.8.8');    # boolean

# Or use the generic method for any path-accessible field
my $city = $ipdata->lookup_field('8.8.8.8', 'city');
```

### EU Endpoint

Route all requests through EU-only servers (Paris, Ireland, Frankfurt) for GDPR compliance:

```perl
my $ipdata = Net::IPData->new(
    api_key => 'YOUR_API_KEY',
    eu      => 1,
);
```

### Custom Base URL

```perl
my $ipdata = Net::IPData->new(
    api_key  => 'YOUR_API_KEY',
    base_url => 'https://custom-proxy.example.com',
);
```

### Error Handling

All methods `croak` on errors. Use `eval` or [Try::Tiny](https://metacpan.org/pod/Try::Tiny) to catch them:

```perl
use Try::Tiny;

try {
    my $result = $ipdata->lookup('invalid');
} catch {
    warn "API error: $_";
};
```

Error messages include the HTTP status code and the API's error message:

| Status | Meaning |
|--------|---------|
| 401 | Invalid or missing API key |
| 403 | Access forbidden |
| 429 | Rate limit exceeded |
| 599 | Network/connection failure |

### Request Headers

Every request carries `Accept: application/json` and the user agent `ipdata-perl/<version>`. The bulk `POST` -- the only request with a body -- also sends `Content-Type: application/json`; `GET` requests send no `Content-Type`.

## Connection reuse

A `Net::IPData` object keeps one persistent HTTPS connection (HTTP/1.1 keep-alive) for as long as it lives. Create one client per process (or one per API key or endpoint), keep it, and reuse it for every lookup: each new client pays a fresh TLS handshake. HTTP/2 is not available with `HTTP::Tiny`, so the saving is the TLS handshake, not multiplexing.

```perl
my $ipdata = Net::IPData->new(api_key => 'YOUR_API_KEY');   # one TLS handshake...

for my $ip (@ips) {
    my $result = $ipdata->lookup($ip);                       # ...reused by every lookup
}
```

The reuse is `HTTP::Tiny`'s own (`keep_alive => 1`, now explicit and configurable): a connection the server has already closed is detected and replaced transparently, a `GET` on a socket that died silently is retried once by `HTTP::Tiny` itself, and `bulk` (a non-idempotent `POST`) gets the same single retry from this module when the failure happened at the socket level before any response arrived (`HTTP::Tiny` status 599 with *Socket closed*, *Unexpected end of stream* or *Connection reset*). A request that received an HTTP status is never retried. With `HTTP::Tiny` 0.092 or later, `keep_alive_timeout => 60` additionally stops reusing a connection that has been idle for a minute, before the server (which keeps idle connections for roughly two minutes) can drop it silently.

A `Net::IPData` object is not shared between threads: use one per thread. It is fork-safe: `HTTP::Tiny` 0.049 and later never reuses a socket inherited from another process or thread, so a forked child opens its own connection on its first request. There is nothing to close explicitly; the connection is shut down when the object is destroyed, so letting it go out of scope (or `undef $ipdata`) at shutdown is all the cleanup needed.

Pass `keep_alive => 0` to open a new connection per request, or supply your own user agent with `ua => $obj` (any object with `HTTP::Tiny`-compatible `get`/`post` methods returning `{status, content, headers, success}`), for example a pre-configured `HTTP::Tiny` or a mock in tests:

```perl
my $ua     = HTTP::Tiny->new(
    keep_alive  => 1,
    timeout     => 10,
    SSL_options => { SSL_ca_file => '/etc/ssl/private-ca.pem' },
);
my $ipdata = Net::IPData->new(api_key => 'YOUR_API_KEY', ua => $ua);
```

## Constructor Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `api_key` | string | *required* | Your ipdata.co API key |
| `eu` | bool | `0` | Use the EU endpoint (`eu-api.ipdata.co`) |
| `base_url` | string | `https://api.ipdata.co` | Custom base URL (overrides `eu`) |
| `timeout` | int | `30` | HTTP timeout in seconds |
| `keep_alive` | bool | `1` | Keep the HTTPS connection open between requests (HTTP/1.1 keep-alive); `0` opens a new connection per request |
| `keep_alive_timeout` | int | *unset* | Seconds a kept-alive connection may sit idle before the next request opens a fresh one; honoured by `HTTP::Tiny` 0.092+ (older versions ignore it) and forwarded only when set; `60` suits api.ipdata.co |
| `verify_ssl` | bool | `1` | Verify the API server's TLS certificate. Passed to `HTTP::Tiny` as `verify_SSL`, so the check applies with every `HTTP::Tiny` version (not only 0.083+, which verify by default) and needs a CA bundle (`Mozilla::CA` or the operating system's); `0` connects without checking the server's identity |
| `ua` | object | new `HTTP::Tiny` | Your own user agent: any object with `HTTP::Tiny`-compatible `get`/`post` returning `{status, content, headers, success}` |

## Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `lookup($ip, %opts)` | hashref | Full lookup for an IP (omit `$ip` for caller's IP) |
| `lookup_mine(%opts)` | hashref | Full lookup for the caller's own IP |
| `lookup_field($ip, $field)` | varies | Single field via path API |
| `bulk(\@ips, %opts)` | arrayref | Bulk lookup for up to 100 IPs |
| `asn($ip)` | hashref | ASN data (`asn`, `name`, `domain`, `route`, `type`) |
| `threat($ip)` | hashref | Threat flags (`is_tor`, `is_vpn`, `is_proxy`, `is_threat`, ...), `blocklists` and `scores` |
| `carrier($ip)` | hashref | Mobile carrier (`name`, `mcc`, `mnc`) |
| `currency($ip)` | hashref | Currency (`name`, `code`, `symbol`, `native`, `plural`) |
| `time_zone($ip)` | hashref | Timezone (`name`, `abbr`, `offset`, `is_dst`, `current_time`) |
| `languages($ip)` | arrayref | Languages (`name`, `native`, `code`) |
| `country_name($ip)` | string | Country name |
| `country_code($ip)` | string | ISO 3166-1 alpha-2 country code |
| `is_eu($ip)` | boolean | EU member state |
| `is_satellite($ip)` | boolean | Satellite internet provider |
| `is_anycast($ip)` | boolean | Anycast address |

## API Response Structure

A full lookup returns a hashref with this shape:

```
{
    ip             => "8.8.8.8",
    is_eu          => false,
    is_satellite   => true,     # present only when true
    is_anycast     => true,     # present only when true
    city           => "Mountain View",
    region         => "California",
    region_code    => "CA",
    country_name   => "United States",
    country_code   => "US",
    continent_name => "North America",
    continent_code => "NA",
    latitude       => 37.386,
    longitude      => -122.0838,
    postal         => "94035",
    calling_code   => "1",
    flag           => "https://ipdata.co/flags/us.png",
    emoji_flag     => "\x{1f1fa}\x{1f1f8}",
    emoji_unicode  => "U+1F1FA U+1F1F8",

    asn       => { asn, name, domain, route, type },
    company   => { name, domain, network, type },
    carrier   => { name, mcc, mnc },
    languages => [{ name, native, code }],
    currency  => { name, code, symbol, native, plural },
    time_zone => { name, abbr, offset, is_dst, current_time },
    threat    => { is_tor, is_vpn, is_icloud_relay, is_proxy, is_datacenter,
                   is_anonymous, is_known_attacker, is_known_abuser,
                   is_threat, is_bogon,
                   blocklists => [{ name, site, type,
                                    first_seen, last_seen, days_seen }],
                   scores => { vpn_score, proxy_score,
                               threat_score, trust_score } },
}
```

The JSON is passed through unchanged, so keys the API adds later simply appear in the hashref. Five fields deserve a note:

| Field | Type | Description |
|-------|------|-------------|
| `is_satellite` | boolean | The address belongs to a satellite internet provider. The API includes the key only when it is true, so test it with a plain `if ($result->{is_satellite})`, never with `exists`; a missing key reads as false |
| `is_anycast` | boolean | The address is an anycast address. Present only when true, like `is_satellite` |
| `threat.blocklists[].first_seen` | string | First calendar date (UTC, `YYYY-MM-DD`) on which that blocklist listed the address; left as a string |
| `threat.blocklists[].last_seen` | string | Most recent such date (UTC, `YYYY-MM-DD`); left as a string |
| `threat.blocklists[].days_seen` | integer | Number of days that blocklist has listed the address |

Some feeds, for example ipdata's own vpn feed, omit all three blocklist fields, so check for them with `exists` before use. Bulk results carry the same shape per item.

## Requirements

- Perl 5.10.1 or later
- Core modules only: [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny) 0.049 or later (ships with Perl 5.22+; older Perls install it from CPAN), [JSON::PP](https://metacpan.org/pod/JSON::PP), [Carp](https://metacpan.org/pod/Carp), [Scalar::Util](https://metacpan.org/pod/Scalar::Util)
- Recommended: [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) 1.56+ and [Net::SSLeay](https://metacpan.org/pod/Net::SSLeay) 1.49+ for HTTPS, plus a CA bundle ([Mozilla::CA](https://metacpan.org/pod/Mozilla::CA) or the operating system's) for the certificate verification that is on by default (`verify_ssl => 1`)

## Testing

Run the unit tests (no API key and no network access needed):

```sh
make test
```

Run the full suite including live API tests:

```sh
IPDATA_API_KEY=your_key_here make test
```

## License

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Links

- [ipdata.co API documentation](https://docs.ipdata.co/)
- [ipdata.co website](https://ipdata.co/)
