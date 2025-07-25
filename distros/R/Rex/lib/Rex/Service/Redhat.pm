#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Service::Redhat;

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
    start          => '/etc/rc.d/init.d/%s start',
    restart        => '/etc/rc.d/init.d/%s restart',
    stop           => '/etc/rc.d/init.d/%s stop',
    reload         => '/etc/rc.d/init.d/%s reload',
    status         => '/etc/rc.d/init.d/%s status',
    ensure_stop    => 'chkconfig %s off',
    ensure_start   => 'chkconfig %s on',
    action         => '/etc/rc.d/init.d/%s %s',
    service_exists => 'chkconfig --list %s',
  };

  return $self;
}

1;
