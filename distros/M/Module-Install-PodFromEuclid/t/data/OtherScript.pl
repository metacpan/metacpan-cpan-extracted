#! /usr/bin/env perl

use 5.006;
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Getopt::Euclid;

our $VERSION = '0.99';

=head1 NAME

MyScript - This is my other script

=head1 REQUIRED ARGUMENTS

=over

=item  -s[ize]=<h>x<w>

Specify size of simulation

=for Euclid:
    h.type:    int > 0
    h.default: 24
    w.type:    int >= 10
    w.default: 80

=back

=head1 OPTIONS

=over

=item  -l[[en][gth]] <l>

Length of simulation. The default is l.default

=for Euclid:
    l.type:    num
    l.default: 1.2

=back

=head1 AUTHOR

Jane Doe

=cut


sub init {
   print "Hello, parameters were:\n".
      "  height: ".$ARGV{-size}{h}."\n".
      "  width:  ".$ARGV{-size}{w}."\n".
      "  length: ".$ARGV{-length}."\n";
}


MyModule::init();

exit;

