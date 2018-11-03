package testapi;

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/testapi";

use parent qw(Net::OpenStack::Client::API);

sub new
{
    my ($this) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub rest
{
    my ($self, $req) = @_;
    # dummy rest call, do nothing, just wrap the request in simple hashref and return it
    return {req => $req};
}

1;

