#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#
use strict;
use warnings;

=head1 NAME

Net::OpenNebula::Host - Access OpenNebula Host Information.

=head1 DESCRIPTION

Query the Hoststatus of an OpenNebula host.

=head1 SYNOPSIS

 use Net::OpenNebula;
 my $one = Net::OpenNebula->new(
    url      => "http://server:2633/RPC2",
    user     => "oneadmin",
    password => "onepass",
 );

 my ($host) = grep { $_->name eq "one-sandbox" } $one->get_hosts();
 for my $vm ($host->vms) { ... }

=cut

package Net::OpenNebula::Host;
$Net::OpenNebula::Host::VERSION = '0.317.0';
use version;

use Net::OpenNebula::RPC;
push our @ISA , qw(Net::OpenNebula::RPC);

use constant ONERPC => 'host';
use constant NAME_FROM_TEMPLATE => 1;

# From include/Host.h
use constant STATES => qw(INIT MONITORING_MONITORED MONITORED ERROR DISABLED MONITORING_ERROR MONITORING_INIT MONITORING_DISABLED);

sub vms {
    my ($self) = @_;
    my $vms = $self->_get_info_extended('VMS');
    my @ret;
    foreach my $vm_id (@{ $vms->[0]->{ID} }) {
        push @ret, $self->{rpc}->get_vm($vm_id);
    }

    return @ret;
}

sub used {
    my ($self) = @_;
    my $hs = $self->_get_info_extended('HOST_SHARE');
    if ($hs->[0]->{RUNNING_VMS}->[0]) {
        return 1;
    }
};


# Use private _enable for the rpc enable interface
sub _enable {
    my ($self, $bool) = @_;

    return $self->_onerpc("enable",
                          [ int => $self->id ],
                          [ boolean => $bool ],
                         );
}

# Use private _status to enable/disable/offline hyps (since ONE 5.0)
# status(int): 0 enabled, 1 disabled, 2 offline
sub _status {
    my ($self, $status) = @_;

    return $self->_onerpc("status",
                          [ int => $self->id ],
                          [ int => $status ],
                         );
}

sub enable {
    my $self = shift;
    if ($self->{rpc}->version() < version->new('5.0.0')) {
        return $self->_enable(1);
    } else {
        return $self->_status(0);
    };
}

sub disable {
    my ($self) = @_;
    if ($self->{rpc}->version() < version->new('5.0.0')) {
        return $self->_enable(0);
    } else {
        return $self->_status(1);
    };
}

# Return the state as string
sub state {
   my ($self) = @_;

   # Needs to be up to date info
   $self->_get_info(clearcache => 1);

   my $state = $self->{extended_data}->{STATE}->[0];

   if(!defined($state)) {
       $self->warn('Undefined '.ONERPC.'-state for id ', $self->id);
       return;
   }

   return (STATES)[$state];
};

# also from include/Host.h
sub is_enabled {
    my $self = shift;
    return $self->state() !~ m/DISABLED$/;
}

sub is_monitoring {
    my $self = shift;
    return $self->state() =~ m/^MONITORING_$/;
}

1;
