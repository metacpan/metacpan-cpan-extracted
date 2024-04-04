package Stancer::Config::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Config;
use Stancer::Core::Object::Stub;
use Stancer::Core::Request;
use LWP::UserAgent;
use POSIX qw(floor);
use TestCase qw(:lwp);
use Try::Tiny;

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(2) {
    my $key = 'stest_' . random_string(24);
    my $host = random_string(15);
    my $port = random_integer(1, 65_535);
    my $timeout = floor(rand 100) * 1000;
    my $version = floor(rand 100) * 1000;
    my %args = (
        debug => 0,
        host => $host,
        keychain => $key,
        port => $port,
        timeout => $timeout,
        version => $version,
    );

    my $object = Stancer::Config->new(%args);

    isa_ok($object, 'Stancer::Config', 'Stancer::Config->new(%args)');

    cmp_deeply($object, noclass({
        calls => [],
        debug => 0,
        host => $host,
        mode => Stancer::Config::TEST,
        port => $port,
        stest => $key,
        timeout => $timeout,
        version => $version,
    }));
}

sub calls : Tests(18) {
    my $config = Stancer::Config->init();
    my $request = Stancer::Core::Request->new();
    my $object = Stancer::Core::Object::Stub->new();

    { # 8 tests
        note 'Without exception';

        isa_ok($config->calls, 'ARRAY', '$config->calls');
        is(scalar @{ $config->calls }, 0, 'Should be empty');

        $mock_ua->clear();

        $request->get($object);

        isa_ok($config->calls, 'ARRAY', '$config->calls');
        is(scalar @{ $config->calls }, 1, 'Should have one call registered');
        isa_ok($config->calls->[0], 'Stancer::Core::Request::Call', '$config->calls->[0]');

        is($config->calls->[0]->request, $mock_request, 'The call should have a request');
        is($config->calls->[0]->response, $mock_response, 'The call should have a response');
        is($config->calls->[0]->exception, undef, 'The call should not have an exception');
    }

    { # 10 tests
        note 'With exception';

        isa_ok($config->calls, 'ARRAY', '$config->calls');
        is(scalar @{ $config->calls }, 1, 'Should still have previous call');

        $mock_ua->clear();
        $mock_response->set_false(qw(is_success));
        $mock_response->set_always(decoded_content => undef);
        $mock_response->set_always(code => 409);

        throws_ok(sub { $request->get($object) }, 'Stancer::Exceptions::Http::Conflict', 'This one was expected');

        my $exception = $EVAL_ERROR;

        isa_ok($config->calls, 'ARRAY', '$config->calls');
        is(scalar @{ $config->calls }, 2, 'Should have one more call registered');
        isa_ok($config->calls->[1], 'Stancer::Core::Request::Call', '$config->calls->[1]');

        is($config->calls->[1]->request, $mock_request, 'The call should have a request');
        is($config->calls->[1]->response, $mock_response, 'The call should have a response');
        is($config->calls->[1]->exception, $exception, 'The call should have an exception');

        is($config->last_call, $config->calls->[1], '"last_call" method return last');
    }
}

sub debug : Tests(6) {
    { # 3 tests
        note('In TEST mode');

        my $object = Stancer::Config->new();

        ok($object->debug, 'True by default');

        $object->debug(0);

        ok(not($object->debug), 'Should accept "false" value');

        $object->debug(1);

        ok($object->debug, 'Should accept "true" value');
    }

    { # 3 tests
        note('In LIVE mode');

        my $object = Stancer::Config->new(mode => Stancer::Config::LIVE);

        ok(not($object->debug), 'False by default');

        $object->debug(1);

        ok($object->debug, 'Should accept "true" value');

        $object->debug(0);

        ok(not($object->debug), 'Should accept "false" value');
    }
}

sub default_timezone : Tests(5) {
    my $object = Stancer::Config->new();
    my $tz = DateTime::TimeZone->new(name => 'Europe/Paris');

    is($object->default_timezone, undef, 'Undefined by default');

    $object->default_timezone($tz);

    isa_ok($object->default_timezone, 'DateTime::TimeZone', '$config->default_timezone');
    is($object->default_timezone, $tz, 'Should be the same instance');

    $object->default_timezone('Europe/Paris');

    isa_ok($object->default_timezone, 'DateTime::TimeZone', '$config->default_timezone');
    cmp_deeply($object->default_timezone, $tz, 'Should be equal to a new instance');
}

sub host : Tests(2) {
    my $object = Stancer::Config->new();
    my $host = random_string(10);

    is($object->host, 'api.stancer.com', 'Should return default API host');

    $object->host($host);

    is($object->host, $host, 'Should update host');
}

sub init : Tests(30) {
    my $pprod = sub { 'pprod_' . random_string(24) };
    my $ptest = sub { 'ptest_' . random_string(24) };
    my $params = sub {
        return {
            keychain => $pprod->(),
        };
    };
    my $args = {};

    # Arrow based notation

    $args = $params->();
    my $arrow_key = Stancer::Config->init($args->{keychain});

    isa_ok($arrow_key, 'Stancer::Config', 'Stancer::Config->init($key)');
    is($arrow_key->pprod, $args->{keychain}, 'Check key is defined');
    cmp_deeply(Stancer::Config->init(), $arrow_key, 'Works like a singleton');

    $args = $params->();
    my $arrow_hash = Stancer::Config->init(%{$args});

    isa_ok($arrow_hash, 'Stancer::Config', 'Stancer::Config->init(keychain => $key)');
    is($arrow_hash->pprod, $args->{keychain}, 'Check key is defined');
    cmp_deeply(Stancer::Config->init(), $arrow_hash, 'Works like a singleton');

    $args = $params->();
    my $arrow_hashref = Stancer::Config->init($args);

    isa_ok($arrow_hashref, 'Stancer::Config', 'Stancer::Config->init({keychain => $key})');
    is($arrow_hashref->pprod, $args->{keychain}, 'Check key is defined');
    cmp_deeply(Stancer::Config->init(), $arrow_hashref, 'Works like a singleton');

    $args = [
        $pprod->(),
        $ptest->(),
    ];
    my $multiple_keys_arrayref = Stancer::Config->init($args);

    isa_ok($multiple_keys_arrayref, 'Stancer::Config', 'Stancer::Config->init(\@keys)');
    is($multiple_keys_arrayref->pprod, $args->[0], 'Check pprod is defined');
    is($multiple_keys_arrayref->ptest, $args->[1], 'Check ptest is defined');
    cmp_deeply(Stancer::Config->init(), $multiple_keys_arrayref, 'Works like a singleton');

    $args = [
        $pprod->(),
        $ptest->(),
    ];
    my $multiple_hash_arrayref = Stancer::Config->init(keychain => $args);

    isa_ok($multiple_hash_arrayref, 'Stancer::Config', 'Stancer::Config->init(keychain => \@keys)');
    is($multiple_hash_arrayref->pprod, $args->[0], 'Check pprod is defined');
    is($multiple_hash_arrayref->ptest, $args->[1], 'Check ptest is defined');
    cmp_deeply(Stancer::Config->init(), $multiple_hash_arrayref, 'Works like a singleton');

    $args = [
        $pprod->(),
        $ptest->(),
    ];
    my $multiple_hashref_arrayref = Stancer::Config->init({keychain => $args});

    isa_ok($multiple_hashref_arrayref, 'Stancer::Config', 'Stancer::Config->init({keychain => \@keys})');
    is($multiple_hashref_arrayref->pprod, $args->[0], 'Check pprod is defined');
    is($multiple_hashref_arrayref->ptest, $args->[1], 'Check ptest is defined');
    cmp_deeply(Stancer::Config->init(), $multiple_hashref_arrayref, 'Works like a singleton');

    # Double colon based notation

    $args = $params->();
    my $colon_key = Stancer::Config::init($args->{keychain});

    isa_ok($colon_key, 'Stancer::Config', 'Stancer::Config::init($key)');
    is($colon_key->pprod, $args->{keychain}, 'Check key is defined');
    cmp_deeply(Stancer::Config::init(), $colon_key, 'Works like a singleton');

    $args = $params->();
    my $colon_hash = Stancer::Config::init(%{$args});

    isa_ok($colon_hash, 'Stancer::Config', 'Stancer::Config::init(keychain => $key)');
    is($colon_hash->pprod, $args->{keychain}, 'Check key is defined');
    cmp_deeply(Stancer::Config::init(), $colon_hash, 'Works like a singleton');

    $args = $params->();
    my $colon_hashref = Stancer::Config::init($args);

    isa_ok($colon_hashref, 'Stancer::Config', 'Stancer::Config::init({keychain => $key})');
    is($colon_hashref->pprod, $args->{keychain}, 'Check key is defined');
    cmp_deeply(Stancer::Config::init(), $colon_hashref, 'Works like a singleton');
}

sub is_live_or_test_mode : Tests(12) {
    my $object = Stancer::Config->new();

    ok($object->is_test_mode, 'Default value + is_test_mode -> true');
    ok($object->is_not_live_mode, 'Default value + is_not_live_mode -> true');
    ok(not($object->is_live_mode), 'Default value + is_live_mode -> false');
    ok(not($object->is_not_test_mode), 'Default value + is_not_test_mode -> false');

    $object->mode(Stancer::Config::LIVE);

    ok($object->is_live_mode, 'Live mode on + is_test_mode -> true');
    ok($object->is_not_test_mode, 'Live mode on + is_not_live_mode -> true');
    ok(not($object->is_test_mode), 'Live mode on + is_live_mode -> false');
    ok(not($object->is_not_live_mode), 'Live mode on + is_not_test_mode -> false');

    $object->mode(Stancer::Config::TEST);

    ok($object->is_test_mode, 'Test mode on + is_test_mode -> true');
    ok($object->is_not_live_mode, 'Test mode on + is_not_live_mode -> true');
    ok(not($object->is_live_mode), 'Test mode on + is_live_mode -> false');
    ok(not($object->is_not_test_mode), 'Test mode on + is_not_test_mode -> false');
}

sub keychain : Tests(47) {
    my $pprod = 'pprod_' . random_string(24);
    my $sprod = 'sprod_' . random_string(24);
    my $ptest = 'ptest_' . random_string(24);
    my $stest = 'stest_' . random_string(24);
    my @keys = (
        $pprod,
        $sprod,
        $ptest,
        $stest,
    );

    {
        # Test with an array
        my $object = Stancer::Config->new();
        my $keys = $object->keychain;

        isa_ok($keys, 'ARRAY', 'Stancer::Config->new->keychain');
        is(scalar @{$keys}, 0, 'Should be empty');

        $object->keychain(@keys);

        is($object->pprod, $pprod, 'Should have updated "pprod"');
        is($object->sprod, $sprod, 'Should have updated "sprod"');
        is($object->ptest, $ptest, 'Should have updated "ptest"');
        is($object->stest, $stest, 'Should have updated "stest"');

        $keys = $object->keychain;

        isa_ok($keys, 'ARRAY', 'Stancer::Config->new->keychain(@keys)');
        is(scalar @{$keys}, 4, 'Should have 4 elements');

        foreach my $key (@keys) {
            my @filtered = grep { $_ eq $key } @{$keys};

            ok(scalar @filtered, 'Should have "' . $key . '" key');
        }
    }

    {
        # Work with ref too
        my $object = Stancer::Config->new();
        my $keys = $object->keychain;

        isa_ok($keys, 'ARRAY', 'Stancer::Config->new->keychain');
        is(scalar @{$keys}, 0, 'Should be empty');

        $object->keychain(\@keys);

        is($object->pprod, $pprod, 'Should have updated "pprod"');
        is($object->sprod, $sprod, 'Should have updated "sprod"');
        is($object->ptest, $ptest, 'Should have updated "ptest"');
        is($object->stest, $stest, 'Should have updated "stest"');

        $keys = $object->keychain;

        isa_ok($keys, 'ARRAY', 'Stancer::Config->new->keychain(\@keys)');
        is(scalar @{$keys}, 4, 'Should have 4 elements');

        foreach my $key (@keys) {
            my @filtered = grep { $_ eq $key } @{$keys};

            ok(scalar @filtered, 'Should have "' . $key . '" key');
        }
    }

    foreach my $key (@keys) {
        my $object = Stancer::Config->new();
        my $keys = $object->keychain;

        isa_ok($keys, 'ARRAY', 'Stancer::Config->new->keychain');
        is(scalar @{$keys}, 0, 'Should be empty');

        $object->keychain($key);

        $keys = $object->keychain;

        isa_ok($keys, 'ARRAY', 'Stancer::Config->new->keychain($key)');
        is(scalar @{$keys}, 1, 'Should have only one element');
        is($keys->[0], $key, 'Should be "' . $key . '"');
    }

    my @invalid = (
        [random_string(30), 'unknown prefix'],
        ['ptest_' . random_string(10), 'too small'],
        ['ptest_' . random_string(30), 'too long'],
    );

    my $not_valid = 'is not a valid API key';
    my $object = Stancer::Config->new();

    foreach my $data (@invalid) {
        throws_ok { $object->keychain($data->[0]) } qr/"$data->[0]" $not_valid/sm, 'Invalid key ' . $data->[1];
    }
}

sub lwp : Tests(2) {
    my $object = Stancer::Config->new();
    my $default = $object->lwp;

    isa_ok($default, 'LWP::UserAgent', '$config->lwp');

    my $ua = LWP::UserAgent->new();

    $object->lwp($ua);

    cmp_deeply($object->lwp, $ua, 'Should return setted object');
}

sub mode : Tests(5) {
    my $object = Stancer::Config->new();

    is($object->mode, Stancer::Config::TEST, '"test" by default');

    $object->mode(Stancer::Config::LIVE);

    is($object->mode, Stancer::Config::LIVE, 'Should be "live"');

    $object->mode(Stancer::Config::TEST);

    is($object->mode, Stancer::Config::TEST, 'Should be "test"');

    my $message = 'Must be one of : "' . Stancer::Config::TEST . '", "' . Stancer::Config::LIVE . '". %s given';
    my $invalid = random_string(4);

    throws_ok {
        $object->mode($invalid);
    } 'Stancer::Exceptions::InvalidArgument', 'Should emit an exception';
    is($EVAL_ERROR->message, sprintf($message, q/"/ . $invalid . q/"/), 'Message check');
}

sub port : Tests(2) {
    my $object = Stancer::Config->new();
    my $port = random_integer(1, 65_535);

    is($object->port, undef, 'Undefined by default');

    $object->port($port);

    is($object->port, $port, 'Should be updated');
}

sub pprod : Tests(8) {
    my $object = Stancer::Config->new();
    my $key = 'pprod_' . random_string(24);
    my @invalid = (
        ['sprod_' . random_string(24), '"sprod" not a "pprod"'],
        ['ptest_' . random_string(24), '"ptest" not a "pprod"'],
        ['stest_' . random_string(24), '"stest" not a "pprod"'],
        [random_string(30), 'unknown prefix' ],
        ['pprod_' . random_string(10), 'too small' ],
        ['pprod_' . random_string(30), 'too long' ],
    );

    is($object->pprod, undef, 'Undefined by default');

    $object->pprod($key);

    is($object->pprod, $key, 'Should allow ' . $key);

    my $not_valid = 'is not a valid public API key for live mode';

    foreach my $data (@invalid) {
        throws_ok { $object->pprod($data->[0]) } qr/"$data->[0]" $not_valid/sm, 'Invalid key, ' . $data->[1];
    }
}

sub public_key : Tests(6) {
    { # 4 tests
        note 'Without keys';

        my $object = Stancer::Config->new();

        throws_ok {
            $object->public_key
        } 'Stancer::Exceptions::MissingApiKey', 'Should complain if no key available (dev)';
        is(
            $EVAL_ERROR->message,
            'You did not provide valid public API key for development.',
            'Should indicate the error (dev)',
        );

        $object->mode('live');

        throws_ok {
            $object->public_key
        } 'Stancer::Exceptions::MissingApiKey', 'Should complain if no key available (prod)';
        is(
            $EVAL_ERROR->message,
            'You did not provide valid public API key for production.',
            'Should indicate the error (prod)',
        );
    }

    { # 2 tests
        note 'With keys';

        my $object = Stancer::Config->new();
        my $prod = 'pprod_' . random_string(24);
        my $test = 'ptest_' . random_string(24);

        $object->keychain($prod, $test);

        is($object->public_key, $test, 'Should return test key on default');

        $object->mode('live');

        is($object->public_key, $prod, 'Should return prod key on live mode');
    }
}

sub ptest : Tests(8) {
    my $object = Stancer::Config->new();
    my $key = 'ptest_' . random_string(24);
    my @invalid = (
        ['pprod_' . random_string(24), '"pprod" is not a "ptest"'],
        ['sprod_' . random_string(24), '"sprod" is not a "ptest"'],
        ['stest_' . random_string(24), '"stest" is not a "ptest"'],
        [random_string(30), 'unknown prefix'],
        ['ptest_' . random_string(10), 'too small'],
        ['ptest_' . random_string(30), 'too long'],
    );

    is($object->ptest, undef, 'Undefined by default');

    $object->ptest($key);

    is($object->ptest, $key, 'Should allow ' . $key);

    my $not_valid = 'is not a valid public API key for test mode';

    foreach my $data (@invalid) {
        throws_ok { $object->ptest($data->[0]) } qr/"$data->[0]" $not_valid/sm, 'Invalid key ' . $data->[1];
    }
}

sub secret_key : Tests(6) {
    { # 4 tests
        note 'Without keys';

        my $object = Stancer::Config->new();

        throws_ok {
            $object->secret_key
        } 'Stancer::Exceptions::MissingApiKey', 'Should complain if no key available (dev)';
        is(
            $EVAL_ERROR->message,
            'You did not provide valid secret API key for development.',
            'Should indicate the error (dev)',
        );

        $object->mode('live');

        throws_ok {
            $object->secret_key
        } 'Stancer::Exceptions::MissingApiKey', 'Should complain if no key available (prod)';
        is(
            $EVAL_ERROR->message,
            'You did not provide valid secret API key for production.',
            'Should indicate the error (prod)',
        );
    }

    { # 2 tests
        note 'With keys';

        my $object = Stancer::Config->new();
        my $prod = 'sprod_' . random_string(24);
        my $test = 'stest_' . random_string(24);

        $object->keychain($prod, $test);

        is($object->secret_key, $test, 'Should return test key on default');

        $object->mode('live');

        is($object->secret_key, $prod, 'Should return prod key on live mode');
    }
}

sub sprod : Tests(8) {
    my $object = Stancer::Config->new();
    my $key = 'sprod_' . random_string(24);
    my @invalid = (
        ['pprod_' . random_string(24), '"pprod" is not a "sprod"'],
        ['ptest_' . random_string(24), '"ptest" is not a "sprod"'],
        ['stest_' . random_string(24), '"stest" is not a "sprod"'],
        [random_string(30), 'unknown prefix'],
        ['sprod_' . random_string(10), 'too small'],
        ['sprod_' . random_string(30), 'too long'],
    );

    is($object->sprod, undef, 'Undefined by default');

    $object->sprod($key);

    is($object->sprod, $key, 'Should allow ' . $key);

    my $not_valid = 'is not a valid secret API key for live mode';

    foreach my $data (@invalid) {
        throws_ok { $object->sprod($data->[0]) } qr/"$data->[0]" $not_valid/sm, 'Invalid key ' . $data->[1];
    }
}

sub stest : Tests(8) {
    my $object = Stancer::Config->new();
    my $key = 'stest_' . random_string(24);
    my @invalid = (
        ['pprod_' . random_string(24), '"pprod" is not a "stest"'],
        ['ptest_' . random_string(24), '"ptest" is not a "stest"'],
        ['sprod_' . random_string(24), '"sprod" is not a "stest"'],
        [random_string(30), 'unknown prefix'],
        ['stest_' . random_string(10), 'too small'],
        ['stest_' . random_string(30), 'too long'],
    );

    is($object->stest, undef, 'Undefined by default');

    $object->stest($key);

    is($object->stest, $key, 'Should allow ' . $key);

    my $not_valid = 'is not a valid secret API key for test mode';

    foreach my $data (@invalid) {
        throws_ok { $object->stest($data->[0]) } qr/"$data->[0]" $not_valid/sm, 'Invalid key ' . $data->[1];
    }
}

sub timeout : Tests(2) {
    my $object = Stancer::Config->new();
    my $timeout = floor(rand 100) * 100;

    is($object->timeout, undef, '`undef` by default');

    $object->timeout($timeout);

    is($object->timeout, $timeout, 'Should be updated');
}

sub uri : Tests(3) {
    my $object = Stancer::Config->new();
    my $host = random_string(10);
    my $port = random_integer(1, 65_535);
    my $version = floor(rand 100) * 100;

    is($object->uri, 'https://api.stancer.com/v1', 'Should use "host", "version"');

    $object->port($port);

    is($object->uri, 'https://api.stancer.com:' . $port . '/v1', 'Should add "port" if provided');

    $object->host($host);
    $object->version($version);

    is($object->uri, 'https://' . $host . q/:/ . $port . q!/v! . $version, 'Fully modified');
}

sub version : Tests(2) {
    my $object = Stancer::Config->new();
    my $version = floor(rand 100) * 100;

    is($object->version, 1, '1 by default');

    $object->version($version);

    is($object->version, $version, 'Should be updated');
}

1;
