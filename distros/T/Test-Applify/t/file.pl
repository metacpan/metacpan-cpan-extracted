#!/usr/bin/env perl
=pod

=head1 NAME

file.pl - an example

=head1 DESCRIPTION

a simple example

=head1 SYNOPSIS

  example.pl [options]

Example:

  example.pl -mode expert -input words.txt

=cut

use strict;
use warnings;

use Applify;

our $VERSION = '1.2.999';

option str  => mode => 'basic or expert', default => 'basic';
option file => input => 'file to read', required => 1;

documentation __FILE__;
version $VERSION;

sub log {}

app {
  warn "$0\n";
  return 0;
};
