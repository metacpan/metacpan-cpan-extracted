#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Service::OpenWrt;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Service::Debian;
use base qw(Rex::Service::Debian);

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = $proto->SUPER::new(@_);

  bless( $self, $proto );

  $self->{commands} = {
    start        => '/etc/init.d/%s start',
    restart      => '/etc/init.d/%s restart',
    stop         => '/etc/init.d/%s stop',
    reload       => '/etc/init.d/%s reload',
    status       => '/sbin/start-stop-daemon -K -t -q -n %s',
    ensure_stop  => '/etc/init.d/%s disable',
    ensure_start => '/etc/init.d/%s enable',
    action       => '/etc/init.d/%s %s',
  };

  return $self;
}

1;
