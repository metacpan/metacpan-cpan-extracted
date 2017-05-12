package Pkg::MainProc;
use strict;
use warnings;
use Su::Template;
my $model = {};
my $val;

sub new {
  return bless { model => $model }, shift;
}

# The main method for this process class.
sub process {
  my $self = shift if ref $_[0] eq __PACKAGE__;

  my $ret = ++$self->{model}->{hoge};
  return $ret;

} ## end sub process

# This method is called If specified as a map filter class.
sub map_filter {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my @results = @_;

  for (@results) {

  }

  return @results;
} ## end sub map_filter

# This method is called If specified as a reduce filter class.
sub reduce_filter {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my @results = @_;
  my $result;
  for (@results) {

  }

  return $result;
} ## end sub reduce_filter

# This method is called If specified as a scalar filter class.
sub scalar_filter {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my $result = shift;

  return $result;
} ## end sub scalar_filter

sub model {
  if ( $_[0] eq __PACKAGE__ ) {
    shift;
  }
  my $arg = shift;
  if ($arg) {
    $model = $arg;
  } else {
    return $model;
  }
} ## end sub model

1;
