package Stancer::Role::Payment::Auth::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Auth;
use Stancer::Auth::Status;
use Stancer::Device;
use Stancer::Role::Payment::Auth::Stub;
use TestCase;

## no critic (RequireExtendedFormatting, RequireFinalReturn, ValuesAndExpressions::RequireInterpolationOfMetachars)

sub auth : Tests(14) {
    { # 3 tests
        note 'With an Auth object';

        my $object = Stancer::Role::Payment::Auth::Stub->new();
        my $auth = Stancer::Auth->new();

        is($object->auth, undef, 'Undefined by default');

        $object->auth($auth);

        is($object->auth, $auth, 'Should be updated');

        my $exported = {
            auth => {
                status => Stancer::Auth::Status::REQUEST,
            },
        };

        cmp_deeply_json($object, $exported, 'Should be exported');
    }

    { # 5 tests
        note 'With an url';

        my $object = Stancer::Role::Payment::Auth::Stub->new();
        my $return_url = 'https://' . random_string(30);

        is($object->auth, undef, 'Undefined by default');

        $object->auth($return_url);

        isa_ok($object->auth, 'Stancer::Auth', '$object->auth');
        is($object->auth->return_url, $return_url, 'Should update `return_url` attribute');
        is($object->auth->status, Stancer::Auth::Status::REQUEST, 'Should have a `request` status');

        my $exported = {
            auth => {
                return_url => $return_url,
                status => Stancer::Auth::Status::REQUEST,
            },
        };

        cmp_deeply_json($object, $exported, 'Should be exported');
    }

    { # 4 tests
        note 'With a true value';

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        is($object->auth, undef, 'Undefined by default');

        $object->auth($true);

        isa_ok($object->auth, 'Stancer::Auth', '$object->auth');
        is($object->auth->status, Stancer::Auth::Status::REQUEST, 'Should have a `request` status');

        my $exported = {
            auth => {
                status => Stancer::Auth::Status::REQUEST,
            },
        };

        cmp_deeply_json($object, $exported, 'Should be exported');
    }

    { # 2 tests
        note 'With a false value';

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        is($object->auth, undef, 'Undefined by default');

        $object->auth($false);

        is($object->auth, undef, 'Still undefined');
    }
}

sub create_device : Tests(14) {
    { # 2 tests
        note 'No method, no device';

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        isa_ok($object->_create_device, 'Stancer::Role::Payment::Auth::Stub', '$object->_create_device');
        is($object->device, undef, 'No device created');
    }

    { # 2 tests
        note 'Got a method and a device';

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        my $object = Stancer::Role::Payment::Auth::Stub->new();
        my $device = Stancer::Device->new(ip => $ip, port => $port);

        $object->device($device);
        $object->method('card'); # For test only

        isa_ok($object->_create_device, 'Stancer::Role::Payment::Auth::Stub', '$object->_create_device');
        is($object->device, $device, 'Should return the same device');
    }

    { # 2 tests
        note 'Got a method, create a device';

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        local $ENV{SERVER_ADDR} = $ip;
        local $ENV{SERVER_PORT} = $port;

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        $object->method('card'); # For test only

        isa_ok($object->_create_device, 'Stancer::Role::Payment::Auth::Stub', '$object->_create_device');
        isa_ok($object->device, 'Stancer::Device', 'Device created');
    }

    { # 2 tests
        note 'Got a method, device is optional, no exception';

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        $object->method('card'); # For test only

        isa_ok($object->_create_device, 'Stancer::Role::Payment::Auth::Stub', '$object->_create_device');
        is($object->device, undef, 'No device created');
    }

    { # 2 tests
        note 'Got an auth object without return URL, no device, no exception';

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        $object->auth(Stancer::Auth::Status::REQUESTED);
        $object->method('card'); # For test only

        isa_ok($object->_create_device, 'Stancer::Role::Payment::Auth::Stub', '$object->_create_device');
        is($object->device, undef, 'No device created');
    }

    { # 4 tests
        note 'Got a method, should alert if device creation is impossible';

        my $ip = ipv4_provider();
        my $port = random_integer(1, 65_535);

        my $object = Stancer::Role::Payment::Auth::Stub->new();

        $object->auth('https://www.example.com');
        $object->method('card'); # For test only

        throws_ok { $object->_create_device } 'Stancer::Exceptions::InvalidIpAddress', 'Should complain for lack of IP address';

        local $ENV{SERVER_ADDR} = $ip;

        throws_ok { $object->_create_device } 'Stancer::Exceptions::InvalidPort', 'Should complain for lack of port';

        local $ENV{SERVER_PORT} = $port;

        isa_ok($object->_create_device, 'Stancer::Role::Payment::Auth::Stub', '$object->_create_device');
        isa_ok($object->device, 'Stancer::Device', 'Device created');
    }
}

sub device : Tests(3) {
    my $object = Stancer::Role::Payment::Auth::Stub->new();
    my $ip = ipv4_provider();
    my $port = random_integer(1, 65_535);
    my $device = Stancer::Device->new(ip => $ip, port => $port);

    is($object->device, undef, 'Undefined by default');

    $object->device($device);

    is($object->device, $device, 'Should be updated');
    cmp_deeply_json($object, { device => { ip => $ip, port => $port } }, 'Should be exported');
}

1;
