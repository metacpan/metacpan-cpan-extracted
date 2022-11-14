# NAME

Plack::Middleware::Greylist - throttle requests with different rates based on net blocks

# VERSION

version v0.1.0

# SYNOPSIS

```perl
use Plack::Builder;

builder {

  enable "Greylist",
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

Rejections will be logged, which will allow you to use something like [fail2ban](https://metacpan.org/pod/fail2ban) to block repeat offenders, since bad
robots are like houseflies that repeatedly bump against closed windows.

# ATTRIBUTES

## default\_rate

This is the default maximum number of hits per minute before requests are rejected, for any request not in the ["greylist"](#greylist).

Omitting it will disable the global rate.

## greylist

This is a hash reference to the greylist configuration.

The keys are network blocks, and the values are an array reference of rates and the tracking type. (A string of space-
separated values can be used instead, to make it easier to directly use the configuration from something like
[Config::General](https://metacpan.org/pod/Config%3A%3AGeneral).)

The rates are either the maximum number of requests per minute, or "whitelist" to not limit the network block, or
"blacklist" to always forbid a network block.

(The rate "-1" corresponds to "whitelist", and the rate "0" corresponds to "blacklist".)

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

This is the path of the throttle count file used by the ["cache"](#cache). If omitted, a default will be set.

This does not need to be set except for running tests.

## cache

This is a code reference to a function that increments the cache counter for a key (usually the IP address or net
block).

# KNOWN ISSUES

This does not try and enforce any consistency or block overlapping netblocks.  It trusts [Net::IP::Match::Trie](https://metacpan.org/pod/Net%3A%3AIP%3A%3AMatch%3A%3ATrie) to
handle any overlapping or conflicting network ranges, or to specify exceptions for larger blocks.

# SOURCE

The development version is on github at [https://github.com/robrwo/Plack-Middleware-Greylist-](https://github.com/robrwo/Plack-Middleware-Greylist-)
and may be cloned from [git://github.com/robrwo/Plack-Middleware-Greylist-.git](git://github.com/robrwo/Plack-Middleware-Greylist-.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Plack-Middleware-Greylist-/issues](https://github.com/robrwo/Plack-Middleware-Greylist-/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
