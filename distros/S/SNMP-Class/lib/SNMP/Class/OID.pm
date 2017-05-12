package SNMP::Class::OID;

use NetSNMP::OID;
use Carp;
use strict;
use warnings;
use Clone;
use Data::Dumper;


=head1 NAME

SNMP::Class::OID - Represents an SNMP Object-ID. 

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

 use SNMP::Class::OID;

 #create an object
 my $oid = SNMP::Class::OID->new('.1.3.6.1.2.1.1.5.0');
 #-or-
 my $oid = SNMP::Class::OID->new('sysName.0');
 
 #overloaded scalar representation
 print $oid; # evaluates to sysName.0

 #representations
 $oid->to_string; #string representation -- sysName.0
 $oid->numeric; #numeric representation -- .1.3.6.1.2.1.1.5.0
 $oid->to_array; #(1,3,6,1,2,1,1,5,0)
 $oid->[1]; #can be used as array reference -- returns 5
 $oid->length; #9

 #slicing
 my $oid2 = $oid->slice(3,6); #new object : .6.1.2.1
 my $oid2 = $oid->slice(3..6); #same

 #equality
 $oid1 == $oid2; # yields true if they are the same
 $oid1 == '.1.3.6.1.2.1.1.5.0' #also acceptable, second operand will be converted 

 #hierarchy
 $oid2 = SNMP::Class::OID->new('.1.3.6.1.2.1.1');
 $oid2->contains($oid); #true; Because .1.3.6.1.2.1.1.5.0 is under .1.3.6.1.2.1.1
 $oid2->contains('.1.3.6.1.2.1.1.5.0'); #also true, string autoconverted to SNMP::Class::OID

 #concatenation
 SNMP::Class::OID(".1.3.6") . SNMP::Class::OID("1.2.1"); #returns .1.3.6.1.2.1
 SNMP::Class::OID(".1.3.6") . '.1.2.1'; #also acceptable, returns the same

=head1 METHODS

=head2 overloaded operators

The following operators are overloaded:

=over 4

=item * <=> 

Two SNMP::Class::OID objects can be compared using the == operator. The result is what everybody expects.


=item * '+' 

Two SNMP::Class::OID objects can be concatenated using the + operator. Note that order actually is important. Example: .1.3.6 + .1.4.1 will yield .1.3.6.1.4.1.


=item * @{} 

If an SNMP::Class::OID object is used as an array reference, it will act as an array containing the individual numbers of the OID. Example:


 my $oid = SNMP::Class::OID->new("1.3.6.1.4.1");
 print $oid->[1]; #will print 3 

=back

=cut


use overload
	'<=>' => \&oid_compare,
	'cmp' => \&oid_compare,
	'.' => \&add,
	'@{}' => \&to_arrayref,
	fallback => 1,
;

=head2 new

new can be used to construct a new object-id. Takes one string as an argument, like ".1.3.6.4.1". Returns an SNMP::Class::OID object, or confesses if that is not possible. If the 1rst argument is a L<NetSNMP::OID> instead of a string, the constructor will notice and take appropriate action to return a valid object.

=cut
 
sub new {
	my $class = shift(@_) or croak "Incorrect call to new";
	my $oid_str = shift(@_);
	if ( eval { $oid_str->isa("NetSNMP::OID") } ) {
		return bless { oid => $oid_str }, $class; #it was not a str after all :)
	}
	if($oid_str eq "0") {
		$oid_str = ".0";
	}
#	my @arr;
#	my $num_str = SNMP::Class::Utils::oid_of($oid_str);
#	while( $num_str =~ /(\d+)/g ){
#		unshift @arr,($1);
#	}
#	print STDERR "Array is ",Dumper(@arr),"\n";
	
	my $self = {};
	$self->{oid} = NetSNMP::OID->new($oid_str) or confess "Cannot create a new NetSNMP::OID object for $oid_str";
		
	return bless $self,$class;
}

#this constructor must DIE. Soon.
#sub new_from_netsnmpoid {
#	my $class = shift(@_) or croak "Incorrect call to new_from_netsnmpoid";
#	my $self = {};
#	$self->{oid} = shift(@_) or croak "Missing argument from new_from_netsnmpoid";
#	return bless $self,$class;
#}

=head2 get_syntax 

Returns, if it exists, the SNMP SYNTAX clause for the oid or undef if it doesn't. 

=cut

sub get_syntax {
	my $self = shift(@_);
	return SNMP::Class::Utils::syntax_of($self->numeric);
}

=head2 has_syntax 

Tells if we know the syntax for the object. Convenience shortcut instead of testing get_syntax for definedness.

=cut

sub has_syntax {
	return defined($_[0]->get_syntax);
}		

=head2 get_label 

Returns the label for this oid if it exists or undef if it doesn't.

=cut

sub get_label {
	my $self = shift(@_);
	return SNMP::Class::Utils::label_of($self->numeric);
}

=head2 get_label_oid

Returns an SNMP::Class::OID object corresponding to the appropriate object-id. For example, for an oid like ifDescr.3, we would get a new SNMP::Class::OID equivalent to ifDescr. May return undef, as the label may not be found in the loaded MIBs.

=cut

sub get_label_oid {
	my $self = shift(@_);
	my $label = $self->get_label;
	return unless defined($label);
	return __PACKAGE__->new($label);
}


=head2 has_label

Tells if there is a label for the object. Convenience shortcut instead of testing get_label_oid for definedness.

=cut

sub has_label {
	return defined($_[0]->get_label);
}

=head2 get_instance_oid

Returns an SNMP::Class::OID object corresponding to the instance of this oid. For example, for an oid like ifDescr.3, we would get a new SNMP::Class::OID equivalent to .3. May return undef, as there may be no instance (for example a non-leaf oid) or it may not be possible to know it. 

=cut

sub get_instance_oid {
	my $self = shift(@_);
	my $label_oid = $self->get_label_oid;
	return unless defined($label_oid);
	my $start = $label_oid->length+1;
	my $end = $self->length;
	return if($start>$end);
	return $self->slice($start,$end);
}

=head2 has_instance

Tells if there is an instance for the object. Convenience shortcut instead of testing get_instance_oid for definedness.

=cut

sub has_instance {
	return defined($_[0]->get_instance_oid);
}
	
	

=head2 slice

Slice can extract a portion of an object-id and return it as a new SNMP::Class::OID object. Example:
 
 my $oid = SNMP::Class::OID->new("1.3.6.1.4.1");
 my $suboid = $oid->slice(1..3); #will return .1.3.6
 my $suboid = $oid->slice(1,2,3); #completely equivalent
 my $suboid = $oid->slice(1,3); #also completely equivalent

To extract a single number from the object-id you can simply say for example:

 my $suboid = $oid->slice(2);

=cut

sub slice {
	my $self = shift(@_);
	my $start = shift(@_);
	my $end = pop(@_) || $start;
	if($end<$start) {
		croak "Cannot have the end $end smaller that the $start in the range you requested";
	}
	$start-=1;
	$end-=1;
	return __PACKAGE__->new('.'.join('.',($self->to_array)[$start..$end]));
}
	

sub oid {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;	
	return $self->{oid};
}

=head2 to_array

Returns an array representation of the object OID.

=cut

sub to_array {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return $self->oid->to_array;
}

sub to_arrayref {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	my @array = $self->to_array;
	return \@array;
}

=head2 length

Returns the length (in items) of the object OID.

=cut

sub length {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return $self->oid->length;
}

=head2 is_null 

returns true if the object represents the null object identifier. 
SNMPv2-SMI defines a null object id to be { 0 0 } or 0.0 or zeroDotZero.
Let's just hope that we won't encounter 0.0 instances any time soon. 

=cut

sub is_null {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return 1 if ($self->numeric eq ".0.0");#this should be fairly fast
	return;
}
	
	
=head2 numeric

Returns a numeric representation of the object. 

=cut

sub numeric {
        my $self = shift(@_);
		croak "self appears to be undefined" unless ref $self;
        return '.'.join('.',$self->to_array);
}

=head2 to_string

Returns a string representation of the object. Difference with numeric is that numeric always returns numbers like .1.3.6.1.2.1.1.5.0, while this method may return strings like "sysName.0" etc.

=cut

sub to_string {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	return $self->oid->quote_oid;
}

=head2 add

Concatenates two OIDs. Use it through the . overloaded operator. Second argument can be a string, will be autoconverted to SNMP::Class::OID before addition. If one of the arguments is 0.0, the result should be equal to the other.

=cut


sub add {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	my $other = convert_to_oid_object(shift(@_)) or croak "Second argument missing from add";
	my $reverse = shift(@_); 
	if(defined($reverse)&&$reverse) {
		($self,$other) = ($other,$self);
	}
	return __PACKAGE__->new($self->numeric) if ($other->is_null);#poor man's clone....
	return __PACKAGE__->new($other->numeric) if ($self->is_null);
	return __PACKAGE__->new($self->oid->add($other->oid));
}

=head2 oid_compare

Compares two OIDs. Has the same semantic with the spaceship <=> operator. Second argument can also be a string. You probably will never use that method explicitly, only through the overloaded operators <,>,==,!= etc. See also the is_equal method.

=cut

sub oid_compare {
	#print Dumper(@_);
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	my $other = convert_to_oid_object(shift(@_));	
	croak "Internal error: Second argument missing from compare. Second argument was ".Dumper($other)."\n" unless(ref $other);
	my @arr1 = $self->to_array;
	my @arr2 = $other->to_array;

	while(1) {
		my $item1 = shift(@arr1);#left argument
		my $item2 = shift(@arr2);#right argument
		###print STDERR "$item1 $item2 \n";
		if((!defined($item1))&&(!defined($item2))) {
			return 0; #items are equal
		}
		elsif((!defined($item1))&&(defined($item2))) {
			return -1;#left is smaller than right, we return -1
		}
		elsif((defined($item1))&&(!defined($item2))) {
			return 1;#opposite
		}
		else {#case where both items are defined. Now we must compare the two numbers
			if ($item1 != $item2) {
					return $item1 <=> $item2;
			}
		} 
	}
}
       
=head2 oid_is_equal 

Returns 1 if the 1st argument is the same oid, else undef.

=cut

sub oid_is_equal {
	return 1 if ($_[0]->oid_compare($_[1]) == 0);
	return;
}
	
	
	 
=head2 contains

Can ascertain if an oid is a subset of the oid represented by the object. Takes SNMP::Class::OID as 1st and only argument. String also acceptable as it will be autoconverted. Example:
 
 $oid1 = SNMP::Class::OID->new(".1.3.6.1.4.1");
 $oid2 = SNMP::Class::OID->new(".1.3.6.1.4.1.1");
 $oid1->contains($oid2); #yields true
 $oid1->contains(".1.3.6.1.4.1.1");#the same
 
=cut
 
sub contains {
	my $self = shift(@_);
	croak "self appears to be undefined" unless ref $self;
	my $other_oid = convert_to_oid_object(shift(@_));
	croak "Second argument missing from contains" unless (ref $other_oid);
	if ($self->length > $other_oid->length) { return }
	my @arr1 = $self->to_array;
	my @arr2 = $other_oid->to_array;
	for(my $i=0;$i<=$#arr1;$i++) {
		return if (!defined($arr2[$i]));
		return if ($arr1[$i] != $arr2[$i]);
		###print STDERR "iteration=$i\t$arr1[$i]\t$arr2[$i]\n";
	}
	return 1;
}

=head2 new_from_string

Can create an oid from a literal string. Useful to generate instances which correspond to strings. 1st argument is the string to represent with an OID. If the 2nd argument is there and is true, the SNMP octet-string is assumed to be IMPLIED, thus the first number which represents the length of the string is missing. Example:

 my $instance = SNMP::Class::OID->new_from_string("foo"); # returns .3.102.111.111

 #but

 my $instance = SNMP::Class::OID->new_from_string("foo","yes_it_is_implied"); # returns .102.111.111

=cut  

sub new_from_string {
	my $class = shift(@_) or confess "Incorrect call to new";
	my $str = shift(@_) or confess "Missing string as 1st argument";
	my $implied = shift(@_) || 0;
	my $newstr;
	if(!$implied) { $newstr = "." . CORE::length($str) }
	map { $newstr .= ".$_" } unpack("c*",$str);
	###print $newstr,"\n";
	my $self={};
	#$self->{oid} = NetSNMP::OID->new($newstr) or croak "Cannot invoke NetSNMP::OID::new method \n";
	#return bless $self,$class;
	return __PACKAGE__->new($newstr);
}


#utility function, not to be used by the user
sub convert_to_oid_object {
	my $arg = shift(@_);
	if ( ! eval { $arg->isa(__PACKAGE__) } ) {
			return __PACKAGE__->new($arg);
	}	
	else {#indeed a __PACKAGE__
		####print "returning ".Dumper($arg);
		return $arg;
	}
}
	

=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class-oid at rt.cpan.org>, or through the web interface at
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

Since I am using NetSNMP::OID internally, my gratitude goes to the fine folks that gave us the original SNMP module. Many thanks to all.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Athanasios Douitsis, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SNMP::Class::OID
