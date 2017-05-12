package Procs::ForLogTest;
use strict;
use warnings;
use Su::Template;
use Su::Log;

my $model = {};

sub new {
  return bless { model => $model }, shift;
}

sub log_test {

  my $log = Su::Log->new;
  $log->info("info test.");
}

sub log_off_test {

  my $log = Su::Log->new;
  $log->off;
  $log->info("info test.");
} ## end sub log_off_test

sub many_level_log {
  my $ret = "";

  my $log = Su::Log->new;

  my $log_data;
  $log_data = $log->debug("debug test.");
  $ret .= $log_data if $log_data;
  $log_data = $log->trace("tarce test.");
  $ret .= $log_data if $log_data;
  $log_data = $log->info("info test.");
  $ret .= $log_data if $log_data;
  $log_data = $log->warn("warn test.");
  $ret .= $log_data if $log_data;
  $log_data = $log->error("error test.");
  $ret .= $log_data if $log_data;
  $log_data = $log->crit("crit test.");
  $ret .= $log_data if $log_data;
} ## end sub many_level_log

# The main method for this process class.
sub process {
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $model = keys %{ $self->{model} } ? $self->{model} : $model;

  my $param = shift;

  #$Su::Template::DEBUG=1;
  my $ret = expand(<<'__TMPL__');

__TMPL__

  #$Su::Template::DEBUG=0;
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
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $arg = shift;
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
