sailthru-perl-client
====================

For a download please visit:
[http://getstarted.sailthru.com/new-for-developers-overview/api-client-library/perl](http://getstarted.sailthru.com/new-for-developers-overview/api-client-library/perl)

####INSTALLATION

To install this module type the following:
```bash
   perl Makefile.PL
   make
   make test
   make install
```
####DEPENDENCIES

This module requires these other modules and libraries:
```perl
Digest::MD5
JSON::XS
LWP::Protocol::https
LWP::UserAgent
Params::Validate
Readonly
URI
Test::MockModule
Test::Exception
```

####API Rate Limiting
Here is an example how to check rate limiting and throttle API calls based on that. For more information about Rate Limiting, see [Sailthru Documentation](https://getstarted.sailthru.com/new-for-developers-overview/api/api-technical-details/#Rate_Limiting)


```perl
my $sailthru_client = Sailthru::Client->new( $API_KEY, $API_SEC );

# ... make some api calls ...

$rate_limit_info = $sailthru_client->get_last_rate_limit_info('user', 'POST');

# get_last_rate_limit_info returns undef if given endpoint/method wasn't triggered previously
if (defined $rate_limit_info) {
    $limit = $rate_limit_info->limit;
    $remaining = $rate_limit_info->remaining;
    $reset_timestamp = $rate_limit_info->reset;

    # throttle api calls based on last rate limit info
    if ($remaining <= 0) {
         $seconds_till_reset = $reset_timestamp - time
         # sleep or perform other business logic before next user api call
         sleep($reconds_till_reset);
    }
}
```

####COPYRIGHT AND LICENSE

Copyright (c) 2016 Sailthru, Inc., https://www.sailthru.com/

Adapted from the original Triggermail module created by Sam Gerstenzang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.
