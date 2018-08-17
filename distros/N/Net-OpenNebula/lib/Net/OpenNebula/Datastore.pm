#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
use strict;
use warnings;

package Net::OpenNebula::Datastore;
$Net::OpenNebula::Datastore::VERSION = '0.313.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'datastore';

sub create {
    my ($self, $tpl_txt, %option) = @_;
    return $self->_allocate([ string => $tpl_txt ],
                            [ int => (exists $option{cluster} ? $option{cluster} : -1) ],
        );
}

sub used {
   my ($self) = @_;
   my $img = $self->_get_info_extended('IMAGES');
   if (defined($img->[0]->{ID}->[0])) {
       return 1;
   } 
};

1;
