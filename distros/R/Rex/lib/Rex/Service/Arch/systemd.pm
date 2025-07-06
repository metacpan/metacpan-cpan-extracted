#
# ArchLinux systemd support
#

package Rex::Service::Arch::systemd;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Service::Redhat::systemd;
use base qw(Rex::Service::Redhat::systemd);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  return $self;
}

1;
