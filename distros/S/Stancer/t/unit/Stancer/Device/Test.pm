package Stancer::Device::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use English qw(-no_match_vars);
use Stancer::Device;
use TestCase;

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub instanciate : Tests(10) {
    note 'Basic tests';

    my $accept = random_string(100);
    my $agent = random_string(100);
    my $city = random_string(100);
    my $country = random_string(100);
    my $ip = join q/./, (
        random_integer(1, 254),
        random_integer(1, 254),
        random_integer(1, 254),
        random_integer(1, 254),
    );
    my $languages = random_string(32);
    my $port = random_integer(1, 65_535);

    my $object = Stancer::Device->new(
        city => $city,
        country => $country,
        http_accept => $accept,
        ip => $ip,
        languages => $languages,
        port => $port,
        user_agent => $agent,
    );

    isa_ok($object, 'Stancer::Device', 'Stancer::Device->new(foo => "bar")');
    isa_ok($object, 'Stancer::Core::Object', 'Stancer::Device->new(foo => "bar")');

    is($object->city, $city, 'Should add a value for `city` property');
    is($object->country, $country, 'Should add a value for `country` property');
    is($object->http_accept, $accept, 'Should add a value for `http_accept` property');
    is($object->ip, $ip, 'Should add a value for `ip` property');
    is($object->languages, $languages, 'Should add a value for `languages` property');
    is($object->port, $port, 'Should add a value for `port` property');
    is($object->user_agent, $agent, 'Should add a value for `user_agent` property');

    my $exported = {
        city => $city,
        country => $country,
        http_accept => $accept,
        ip => $ip,
        languages => $languages,
        port => $port,
        user_agent => $agent,
    };

    cmp_deeply_json($object, $exported, 'They should be exported');
}

sub city : Tests(3) {
    my $object = Stancer::Device->new();
    my $city = random_string(100);

    is($object->city, undef, 'Undefined by default');

    $object->city($city);

    is($object->city, $city, 'Should be updated');
    cmp_deeply_json($object, { city => $city }, 'Should be exported');
}

sub country : Tests(3) {
    my $object = Stancer::Device->new();
    my $country = random_string(100);

    is($object->country, undef, 'Undefined by default');

    $object->country($country);

    is($object->country, $country, 'Should be updated');
    cmp_deeply_json($object, { country => $country }, 'Should be exported');
}

sub http_accept : Tests(3) {
    my $object = Stancer::Device->new();
    my $accept = random_string(100);

    is($object->http_accept, undef, 'Undefined by default');

    $object->http_accept($accept);

    is($object->http_accept, $accept, 'Should be updated');
    cmp_deeply_json($object, { http_accept => $accept }, 'Should be exported');
}

sub hydrate_from_env : Tests(52) {
    { # 12 tests
        note 'With complete env and empty object';

        my $accept = random_string(100);
        my $agent = random_string(100);
        my $ip = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        my $languages = random_string(32);
        my $port = random_integer(1, 65_535);

        local $ENV{SERVER_ADDR} = $ip;
        local $ENV{SERVER_PORT} = $port;
        local $ENV{HTTP_ACCEPT} = $accept;
        local $ENV{HTTP_ACCEPT_LANGUAGE} = $languages;
        local $ENV{HTTP_USER_AGENT} = $agent;

        my $object = Stancer::Device->new;

        is($object->http_accept, undef, 'Should return undef for `http_accept` property');
        is($object->ip, undef, 'Should return undef for `ip` property');
        is($object->languages, undef, 'Should return undef for `languages` property');
        is($object->port, undef, 'Should return undef for `port` property');
        is($object->user_agent, undef, 'Should return undef for `user_agent` property');

        isa_ok($object->hydrate_from_env, 'Stancer::Device', '$device->hydrate_from_env()');

        is($object->http_accept, $accept, 'Should add a value for `http_accept` property');
        is($object->ip, $ip, 'Should add a value for `ip` property');
        is($object->languages, $languages, 'Should add a value for `languages` property');
        is($object->port, $port, 'Should add a value for `port` property');
        is($object->user_agent, $agent, 'Should add a value for `user_agent` property');

        my $data = {
            http_accept => $accept,
            ip => $ip,
            languages => $languages,
            port => $port,
            user_agent => $agent,
        };

        cmp_deeply_json($object, $data, 'They should be exported');
    }

    { # 12 tests
        note 'With complete env and partial object';

        my $accept = random_string(100);
        my $agent = random_string(100);
        my $ip = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        my $languages = random_string(32);
        my $port = random_integer(1, 65_535);

        local $ENV{SERVER_ADDR} = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        local $ENV{SERVER_PORT} = $port;
        local $ENV{HTTP_ACCEPT} = $accept;
        local $ENV{HTTP_ACCEPT_LANGUAGE} = random_string(32);
        local $ENV{HTTP_USER_AGENT} = $agent;

        my $object = Stancer::Device->new(ip => $ip, languages => $languages);

        is($object->http_accept, undef, 'Should return undef for `http_accept` property');
        is($object->ip, $ip, 'Should already have a value for `ip` property');
        is($object->languages, $languages, 'Should already have a value for `languages` property');
        is($object->port, undef, 'Should return undef for `port` property');
        is($object->user_agent, undef, 'Should return undef for `user_agent` property');

        isa_ok($object->hydrate_from_env, 'Stancer::Device', '$device->hydrate_from_env()');

        is($object->http_accept, $accept, 'Should add a value for `http_accept` property');
        is($object->ip, $ip, 'Should keep `ip` value');
        is($object->languages, $languages, 'Should keep `languages` value');
        is($object->port, $port, 'Should add a value for `port` property');
        is($object->user_agent, $agent, 'Should add a value for `user_agent` property');

        my $data = {
            http_accept => $accept,
            ip => $ip,
            languages => $languages,
            port => $port,
            user_agent => $agent,
        };

        cmp_deeply_json($object, $data, 'They should be exported');
    }

    { # 12 tests
        note 'With complete object';

        my $accept = random_string(100);
        my $agent = random_string(100);
        my $ip = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        my $languages = random_string(32);
        my $port = random_integer(1, 65_535);

        local $ENV{SERVER_ADDR} = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        local $ENV{SERVER_PORT} = random_integer(1, 65_535);
        local $ENV{HTTP_ACCEPT} = random_string(100);
        local $ENV{HTTP_ACCEPT_LANGUAGE} = random_string(32);
        local $ENV{HTTP_USER_AGENT} = random_string(100);

        my $object = Stancer::Device->new(
            http_accept => $accept,
            ip => $ip,
            languages => $languages,
            port => $port,
            user_agent => $agent,
        );

        is($object->http_accept, $accept, 'Should have a value for `http_accept` property');
        is($object->ip, $ip, 'Should have a value for `ip` property');
        is($object->languages, $languages, 'Should have a value for `languages` property');
        is($object->port, $port, 'Should have a value for `port` property');
        is($object->user_agent, $agent, 'Should have a value for `user_agent` property');

        isa_ok($object->hydrate_from_env, 'Stancer::Device', '$device->hydrate_from_env()');

        is($object->http_accept, $accept, 'Should not modify `http_accept` value');
        is($object->ip, $ip, 'Should not modify `ip` value');
        is($object->languages, $languages, 'Should not modify `languages` value');
        is($object->port, $port, 'Should not modify `port` value');
        is($object->user_agent, $agent, 'Should not modify `user_agent` value');

        my $data = {
            http_accept => $accept,
            ip => $ip,
            languages => $languages,
            port => $port,
            user_agent => $agent,
        };

        cmp_deeply_json($object, $data, 'They should be exported');
    }

    { # 16 tests
        note 'With no env';

        my $ip = join q/./, (
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
            random_integer(1, 254),
        );
        my $port = random_integer(1, 65_535);

        my $object = Stancer::Device->new();

        is($object->http_accept, undef, 'Should return undef for `http_accept` property');
        is($object->ip, undef, 'Should return undef for `ip` property');
        is($object->languages, undef, 'Should return undef for `languages` property');
        is($object->port, undef, 'Should return undef for `port` property');
        is($object->user_agent, undef, 'Should return undef for `user_agent` property');

        throws_ok {
            $object->hydrate_from_env
        } 'Stancer::Exceptions::InvalidIpAddress', 'Throw exception if no IP address found';
        is($EVAL_ERROR->message, 'Invalid IP address.', 'Should indicate the error');

        local $ENV{SERVER_ADDR} = $ip;

        throws_ok {
            $object->hydrate_from_env
        } 'Stancer::Exceptions::InvalidPort', 'Throw exception if no port found';
        is($EVAL_ERROR->message, 'Invalid port.', 'Should indicate the error');

        local $ENV{SERVER_PORT} = $port;

        isa_ok($object->hydrate_from_env, 'Stancer::Device', '$device->hydrate_from_env()');

        is($object->http_accept, undef, 'Should still have no value for `http_accept` property');
        is($object->ip, $ip, 'Should add a value for `ip` property');
        is($object->languages, undef, 'Should still have no value for `languages` property');
        is($object->port, $port, 'Should add a value for `port` property');
        is($object->user_agent, undef, 'Should still have no value for `user_agent` property');

        my $data = {
            ip => $ip,
            port => $port,
        };

        cmp_deeply_json($object, $data, 'They should be exported');
    }
}

sub ip : Tests(34) {
    { # 15 tests
        note 'IPv4';

        my @ips = ipv4_provider();
        my $object = Stancer::Device->new();

        is($object->ip, undef, 'Undefined by default');

        for my $addr (@ips) {
            $object->ip($addr);

            is($object->ip, $addr, 'Should be updated with ' . $addr);
            cmp_deeply_json($object, { ip => $addr }, 'Should be exported');
        }
    }

    { # 19 tests
        note 'IPv6';

        my @ips = ipv6_provider();
        my $object = Stancer::Device->new();

        is($object->ip, undef, 'Undefined by default');

        for my $addr (@ips) {
            $object->ip($addr);

            is($object->ip, $addr, 'Should be updated with ' . $addr);
            cmp_deeply_json($object, { ip => $addr }, 'Should be exported');
        }
    }
}

sub languages : Tests(3) {
    my $object = Stancer::Device->new();
    my $languages = random_string(32);

    is($object->languages, undef, 'Undefined by default');

    $object->languages($languages);

    is($object->languages, $languages, 'Should be updated');
    cmp_deeply_json($object, { languages => $languages }, 'Should be exported');
}

sub port : Tests(3) {
    my $object = Stancer::Device->new();
    my $port = random_integer(1, 65_535);

    is($object->port, undef, 'Undefined by default');

    $object->port($port);

    is($object->port, $port, 'Should be updated');
    cmp_deeply_json($object, { port => $port }, 'Should be exported');
}

sub user_agent : Tests(3) {
    my $object = Stancer::Device->new();
    my $agent = random_string(100);

    is($object->user_agent, undef, 'Undefined by default');

    $object->user_agent($agent);

    is($object->user_agent, $agent, 'Should be updated');
    cmp_deeply_json($object, { user_agent => $agent }, 'Should be exported');
}

1;
