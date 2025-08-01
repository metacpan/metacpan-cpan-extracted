#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Service::Debian;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use base qw(Rex::Service::Base);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  $self->{commands} = {
    start          => '/etc/init.d/%s start',
    restart        => '/etc/init.d/%s restart',
    stop           => '/etc/init.d/%s stop',
    reload         => '/etc/init.d/%s reload',
    status         => '/etc/init.d/%s status',
    ensure_stop    => 'update-rc.d -f %s remove',
    ensure_start   => 'update-rc.d %s defaults',
    action         => '/etc/init.d/%s %s',
    service_exists => '/usr/sbin/service --status-all 2>&1 | grep %s',
  };

  return $self;
}

1;
