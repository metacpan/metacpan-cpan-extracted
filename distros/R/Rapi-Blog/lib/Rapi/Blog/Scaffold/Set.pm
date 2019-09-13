package Rapi::Blog::Scaffold::Set;
use strict;
use warnings;

use RapidApp::Util qw(:all);
use Rapi::Blog::Util;
use List::Util;

use Moo;
use Types::Standard ':all';

has 'Scaffolds', is => 'ro', required => 1, isa => ArrayRef[InstanceOf['Rapi::Blog::Scaffold']];

sub count { scalar(@{(shift)->Scaffolds}) }
sub all   { @{(shift)->Scaffolds}        }
sub first { (shift)->Scaffolds->[0]      }


sub BUILD {
  my $self = shift;
  
  $self->first or die "At least one Scaffold is required";
}

sub first_with_param {
  my $self = shift;
  my $param = shift or die "no param supplied";
  
  List::Util::first { $_->config->$param } $self->all
}

sub first_with_param_file {
  my $self = shift;
  my $param = shift or die "no param supplied";
  
  List::Util::first {
    my $val = $_->config->$param;
    if($val) {
      my $File = $_->dir->file($val);
      -f $File
    }
    else {
      0
    }
  } $self->all
}

sub first_config_value {
  my ($self, $param) = @_;
  
  my $Scaffold = $self->first_with_param($param) or return undef;
  $Scaffold->config->$param
}

sub first_config_value_file {
  my ($self, $param) = @_;
  
  my $Scaffold = $self->first_with_param_file($param) or return undef;
  $Scaffold->config->$param
}

sub first_config_value_filepath {
  my ($self, $param) = @_;
  
  my $Scaffold = $self->first_with_param_file($param) or return undef;
  $Scaffold->dir->file( $Scaffold->config->$param )->stringify
}




1;