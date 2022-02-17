#!/usr/bin/env perl
#
# Demo script to show the difference between
# calling get_options_from_array with "pass_through"
# enabled and disabled.
#
# Usage:
#
#   getopt_test.pl FLAG ARG ...
#
use 5.014;
use warnings;
use Data::Dumper;
use Term::CLI::Util qw( get_options_from_array );

my ($pass_through, @args) = @ARGV;

my %options;

my %result = get_options_from_array(
   args         => \@args,
   spec         => [ 'verbose|v+', 'debug|d' ],
   result       => \%options,
   pass_through => $pass_through,
);

print Data::Dumper->Dump(
   [ \%result, \%options, \@args ],
   [ '*result', '*options', '*args' ]
);
