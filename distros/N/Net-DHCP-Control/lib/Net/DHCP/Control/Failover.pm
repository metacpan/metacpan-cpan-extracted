

################################################################
package Net::DHCP::Control::Failover;
use base Net::DHCP::Control::Generic;

%EXPORTS = ('failover_statename' => 'Net::DHCP::Control::Failover::State',
	   );

sub import {
  my $class = shift;
  my $caller = caller;
  for my $import (@_) {
    my $package = $EXPORTS{$import};
    unless (defined $package) {
      $class->carp(qq{"$import" is not exported by the $class module
can't continue after import errors});
    }
    *{"$caller\::$import"} = \&{"$package\::$import"};
  }
}

################################################################
package Net::DHCP::Control::Failover::State;

use Net::DHCP::Control ':types';
@ISA = 'Net::DHCP::Control::Failover';

$KIND = 'failover-state';

%ATTRS = ('local-state' => TP_UINT,
          'name' => TP_STRING,
         );

%OPTS = %Net::DHCP::Control::Generic::OPTS;

my @state = ('unavailable',     # 0
	     'partner down', 	# 1
	     'normal',		# 2
	     'communications interrupted', # 3
	     'resolution interrupted', # 4
	     'potential conflict', # 5
	     'recover', 	# 6
	     'recover done',	# 7
	     'shutdown', 	# 8
	     'paused',		# 9
	     'startup',		# 10
	     'recover-wait',	# 11
	    );

my %state = map {$state[$_] => $_} 0 .. $#state;

sub failover_statename {
  my $arg = shift;
  if ($arg =~ /^\d+$/) {
    $state[$arg];
  } else {
    $state{$arg};
  }
}


package Net::DHCP::Control::Failover::Link;
@ISA = 'Net::DHCP::Control::Failover';

$KIND = 'failover-link';

%ATTRS = ();

%OPTS = %Net::DHCP::Control::Generic::OPTS;


package Net::DHCP::Control::Failover::Listener;
@ISA = 'Net::DHCP::Control::Failover';

$KIND = 'failover-listener';

%ATTRS = ();

%OPTS = %Net::DHCP::Control::Generic::OPTS;


1;
