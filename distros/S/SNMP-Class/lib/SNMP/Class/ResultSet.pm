package SNMP::Class::ResultSet;

=head1 SNMP::Class::ResultSet

SNMP::Class::ResultSet - A list of L<SNMP::Class::Varbind> objects. 

=head1 VERSION

Version 0.12

=cut

use version; our $VERSION = qv("0.11");

=head1 SYNOPSIS

    use SNMP::Class::ResultSet;

    my $foo = SNMP::Class::ResultSet->new;
    $foo->push($vb1);
    
    ...
    
    #later:
    ...

=cut

use warnings;
use strict;
use Carp;
use SNMP;	
use SNMP::Class;
use Data::Dumper;
use UNIVERSAL qw(isa);
use Class::Std;

use Log::Log4perl qw(:easy);
my $logger = get_logger();

use overload 
	'@{}' => \&varbinds,
	'.' => \&dot,
	'+' => \&plus,
	fallback => 1;

#class fields
my (%varbinds,%index_object,%index_instance,%index_value,%index_oid) : ATTRS();


=head1 METHODS

B<IMPORTANT NOTICE:> All the methods that are returning a ResultSet will only do so when called in scalar context. They alternatively return the list of varbinds in list context.

=head2 new

Constructor. Just issue it without arguments. Creates an empty ResultSet. SNMP::Class::Varbind objects can later be stored in there using the push method.

=cut

sub BUILD {
	my ($self, $id, $arg_ref) = @_;
	$varbinds{$id} = [];
	$index_oid{$id} = {};
	$index_object{$id} = {};
	$index_instance{$id} = {};
	$index_value{$id} = {};
}

=head2 smart_return 

In scalar context, this method returns the object itself, while in list context returns the list of the varbinds. In null context, it will croak. This method is mainly used for internal purposes. 

=cut

sub smart_return {

	defined(my $self = shift(@_)) or croak "Incorrect call to smart_return";

	defined(my $context = wantarray) or croak "ResultSet used in null context";

	if ($context) {
		DEBUG "List context detected";
		return @{$self->varbinds};
	}

	return $self;
}

=head2 varbinds

Returns a reference to a list containing all the stored varbinds. Modifying the list alters the object.

=cut

sub varbinds {
	my $self = shift(@_) or croak "Incorrect call to varbind";
	my $id = ident $self;
	return $varbinds{$id};
}



sub index_oid {
	my $self = shift(@_) or croak "Incorrect call to index_oid";
	my $id = ident $self;
	return $index_oid{$id};
}

sub index_object {
	my $self = shift(@_) or croak "Incorrect call to index_object";
	my $id = ident $self;
	return $index_object{$id};
}

sub index_instance {
	my $self = shift(@_) or croak "Incorrect call to index_instance";
	my $id = ident $self;
	return $index_instance{$id};
}

sub index_value {
	my $self = shift(@_) or croak "Incorrect call to index_value";
	my $id = ident $self;
	return $index_value{$id};
}


=head2 dump

Returns a string representation of the entire ResultSet. Mainly used for debugging purposes. 

=cut

sub dump  {
	my $self = shift(@_);
	croak "Incorrect call to dump" unless defined($self);
	return join("\n",($self->map(sub {$_->dump})));
}

=head2 push

Takes one argument, which must be an L<SNMP::Class::Varbind> or a descendant of that class. Inserts it into the ResultSet.

=cut
 
sub push {
	my $self = shift(@_) or croak "Incorrect call to push";
	my $id = ident $self;
	my $payload = shift(@_);

	#make sure that this is of the correct class
	if (! eval $payload->isa('SNMP::Class::Varbind')) {
		confess "Payload is not an SNMP::Class::Varbind";
	}
	push @{$self->varbinds},($payload);
	$self->index_oid->{$payload->numeric} = \$payload;
	#@#push @{$self->index_object->{$payload->object->numeric}},(\$payload);
	#@#push @{$self->index_instance->{$payload->instance->numeric}},(\$payload);
	#@#push @{$self->index_value->{$payload->raw_value}},(\$payload);
	
	#using the get_oid inside a hash key will force it to use the overloaded '""' quote_oid subroutine
	###$self->{oid_index}->{$payload->get_oid}->{$payload->get_instance_numeric} = \$payload;
	
}

=head2 pop

Pops a varbind out of the Set. Takes no arguments.

=cut

sub pop {
	my $self = shift(@_) or croak "Incorrect call";
	return pop @{$self->varbinds};
}



#take a list with possible duplicate elements
#return a list with each element unique
#sub unique {
#	my @ret;
#	for my $elem (@_) {
#		next unless defined($elem);
#		CORE::push @ret,($elem) if(!(grep {$elem == $_} @ret));#make sure the the == operator does what you expect
#	}
#	return @ret;
#}


#this function (this is not a method) takes an assorted list of SNMP::Class::OIDs, SNMP::Class::ResultSets and even strings
#and returns a proper list of SNMP::Class::OIDs. Used for internal purposes.
sub construct_matchlist {
	my @matchlist;
	for my $item (@_) {
		if(ref($item)) {
			if ( eval $item->isa("SNMP::Class::OID") ) {
				CORE::push @matchlist,($item);
			}
			elsif (eval $item->isa('SNMP::Class::ResultSet')) {
				CORE::push @matchlist,(@{$item->varbinds});
			}
			else { 
				croak "I don't know how to handle a ".ref($item);
			}
		}
		else {
			CORE::push @matchlist,(SNMP::Class::OID->new($item));
		}
	}
	return @matchlist;
}


#4 little handly subroutines to use for matching using various ways

sub match_label {
	my($x,$y) = @_;
	return unless defined($x->get_label_oid);
	return unless defined($y->get_label_oid);
	return $x->get_label_oid->oid_is_equal( $y->get_label_oid );
}

sub match_instance {
	my($x,$y) = @_;
	return unless defined($x->get_label_oid);
	return unless defined($y->get_label_oid);
	return $x->get_instance_oid->oid_is_equal( $y->get_instance_oid );
}

sub match_fulloid {
	my($x,$y) = @_;
	return $x->oid_is_equal( $y );
}

sub match_value {
	my($x,$y) = @_;
	return $x->value eq $y;
}

#this is the core of the filtering mechanism
#the match_callback method may be used as an argument to the filter method
#takes 2 arguments:
#1)a reference to a comparing subref which returns true or false (see 4 ready match_* subrefs above)
#2)a list of items to match against.
#produces a closure that matches $_ against any of those items (grep-style) using the comparing subref
sub match_callback {
	my $match_sub_ref = shift(@_);
	my @matchlist = (@_);
	confess "Please do not supply empty matchlists in your filters -- completely pointless" unless @matchlist;
	return sub {		
		for my $match_item (@matchlist) {
			if ($match_sub_ref->($_,$match_item)) {
				DEBUG "Item ".$_->to_string." matches"; 
				return 1;
			}
		}
		return;
	};
}


sub filter_label {
	my $self = shift(@_) or croak "Incorrect call to label";
	return $self->filter(match_callback(\&match_label,construct_matchlist(@_)));
}
sub filter_instance {
	my $self = shift(@_) or croak "Incorrect call to label";
	return $self->filter(match_callback(\&match_instance,construct_matchlist(@_)));
}
sub filter_fulloid {
	my $self = shift(@_) or croak "Incorrect call to label";
	return $self->filter(match_callback(\&match_fulloid,construct_matchlist(@_)));
}
sub filter_value {
	my $self = shift(@_) or croak "Incorrect call to label";
	return $self->filter(match_callback(\&match_value,@_));
}

=head2 filter

filter can be used when there is the need to filter the varbinds inside the resultset using arbitrary rules. Takes one argument, which is a reference to a subroutine which will be doing the filtering. The subroutine must return an appropriate true or false value just like in L<CORE::grep>. The value of each L<SNMP::Class::Varbind> item in the ResultSet gets assigned to the $_ global variable. For example:

 print $rs->filter(sub {$_->get_label_oid == 'sysName'});

If used in a scalar context, a reference to a new ResultSet containing the filter results will be returned. If used in a list context, a simple array containing the varbinds of the result will be returned. Please do note that in the previous example, the print function always forces list context, so we get what we want.

=cut

sub filter {
	my $self = shift(@_) or croak "Incorrect call";
	my $coderef = shift(@_);
	if(ref($coderef) ne 'CODE') {
		confess "First argument must be always a reference to a sub";
	}
	my $ret_set = SNMP::Class::ResultSet->new;
	map { $ret_set->push($_); } ( grep { &$coderef; } @{$self->varbinds} );
	
	$ret_set->smart_return;
}

=head2 find

Filters based on key-value pairs that are labels and values. For example: 

 $rs->find('ifDescr' => 'eth0', ifDescr => 'eth1');

will find which are the instance oids of the row that has ifDescr equal to 'eth0' B<or> 'eth1' (if any), and filter using that instances.

This means that to get the ifSpeed of eth0, one can simply issue:
 
 my $speed = $rs->find('ifDescr' => 'eth0')->ifSpeed->value;

=cut
  	
sub find {
	my $self = shift(@_) or croak "Incorrect call to find";

	my @matchlist = ();
	###print Dumper(@_);
	
	while(1) {
		my $object = shift(@_);
		last unless defined($object);
		my $value = shift(@_);
		last unless defined($value);
		DEBUG "Searching for instances with $object == $value";
		CORE::push @matchlist,(@{$self->filter_label($object)->filter_value($value)});
	}
	
	#be careful. The matchlist which we have may very well be empty! 
	#we should not be filtering against an empty matchlist
	#note that the filter_instance will croak in such a case.
	return $self->filter_instance(@matchlist);
}


=head2 number_of_items

Returns the number of items present inside the ResultSet

=cut

sub number_of_items {
	my $self = shift(@_) or croak "Incorrect call to number_of_items";
	return scalar @{$self->varbinds};
}

=head2 is_empty

Reveals whether the ResultSet is empty or not.

=cut

sub is_empty {
	my $self = shift(@_) or croak "Incorrect call to is_empty";
	return ($self->number_of_items == 0);
}


=head2 dot

The dot method overloads the '.' operator, returns L<SNMP::Class::Varbind>. Use it to get a single L<SNMP::Class::Varbind> out of a ResultSet as a final instance filter. For example, if $rs contains ifSpeed.1, ifSpeed.2 and ifSpeed.3, then this call: 

 $rs.3 
 
returns the ifSpeed.3 L<SNMP::Class::Varbind>.

B<Please note that this method does not return a ResultSet like the instance method, but a Varbind which should be the sole member of the ResultSet having that instance. If the ResultSet has more than one Varbinds with the requested instance and the dot operator is used, a warning will be issued, and only the first matching Varbind will be returned> 

=cut
 
sub dot {
	my $self = shift(@_) or croak "Incorrect call to dot";
	my $str = shift(@_); #we won't test because it could be false, e.g. ifName.0
	
	$logger->debug("dot called with $str as argument");

	#we force scalar context
	my $ret = scalar $self->filter_instance($str);

	if ($ret->is_empty) {
		confess "empty resultset";
	} 
	if ($ret->number_of_items > 1) {
		carp "Warning: resultset with more than 1 items";
	}
	return $ret->item(0);
}

=head2 item

Returns the item of the ResultSet with index same as the first argument. No argument yields the first item (index 0) in the ResultSet.

=cut
 
sub item {
	my $self = shift(@_) or croak "Incorrect call";
	my $index = shift(@_) || 0;
	return $self->varbinds->[$index];
}

#calls named method $method on the and hopefully only existing item. Should not be used by the user.
#This is an internal shortcut to simplify method creation that applies to SNMP::Class::OID single members of a ResultSet
sub item_method :RESTRICTED() {
	my $self = shift(@_) or croak "Incorrect call";
	my $method = shift(@_) or croak "missing method name";
	my @rest = (@_);
	if($self->is_empty) {
		croak "$method cannot be called on an empty result set";
	}
	if ($self->number_of_items > 1) {
		WARN "Warning: Calling $method on a result set that has more than one item";
	}
	return $self->item(0)->$method(@rest);
}

#warning: plus will not protect you from duplicates
#plus will return a new object
sub plus {
	my $self = shift(@_) or croak "Incorrect call to plus";
	my $item = shift(@_) or croak "Argument to add(+) missing";

	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));

	my $ret = SNMP::Class::ResultSet->new();

	map { $ret->push($_) } (@{$self->varbinds});
	map { $ret->push($_) } (@{$item->varbinds});

	return $ret;
}

#append act on $self
sub append { 
	my $self = shift(@_) or croak "Incorrect call to append";
	my $item = shift(@_) or croak "Argument to append missing";
	#check that this object is an SNMP::Class::Varbind
	confess "item to add is not an SNMP::Class::ResultSet!" unless (ref($item)&&(eval $item->isa("SNMP::Class::ResultSet")));
	map { $self->push($_) } (@{$item->varbinds});
	return;
}

sub map {
	my $self = shift(@_) or croak "Incorrect call";
	my $func = shift(@_) or croak "missing sub";
	croak "argument should be code reference" unless (ref $func eq 'CODE');
	#$logger->debug("mapping....");
	my @result;
	for(@{$self->varbinds}) {
		#$logger->debug("executing sub with ".$_->dump);
		CORE::push @result,($func->());
	}
	return @result;
}


sub AUTOMETHOD {
	my $self = shift(@_) or confess("Incorrect call to AUTOMETHOD");
	my $id = shift(@_) or confess("Second argument (id) to AUTOMETHOD missing");
	my $subname = $_;   # Requested subroutine name is passed via $_;
	
	if (SNMP::Class::Utils::is_valid_oid($subname)) {
		$logger->debug("ResultSet: $subname seems like a valid OID ");	
		return sub {
#			if(wantarray) {
#				$logger->debug("$subname called in list context");
#				return @{$self->filter_label($subname)->varbinds};
#			}
			DEBUG "Returning the resultset";
			return $self->filter_label($subname);
		};

	}
	elsif (SNMP::Class::Varbind->can($subname)) {
		DEBUG "$subname method call was refering to the contained varbind. Will delegate to the first item. Resultset is ".$self->dump;
		return sub { return $self->item_method($subname,@_) };
	}	
	else {
		$logger->debug("$subname doesn't seem like something I can actually make sense of. .");
		return;
	}
	
	#we'll just have to create this little closure and return it to the Class::Std module
	#remember: this closure will run in the place of the method that was called by the invoker

}
	
 


=head1 AUTHOR

Athanasios Douitsis, C<< <aduitsis at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-class-resultset at rt.cpan.org>, or through the web interface at
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

1; # End of SNMP::Class::ResultSet
