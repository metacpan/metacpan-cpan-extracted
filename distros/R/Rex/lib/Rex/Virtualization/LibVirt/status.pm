#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Virtualization::LibVirt::status;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Virtualization::LibVirt::info;

sub execute {
  my ( $class, $arg1, %opt ) = @_;

  my $info = Rex::Virtualization::LibVirt::info->execute($arg1);
  if ( $info->{State} eq "shut off" ) {
    return "stopped";
  }

  return "running";
}

1;
