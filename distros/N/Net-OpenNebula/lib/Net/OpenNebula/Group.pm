use strict;
use warnings;

package Net::OpenNebula::Group;
$Net::OpenNebula::Group::VERSION = '0.316.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'group';

sub create {
   my ($self, $name) = @_;
   return $self->_allocate([ string => $name ]);
}

1;
