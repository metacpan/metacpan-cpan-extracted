#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
# !no_doc!
use strict;
use warnings;

package Net::OpenNebula::VM;
$Net::OpenNebula::VM::VERSION = '0.313.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'vm';

# the VM states as constants
use constant {
    STOPPED => "stopped",
    PENDING => "pending",
    PROLOG => "prolog",
    RUNNING => "running",
    SHUTDOWN => "shutdown",
    DONE => "done"
};

use Net::OpenNebula::VM::NIC;

sub nics {
   my ($self) = @_;
   my $template = $self->_get_info_extended('TEMPLATE');

   my @ret = ();

   for my $nic (@{ $template->[0]->{NIC} }) {
      push(@ret, Net::OpenNebula::VM::NIC->new(data => $nic));
   }

   return @ret;
}


sub start {
   my ($self) = @_;
   $self->_get_info(clearcache => 1);

   my $state = $self->{extended_data}->{STATE}->[0];  
   
   if($state == 5 || $state == 4 || $state == 8) {
      return $self->resume();
   }
   else {
      return $self->_onerpc_simple("action", "start");
   }
}

# don't know how to get the state properly. didn't found good docs.
sub state {
   my ($self) = @_;
   $self->_get_info(clearcache => 1);

   my $state = $self->{extended_data}->{STATE}->[0];

   if(!defined($state)) {
       $self->warn('Undefined '.ONERPC.'-state for id ', $self->id);
   }

   if($state == 4) {
      return STOPPED;
   }

   if($state == 1) {
      return PENDING;
   }

   my $last_poll = $self->{extended_data}->{LAST_POLL}->[0];
   if($state == 3 && $last_poll == 0) {
      return PROLOG;
   }

   if($state == 3 && $last_poll->[0] && $last_poll > 0) {
      return RUNNING;
   }

   my $lcm_state = $self->{extended_data}->{LCM_STATE}->[0];  
   if($lcm_state == 12) {
      return SHUTDOWN;
   }

   # TODO what is this supposed to mean? it's impossible or a typo 
   if($lcm_state == 0 || $lcm_state == 6) {
      return DONE;
   }


}

sub arch {
   my ($self) = @_;
   
   my $template = $self->_get_info_extended('TEMPLATE');
   
   return $template->[0]->{OS}->[0]->{ARCH}->[0];
}

sub get_data {
   my ($self) = @_;
   $self->_get_info;
   return $self->{extended_data};
}

# define all generic actions
no strict 'refs'; ## no critic
foreach my $i (qw(shutdown shutdown_hard reboot reboot_hard poweroff poweroff_hard 
                  suspend resume restart stop delete delete_recreate hold release 
                  boot resched unresched undeploy undeploy_hard)) {
    *{$i} = sub {
        my $self = shift;
        return $self->_onerpc_simple("action", $i);
    }
}
use strict 'refs';

1;
