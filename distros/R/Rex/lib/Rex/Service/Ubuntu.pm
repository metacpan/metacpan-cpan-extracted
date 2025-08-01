#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Service::Ubuntu;

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
    start          => '/usr/sbin/service %s start',
    restart        => '/usr/sbin/service %s restart',
    stop           => '/usr/sbin/service %s stop',
    reload         => '/usr/sbin/service %s reload',
    status         => '/usr/sbin/service %s status',
    ensure_stop    => '/usr/sbin/update-rc.d -f %s remove',
    ensure_start   => '/usr/sbin/update-rc.d %s defaults',
    action         => '/usr/sbin/service %s %s',
    service_exists => '/usr/sbin/service --status-all 2>&1 | grep %s',
  };

  return $self;
}

sub status {
  my ( $self, $service, $options ) = @_;

  my $ret = $self->SUPER::status( $service, $options );

  # bad... really bad ...
  if ( $ret == 0 ) {
    return 0;
  }

  my $output = $self->get_output;

  if ( $output =~ m/NOT running|stop\//ms ) {
    return 0;
  }

  return 1;
}

1;
