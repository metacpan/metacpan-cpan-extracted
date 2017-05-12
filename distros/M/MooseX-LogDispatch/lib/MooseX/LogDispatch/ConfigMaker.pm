package # Hide from Pause
  MooseX::LogDispatch::ConfigMaker;


use strict;
use warnings;

use base qw/Log::Dispatch::Configurator/;

sub new { bless { default => $_[1] }, $_[0] }

sub get_attrs_global { 
  return {format => undef, dispatchers => ['default' ] } 
}

sub get_attrs { 
  my ($self, $name) = @_;
  $self->{$name} || die "invalid dispatcher name: $name";
}

sub needs_reload { 0 }

1;
