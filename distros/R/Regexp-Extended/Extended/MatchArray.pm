package Regexp::Extended::MatchArray;

use strict;
use Carp;

sub STORE {
  my ($self, $arg1, $arg2) = @_;
  my $data = ${${$self}};

  $data->{'matches'}->[$arg1]->{'value'} = $arg2;
  $data->{'matches'}->[$arg1]->{'dirty'} = 1;
}

sub FETCH {
  my ($self, $arg1) = @_;
  my $data = ${${$self}};

  return $data->{'matches'}->[$arg1]->{'value'};
}  

sub FETCHSIZE {
  my ($self) = @_;
  my $data = ${${$self}};

  return scalar @{$data->{'matches'}};
}

sub PUSH {
  my ($self, $obj) = @_;
  my $data = ${${$self}};

  push @{$data->{'matches'}}, $obj;
}

sub EXISTS {
  print STDERR "Exists\n";
}
sub DELETE {
  print STDERR "Delete\n";
}
sub CLEAR {
  print STDERR "Clear\n";
}
sub UNSHIFT {
  print STDERR "Unshift\n";
}
sub POP {
  print STDERR "Pop\n";
}
sub SHIFT {
  print STDERR "Shift\n";
}
sub SPLICE {
  print STDERR "Splice\n";
}

return 1;
