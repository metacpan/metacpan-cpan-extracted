#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
use strict;
use warnings;

package Net::OpenNebula::Image;
$Net::OpenNebula::Image::VERSION = '0.311.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'image';
use constant NAME_FROM_TEMPLATE => 1;

# from include/Image.h enum ImageState
use constant STATES => qw(INIT READY USED DISABLED LOCKED ERROR CLONE DELETE USED_PERS);

sub create {
   my ($self, $tpl_txt, $datastoreid) = @_;
   my $id = $self->_onerpc("allocate", [ string => $tpl_txt ], [ int => $datastoreid ]);
   $self->{data} =  $self->_get_info(id => $id);
   return $id;
}


sub delete {
    my ($self) = @_;
    return $self->_onerpc_id("delete");
}

# Return the state as string
sub state {
   my ($self) = @_;
   $self->_get_info(clearcache => 1);

   my $state = $self->{extended_data}->{STATE}->[0];

   if(!defined($state)) {
       $self->warn('Undefined '.ONERPC.'-state for id ', $self->id);
       return;
   }

   return (STATES)[$state];
};


1;
