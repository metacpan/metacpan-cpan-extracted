#!/usr/bin/perl6
use v6;

# 

my %person = (
    fname => 'Foo',
    lname => 'Bar',
);
%person{"fname"}.say;
%person{"lname"}.say;

%person{"email"} = 'foo@bar.com';
%person{"email"}.say;

