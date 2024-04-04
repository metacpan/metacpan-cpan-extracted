package Stancer::Core::Types::Network::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::Network qw(:all);

has an_ip_address => (
    is => 'ro',
    isa => IpAddress,
);

has a_port => (
    is => 'ro',
    isa => Port,
);

has an_url => (
    is => 'ro',
    isa => Url,
);

1;
