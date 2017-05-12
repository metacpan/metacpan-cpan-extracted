package pkg::MainProc;
use strict;
use warnings;
use Su::Template;

my $model = {};

sub new {
  return bless { model => $model }, shift;
}

# The main method for this process class.
sub process {
  my $self             = shift if ( $_[0] && ref $_[0] eq __PACKAGE__ );
  my $self_module_name = shift if ( $_[0] && $_[0]     eq __PACKAGE__ );
  my $model = keys %{ $self->{model} } ? $self->{model} : $model;

  my $ret = "value1";

  return $ret;
} ## end sub process

# This method is called if specified as a map filter class.
sub map_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;

  for (@results) {

  }

  return @results;
} ## end sub map_filter

# This method is called if specified as a reduce filter class.
sub reduce_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;
  my $result;
  for (@results) {

  }

  return $result;
} ## end sub reduce_filter

# This method is called if specified as a scalar filter class.
sub scalar_filter {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $result = shift;

  return $result;
} ## end sub scalar_filter

sub model {
  my $self             = shift if ref $_[0] eq __PACKAGE__;
  my $self_module_name = shift if $_[0]     eq __PACKAGE__;
  my $arg              = shift;
  if ($arg) {
    if ($self) { $self->{model} = $arg; }
    else {
      $model = $arg;
    }
  } else {
    if ($self) {
      return $self->{model};
    } else {
      return $model;
    }
  } ## end else [ if ($arg) ]
} ## end sub model

1;
