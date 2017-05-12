#!/usr/bin/perl

## In your class 
package My::App;
use Moose;

with 'MooseX::Getopt::Usage',
     'MooseX::Getopt::Usage::Role::Man';

has verbose => ( is => 'ro', isa => 'Bool', default => 0,
    documentation => qq{Say lots about what we are doing} );

has gumption => ( is => 'rw', isa => 'Int', default => 23,
    documentation => qq{How much gumption to apply} );

# ... rest of class

## In your script
package main;
my $app = My::App->new_with_options;
