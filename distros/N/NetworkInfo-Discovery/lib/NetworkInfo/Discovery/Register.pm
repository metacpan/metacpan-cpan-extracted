package NetworkInfo::Discovery::Register;

use strict;
use warnings;

=head1 NAME

NetworkInfo::Discovery::Register - Register of network information

=head1 SYNOPSIS

    use NetworkInfo::Discovery::Register;

    # is like doing a $r->autosave(1) and $r->file("/tmp/the.register")
    my $r = new NetworkInfo::Discovery::Register(autosave=>1, file=>"/tmp/the.register");

    $r->read_register();    # restore state from last save

    # ACLs allow us to remember only what we are allowed to
    $r->clear_acl;
    $r->add_acl("allow", "192.168.1.3/24"); # 192.168.1.3/24 gets converted to 192.168.1.0/24 
    $r->add_acl("deny", "0.0.0.0/0");

    my $interface = { ip    =>	'192.168.1.1',
		      mac   =>	'aa:bb:cc:dd:ee:ff',
		      mask  =>	'255.255.255.0',    # or 24 (as in prefix notation)
		      dns   =>	'www.somehost.org',
		    };

    $r->add_interface($interface);

    my $subnet	= { ip	    =>	'192.168.1.0', # this is the network address
		    mask    =>	24, # could also be '255.255.255.0'
		  };

    $r->add_subnet($subnet);

    my $gateway =   { ip    =>	'192.168.1.254',
		      mask  =>	24,
		      mac   =>	'ff:ee:dd:cc:bb:aa',
		      dns   =>	'router.somehost.org',
		    };

    $r->add_gateway($gateway);

    $r->write_register();    # save state for future restore

=head1 DESCRIPTION

C<NetworkInfo::Discovery::Register> is a place to combine all that we have discovered about the network.
As more information gets put in, the more corrolation we should see here.

For example, finding the netmask of an interface is not easy to do.
If we happen to find a subnet from some source (say RIP, or an ICMP "Address Mask Request"), 
we may later see that those hosts with no netmask probably fit into the subnet.  Once we are sure of this, 
we can add the netmask to the interfaces, and the interfaces into the subnet.
By combining our knowledge in this manner, hopefully we discover more than we would by finding 
random bits of information.

The register stores information about interfaces, gateways, and subnets.
Each is a list of hashes in it's core,
and thus has an extensible set of attributes that we can tag onto each object.
With that said, the pieces of information that I am using for corrolation is as follows 
(a * denotes that an attribute is mandatory):

    interface
	ip	# * this is the ip address of the interface
	mac	# * this is the ethernet MAC address of the interface
	mask	# the network mask in prefix or dotted-quad format 

    subnet
	ip	# * an ip address on the subnet
	mask	# * the network mask in prefix or dotted-quad 

    gateway
	ip	# * ip address of the interface that is this gateway

In this module we also provide for persistance using Storable.  No one likes forgetting information, right?

=head1 METHODS

=over 4

=item new

=cut

sub new {
    my $proto = shift;
    my %args = @_;

    my $class = ref($proto) || $proto;

    my $self  = {
	'subnets'   => [],  # list of host indexes.
	'gateways'  => [],  # list of host/subnet lists
	'interfaces'=> [],  # list of things we know about an interface
	'events'    => [],  # three dogs and a biscut
	'mac2int'   => {},  # lookup table for mac to interface
	'ip2int'    => {},  # lookup table for ip to interface
	'file'	    => '',
	'autosave'  => 0,
	'_acls'	    => [],
    };

    bless ($self, $class);

    $self->{'file'} = $args{file} if (exists $args{file});
    $self->{'autosave'} = $args{autosave} if (exists $args{autosave});

    if ($self->file && -r $self->file) {
	$self = $self->read_register( );
    }

    # add a subnet to cover all hosts
    $self->add_subnet({ ip=>'0.0.0.0', mask=>0 });
    return $self;
}

=pod 

=item add_interface ($interface_hashref)

=cut

sub add_interface {
    my $self = shift;
    my $args = &verify_args(shift);

    # we must have an ip or a mac
    return 0 unless ($args->{ip} or $args->{mac});

    # make sure we pass our ACLs
    return 0 unless ($self->test_acl($args->{ip}));

    # if the interface exists, update it
    if (my $int = $self->has_interface($args)) {
	return $self->update_interface($int, $args);
    }
 
    # set the creation date
    $args->{create_date} = time;


    # add us to the interface list
    my $index = push (@{$self->{interfaces}}, $args);
    $index--;

#    $self->add_event("add_interface: at index $index ip=>" . $args->{ip} . " mac=>" . $args->{mac} );

    unless ( defined $args->{mask} ) {
	$args->{mask} = $self->guess_mask($args->{ip});
	$args->{mask_prob} = .5;
    }
    # if we have an ip and a mask, we know our subnet
    if ($args->{ip} and $args->{mask}) {
	my $net;

	# create the subnet if it doesn't exist
	unless ($net = $self->has_subnet({ ip=>$args->{ip}, mask=>$args->{mask } }) ) {
	    $net = $self->add_subnet({ ip=>$args->{ip}, mask=>$args->{mask } });
	}

	# add this interface to the subnet
	$self->add_interface_to_subnet($index, $net);
    } else {
	# we don't have a mask, add us to the default subnet
	$self->add_interface_to_subnet($index, 0);
    }
	
	    
    # index us by ip and by mac for fast lookups
    $self->{ip2int}->{$args->{ip}}   = $index if $args->{ip};
    $self->{mac2int}->{$args->{mac}} = $index if $args->{mac};

    # being careful about the "0th" index, return the index
    return "0 but true" if $index == 0;
    return $index;
}

=pod

=item add_interface_to_subnet ($interface_index, $subnet_index)

=cut

sub add_interface_to_subnet {
    my $self = shift;
    # look out for "0 but true"
    my $interface = int(shift);
    my $subnet = int(shift);

    $self->add_event("add_interface_to_subnet interface=$interface, subnet=$subnet");
    # add this interface to the subnet
    push (@{$self->{subnets}->[$subnet]->{interfaces} }, $interface);

    # add a pointer to the subnet in the interface
    $self->{interfaces}->[$interface]->{subnet} = $subnet;

}

=pod

=item delete_interface ($interface_hashref)

This cuts an interface out of the interface list.
To keep holes from forming in the list, 
take the last interface off the list and put it in place of the one we want to delete.

Also, keep track of pointers to subnets and gateways,
from subnets and gateways,
and interface lookup tables.

The special case is when we are the last interface in the list, and should just cut us out.

=cut

sub delete_interface {
    my $self = shift;
    my $args = &verify_args(shift);

    return 0 unless ($args->{ip} or $args->{mac});
	
    if ( my $interface_index = $self->has_interface($args) ){
	$self->add_event("delete_interface: from index $interface_index");
	# index to the last interface in the list
	my $last_index = $#{ $self->{interfaces} };

	# pop the last interface off
	my $last_interface = pop(@{$self->{interfaces}});

	# remove the indexes for the last_interface
	delete $self->{ip2int}->{$last_interface->{ip}}   if exists $last_interface->{ip};
	delete $self->{mac2int}->{$last_interface->{mac}} if exists $last_interface->{mac};

	# remove the last interface from any subnets and gateways
	$self->remove_interface_from_subnet($last_index, $last_interface->{subnet}) if (exists $last_interface->{subnet});
	$self->remove_interface_from_gateway($last_index, $last_interface->{gateway}) if (exists $last_interface->{gateway});

	# we are done if we happen to be the last interface
	return 1 if ($last_index == $interface_index) ;


	$self->add_event("delete_interface: swapping index $interface_index for $last_index");
	# remove our interface, replace with the last one
	my $cut_interface = splice(@{$self->{interfaces}}, $interface_index, 1, $last_interface );

	# clear out the cut interface's indexs
	delete $self->{ip2int}->{$cut_interface->{ip}}   if exists $cut_interface->{ip};
	delete $self->{mac2int}->{$cut_interface->{mac}} if exists $cut_interface->{mac};

	# remove the cut interface from any subnets and gateways
	$self->remove_interface_from_subnet($interface_index, $cut_interface->{subnet}) if (exists $cut_interface->{subnet});
	$self->remove_interface_from_gateway($interface_index, $cut_interface->{gateway}) if (exists $cut_interface->{gateway});
    
	
	# now update indexes for the last interface
	$self->{ip2int}->{$last_interface->{ip}}   = $interface_index if $last_interface->{ip};
	$self->{mac2int}->{$last_interface->{mac}} = $interface_index if $last_interface->{mac};
	
	# finally, re-add the pointers to subnets and gateways
	$self->add_interface_to_subnet($interface_index, $last_interface->{subnet}) if (exists $last_interface->{subnet});
	$self->add_interface_to_gateway($interface_index, $last_interface->{gateway}) if (exists $last_interface->{gateway});
    }

    return 1;
}

=pod

=item add_interface_to_gateway ($interface_index, $gateway_index)

=cut

sub add_interface_to_gateway {
    my $self = shift;
    my $interface = int(shift);
    my $gateway = int(shift);

    $self->add_event("add_interface_to_gateway interface=$interface, gateway=$gateway");
    #  add us to the gateway
    push ( @{$self->{gateways}->[$gateway]->{interfaces} }, $interface);
}
=pod

=item remove_interface_from_gateway ($interface_index, $gateway_index)

=cut

sub remove_interface_from_gateway {
    my $self = shift;
    my $interface = int(shift);
    my $gateway = int(shift);
    
    $self->add_event("remove_interface_from_gateway: interface=$interface, gateway=$gateway");

    # remove us from any gateways
    @{$self->{gateways}->[$gateway]->{interfaces} } = grep { $_ != $interface } 
	    @{$self->{gateways}->[$gateway]->{interfaces} };
}

=pod

=item remove_interface_from_subnet ($interface_index, $subnet_index)

=cut

sub remove_interface_from_subnet {
    my $self = shift;
    my $interface = int(shift);
    my $subnet = int(shift);

    $self->add_event("remove_interface_from_subnet: interface=$interface, subnet=$subnet");
    # remove us from any subnets
    @{$self->{subnets}->[$subnet]->{interfaces} } = 
	grep { $_ != $interface } @{$self->{subnets}->[$subnet]->{interfaces} };

    # remove the pointer to the subnet from the interface
    delete $self->{interfaces}->[$interface]->{subnet} if exists $self->{interfaces}->[$interface];
}


=pod

=item has_interface($interface_hashref)

=cut

sub has_interface {
    my $self = shift;
    my $args = &verify_args(shift);

    #no warnings;

    if (exists $args->{ip} and exists $self->{ip2int}->{$args->{ip}} ) {
	my $i = $self->{ip2int}->{$args->{ip}};
	return "0 but true" if $i == 0;
	return $i;
    }
    if ( exists $args->{mac} and exists $self->{mac2int}->{$args->{mac}} ) {
	my $i = $self->{mac2int}->{$args->{mac}};
	return "0 but true" if $i == 0;
	return $i;
    }
    
    return 0;
}

#sub has_interface {
#    my $self = shift;
#    my %args = &verify_args(@_);
#
#    return 0 unless ($args{ip} or $args{mac});
#
#    no warnings;
#    for (my $i=0; $i < @{$self->{interfaces}}; $i++) {
#	if (  $self->{interfaces}->[$i]->{ip} eq $args{ip}
#	     or $self->{interfaces}->[$i]->{mac} eq $args{mac} ) {
#
#	    return "0 but true" if $i == 0;
#	    return $i;
#	}
#    }
#
#    return 0;
#}

=pod

=item update_interface($interface_hashref)

=cut

sub update_interface {
    my $self=shift;
    my $interface = int(shift);
    my $args = &verify_args(shift);
   
    # this create our new interface based on the old one
    my %newint = %{$self->{interfaces}->[$interface]};

    # release old indexes
    delete $self->{ip2int}->{$newint{ip}}   if $newint{ip};
    delete $self->{mac2int}->{$newint{mac}} if $newint{mac};

    # then over write the old one with the passed args
    while (my ($k, $v) = each(%$args) ) {
        $v="" unless $v;
        $k="" unless $k;
	if (exists $newint{$k}) {
	    if ($v and $newint{$k} ne $v) {
		# make an event here...
		#print "changed interface $interface key $k from $newint{$k} to $v\n";
		$newint{$k} = $v;

	    } else {
		#print "left interface $interface alone for $k $newint{$k} == $v\n";
	    }
	} else {
	    #print "added key $k to interface $interface\n";
	}
    }

    # finish moving the last interface into place
    $newint{update_date} = time;
    %{$self->{interfaces}->[$interface]} = %newint;

    # set new indexes
    $self->{ip2int}->{$newint{ip}}   = $interface if $newint{ip};
    $self->{mac2int}->{$newint{mac}} = $interface if $newint{mac};

    return "0 but true" if $interface == 0;
    return $interface;
}


=pod

=item add_subnet($subnet_hashref)

=cut

sub add_subnet {
    my $self = shift;
    my $args = &verify_args(shift);

    return 0 unless ($args->{ip} and ($args->{mask} ne ""));

    # make sure we pass our ACLs
    return 0 unless ($self->test_acl($args->{ip}));

    my $index;
    # don't add the subnet unless it doesn't exist
    unless ($index = $self->has_subnet({ ip=>$args->{ip}, mask=>$args->{mask} } )) {
	# find our network address
	my $ip = unpack("N", pack("C4", split(/\./, $args->{ip})));
	my $networknum = ($ip >> (32 - $args->{mask})) << (32 - $args->{mask});
    
	$args->{ip} = join ('.', unpack( "C4", pack( "N", $networknum ) ) );
   
	$args->{create_date} = time;
#    print "add_subnet \n";
#    while (my ($k,$v) = each (%$args)){ print "	$k=>$v\n"; }
	$index = push (@{$self->{subnets}}, $args);
	$index--;
	$self->add_event("added subnet " . $args->{ip} . " at index $index");

    }
    return "0 but true" if $index == 0;
    return $index;
}

=pod

=item has_subnet($subnet_hashref)

=cut

sub has_subnet {
    my $self = shift;
    my $args = &verify_args(shift);

#    print "has_subnet: just entering, ip=>" . $args->{ip} . " mask=>". $args->{mask} . "\n";
    return 0 unless ($args->{ip} and $args->{mask} ne "");

    # find our network address
    my $ip = unpack("N", pack("C4", split(/\./, $args->{ip})));
    my $networknum = ($ip >> (32 - $args->{mask})) << (32 - $args->{mask});
    $args->{ip} = join ('.', unpack( "C4", pack( "N", $networknum ) ) );


    for (my $i=0; $i < @{$self->{subnets}}; $i++) {
	if ($self->{subnets}->[$i]->{ip} eq $args->{ip}
		and $self->{subnets}->[$i]->{mask} eq $args->{mask} ) {
	    return "0 but true" if $i == 0;
	    return $i;
	}
    }

    return 0;
}

##########
## Gateway stuff...
###################

=pod

=item add_gateway($gateway_hashref)

=cut

sub add_gateway {
    my $self = shift;
    my $args = &verify_args(shift);

    # must have at least an ip
    return 0 unless ($args->{ip});

    # make sure we pass our ACLs
    return 0 unless ($self->test_acl($args->{ip}));

    my $gwindex;
    if ($gwindex = $self->has_gateway($args)) {
	# update the gateway...
    } else {
	$gwindex = @{ $self->{gateways} }; 
    	$args->{gateway} = $gwindex;

    	my $interfaceindex;
    	if ($interfaceindex = $self->has_interface($args)) {
    	    $self->update_interface($interfaceindex, $args);
    	} else {
    	    $interfaceindex = $self->add_interface($args);
    	}

    	my $gw;
    	push(@{ $gw->{interfaces} }, $interfaceindex);
    	push(@{ $gw->{subnets} }, $self->{interfaces}->[$interfaceindex]->{subnet});
    	push(@{ $self->{gateways} }, $gw);
    }
    return "0 but true" if $gwindex == 0;
    return $gwindex;
}


=pod

=item has_gateway($gateway_hashref)

=cut

sub has_gateway {
    my $self = shift;
    my $args = &verify_args(shift);

    return 0 unless ($args->{ip});
    
    for (my $i=0; $i < @{$self->{gateways}}; $i++) {
	# if one of the gatway interfaces matches our ip
	if ( grep { $self->{interfaces}->[$_]->{ip} eq $args->{ip} } @{ $self->{gateways}->[$i]->{interfaces} } ) {
	    return "0 but true" if $i == 0;
	    return $i;
	}
    }
    return 0;
}

=pod

=item verify_args($hashref)

internal only

=cut

sub verify_args{
    my $args = shift;

#    print "got: " . join(',',keys(%$args)) . "\n";
    if (exists $args->{ip} and $args->{ip} ) {
	return unless $args->{ip} =~ m!^\d+\.\d+\.\d+\.\d+!;
    }
	
    if ( exists $args->{mask} and $args->{mask} ne "") {
	    return unless $args->{mask} =~ m#^(?:\d+|\d+\.\d+\.\d+\.\d+)$#;
	    $args->{mask} = _mask2bits($args->{mask});
    }

    if (exists $args->{mac}  and $args->{mac}){
	    return unless $args->{mac} =~ m!^(?:[0-9A-F]{2}:){5}[0-9A-F]{2}!;
    }
    
    return $args;
}

=pod

=item verify_structure

internal only.

=cut

sub verify_structure {
    my $self = shift;

    # make sure interfaces are logical
    my $i=0;
    foreach my $int ( @{ $self->{interfaces} } ) {
	if (exists $int->{subnet}) {
	    unless (grep {$_ == $i} @{$self->{subnets}->[$int->{subnet}]->{interfaces} } ) {
		warn ("interface $i has subnet " . $int->{subnet} . " but subnet " . $int->{subnet} . " only has nterfaces [ " . join(', ',@{$self->{subnets}->[$int->{subnet}]->{interfaces} } ) . " ]\n");
	    }
	}
	$i++;
    }

    # make sure subnets are logical
    $i=0;
    foreach my $net ( @{ $self->{subnets} } ) {
	if (exists $net->{interfaces}) {
	    foreach my $int (@{ $net->{interfaces} } ) {
		unless ($self->{interfaces}->[$int]->{subnet} eq $i) {
		    warn ("subnet $i has interface $int but interface $i has subnet " . $self->{interfaces}->[$int]->{subnet} . "\n" );
		}
	    }
	}
	$i++;
    }
}

sub _mask2bits {
    my $mask = shift;

    # if the mask is like 255.255.255.0, make it into 24
    if ($mask =~ m!^\d+\.\d+\.\d+\.\d+!) {
	my $mask_bits=unpack("B32", pack("C4", split(/\./, $mask)));
	$mask=length( (split(/0/,$mask_bits,2))[0] );	
    }

    return $mask;
}
sub _bits2mask {
    my $mask = shift;

    # if the mask is like 24 make it into 255.255.255.0
    if ($mask =~ m/^\d+$/) {
	$mask = pack('B32', 1 x $mask . 0 x (32-$mask));

	$mask= join (".", unpack("C4", $mask) );
    }

    return $mask;
}

sub _ip2int {
    my $ip = shift;

    if ($ip =~ m!^\d+\.\d+\.\d+\.\d+!) {
	$ip=unpack("N", pack("C4", split(/\./, $ip)));
    }

    return $ip;
}


=pod

=item print_register

prints the formated register to STDOUT

=cut

sub print_register {
    my $self = shift;

    require Data::Dumper;
    print Data::Dumper->Dump([$self], [qw(self)]);
}
sub dump_us {
    my $self = shift;
     
    require Data::Dumper;
    print Data::Dumper->Dump([$self], [qw(self)]);
}

    
=pod

=item read_register ([$filename])

tries to read the register from a file.
if $filename is not give., tries to use what was set at creation
of this object.

=cut

sub read_register {
    my $self = shift;
    my $file;
    
    if (@_) {
	$file = shift;
    } elsif ( $self->file ) {
	$file = $self->file;
    } else {
	return undef;
    }

    require Storable;

    $self = Storable::retrieve($file);
    $self->{restored} = time;
    $self->file($file);

    return $self;
}

=pod

=item write_register ([$filename])

stores the register in $filename.
if $filename is not given, tries to use what was set at creation
of this object.

=cut

sub write_register {
    my $self = shift;
    my $file;

    if (@_) {
	$file = shift;
    } elsif ( $self->file ) {
	$file = $self->file;
    } else {
	return undef;
    } 

    require Storable;
    Storable::nstore($self, $file);
}

=pod

=item file ([ $filename ])

get/set the file to store data in

=cut

sub file {
    my $self = shift;
    $self->{'file'} = shift if (@_) ;
    return $self->{'file'};
}

=pod

=item autosave

get/set auto save.  pass this a "1" to turn on, a "0" to turn off.
Autosave means that we will try to save the register to our "file" before
we exit.

=cut

sub autosave {
    my $self = shift;
    $self->{'autosave'} = shift if (@_) ;
    return $self->{'autosave'};
}

=pod

=item test_acl ($ip_to_test)

$ip_to_test is the ip addresse you want to check against the acl list set using add_acl.
it should be in the form "a.b.c.d".
we return as soon as we find a matching rule that says allow or deny.
we return 1 to accept it, 0 to deny it.

=cut

#sub test_acl {
#    my ($self, $ip) = @_;
#
#    # this is just for kicks... lets up pass in a host obj
#    if (ref($ip) =~ m/^NetworkInfo::Discovery::Host/) {
#	$ip = $ip->ipaddress;
#    }
#    # check it against each acl and try to buffer calls to the matcher
#    my $lastAorD = "allow";
#    my @buffered_ips;
#
#    print "checking acls against $ip\n";
#    foreach (@{$self->{'_acls'}}) {
#	print "____:$_\n";
#	
#	m!^(allow|deny):(.*)!;
#
#	# if this is the same type that we saw last time, 
#	if ($lastAorD eq $1) {
#	    # save it and keep going
#	    push(@buffered_ips, $2);
#	    next;
#	}
#
#	# otherwise, this is a change so
#	# check what we have buffered
#	if (@buffered_ips) {
#	    #we are supposed to allow these...
#	    if ($lastAorD eq "allow") {
#		# return 1 to if we found an allow
#		print "calling return 1 if ($self->acl_match($ip, @buffered_ips))\n";
#		return 1 if ($self->acl_match($ip, @buffered_ips));
#
#	    #we are supposed to deny these...
#	    } else {
#		# return 0 to if we found a deny match
#		print "calling return 0 if ($self->acl_match($ip, @buffered_ips))\n";
#		return 0 if ($self->acl_match($ip, @buffered_ips));
#	    }
#	
#	    # we are done with the buffer, clen it out
#	    @buffered_ips=();
#	}
#
#
#	# save what we have now
#	push(@buffered_ips, $2);
#	# don't forget where we've been
#	$lastAorD = $1;
#
#	#thanks. may i have another?
#    }
#}

sub test_acl {
    my ($self, $ip) = @_;

#    print "checking acls against $ip\n";
    foreach (@{$self->{'_acls'}}) {
#	print "____:$_\n";
	m!^(allow|deny):(.*)!;

	#we are supposed to allow these...
	if ($1 eq "allow") {
	    # return 1 to if we found an allow
#	    print "calling return 1 if ($self->acl_match($ip, $2))\n";
	    return 1 if ($self->acl_match($ip, $2));

	#we are supposed to deny these...
	} else {
	    # return 0 to if we found a deny match
#	    print "calling return 0 if ($self->acl_match($ip, $2))\n";
	    return 0 if ($self->acl_match($ip, $2));
	}
    }
    #if we passed all of the above, we must not have an acl for this ip
    return 1;
}

=pod

=item acl_match ($ip_to_test, @against_these)

ip is like 172.16.20.4
the acls are either in CIDR notation "172.16.4.12/25" or a single address
returns true if the ip matches the acl.
returns false otherwise

=cut

sub acl_match {
    my ($self, $ip, @others) = @_;

    # get our ip in machine representation
    my $mainIP = unpack("N", pack("C4", split(/\./, $ip)));

    # for all the acls
    foreach (@others) {
	# split off the CIDR mask if there is one
	m!^(\d+\.\d+\.\d+\.\d+)(?:/(\d+))?!g;

	# 0.0.0.0/0 matches all
	if (($1 eq "0.0.0.0") and ($2 eq 0)) {
	    return 1;
	}

	# what is left over from the mask
	my $bits = 32 - ($2 || 32);

	# put this acl into machine representation
	my $otherIP = unpack("N", pack("C4", split(/\./, $1)));

	# keep only the important parts of the ip address/mask pair
	my $maskedIP = $otherIP >> $bits;

	# if there was a CIDR mask
	if ($bits) {
	    # return true if this one matches
#print "bits->$bits, maskedIP->$maskedIP, mainIP->" . ($mainIP>>$bits) . "\n";
	    return 1 if  ($maskedIP == ($mainIP >> $bits));

	} else {
	    # return true if this one matches (without mask)
print "bits->$bits, maskedIP->$maskedIP, mainIP->$mainIP\n";
	    return 1 if ($maskedIP == $mainIP);
	}
    } 

    # return false if we didn't match any acl
    return 0;
}

=pod

=item add_acl ("(allow|deny)", @acls)

this function sets a list of hosts/networks that we are allowed to discover.
note that order matters.
the first argument is set to allow or deny.  the meaning should be clear.
@acls is a list of ip addresses in the form:
    a.b.c.d/mask	# to acl a whole network
    or 
    a.b.c.d		# to acl a host

the following calls will allow us to discover stuff on only the network 172.16.1.0/24:
    $d->add_acl("allow", "172.16.1.0/24");
    $d->add_acl("deny", "0.0.0.0/0");

the following calls will allow us to discover anything but stuff on network 172.16.1.0/24:
    $d->add_acl("deny", "172.16.1.0/24");
    $d->add_acl("allow", "0.0.0.0/0");

=cut

sub add_acl {
    my ($self,$AorD, @acls) = @_;

    # only accept this if we have valid allow or deny rules.
    return undef unless ($AorD =~ m/(allow|deny)/);

    foreach my $a (@acls) {
	# only accept this if we have addresses like "a.b.c.d" or "a.b.c.d/n"
	return undef unless($a =~ m!^\d+\.\d+\.\d+\.\d+(?:/\d+)?!);

	push (@{$self->{"_acls"}}, "$AorD:$a");
    }
    return 1;
}

=pod

=item clear_acl 

this function clears the acl list

=cut

sub clear_acl {
    my $self = shift;
    @{$self->{"_acls"}} = ();
}

=pod

=item guess_mask ($ip)

attempt to guess the mask based on the ip.
returns the guessed mask

=cut

sub guess_mask {
    my $self = shift;
    my $ip = shift;

    # see how many ones lead the ipaddress
    my $bits = _mask2bits($ip);
    my $mask = 0;
   
    if ($bits eq 0) {
	# class a address
	$mask = "255.0.0.0";
    } elsif ( $bits eq 1 ) {
	# class B address
	$mask = "255.255.0.0";
    } elsif ( $bits eq 2 ) {
	# class C address
	$mask = "255.255.255.0";
    }
    return $mask;
}
=pod

=item add_event ("string")

add an event to the log

=cut

sub add_event {
    my $self=shift;

    my $msg = time . " " . join(",",@_);
    
    push(@{$self->{events}}, $msg);
}

=pod

=item DESTROY

just tries to write_register if we have autosave turned on

=cut

sub DESTROY {
    my $self=shift;
    $self->write_register() if ($self->autosave);
}

=pod

=back

=cut

1;
