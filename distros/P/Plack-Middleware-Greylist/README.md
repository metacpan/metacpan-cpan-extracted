# NAME

Plack::Middleware::Greylist - throttle requests with different rates based on net blocks

# VERSION

version v0.6.0

# SYNOPSIS

```perl
use Plack::Builder;

builder {

  enable "Greylist",
    file         => sprintf('/run/user/%u/greylist', $>), # cache file
    default_rate => 250,
    greylist     => {
        '192.168.0.0/24' => 'whitelist',
        '172.16.1.0/25'  => [ 100, 'netblock' ],
    };

}
```

# DESCRIPTION

This middleware will apply rate limiting to requests, depending on the requestor netblock.

Hosts that exceed their configured per-minute request limit will be rejected with HTTP 429 errors.

## Log Messages

Rejections will be logged with a message of the form

```
Rate limiting $ip after $hits/$rate for $netblock
```

for example,

```
Rate limiting 172.16.0.10 after 225/250 for 172.16.0.0/24
```

Note that the `$netblock` for the default rate is simply "default", e.g.

```
Rate limiting 192.168.0.12 after 101/100 for default
```

This will allow you to use something like [fail2ban](https://metacpan.org/pod/fail2ban) to block repeat offenders, since bad
robots are like houseflies that repeatedly bump against closed windows.

# ATTRIBUTES

## default\_rate

This is the default maximum number of hits per minute before requests are rejected, for any request not in the ["greylist"](#greylist).

Omitting it will disable the global rate.

## retry\_after

This sets the `Retry-After` header value, in seconds. It defaults to 1 + `expiry_time` (61) seconds, which is the
minimum allowed value.

Note that this does not enforce that a client has waited that amount of time before making a new request, as long as the
number of hits per minute is within the allowed rate.

This option was added in v0.2.0

## greylist

This is a hash reference to the greylist configuration.

The keys are network blocks, and the values are an array reference of rates and the tracking type. (A string of space-
separated values can be used instead, to make it easier to directly use the configuration from something like
[Config::General](https://metacpan.org/pod/Config%3A%3AGeneral).)

The rates are either the maximum number of requests per minute, or "whitelist" or "allowed" to not limit the network
block, or "blacklist" or "rejected" to always forbid a network block.

(The rate "-1" corresponds to "allowed", and the rate "0" corresponds to "rejected".)

A special rate code of "norobots" will reject all requests except for `/robots.txt`, which is allowed at a rate of 60
per minute.  This will allow you to block a robot but still allow the robot to access the robot rules that say it is
disallowed.

The tracking type defaults to "ip", which applies limits to individual ips. You can also use "netblock" to apply the
limits to all hosts in that network block, or use a name so that limits are applied to all hosts in network blocks
with that name.

For example:

```perl
{
    '127.0.0.1/32' => 'whitelist',

    '192.168.1.0/24' => 'blacklist',

    '192.168.2.0/24' => [ 100, 'ip' ],

    '192.168.3.0/24' => [  60, 'netblock' ],

    # All requests from these blocks will limited collectively

    '10.0.0.0/16'    => [  60, 'group1' ],
    '172.16.0.0/16'  => [  60, 'group1' ],
}
```

Note: the network blocks shown above are examples only.

The limit may be larger than ["default\_rate"](#default_rate), to allow hosts to exceed the default limit.

## file

This is the path of the throttle count file used by the ["cache"](#cache).

It is required unless you are defining your own ["cache"](#cache) or you have specified a `share_file` in ["cache\_config"](#cache_config).

## cache\_config

This is a hash reference for configuring [Cache::FastMmap](https://metacpan.org/pod/Cache%3A%3AFastMmap).  If it's omitted, defaults will be used.

The following options can be configured:

- `init_file`

    This is boolean that configures whether ["file"](#file) will be re-initialised in startup. Unless you are preloading the
    application before forking, this should be false (default).

- `unlink_on_exit`

    When true, the cache file will be deleted on exit. This defaults the negation of `init_file`.

- `expire_time`

    This sets the expiration time, which defaults to 60 seconds.

    The ["retry\_after"](#retry_after) attribute will default to 1 + `expiry_time`.

Note that the ["file"](#file) attribute will be used to set the `share_file`.

See ["new" in Cache::FastMmap](https://metacpan.org/pod/Cache%3A%3AFastMmap#new) for more information.

This option was added in v0.5.5.

## cache

This is a code reference to a function that increments the cache counter for a key (usually the IP address or net
block).

If you customise this, then you need to ensure that the counter resets or expires counts after a set period of time,
e.g. one minute.  If you use a different time interval, then you may need to adjust the ["retry\_after"](#retry_after) time.

# KNOWN ISSUES

This does not try and enforce any consistency or block overlapping netblocks.  It trusts [Net::IP::LPM](https://metacpan.org/pod/Net%3A%3AIP%3A%3ALPM) to
handle any overlapping or conflicting network ranges, or to specify exceptions for larger blocks.

When configuring the ["greylist"](#greylist) netblocks from a configuration file using [Config::General](https://metacpan.org/pod/Config%3A%3AGeneral), duplicate netblocks may
be merged in unexpected ways, for example

```
10.0.0.0/16   60 group-1

...

10.0.0.0/16  120 group-2
```

may be merged as something like

```perl
'10.0.0.0/16' => [ '60 group-1', '120 group-2' ],
```

Some search engine robots may not respect HTTP 429 responses, and will treat these as errors. You may want to make an
exception for trusted networks that gives them a higher rate than the default.

This does not enforce consistent rates for named blocks. For example, if you specified

```perl
'10.0.0.0/16'    => [  60, 'named-group' ],
'172.16.0.0/16'  => [ 100, 'named-group' ],
```

Requests from both netblocks would be counted together, but requests from 10./16 netblock would be rejected after 60
requests. This is probably not something that you want.

# SUPPORT FOR OLDER PERL VERSIONS

This module requires Perl v5.12 or later.

Future releases may only support Perl versions released in the last ten years.

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Greylist](https://github.com/robrwo/Plack-Middleware-Greylist)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-Greylist.git](git://github.com/robrwo/Plack-Middleware-Greylist.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Greylist/issues](https://github.com/robrwo/Plack-Middleware-Greylist/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Gabor Szabo <gabor@szabgab.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
