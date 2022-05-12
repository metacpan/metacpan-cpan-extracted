# NAME

Robots::Validate - Validate that IP addresses are associated with known robots

# VERSION

version v0.2.7

# SYNOPSIS

```perl
use Robots::Validate;

my $rv = Robots::Validate->new;

...

if ( $rs->validate( $ip, \%opts ) ) { ...  }
```

# DESCRIPTION

# ATTRIBUTES

## `resolver`

This is the [Net::DNS::Resolver](https://metacpan.org/pod/Net%3A%3ADNS%3A%3AResolver) used for DNS lookups.

## `robots`

This is an array reference of rules with information about
robots. Each item is a hash reference with the following keys:

- `name`

    The name of the robot.

- `agent`

    A regular expression for matching against user agent names.

- `domain`

    A regular expression for matching against the hostname.

## `die_on_error`

When true, ["validate"](#validate) will die on a ["resolver"](#resolver) failure.

By default it is false.

# METHODS

## `validate`

```perl
my $result = $rv->validate( $ip, \%opts );
```

This method attempts to validate that an IP address belongs to a known
robot by first looking up the hostname that corresponds to the IP address,
and then validating that the hostname resolves to that IP address.

If this succeeds, it then checks if the hostname is associated with a
known web robot.

If that succeeds, it returns a copy of the matched rule from ["robots"](#robots).

You can specify the following `%opts`:

- `agent`

    This is the user-agent string. If it does not match, then the DNS lookkups
    will not be performed.

    It is optional.

Alternatively, you can pass in a Plack environment:

```perl
my $result = $rv->validate($env);
```

# KNOWN ISSUES

## Undocumented Rules

Many of these rules are not documented, but have been guessed from web
traffic.

## Limitations

The current module can only be used for systems that consistently
support reverse DNS lookups. This means that it cannot be used to
validate some robots from
[Facebook](https://developers.facebook.com/docs/sharing/webmasters/crawler)
or Twitter.

# SEE ALSO

- [Verifying Bingbot](https://www.bing.com/webmaster/help/how-to-verify-bingbot-3905dc26)
- [Verifying Googlebot](https://support.google.com/webmasters/answer/80553)
- [How to check that a robot belongs to Yandex](https://yandex.com/support/webmaster/robot-workings/check-yandex-robots.html)

# SOURCE

The development version is on github at [https://github.com/robrwo/Robots-Validate](https://github.com/robrwo/Robots-Validate)
and may be cloned from [git://github.com/robrwo/Robots-Validate.git](git://github.com/robrwo/Robots-Validate.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Robots-Validate/issues](https://github.com/robrwo/Robots-Validate/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2022 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
