package NetworkInfo::Discovery::Detect;

use strict;
use warnings;

=head1 NAME

NetworkInfo::Discovery::Detect - Super Class for all detection modules

=head1 SYNOPSIS

    See NetworkInfo::Discovery::(Sniff|Traceroute|Scan)
    for examples.

=head1 DESCRIPTION

NetworkInfo::Discovery::Detect is set up to be the super class of all the detection modules.
It sets up the methods for setting and getting the discovered information about interfaces, gateways, and subnets.


=head1 METHODS

=over 4

=item new 

just set up lists for holding interfaces, subnets, and gateways

=cut

sub new {
    my $proto = shift;
    my %args = @_;
    my $err;

    my $class = ref($proto) || $proto;

    my $self  = {};
    bless ($self, $class);

    #set defaults
    $self->{'interfacelist'} = [];
    $self->{'gwlist'} = [];
    $self->{'subnetlist'} = [];

    # for all args, see if we can autoload them
    foreach my $attr (keys %args) {
	if ($self->can($attr) ) {
	    $self->$attr( $args{$attr} );
	} else {
	    print "error calling $class->$attr (  $args{$attr} ) : no method $attr \n";
	}
    }

    return $self;
}

=pod

=item do_it

this needs to be implemented in the subclass.  
it should do what ever it does to detect interfaces, gateways, or subnets adding them to our lists by using the add_* methods below.

=cut

sub do_it {

}

=pod

=item get_interfaces

=item get_gateways

=item get_subnets

returns a list of hash references for interfaces, gateways, or subnets.

=cut

sub get_interfaces {
    my $self = shift;

    return @{$self->{'interfacelist'}};
}
sub get_gateways {
    my $self = shift;

    return @{$self->{'gwlist'}};
}
sub get_subnets {
    my $self = shift;

    return @{$self->{'subnetlist'}};
}

=pod

=item add_interface ($hashref)

=item add_gateway ($hashref)

=item add_subnet ($hashref)

adds the hash ref to the list of interfaces, gateways, or subnets.

=cut

sub add_interface {
    my $self = shift;

    while (@_) {
	push (@{$self->{'interfacelist'}}, shift);
    }
}

sub add_gateway {
    my $self = shift;

    while (@_) {
	push (@{$self->{'gwlist'}}, shift);
    }
}

sub add_subnet {
    my $self = shift;

    while (@_) {
	push (@{$self->{'subnetlist'}}, shift);
    }
}

=back

=head1 AUTHOR

Tom Scanlan <tscanlan@they.gotdns.org>

=head1 SEE ALSO

L<NetworkInfo::Discovery::Sniff>

L<NetworkInfo::Discovery::Traceroute>

L<NetworkInfo::Discovery::Scan>

=head1 BUGS

Please send any bugs to Tom Scanlan <tscanlan@they.gotdns.org>

=cut

1;
