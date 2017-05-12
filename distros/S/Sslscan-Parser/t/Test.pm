#!/usr/bin/perl
package t::Test;
use Test::Class;     eval 'use Test::Class';
plan( skip_all => 'Test::Class required for additional testing' ) if $@;

use Sslscan::Parser;
use base 'Test::Class';
use Test::More;

sub setup : Test(setup => no_plan) {
    my ($self) = @_;
    
    $self->{parser1} = Sslscan::Parser->parse_file('t/test1.xml');
}
1;
