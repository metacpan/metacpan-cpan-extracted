#!/usr/bin/perl

package Eg::Exception;

use Moose;
extends 'MooseX::Exception::Base';

has '+_verbose' => (
    default => 1,
);

package Eg::Exception::Bad;

use Moose;
extends 'Eg::Exception';

has '+_verbose' => (
    default => 2,
);
has bad => (
    is     => 'rw',
    isa    => 'Str',
    traits => [qw/MooseX::Exception::Stringify/],
);

package main;

use strict;
use warnings;

eval { Eg::Exception->throw(error => 'first error') };

if ($@) {
    print "Caught error: $@\n\n";
}

bad();

sub bad {
    eval { Eg::Exception::Bad->throw(error => 'second error', bad => 'Very bad!') };

    if ($@) {
        print "Caught bad error: $@\n\n";
    }
}
