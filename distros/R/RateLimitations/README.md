# NAME

[![Build Status](https://travis-ci.org/binary-com/perl-RateLimitations.svg?branch=master)](https://travis-ci.org/binary-com/perl-RateLimitations)
[![codecov](https://codecov.io/gh/binary-com/perl-RateLimitations/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-RateLimitations)

RateLimitations - manage per-service rate limitations

# SYNOPSIS

    use 5.010;

    use RateLimitations qw(
        rate_limited_services
        rate_limits_for_service
        within_rate_limits
        all_service_consumers
    );

    # Example using the built-in default "rl_internal_testing" service:
    #   rl_internal_testing:
    #       10s: 2
    #       5m:  6

    my @rl_services = rate_limited_services();
    # ("rl_internal_testing")

    my @test_limits = rate_limits_for_service('rl_internal_testing');
    # ([10 => 2], [300 => 6])

    foreach my $i (1 .. 6) {
        my $guy = ($i % 2) ? 'OddGuy' : 'EvenGuy';
        my $result = (
            within_rate_limits({
                    service  => 'rl_internal_testing',
                    consumer => $guy,
                })) ? 'permitted' : 'denied';
        say $result . ' for ' . $guy;
    }
    # permitted for OddGuy
    # permitted for EvenGuy
    # permitted for OddGuy
    # permitted for EvenGuy
    # denied for OddGuy
    # denied for EvenGuy

    my $consumers = all_service_consumers();
    # { rl_internal_testing => ['EvenGuy', 'OddGuy']}

# DESCRIPTION

RateLimitations is a module to help enforce per-service rate limits.

The rate limits are checked via a backing Redis store.  This persistence allows for
multiple processes to maintain a shared view of resource usage.  Acceptable rates
are defined in the `/etc/perl_rate_limitations.yml` file.

Several utility functions are provided to help examine the inner state to help confirm
proper operation.

Nothing is exported from this package by default.

# FUNCTIONS

- within\_rate\_limits({service => $service, consumer => $consumer\_id})

    Returns **1** if `$consumer_id` is permitted further access to `$service`
    under the rate limiting rules for the service; **0** is returned if this
    access would exceed those limits.

    Will croak unless both elements are supplied and `$service` is valid.

    Note that this call will update the known request rate, even if it is eventually
    determined that the request is not within limits.  This is a conservative approach
    since we cannot know for certain how the results of this call are used. As such,
    it is best to use this call **only** when legitimately gating service access and
    to allow a bit of extra slack in the permitted limits.

- verify\_rate\_limitations\_config()

    Attempts to load the `/etc/perl_rate_limitations.yml` file and confirm that its
    contents make sense.  Parsing the file in much the same way as importing the
    module, additional sanity checks are performed on the supplied rates.

    Returns **1** if the file appears to be OK; **0** otherwise.

- rate\_limited\_services()

    Returns an array of all known services which have applied rate limits.

- rate\_limits\_for\_service($service)

    Returns an array of rate limits applied to requests for a known `$service`.
    Each member of the array is an array reference with two elements:

        [number_of_seconds, number_of_accesses_permitted_in_those_seconds]

- all\_service\_consumers()

    Returns a hash reference with all services and their consumers.  May be useful
    for verifying consumer names are well-formed.

        { service1 => [consumer1, consumer2],
          service2 => [consumer1, consumer2],
        }

- flush\_all\_service\_consumers()

    Clears the full list of consumers.  Returns the number of items cleared.

# CONFIG FILE FORMAT

The services to be limited are defined in the `/etc/perl_rate_limitations.yml`
file.  This file should be laid out as follows:

    service_name:
        time: count
        time: count
    service_name:
        time: count
        time: count

**service\_name** is an arbitrary string to uniquely identify the service

**time** is a string which can be interpreted by **Time::Duration::Concise**. This
may include using an integer number of seconds.

**count** is an integer which sets the maximum permitted **service\_name** accesses
per **time**

# AUTHOR

Binary.com <perl@binary.com>

# COPYRIGHT

Copyright 2015-

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
