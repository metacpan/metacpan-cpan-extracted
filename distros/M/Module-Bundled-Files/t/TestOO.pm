#!/usr/bin/perl -w
package TestOO;
use strict;

use base 'Module::Bundled::Files';

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