#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Package::Base;

use strict;
use warnings;

use Rex::Commands::Gather;

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  my %sys_info = get_system_information();

  $self->{arch} ||= $sys_info{architecture}, $self->{version} ||= "1.0";

  return $self;
}

for my $name (
  qw/
  path
  source
  release
  epoch
  version
  arch
  name
  file_user
  file_group
  /
  )
{
  no strict 'refs';
  *{ __PACKAGE__ . "::$name" } = sub {
    my ( $self, $data ) = @_;

    if ($data) {
      $self->{$name} = $data;
    }

    $self->{$name};

  };
  use strict;
}

sub prefix {
  my ( $self, $prefix ) = @_;

  if ($prefix) {
    $self->{prefix} = $prefix;
  }

  return $self->{prefix} || $self->{path};
}

1;
