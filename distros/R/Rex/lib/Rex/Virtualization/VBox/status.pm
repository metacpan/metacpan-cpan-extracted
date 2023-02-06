#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Virtualization::VBox::status;

use 5.010001;
use strict;
use warnings;

our $VERSION = '1.14.0'; # VERSION

use Rex::Virtualization::VBox::list;

sub execute {
  my ( $class, $arg1, %opt ) = @_;

  my $vms = Rex::Virtualization::VBox::list->execute("all");

  my ($vm) = grep { $_->{name} eq $arg1 } @{$vms};

  if ( $vm->{status} eq "poweroff" ) {
    return "stopped";
  }
  else {
    return "running";
  }
}

1;
