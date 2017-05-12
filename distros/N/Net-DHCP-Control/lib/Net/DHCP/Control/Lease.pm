
package Net::DHCP::Control::Lease;
use Net::DHCP::Control ':types';
use base Net::DHCP::Control::Generic;
use base Exporter;
@EXPORT_OK = qw(lease_statename);

$KIND = 'lease';

%ATTRS = ('ip-address' => TP_STRING,
	  ends => TP_INT,	  
	  starts => TP_INT,	  
	  state => TP_UINT,
	  'dhcp-client-identifier' => TP_STRING,
	  'client-hostname' => TP_STRING,
#	  host => TP_HANDLE,
#	  subnet => TP_HANDLE,
#	  pool => TP_HANDLE,
#	  'billing-class' => TP_HANDLE,
	  'hardware-address' => TP_STRING,
	  'hardware-type' => TP_STRING,
	  );

%OPTS = %Net::DHCP::Control::Generic::OPTS;

sub is_active {
    my $self = shift;
    my $now = time;
    $self->get('ends') > $now && $self->get('starts') <= $now ;
}

my @state = qw(unavailable free active expired released abandoned
	       reset backup reserved bootp);

my %state = map {$state[$_] => $_} 0 .. $#state;

sub lease_statename {
  my $arg = shift;
  if ($arg =~ /^\d+$/) {
    $state[$arg];
  } else {
    $state{$arg};
  }
}

1;
