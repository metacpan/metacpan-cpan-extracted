package SNMP::Class::Varbind;

our $VERSION = '0.13';

use warnings;
use strict;
use SNMP;
use Carp qw(cluck carp croak confess);
use SNMP::Class::OID;
use Data::Dumper;
use Log::Log4perl qw(:easy);

use SNMP::Class::Varbind::IpAddress;
use SNMP::Class::Varbind::SysUpTime;
use SNMP::Class::Varbind::IpForwarding;

BEGIN {
	eval { 
		require Time::HiRes;
		import Time::HiRes qw(time);
	};
	warn "Time::HiRes not installed -- you only get the low granularity built in time function" if ($@);
}

use overload 
	'""' => \&value,
	fallback => 1
;

use base qw(SNMP::Class::OID);

my %callback=();


=head2 new(oid=>$oid,type=>$type,value=>$value)

Constructor. $oid can be either a string or an L<SNMP::Class::OID>. Normally this method should almost never be used, as the user rarely has to construct this kind of objects by hand. 

=cut
	
sub new {
	my $class = shift(@_) or croak "Incorrect call to new";
	my $self;
	
	my %arg_h = (@_);
	
	if(defined($arg_h{varbind})) {
		my $varbind = $arg_h{varbind};
		croak "new was called with a varbind that was not an SNMP::Varbind." unless (eval { $varbind->isa("SNMP::Varbind") } );
		my $object = SNMP::Class::OID->new($varbind->[0]);
		my $instance = ((!exists($varbind->[1]))||($varbind->[1] eq ''))? SNMP::Class::OID->new('0.0') : SNMP::Class::OID->new($varbind->[1]);
		$self = $object . $instance;#make sure that marginal cases produce correct overloaded '+' result
		croak "Internal error. Self is not an SNMP::Class::OID object!" unless ($self->isa("SNMP::Class::OID"));
		$self->{type} = $varbind->[3];
		$self->{raw_value} = $varbind->[2];
		#@#$self->{value} = $self->construct_value;

	}
	else {
		croak "Cannot create a new varbind without an oid" unless defined($arg_h{oid});
		
		if (eval { $arg_h{oid}->isa("SNMP::Class::OID") }) {
			#we just keep it intact and continue
			$self = $arg_h{oid};
		} 
		else {
			#let's assume that argument was a plain string
				$self = $class->SUPER::new($arg_h{oid});
		}
		for my $field (qw(type value raw_value)) {
			if(defined($arg_h{$field})) {
				$self->{$field} = $arg_h{$field};
			}
		}
	}
	
	#default fallback: value coincides with raw_value
	#this may be freely modified later
	if(defined($self->{raw_value})) {
		$self->{value} = $self->{raw_value};
	}
	
	#we now have an almost complete object. Let's see if there is any more functionality inside a callback
	if(defined($self->{raw_value})&&$self->has_label&&defined($callback{label}->{$self->get_label})) {
		DEBUG "There is a special callback for label ".$self->get_label;
		bless $self,$callback{label}->{$self->get_label};
		if($self->can("initialize_callback_object")) {
			DEBUG "Calling initializing method for ".$callback{label}->{$self->get_label};
			$self->initialize_callback_object;
		}

	}
	elsif(defined($self->{raw_value})&&$self->has_syntax&&defined($callback{syntax}->{$self->get_syntax})) {
		DEBUG "There is a special callback for syntax ".$self->get_syntax;
		bless $self,$callback{syntax}->{$self->get_syntax};
		if($self->can("initialize_callback_object")) {
			DEBUG "Calling initializing method for ".$callback{syntax}->{$self->get_syntax};
			$self->initialize_callback_object;
		}
	}
	else {
		bless $self,$class;
	}

	return $self;
}

#user should not have to know about this method. Used internally. 

#sub new_from_varbind {
#	my $class = shift(@_) or croak "Incorrect call to new_from_varbind";
#	my $varbind = shift(@_) or croak "2nd argument (varbind) missing from call to new_from_varbind";
#	
#
#	#check that we were given a correct type of argument
#	if(eval { $varbind->isa("SNMP::Varbind") } ) {
#			#$self->{varbind} = $varbind;
#	}
#	else {
#		croak "new_from_varbind was called with an argument that was not an SNMP::Varbind.";
#	}
#	
#
#	$self->{object} = SNMP::Class::OID->new($varbind->[0]);
#	$self->{instance} = ($varbind->[1] eq '')? SNMP::Class::OID->new('0.0') : SNMP::Class::OID->new($varbind->[1]);
#	$self->{oid} = $self->object + $self->instance;#make sure that marginal cases produce correct overloaded '+' result
#	$self->{type} = $varbind->[3];
#	$self->{raw_value} = $varbind->[2];
#	$self->{value} = $self->construct_value;
#
#	return $self;
#	#after completion, the SNMP::Varbind is thrown away. Better this way.
#}


#I am lazy + I don't want to repeat the same code over and over
#So, I construct these 6 methods by using this nifty trick
for my $item (qw(object instance type raw_value value)) {
	no strict 'refs';#only temporarily 
	*{$item} = sub { return $_[0]->{$item} };
	use strict;
}

#this the opposite from new_from_varbind. You get the SNMP::Varbind. Warning, you only get the correct oid, but you shouldn't get types,values,etc.s 
sub generate_varbind {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	#@#return SNMP::Varbind->new([$self->object->numeric]) or croak "Cannot invoke SNMP::Varbind::new method with ".$_[0]->numeric." \n";	
	return SNMP::Varbind->new([$self->numeric]) or croak "Cannot invoke SNMP::Varbind::new method with argument".$self->numeric." \n";	
}

#return the varbind
#sub get_varbind {
#	my $ref_self = \ shift(@_) or croak "Incorrect call to get_varbind";
#	return $$ref_self->{varbind};
#}

#returns the object part of the varbind. (example: ifName or .1.2.3)
#The type of the object returned is SNMP::Class::OID
#sub get_object {
#	my $ref_self = \ shift(@_) or croak "Incorrect call to get_object";
#	return new SNMP::Class::OID($$ref_self->get_varbind->[0]);
#}

#returns the instance part of the varbind. (example: 10.10.10.10)
#If the instance is '', it will return undef (surprise,surprise!)
#sub get_instance {
#	my $ref_self = \ shift(@_) or croak "Incorrect call to get_instance";
#	if ($$ref_self->get_varbind->[1] eq '') {
#		#this is an ugly hack....
#		#the SNMP library will occasionally return varbinds with a '' instance, which is, well, not good
#		#if we find the instance empty, we'll just stick the zeroDotzero instance and return it instead of undef
#		#this happens with e.g. the sysUpTimeInstance object
#		return SNMP::Class::OID->new('0.0');
#	}
#	return SNMP::Class::OID->new($$ref_self->get_varbind->[1]);
#}

#returns a string numeric representation of the instance
#sub instance_numeric {
#	my $self = shift(@_);
#	croak "self appears to be undefined" unless ref $self;
#	#if(!$$ref_self->get_instance) {
#	#	return '';
#	#}
#	return $self->instance->numeric;
#}

#returns the full oid of this varbind. 
#type returned is SNMP::Class::OID
#also handles correctly the case where the instance is undef
#sub get_oid {
#	my $ref_self = \ shift(@_) or croak "Incorrect call to get_oid";
#	if(!$$ref_self->get_instance) {
#		return $$ref_self->get_object;
#	} 
#	return $$ref_self->get_object + $$ref_self->get_instance;
#}
	
#sub get_value {
#	my $ref_self = \ shift(@_);
#	#my $self = shift(@_) or croak "Incorrect call to get_value";
#	return SNMP::Class::Value->new($$ref_self->get_varbind->[2]);
#}

=head2 dump

Use this method with no arguments to get a human readable string representation of the object. Example:
"ifName.3 eth0 OCTET-STR"

=cut

sub dump {
	my $self = shift(@_);
	return $self->to_string." ".$self->value." ".$self->type;
}

#this is a class method. Other modules wishing to register themselves as varbind handlers must use it. 
sub register_handler {
	my $type_of_callback = shift(@_);#type can be object,syntax
	my $identifier = shift(@_);
	my $callback = shift(@_);
	$callback{$type_of_callback}->{$identifier} = $callback;
}
	
	

sub construct_value {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;

	#if it is an object id, then find the label
	if ($self->type eq 'OBJECTID') {
		###$logger->debug("This is an objectid...I will try to translate it to a label");
		return SNMP::Class::Utils::label_of($self->get_value);
	}

	#if it is an enum, return the appr. item
	my $enum;
	if($enum = SNMP::Class::Utils::enums_of($self->object->to_string)) {
		#we will make sure that the key actually exists in the enum
		if(defined($enum->{$self->raw_value})) {
			return $enum->{$self->raw_value};	
		}
		WARN "WARNING: There is no corresponding enum for value=".$self->raw_value." in ".$self->object->to_string;
		return "unknown";
	}

	my $tc = SNMP::Class::Utils::textual_convention_of($self->object->to_string);
	if (defined($tc)) {
		if ($tc eq 'PhysAddress') {
			return SNMP::Class::Value::MacAddress->new($self->raw_value);
		}
	}

	#fallback
	return SNMP::Class::Value->new($self->raw_value);
}

#sub get_type {
#	my $ref_self = \ shift(@_) or croak "Incorrect call to get_type";
#	return $$ref_self->get_varbind->[3];
#}

#@#sub normalize {
#@#	my $ref_self = \ shift(@_) or croak "Incorrect call to normalize";
#@#	$$ref_self->get_varbind->[0] = $$ref_self->get_oid->numeric;
#@#}

	

=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class-varbind at rt.cpan.org>, or through the web interface at
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

=head1 COPYRIGHT & LICENSE

Copyright 2007 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class::Varbind
