package Serivce::Example::Config;

use strict;
use warnings;

use Myriad::Service;

config 'required_key';
config 'optional_key', default => 'option';
config 'secret', secure => 1;

async method startup () {

    # if required key was not found in one of the sources
    # this sub will never run

    # access config through API
    # value because all config are Ryu::Observable
    my $secret = $api->config('secret')->value->secret_value;
    my $optional = $api->config('optional_key')->as_string;

    # This will throw
    my $unknown = $api->config('unknown');
}

1;
