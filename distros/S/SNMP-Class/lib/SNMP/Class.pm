package SNMP::Class;

=head1 NAME

SNMP::Class - A convenience class around the NetSNMP perl modules. 

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

This module aims to enable snmp-related tasks to be carried out with the best possible ease and expressiveness while at the same time allowing advanced features like subclassing to be used without hassle.

	use SNMP::Class;
	
	#create a session to a managed device -- 
	#community will default to public, version will be autoselected from 2,1
	my $s = SNMP::Class->new({DestHost => 'myhost'});    
	
	#modus operandi #1
	#walk the entire table
	my $ifTable = $s->walk("ifTable");
	#-more compact- 
	my $ifTable = $s->ifTable;
	
	#get the ifDescr.3
	my $if_descr_3 = $ifTable->object("ifDescr")->instance("3");
	#more compact
	my $if_descr_3 = $ifTable->object(ifDescr).3;
	
	#iterate over interface descriptions -- method senses list context and returns array
	for my $descr ($ifTable->object"ifDescr")) { 
		print $descr->get_value,"\n";
	}
	
	#get the speed of the instance for which ifDescr is en0
	my $en0_speed = $ifTable->find("ifDescr","en0")->object("ifSpeed")->get_value;  
	#
	#modus operandi #2 - list context
	while($s->ifDescr) {
		print $_->get_value;
	}
	
   
=head1 METHODS

=cut

use warnings;
use strict;
use Carp;
use Data::Dumper;
use SNMP;
use SNMP::Class::ResultSet;
use SNMP::Class::Varbind;
use SNMP::Class::OID;
use SNMP::Class::Utils;
use Class::Std;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({
	level=>$DEBUG,
	layout => "%M:%L %m%n",
});
my $logger = get_logger();

####&SNMP::loadModules('ALL');


my (%session,%name,%version,%community,%deactivate_bulkwalks) : ATTRS;


=head2 new({DestHost=>$desthost,Community=>$community,Version=>$version,DestPort=>$port})

This method creates a new session with a managed device. Argument must be a hash reference (see L<Class::Std> for that requirement). The members of the hash reference are the same with the arguments of the new method of the L<SNMP> module. If Version is not present, the library will try to probe by querying sysName.0 from the device using version 2 and then version 1, whichever succeeds first. This method croaks if a session cannot be created. If the managed node cannot return the sysName.0 object, the method will also croak. Most people will want to use the method as follows and let the module figure out the rest.
 
 my $session = SNMP::Class->new({DestHost=>'myhost.mydomain'}); 
 

=cut
 

sub BUILD {
	my ($self, $obj_ID, $arg_ref) = @_;

	croak "You must supply a DestHost in the arguments to new." unless defined($arg_ref->{DestHost});

	my $session;
	my @versions = ( $arg_ref->{Version} );



	#if the user did not specify a version, then we will try one after the other
	if ( !defined($arg_ref->{Version})) {
		@versions = ( "2" , "1" );
	}	

	#if the user has not supplied a community, why not try a default one?
	if (!defined($arg_ref->{Community})) {
		$arg_ref->{Community} = "public";
	}	

	if (!defined($arg_ref->{RemotePort})) {
		$logger->debug("setting port to default (161)");
		$arg_ref->{RemotePort} = 161;
	}

	$logger->info("Host is $arg_ref->{DestHost}, community is $arg_ref->{Community}");
	
	for my $version (@versions) {
		$logger->debug("trying version $version");
		
		#set $arg_ref->{Version} to $version
		$arg_ref->{Version}=$version;

		#construct a string for debug purposes and log it
		my $debug_str = join(",",map( "$_=>$arg_ref->{$_}", (keys %{$arg_ref})));
		$logger->debug("doing SNMP::Session->new($debug_str)");

		#construct the arguments we will be passing to SNMP::Session->new
		my @argument_array = map { $_ => $arg_ref->{$_}  } (keys %{$arg_ref});
		$session{$obj_ID} = SNMP::Session->new(@argument_array);
		if(!$session{$obj_ID}) {
			$logger->debug("null session. Next.");
		}
		my $name;
		if(eval { $name = $self->get_oid('sysName.0') }) {
			$logger->debug("get_oID(sysName.0) success. Name = $name");
			#if we got to this point, then this means that
			#we were able to retrieve the sysname variable from the session
			#session is probably good
			$logger->debug("Session should be ok.");
			$name{$obj_ID} = $name;	
			$version{$obj_ID} = $version;
			$community{$obj_ID} = $arg_ref->{Community};
			return 1;
		} else { 
			$logger->debug("getOID(sysName,0) failed. Error is $@");
			$logger->debug("Going to next SNMP version");
			next;
		}
		
	}
	#if we got here, the session could not be created
	$logger->debug("session could not be created after all");
	croak "cannot initiate object for $arg_ref->{DestHost},$arg_ref->{Community}";

}

=head2 deactivate_bulkwalks

If called, this method will permanently deactivate usage of bulkwalk for the session. Mostly useful for broken agents, some buggy versions of Net-SNMP etc. 

=cut

sub deactivate_bulkwalks {
	my $self = shift(@_) or croak "deactivate_bulkwalks called outside of an object context";
	my $id = ident $self;
	$deactivate_bulkwalks{$id} = 1 ;
	return;	
}


sub get_oid {
	
	my $self = shift(@_) or croak "getvar called outside of an object context";
	my $oid = shift(@_) or croak "first arg to getvar (oid), missing";
	####my $instance = shift(@_); #instance could be 0, so we do not check
	####if (!defined($instance)) { confess "second arg to getvar (instance), missing" }
	my $id = ident $self;

	####my $vars = new SNMP::VarList([$oid,$instance]) or confess "Internal Error: Could not create a new SNMP::VarList for $oid.$instance";

	my @a = $session{$id}->get($oid);

	#print Dumper(@a);

	confess $session{$id}->{ErrorStr} if ($session{$id}->{ErrorNum} != 0);
	croak "Got error when tried to ask $session{$id}->{DestHost} for $oid" if ($a[0] eq "NOSUCHINSTANCE");

	return $a[0];
}

=head2 getSysName

Returns the sysname of the machine corresponding to the session

=cut

sub get_name {
	my $self = shift(@_) or confess "incorrect call";
	my $id = ident $self;
	return $name{$id};
}


=head2 get_version

Returns the SNMP version of the session object.

=cut

#This method returns the SNMP version of the object
sub get_version {
	my $self = shift(@_);
	confess "sub getVersion called outside of an object context" unless (ref $self);
	my $id = ident $self;
	return $version{$id};
}


=head2 walk

A generalized walk method. Takes 1 argument, which is the object to walk. Depending on whether the session object is version 1 or 2, it will respectively try to use either SNMP GETNEXT's or GETBULK. On all cases, an L<SNMP::Class::ResultSet> is returned. If something goes wrong, the method will croak.

One should probably also take a look at L<SNMP::Class::ResultSet> to see what's possible.

=cut

#Does snmpwalk on the session object. Depending on the version, it will try to either do a
#normal snmpwalk, or, in the case of SNMPv2c, bulkwalk.
sub walk {
	my $self = shift(@_) or confess "sub walk called outside of an object context";
	my $id = ident $self;
	my $oid_name = shift(@_) or confess "First argument missing in call to get_data";
	
	if ($deactivate_bulkwalks{$id}) { 
		return $self->_walk($oid_name);
	}

	if ($self->get_version > 1) {
		return $self->bulk($oid_name);
	} else {
		return $self->_walk($oid_name);
	}
}

#sub add_instance_to_bag {
#	my $self = shift(@_) or confess "Incorrect call to add_instance_to_bag";
#	my $oid = shift(@_) || confess "Missing 1st argument -- oid";
#	my $bag = shift(@_) || confess "Missing 2nd argument -- bag";
#	
#	my @result;
#	if ( eval { $self->get_oid($oid) } ) {
#		$bag->push(SNMP::Class::Varbind->new(
#}

sub get_varbind :PRIVATE() {
	my $self = shift(@_) or confess "Incorrect call to get_varbind";
	my $id = ident $self;
	my $vb = shift(@_);
	my $bag = shift(@_);

	my $varbind = $vb->generate_varbind;
	my @a;
	eval { @a = $session{$id}->get($varbind) }; 
	if($@) {
		confess "Could not make the initial GET request for ",$vb->to_string," because of error: ",$@;
	}
	if ($session{$id}->{ErrorNum} != 0) {
		confess "Could not make the initial GET request  because of error: ".$session{$id}->{ErrorStr};
		
	}
	if (($a[0] eq 'NOSUCHINSTANCE')||($a[0] eq 'NOSUCHOBJECT')) {
		DEBUG "Skipping initial object ".$vb->to_string;
		return;
	}
	my $vb2 = SNMP::Class::Varbind->new(varbind=>$varbind);
	DEBUG "Pushing initial varbind ".$vb2->dump." to the resultset";
	$bag->push( $vb2 );
	DEBUG $bag->dump;
}
	


sub bulk:RESTRICTED() {
	my $self = shift(@_) or confess "Incorrect call to bulk, self argument missing";
	my $id = ident $self;
	my $oid = shift(@_) or confess "First argument missing in call to bulk";	
	
	$oid = SNMP::Class::OID->new($oid);
	$logger->debug("Object to bulkwalk is ".$oid->to_string);

	#create the varbind
	#was: my $vb = SNMP::Class::Varbind->new($oid) or confess "cannot create new varbind for $oid";
	my $vb = SNMP::Class::Varbind->new(oid=>$oid);
	croak "vb is not an SNMP::Class::Varbind" unless (ref $vb eq 'SNMP::Class::Varbind');

	#create the bag
	my $ret = SNMP::Class::ResultSet->new;

	#make the initial GET request and put it in the bag
	$self->get_varbind($vb,$ret);

	#the first argument is definitely 0, we don't want to just emulate an snmpgetnext call
	#the second argument is tricky. Setting it too high (example: 100000) tends to berzerk some snmp agents, including netsnmp.
	#setting it too low will degrade performance in large datasets since the client will need to generate more traffic
	#So, let's set it to some reasonable value, say 10.
	#we definitely should consider giving the user some knob to turn.
	#After all, he probably will have a good sense about how big the is walk he is doing.
	
	my ($temp) = $session{$id}->bulkwalk(0,10,$vb->generate_varbind); #magic number 10 for the time being
	#make sure nothing went wrong
	confess $session{$id}->{ErrorStr} if ($session{$id}->{ErrorNum} != 0);

	for my $object (@{$temp}) {
		my $vb = SNMP::Class::Varbind->new(varbind=>$object);		
		DEBUG $vb->dump;
		#put it in the bag
		$ret->push($vb);
	}					
	return $ret;
}


#does an snmpwalk on the session object
sub _walk:RESTRICTED() {
	my $self = shift(@_) or confess "Incorrect call to _walk, self argument missing";
	my $id = ident $self;
	my $oid_str = shift(@_) or confess "First argument missing in call to get_data";
	my $oid = SNMP::Class::OID->new($oid_str); #that's the original requested oid. We won't change that object.
	
	DEBUG "Object to walk is ".$oid->to_string;

	#we will store the previous-loop-iteration oid here to make sure we didn't enter some loop
	#we init it to something that can't be equal to anything
	my $previous = SNMP::Class::OID->new("0.0");##let's just assume that no oid can ever be 0.0

	#create the varbind
	my $vb = SNMP::Class::Varbind->new(oid=>$oid);
	croak "returned vb is not an SNMP::Class::Varbind" unless (ref $vb eq 'SNMP::Class::Varbind');

	#create the bag
	my $ret = SNMP::Class::ResultSet->new();

	
	#make the initial GET request and put it in the bag
	$self->get_varbind($vb,$ret);

	LOOP: while(1) {
		
		my $varbind = $vb->generate_varbind;

		#call an SNMP GETNEXT operation
		#@my $value = $session{$id}->getnext($vb->get_varbind);
		my $value = $session{$id}->getnext($varbind);
		#make sure nothing went wrong
		confess $session{$id}->{ErrorStr} if ($session{$id}->{ErrorNum} != 0);

		#now sync the varbind back to the vb
		#$vb = SNMP::Class::Varbind->new_from_varbind($varbind);
		$vb = SNMP::Class::Varbind->new(varbind=>$varbind);

		DEBUG $vb->dump;
		
		#handle some special types
		#For example, a type of ENDOFMIBVIEW means we should stop
		if($vb->type eq 'ENDOFMIBVIEW') {
			DEBUG "We should stop because an end of MIB View was encountered";
			last LOOP;
		}

		#make sure that we got a different oid than in the previous iteration
		if($previous->oid_is_equal( $vb )) { 
			confess "OID not increasing at ".$vb->to_string." (".$vb->numeric.")\n";
		}

		#make sure we are still under the original $oid -- if not we are finished
		if(!$oid->contains($vb)) {
			$logger->debug($oid->numeric." does not contain ".$vb->numeric." ... we should stop");
			last LOOP;
		}

		$ret->push($vb);

		#Keep a copy for the next iteration. Remember that only the reference is copied. 
		$previous = $vb;

		#we need to make sure that next iteration we won't use the same $vb
		$vb = SNMP::Class::Varbind->new(oid=>$vb);

	};
	return $ret;
}	

#=head2 AUTOMETHOD
#
#Using a method call that coincides with an SNMP OBJECT-TYPE name is equivalent to issuing a walk with that name as argument. This is provided as a shortcut which can result to more easy to read programs. 
#Also, if such a method is used in a list context, it won't return an SNMP::ResultSet object, but rather a list with the ResultSet's contents. This is pretty convenient for iterating through SNMP results using few lines of code.
#
#=cut
#
#sub AUTOMETHOD {
#	my $self = shift(@_) or croak("Incorrect call to AUTOMETHOD");
#	my $ident = shift(@_) or croak("Second argument to AUTOMETHOD missing");
#	my $subname = $_;   # Requested subroutine name is passed via $_;
#	$logger->debug("AUTOMETHOD called as $subname");  
#	
#	if (eval { my $dummy = SNMP::Class::Utils::get_attr($subname,"objectID") }) {
#		$logger->debug("$subname seems like a valid OID ");
#	}
#	else {
#		$logger->debug("$subname doesn't seem like a valid OID. Returning...");
#		return;
#	}
#	
#	#we'll just have to create this little closure and return it to the Class::Std module
#	#remember: this closure will run in the place of the method that was called by the invoker
#	return sub {
#		if(wantarray) {
#			$logger->debug("$subname called in list context");
#			return @{$self->walk($subname)->varbinds};
#		}
#		return $self->walk($subname);
#	}
#
#}






=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SNMP::Class>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::Class

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP::Class>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP::Class>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SNMP::Class>

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP::Class>

=back

=head1 ACKNOWLEDGEMENTS

This module obviously needs the perl libraries from the excellent Net-SNMP package. Many thanks go to the people that make that package available.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class
