package Net::OpenStack::Client::Theservice::v3DOT1;

use strict;
use warnings;

our $avar = "test";

sub custom_method
{
    my ($self, @args) = @_;

    return \@args;
}

1;
