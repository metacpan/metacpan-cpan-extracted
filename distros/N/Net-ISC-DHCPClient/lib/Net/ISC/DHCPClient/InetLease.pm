package Net::ISC::DHCPClient::InetLease;

use 5.006;
use strict;
use warnings;


=head1 NAME

Net::ISC::DHCPClient - ISC dhclient AF inet lease object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{INTERFACE} = undef;
    $self->{FIXED_ADDRESS} = undef;
    $self->{OPTION} = {};
    $self->{RENEW} = undef;
    $self->{REBIND} = undef;
    $self->{EXPIRE} = undef;

    bless ($self, $class);

    return $self;
}

sub interface {
    my $self = shift;
    if (@_) { $self->{INTERFACE} = shift }
    return $self->{INTERFACE};
}
sub fixed_address {
    my $self = shift;
    if (@_) { $self->{FIXED_ADDRESS} = shift }
    return $self->{FIXED_ADDRESS};
}
sub option {
    my $self = shift;
    if (@_) { $self->{OPTION} = shift }
    return $self->{OPTION};
}
sub renew {
    my $self = shift;
    if (@_) { $self->{RENEW} = shift }
    return $self->{RENEW};
}
sub rebind {
    my $self = shift;
    if (@_) { $self->{REBIND} = shift }
    return $self->{REBIND};
}
sub expire {
    my $self = shift;
    if (@_) { $self->{EXPIRE} = shift }
    return $self->{EXPIRE};
}

# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

1;
