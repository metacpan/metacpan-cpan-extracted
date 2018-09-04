package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use FFI::CheckLib;

sub myWriteMakefile
{
  my %args = @_;

  my @find_lib_args = (
    lib => [ qw(newrelic-collector-client newrelic-common newrelic-transaction) ]
  );
  push @find_lib_args, libpath => ['/opt/newrelic/lib/'] if -d '/opt/newrelic/lib/';
  my @system = FFI::CheckLib::find_lib(@find_lib_args);

  unless(@system)
  {
    $args{PREREQ_PM}->{'Alien::nragent'} = 0;
  }
  
  WriteMakefile(%args);
}

1;
