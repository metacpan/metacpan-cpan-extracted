#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
# !no_doc!
use strict;
use warnings;

package Net::OpenNebula::VMGroup;
$Net::OpenNebula::VMGroup::VERSION = '0.317.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'vmgroup';
use constant ONEPOOLKEY => 'VM_GROUP';

sub create {
   my ($self, $tpl_txt) = @_;
   return $self->_allocate([ string => $tpl_txt ]);
}

sub used {
   my ($self) = @_;
   my $vms = $self->_get_info_extended('ROLES');
   if (defined($vms->[0]->{ROLE}->[0]->{VMS}->[0])) {
       return 1;
   }
};

1;
