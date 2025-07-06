#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Virtualization::VBox::status;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

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
