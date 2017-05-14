Riak-Light
==========

Fast and lightweight Perl client for Riak

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

    # fetch hashref from bucket 'foo', key 'bar'
    my $hash = $client->get( foo => 'bar');

    # delete hashref from bucket 'foo', key 'bar'
    $client->del(foo => 'bar');
    
    # list keys in stream
    $client->get_keys(foo => sub{
       my $key = $_[0];
       
       # you should use another client inside this callback!
       $another_client->del(foo => $key);
    });

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

Only GET (`benchmark/compare_all_only_get.pl`)
 
                           Rate Data::Riak (REST) Net::Riak (REST) Riak::Tiny (REST) Data::Riak::Fast (REST) Net::Riak (PBC) Riak::Light (PBC)
    Data::Riak (REST)        303/s                --             -29%              -38%                    -45%            -66%              -90%
    Net::Riak (REST)         425/s               40%               --              -13%                    -23%            -53%              -86%
    Riak::Tiny (REST)        485/s               60%              14%                --                    -12%            -46%              -84%
    Data::Riak::Fast (REST)  553/s               82%              30%               14%                      --            -38%              -82%
    Net::Riak (PBC)          899/s              196%             112%               85%                     62%              --              -71%
    Riak::Light (PBC)       3125/s              930%             636%              544%                    465%            248%                --
 
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
* support an option to not die, but return undef (ok)
* be optimized for speed. (ok)
* try to get 100% coverage. (ok)
* benchmark with Data::Riak, Net::Riak REST, etc... (ok)
* documentation (ok)
* support raw data (ok)
* support list keys (ok)
* debug mode (to do)
* on_error callback (to do)
* refactor to use Moo::Roles instead other objects (to do)