Riak-Light
==========

Fast and lightweight Perl client for Riak [![CPAN version](https://badge.fury.io/pl/Riak-Light.png)](http://badge.fury.io/pl/Riak-Light)

```perl
    # create a new instance - using pbc only
    my $client = Riak::Light->new(
      host => '127.0.0.1',
      port => 8087
    );
    
    $client->is_alive() or die "ops, riak is not alive";

    # store hashref into bucket 'foo', key 'bar'
    # will serializer as 'application/json'
    $client->put( foo => bar => { baz => 1024 });
    
    # store text into bucket 'foo', key 'bar' 
    $client->put( foo => baz => "sometext", 'text/plain');
    $client->put_raw( foo => baz => "sometext");  # does not encode !

    # fetch hashref from bucket 'foo', key 'bar'
    my $hash = $client->get( foo => 'bar');
    my $text = $client->get_raw( foo => 'baz');   # does not decode !

    # delete hashref from bucket 'foo', key 'bar'
    $client->del(foo => 'bar');
    
    # check if exists (like get but using less bytes in the response)
    $client->exists(foo => 'baz') or warn "ops, foo => bar does not exist";
    
    # list keys in stream (callback only)
    $client->get_keys(foo => sub{
       my $key = $_[0];
       
       # you should use another client inside this callback!
       $another_client->del(foo => $key);
    });
```

Install
=======

It is available on CPAN

    cpan Riak::Light
    
https://metacpan.org/release/Riak-Light/

Test Coverage
=============

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Riak/Light.pm        100.0  100.0  100.0  100.0   80.0   48.4   99.5
    ...b/Riak/Light/Connector.pm  100.0  100.0    n/a  100.0    0.0   32.4   96.6
    .../lib/Riak/Light/Driver.pm  100.0  100.0    n/a  100.0    0.0    4.0   93.3
    blib/lib/Riak/Light/PBC.pm    100.0    n/a    n/a  100.0    n/a   10.1  100.0
    ...lib/Riak/Light/Timeout.pm  100.0    n/a    n/a  100.0    n/a    0.7  100.0
    ...ak/Light/Timeout/Alarm.pm  100.0  100.0    n/a  100.0    0.0    0.7   94.3
    ...k/Light/Timeout/Select.pm  100.0    n/a    n/a  100.0    0.0    0.4   90.2
    ...t/Timeout/SelectOnRead.pm  100.0    n/a    n/a  100.0    0.0    0.2   91.3
    ...ght/Timeout/SetSockOpt.pm  100.0  100.0    n/a  100.0    0.0    0.5   96.8
    .../Light/Timeout/TimeOut.pm  100.0  100.0    n/a  100.0    0.0    0.9   94.9
    blib/lib/Riak/Light/Util.pm   100.0    n/a    n/a  100.0    0.0    1.7   87.5
    Total                         100.0  100.0  100.0  100.0   15.4  100.0   96.1
    ---------------------------- ------ ------ ------ ------ ------ ------ ------


Simple Benchmark
================

Using Perl 5.12.2 under MacOSX 10.8.3 / 4GB Ram / 2.4 GHz Intel Core 2 Duo and Riak 1.3.0 (localhost)

Only GET (`benchmark/compare_all_only_get.pl`)
 
                             Rate Data::Riak (REST) Net::Riak (REST) Riak::Tiny (REST) Data::Riak::Fast (REST) Net::Riak (PBC) Riak::Light (PBC)
    Data::Riak (REST)        318/s                --             -33%              -42%                    -46%            -69%              -92%
    Net::Riak (REST)         478/s               50%               --              -12%                    -20%            -54%              -87%
    Riak::Tiny (REST)        544/s               71%              14%                --                     -8%            -47%              -86%
    Data::Riak::Fast (REST)  594/s               87%              24%                9%                      --            -42%              -84%
    Net::Riak (PBC)         1031/s              224%             116%               89%                     73%              --              -73%
    Riak::Light (PBC)       3774/s             1086%             690%              593%                    535%            266%                --               --
 
Only PUT (`benchmark/compare_all_only_put.pl`)

                              Rate Net::Riak (REST) Data::Riak (REST) Riak::Tiny (REST) Net::Riak (PBC) Data::Riak::Fast (REST) Riak::Light (PBC)
    Net::Riak (REST)         418/s               --              -16%              -22%            -55%                    -58%              -88%
    Data::Riak (REST)        499/s              19%                --               -7%            -46%                    -50%              -86%
    Riak::Tiny (REST)        534/s              28%                7%                --            -42%                    -46%              -85%
    Net::Riak (PBC)          924/s             121%               85%               73%              --                     -6%              -74%
    Data::Riak::Fast (REST)  988/s             137%               98%               85%              7%                      --              -73%
    Riak::Light (PBC)       3604/s             763%              623%              575%            290%                    265%                --

Timeout Providers (`benchmark/compare_timeout_providers.pl`)

                    Rate Riak::Light 6 Riak::Light 3 Riak::Light 2 Riak::Light 4 Riak::Light 5 Riak::Light 1
    Riak::Light 6 2158/s            --          -16%          -21%          -21%          -32%          -38%
    Riak::Light 3 2564/s           19%            --           -6%           -6%          -20%          -26%
    Riak::Light 2 2727/s           26%            6%            --            0%          -15%          -22%
    Riak::Light 4 2727/s           26%            6%            0%            --          -15%          -22%
    Riak::Light 5 3191/s           48%           24%           17%           17%            --           -9%
    Riak::Light 1 3488/s           62%           36%           28%           28%            9%            --

    where

    1 - undef / no IO timeout
    2 - using Time::HiRes (alarm)
    3 - using IO::Select (DEFAULT)
    4 - using IO::Select only in read operations
    5 - using setsockopt
    6 - using Time::Out

Features
========

* be PBC only (ok)
* supports timeout (ok)
* use Moo (ok)
* doesn't create an object per key (ok)
* support an option to not die, but return undef (deprecated, will be removed to the next version)
* be optimized for speed. (ok)
* try to get 100% coverage. (ok)
* benchmark with Data::Riak, Net::Riak REST, etc... (ok)
* documentation (ok)
* support raw data (ok)
* support list keys (ok)
* debug/trace mode (to do)
* vclock support (in progress)
* refactor to use Moo::Roles instead other objects (to do)
* extract timeout provider to an external project (to do)
