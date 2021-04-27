#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
use strict;
use warnings;

package Net::OpenNebula::User;
$Net::OpenNebula::User::VERSION = '0.316.0';
use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'user';

sub create {
   my ($self, $name, $password, $driver) = @_;
   if (! defined $driver) {
       $driver = "core";
   }
   return $self->_allocate([ string => $name ],
                           [ string => $password ],
                           [ string => $driver ],
                          );
}

# foir current user, apply method to groupid
sub _do_grp {
    my ($self, $grp_id, $method) = @_;

    $self->has_id($method) || return;

    $self->debug(1, "$self->{ONERPC} $method id ".$self->id." group id $grp_id");
    return $self->_onerpc($method,
                          [ int => $self->id ],
                          [ int => $grp_id ],
                          );
}

# chgrp groupid
sub chgrp {
    my ($self, $grp_id) = @_;
    return $self->_do_grp($grp_id, 'chgrp');
}

# addgroup groupid
sub addgroup {
    my ($self, $grp_id) = @_;
    return $self->_do_grp($grp_id, 'addgroup');
}

# delgroup groupid
sub delgroup {
    my ($self, $grp_id) = @_;
    return $self->_do_grp($grp_id, 'delgroup');
}

# chauth
# when passwd is undefined, empty string is used (i.e. password is not changed)
sub chauth
{
    my ($self, $driver, $passwd) = @_;

    $passwd = '' if(!defined($passwd));

    my $method = 'chauth';
    $self->has_id($method) || return;

    $self->debug(1, "$self->{ONERPC} $method id ".$self->id." driver $driver " . (length($passwd) ? 'non-' : ''). "empty password");
    return $self->_onerpc($method,
                          [ int => $self->id ],
                          [ string => $driver ],
                          [ string => $passwd ],
                          );
}

1;
