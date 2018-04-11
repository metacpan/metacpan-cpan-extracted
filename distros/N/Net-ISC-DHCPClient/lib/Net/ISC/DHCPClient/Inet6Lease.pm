package Net::ISC::DHCPClient::Inet6Lease;

use 5.006;
use strict;
use warnings;


=head1 NAME

Net::ISC::DHCPClient - ISC dhclient inet6 lease object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{INTERFACE} = undef;
    $self->{IA} = {};
    $self->{OPTION} = {};

    bless ($self, $class);

    return $self;
}

sub interface($) {
    my $self = shift;
    if (@_) { $self->{INTERFACE} = shift }
    return $self->{INTERFACE};
}
sub ias($$) {
    my $self = shift;
    return keys(%{$self->{IA}});
}

sub address($$) {
    my ($self, $ia) = @_;

    my $ia_addr_info = $self->_get_ia_addr_info($ia);
    return undef if (!$ia_addr_info);
    return $ia_addr_info->{addr};
}
sub starts($$) {
    my ($self, $ia) = @_;

    my $ia_info = $self->_get_ia_info($ia);
    return undef if (!$ia_info);
    return $ia_info->{starts};
}
sub renew($$) {
    my ($self, $ia) = @_;

    my $ia_info = $self->_get_ia_info($ia);
    return undef if (!$ia_info);
    return $ia_info->{renew};
}
sub rebind($$) {
    my ($self, $ia) = @_;

    my $ia_info = $self->_get_ia_info($ia);
    return undef if (!$ia_info);
    return $ia_info->{rebind};
}
sub preferred_life($$) {
    my ($self, $ia) = @_;

    my $ia_addr_info = $self->_get_ia_addr_info($ia);
    return undef if (!$ia_addr_info);
    return $ia_addr_info->{'preferred-life'};
}
sub max_life($$) {
    my ($self, $ia) = @_;

    my $ia_addr_info = $self->_get_ia_addr_info($ia);
    return undef if (!$ia_addr_info);
    return $ia_addr_info->{'max-life'};
}
sub option($;$) {
    my ($self, $opt) = @_;

    return keys(%{$self->{OPTION}}) if (!$opt);
    return $self->{OPTION}->{$opt};
}


sub _get_ia_info($$)
{
    my ($self, $ia) = @_;

    return undef if (!$self->{IA}->{$ia});
    return $self->{IA}->{$ia};
}
sub _get_ia_addr_info($$)
{
    my ($self, $ia) = @_;

    return undef if (!$self->{IA}->{$ia});
    if ($ia eq 'non-temporary') {
        return $self->{IA}->{$ia}->{iaaddr};
    } elsif ($ia eq 'prefix') {
        return $self->{IA}->{$ia}->{iaprefix};
    }

    return undef;
}


# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

1;
