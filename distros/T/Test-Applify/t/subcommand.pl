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
option file => input => 'file to read';

documentation __FILE__;
version $VERSION;

subcommand cat => 'cat a file' => sub {
  option str => 'line-number' => ' print line numbers', default => 0;
};

sub command_cat {
  my $self = shift;

  return 0;
}

sub log {}

app {
  my $self = shift;
  return 0;
};
