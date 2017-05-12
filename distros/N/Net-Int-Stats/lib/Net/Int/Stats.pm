package Net::Int::Stats;

our $VERSION = '2.1';

use strict;
use warnings;

############ Global Declarations ##############

# hash of hashes
# key1 - interface, key2 - type ex: rx_packets, values ex: 'packets:12345'
my %interface_values;

# tmp array to store string tokens
my @tmp;

# interface name
my $key1;

# value types
my @key2;

########## End Global Declarations ###########

# generate ifconfig values
sub data {

    # store ifconfig output
    my @ifconfig_out = `/sbin/ifconfig`;

    # loop through each line of ifconfig output
    foreach (@ifconfig_out){

        # skip if blank line
        next if /^$/;

        # get interface name if not white space
        if (!/^\s/){

            # extract values
            extract($_);

            # store first token of interface name
            $key1 = shift(@tmp);
        }

        # get inet address, RX, TX, collisions and txqueuelen values
        # look for 'inet addr' or 'RX' or 'TX' or 'collisions' text
        if (/RX/ || /TX/ || /collisions/ || /inet addr/){

            # key2 values
            @key2 = qw(inet_addr) if (/inet addr/);
            @key2 = qw(rx_packets rx_errors rx_dropped rx_overruns rx_frame) if (/RX packets/);
            @key2 = qw(tx_packets tx_errors tx_dropped tx_overruns tx_carrier) if (/TX packets/);
			@key2 = qw(rx_bytes tx_bytes) if (/RX bytes/);
            @key2 = qw(collisions txqueuelen) if (/collisions/);

            # extract values
            extract($_);

            # shift first token of 'inet' or 'RX' or 'TX'
            shift(@tmp) if (/inet addr/ || /RX packets/ || /TX packets/);

            # build values hash
            build();
        }
    }
}

# extract values
sub extract {

    # ifconfig output line with newlines removed
    my $line = shift;

    # remove spaces
    $line =~ s/^\s+//;

    # store tokens split on spaces
    @tmp = split (/\s/, $line);

    # check if line is RX or TX bytes
    if ($line =~ /bytes/){
        # slice bytes values
        @tmp = @tmp[1,6];
    }
}

# build values hash
sub build {

    # values type count
    my $i = 0;

    # loop through value types
    for (@key2){
	
        # build hash with interface name, value type, and value
        $interface_values{$key1}{$_} = $tmp[$i];

        # increment values type count
        $i++;
    }
}

# validate interface name
sub validate {

    # interface name
    my $int = shift;

    # terminate program if specified interface name is not in ifconfig output
    die "specified interface $int not listed in ifconfig output!\n" if !(grep(/$int/, keys %interface_values));
}

# create new Net::Int::Stats object
sub new {

    # class name
    my $class = shift;

    # allocate object memory
    my $self = {};

    # assign object reference to class
    bless($self, $class);

    # initialize values reference
    $self->{VALUES} = '';

    # initialize interfaces list reference
    $self->{INTERFACES} = '';

    # generate value data
    data();

    # return object reference
    return $self;
}

# get specific ifconfig value for specific interface
sub value {

    # object reference
    my $self = shift;

    # interface name
    my $int = shift;

    # value type
    my $type = shift;

    # validate if supplied interface is present
    validate($int);

    # user specified value
    $self->{VALUES} = $interface_values{$int}{$type};

    # return value
    return $self->{VALUES};
}

sub interfaces {

    # object reference
    my $self = shift;

    # interface list
    my @int_list = keys %interface_values;

    # interface list reference
    $self->{INTERFACES} = "@int_list";

    # return value
    return $self->{INTERFACES};
}

1;

__END__

=head1 NAME

Net::Int::Stats - Reports specific ifconfig values for a network interface

=head1 SYNOPSIS

  use Net::Int::Stats;

  my $get = Net::Int::Stats->new();

  # get a value for a specific interface
  my $int     = 'eth0';
  my $stat    = 'rx_packets';
  my $packets = $get->value($int, $stat);

  # get a list of all interfaces
  my @interface_list = $get->interfaces();

=head1 DESCRIPTION

  This module provides a list of all interfaces and various statistics generated from the ifconfig command
  for specific interfaces. RX values consist of packets, errors, dropped, overruns, frame, and bytes. TX
  values consist of packets, errors, dropped, overruns, carrier, and bytes. In addition IPv4 address, collisions,
  and txqueuelen are reported. Values are in the format of type:n - ex 'packets:123456'. The interfaces() method
  returns a space delimited list of all interfaces. Ex: lo eth0 eth1.

=head1 METHODS

Use this method to get specific values which requires two arguments: B<value()>.
Ex: $packets = $get->value($int, 'rx_packets');

The first argument is the interface and the second is the type value to extract.

RX values - rx_packets, rx_errors, rx_dropped, rx_overruns, rx_frame, rx_bytes

TX values - tx_packets, tx_errors, tx_dropped, tx_overruns, tx_carrier, tx_bytes

Miscellaneous values - collisions, txqueuelen, inet_addr

Use this method to get a list of all interfaces: B<interfaces()>.
Ex: @interface_list = $get->interfaces();

=head1 DEPENDENCIES

This module is platform dependent. It uses the linux version
of /sbin/ifconfig. Other platforms such as the windows equivalent
of ipconfig, mac osx, and other versions of unix are not supported. 
This is due to the fact that each platform generates and displays
different information in different formats of ifconfig results.
The linux version is used over the other platforms because of the 
amount of data the default command outputs.  

=head1 SEE ALSO

linux command /sbin/ifconfig

=head1 NOTES

ifconfig output contains more information than the values that are
extracted in this module. More values and/or support for other
operating systems can be added if there are any requests to do so.   

=head1 AUTHOR

Bruce Burch <bcb12001@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Bruce Burch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
