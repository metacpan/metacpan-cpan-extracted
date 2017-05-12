#!/usr/bin/perl -w
package TestNonOO;
use strict;

use Module::Bundled::Files;

sub new()
{
    my $class = shift;
    my $proto = ref($class) || $class;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub donothing()
{
    return 'nothing done';
}

1;