package Sys::Simple;

use strict;
use warnings;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/cpu_usage/;

our $VERSION = 0.001;

use Sys::Simple::CPU::Linux;

# Only works on linux for now

sub cpu_usage{ return Sys::Simple::CPU::Linux::cpu_usage( @_ ); }

1;

 # ABSTRACT: Sys Simple, functional system information, made simple

=head1 NAME

Sys::Simple is a set of functions and perl modules that retrieve information
about the local system. The goal is to have light and simple functions, that
has a simple scopped answer. 

=head1 VERSION 

version 0.001

=head1 SYNOPSIS

    use Sys::Simple qw/ list of functions/;

    function();

OR

you can use a given function directly using the full namespace:

    use Sys::Simple::CPU::Linux;

    Sys::Simple::CPU::Linux::cpu_usage();

=head1 EXPORTS

None of the functions are exported by default

=head2 cpu_usage

Returns the amount of the cpu being used on the machine. If the 
machine have more than one cpu or cores, it will count all processing
power as one and give the percentage used from the pool. By example
a given machine with 4 cpus with three of them idle and one at full use
will return 0.25. To have the total percentage you must multiply the 
value by 100;

The way it calculates use a wait of 10 miliseconds, but if more time 
is necessary you can pass a numeric argument and this will multiply the
10 miliseconds used as interval to calculate the cpu_usage.

There is other modules all over CPAN that does almost the same, this one
is different because really does not create an object, or requires setup, 
or whatever, call it and return the usage.


=head1 SOURCE CODE

Github: https://github.com/fredericorecsky/Sys-Simple

=head1 AUTHOR

Frederico Recsky <recsky@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
