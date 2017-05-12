package SNMP::Effective::HostList;

=head1 NAME

SNMP::Effective::HostList - Helper module for SNMP::Effective

=head1 DESCRIPTION

An object from this class holds an hash-ref where the keys are
hostnames and the values are L<SNMP::Effective::Host> objects.

=cut

use warnings;
use strict;
use Carp qw/ confess cluck /;
use SNMP::Effective::Host;

use overload '""'  => sub { 0 + keys %{ $_[0] } };
use overload '@{}' => sub { my @array; tie @array, ref $_[0], $_[0]; \@array };

=head1 METHODS

=head2 new

Object constructor.

=cut

sub new {
    return bless {}, (ref $_[0] || $_[0]);
}

=head2 length

    $int = $self->length;

Returns the number of hosts in this hostlist.

=cut

sub length {
    return 0 + keys %{$_[0]};
}

=head2 get_host

    $host_obj = $self->get_host($address);

=cut

sub get_host {
    return $_[0]->{$_[1]};
}

=head2 add_host

    $self->add_host(address => $str, ...);
    $self->add_host($host_obj);

=cut

sub add_host {
    my $self = shift;
    my $host;

    if(ref $_[0]) {
        return $self->{ $_[0]->address } = $_[0];
    }
    elsif(my %args = @_) {
        return $self->{ $args{'address'} } = SNMP::Effective::Host->new(\%args);
    }

    confess 'Invalid input to $self->add_host(...)';
}

=head2 shift

    $host = $self->shift;

Remove a host object from this hostlist, and return it.

=cut

sub shift {
    my $self = shift;
    my $key = (keys %$self)[0] or return;
    return delete $self->{$key};
}

sub TIEARRAY {
    cluck "Working on a tied HostList is deprecated";
    return $_[1];
}

sub FETCHSIZE {
    cluck "Working on a tied HostList is deprecated";
    &length;
}

sub SHIFT {
    cluck "Working on a tied HostList is deprecated";
    &shift;
}

=head1 AUTHOR

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

See L<SNMP::Effective>

=cut

1;
