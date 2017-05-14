package Siebel::Integration::Com::PropSet 0.02;

use 5.006;
use Moose;
use namespace::autoclean;
use strict;
use warnings;
use Win32::OLE;
use Win32::OLE::Variant;

has Error 		=>(
					is => 'rw', 
					isa=>'Str', 
					default=> '',
				);

has _ThickError =>(
					is => 'rw', 
				);
				
has ConnectionType =>( 
					is => 'rw', 
					isa=>'Str', 
					required => 1,
				);
has SApp 		=>(
					is => 'rw',
					required => 1,
				);
has _PS			=>(
					is => 'rw',
				);
				
		
sub BUILD{
	my $self = shift;
	if($self->_PS){#allow for copy method, sets _PS in constrcutor
		$self->_ThickError(Variant(VT_I2|VT_BYREF, 0)) if $self->ConnectionType eq 'Thick';
	}else{
		if($self->ConnectionType eq 'Thin'){
			$self->_PS($self->SApp->NewPropertySet()); 																return undef if $self->_chkErr("Can't create PS");
		}else{
			$self->_ThickError(Variant(VT_I2|VT_BYREF, 0));
			$self->_PS($self->SApp->NewPropertySet($self->_ThickError)); 											return undef if $self->_chkErr("Can't create PS");
		}
	}
}


sub GetPropertyCount{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetPropertyCount();
	}else{
		return $self->_PS->GetPropertyCount($self->_ThickError);
	}
}

sub GetFirstProperty{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetFirstProperty();
	}else{
		return $self->_PS->GetFirstProperty($self->_ThickError);
	}
}
sub GetNextProperty{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetNextProperty();
	}else{
		return $self->_PS->GetNextProperty($self->_ThickError);
	}
}



sub GetProperty{
	my $self = shift;
	my $name = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetProperty($name);
	}else{
		return $self->_PS->GetProperty($name, $self->_ThickError);
	}
}

sub SetProperty{
	#http://search.cpan.org/~jdb/Win32-OLE-0.1709/lib/Win32/OLE.pm SetProperty clashes with OLE internal use Invoke instead.
	my $self = shift;
	my $name = shift;
	my $value = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->Invoke('SetProperty', $name, $value);									return undef if $self->_chkErr("Can't Set Property");
	}else{
		$self->_PS->Invoke('SetProperty', $name, $value, $self->_ThickError);				return undef if $self->_chkErr("Can't Set Property");
	}
	return 1;
}



sub PropertyExists{
	my $self = shift;
	my $name = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->PropertyExists($name);
	}else{
		return $self->_PS->PropertyExists($name, $self->_ThickError);
	}
}


sub GetType{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetType();
	}else{
		return $self->_PS->GetType($self->_ThickError);
	}
}
sub GetChildCount{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetChildCount();
	}else{
		return $self->_PS->GetChildCount($self->_ThickError);
	}
}

sub GetChild{
	my $self = shift;
	my $index = shift;
	my $RawPS;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$RawPS = $self->_PS->GetChild($index);								return undef if $self->_chkErr("Can't GetChild");
	}else{
		$RawPS = $self->_PS->GetChild($index, $self->_ThickError);			return undef if $self->_chkErr("Can't GetChild");
	}
	return Siebel::Integration::Com::PropSet->new(ConnectionType => $self->ConnectionType, SApp => $self->SApp, _PS=>$RawPS);
}

sub AddChild{#returns index 
	my $self = shift;
	my $child = shift;#perl PS or Siebel PS?
	if(ref $child eq 'Siebel::Integration::Com::PropSet'){#other possible val is Win32::OLE
		$child = $child->_PS;
	}
	my $index;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$index = $self->_PS->AddChild($child);								return undef if $self->_chkErr("Can't AddChild");
	}else{
		$index = $self->_PS->AddChild($child, $self->_ThickError);			return undef if $self->_chkErr("Can't AddChild");
	}
	return $index;
}

sub Copy{
	my $self = shift;
	my $RawPS;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$RawPS = $self->_PS->Copy();										return undef if $self->_chkErr("Can't Copy");
	}else{
		$RawPS = $self->_PS->Copy($self->_ThickError);						return undef if $self->_chkErr("Can't Copy");
	}
	return Siebel::Integration::Com::PropSet->new(ConnectionType => $self->ConnectionType, SApp => $self->SApp, _PS=>$RawPS);
}

sub Reset{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->Reset();												return undef if $self->_chkErr("Can't Reset");
	}else{
		$self->_PS->Reset($self->_ThickError);								return undef if $self->_chkErr("Can't Reset");
	}
	return 1;
}

sub SetType{
	my $self = shift;
	my $type = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->SetType($type);											return undef if $self->_chkErr("Can't SetType");
	}else{
		$self->_PS->SetType($type, $self->_ThickError);						return undef if $self->_chkErr("Can't SetType");
	}
	return 1;
}

sub SetValue{
	#SetValue clashes use Invoke instead.
	my $self = shift;
	my $value = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->Invoke('SetValue', $value);											return undef if $self->_chkErr("Can't SetValue");
	}else{
		$self->_PS->Invoke('SetValue', $value, $self->_ThickError);						return undef if $self->_chkErr("Can't SetValue");
	}
	return 1;
}

sub GetValue{
	my $self = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		return $self->_PS->GetValue();
	}else{
		return $self->_PS->GetValue($self->_ThickError);
	}
}

sub InsertChildAt{
	my $self = shift;
	my $PS = shift; #perl PS or Siebel PS?
	if(ref $PS eq 'Siebel::Integration::Com::PropSet'){#other possible val is Win32::OLE
		$PS = $PS->_PS;
	}
	my $index = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->InsertChildAt($PS, $index);											return undef if $self->_chkErr("Can't InsertChildAt");
	}else{
		$self->_PS->InsertChildAt($PS, $index, $self->_ThickError);						return undef if $self->_chkErr("Can't InsertChildAt");
	}
	return 1;
}
sub RemoveChild{
	my $self = shift;
	my $index = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->RemoveChild($index);											return undef if $self->_chkErr("Can't RemoveChild");
	}else{
		$self->_PS->RemoveChild($index, $self->_ThickError);						return undef if $self->_chkErr("Can't RemoveChild");
	}
	return 1;
}
sub RemoveProperty{
	my $self = shift;
	my $propName = shift;
	$self->Error('');
	if($self->ConnectionType eq 'Thin'){
		$self->_PS->RemoveProperty($propName);											return undef if $self->_chkErr("Can't RemoveProperty");
	}else{
		$self->_PS->RemoveProperty($propName, $self->_ThickError);						return undef if $self->_chkErr("Can't RemoveProperty");
	}
	return 1;
}

sub _chkErr{
	my $self = shift;
	my $what = shift;
	my $ErrorCode;
	if($self->ConnectionType eq 'Thin'){
		$ErrorCode = $self->SApp->GetLastErrCode();
	}else{
		$ErrorCode = $self->_ThickError;
	}
	if(($ErrorCode // 0) != 0){
		$self->Error("[$what] " . $ErrorCode . ': ' . $self->SApp->GetLastErrText());
		return 1;
	}
	return 0;
}

#Extended Methods

sub ToXML{
	my $self = shift;
	my $result;
	
	$result .= "<PropertySet";
	$result .= " type='" . $self->GetType() . "'" if $self->GetType();
	$result .= " value='" . $self->GetValue() . "'" if $self->GetValue();
	$result .= ">\n";
	
	$result .= $self->_DumpPS($self, 'xml');#pass self since other levels may pass children
	
	$result .= '</PropertySet>';
	return $result;
}

sub ToText{
	my $self = shift;
	my $result;
	$result .= "Property Set Type => " . $self->GetType() . "\n" if $self->GetType();
	$result .= "Property Set Value => " . $self->GetValue() . "\n" if $self->GetValue();
	$result .= ('-'x50) . "\n" if $result;
	$result .=  $self->_DumpPS($self, 'text');#pass self since other levels may pass children
	return $result;
}

sub _DumpPS{
	my $self = shift;
	my $PS = shift;
	my $mode = shift;
	my ($level, $result);
	if(@_){
		$level = shift;
	}else{
		$level = 1;
	}
	my $childLevel = $level + 1;
	$result .= $self->_DumpPSProps($PS, $mode, $level);
	my $numChildren = $PS->GetChildCount();
	for(my $i = 0;$i<$numChildren;$i++){
		if($mode eq 'text'){
			$result .= ('-'x50) . "\n";
		}elsif($mode eq 'xml'){
			$result .= ("\t" x $level) . "<PropertySet$i>\n";
		}
		
		$result .= $self->_DumpPS($PS->GetChild($i), $mode, $childLevel);

		if($mode eq 'xml'){
			$result .= ("\t" x $level) . "</PropertySet$i>\n";
		}
	}

	return $result;
}

sub _DumpPSProps{
	my $self = shift;
	my $PS = shift;
	my $mode = shift;
	my $result = '';#prevents warnings when no properties are found
	my $level = shift;
	
	if(my $Prop = $PS->GetFirstProperty()){
		do{
			$result .= "\t" x $level;
			if($mode eq 'text'){
				$result .= $Prop . '=>' . $PS->GetProperty($Prop) . "\n";
			}elsif($mode eq 'xml'){
				$result .= "<$Prop>" . $PS->GetProperty($Prop) . "</$Prop>\n";
			}
		}while($Prop = $PS->GetNextProperty());
	}
	return $result;
}






__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Siebel::Integration::Com::PropSet - Abstraction of Siebel Property Set

=head1 SYNOPSIS

	use Siebel::Integration::Com;
	
	my $sa = Siebel::Integration::Com->new(
			ConnectionType=>'Thick', 
			UserName=>$inputs{user}, 
			PassWord=>$inputs{pass}, 
			CFG=>$inputs{cfg}, 
			DataSource=>$inputs{DataSource}
		);
																	
	my $PS = $sa->NewPropertySet();
	if($PS->Error ne ''){
		die print "Error creating Prop Set: " . $PS->Error;
	}
	my $ChildPS = $sa->NewPropertySet();
	if($ChildPS->Error ne ''){
		die print "Error creating Prop Set: " . $ChildPS->Error;
	}
	
	$PS->SetType('PropSetType');
	$PS->SetValue('PropSetValue');
	$PS->SetProperty('Prop1', "This is Prop1's value");
	$PS->SetProperty('Prop2', "This is Prop2's value");
	$ChildPS->SetProperty('ChildProp1', "This is ChildProp1's value");
	$ChildPS->SetProperty('ChildProp2', "This is ChildProp2's value");
	$PS->AddChild($ChildPS);
	
	#Print Prop Set details
	print "Parent Level PS has " . $PS->GetPropertyCount() . " properties\n";
	print "Parent Level PS has " . $PS->GetChildCount() . " child\n";
	print "Parent Level PS has a type of " . $PS->GetType() . "\n";
	print "Parent Level PS has a value of " . $PS->GetValue() . "\n";
	
	if(my $Prop = $PS->GetFirstProperty()){
		do{
			print $Prop . '=>' . $PS->GetProperty($Prop) . "\n";
		}while($Prop = $PS->GetNextProperty());
	}else{
		print "No properties found, something is wrong.";
	}
	my $PSGetChild = $PS->GetChild(0);
	if($PSGetChild->Error ne ''){
		die print "Error GetChild at index 0: " . $PSGetChild->Error;
	}
	
	if(my $Prop = $PSGetChild->GetFirstProperty()){
		do{
			print "\t" . $Prop . '=>' . $PSGetChild->GetProperty($Prop) . "\n";
		}while($Prop = $PSGetChild->GetNextProperty());
	}else{
		print "No properties found in child, something is wrong.";
	}
	
	#prints
		#Parent Level PS has 2 properties
		#Parent Level PS has 1 child
		#Parent Level PS has a type of PropSetType
		#Parent Level PS has a value of PropSetValue
		#Prop2=>This is Prop2's value
		#Prop1=>This is Prop1's value
		#		ChildProp1=>This is ChildProp1's value
		#		ChildProp2=>This is ChildProp2's value
	
	#a simpler way of dumping property sets is with these 2 methods. These methods will also get all children and grandchildren and so on
	print $PS->ToXML();
	
	print $PS->ToText();
	
	#remove a property by name
	$PS->RemoveProperty('Prop1');
	
	#remove a child PS by index
	$PS->RemoveChild(0);

=head1 DESCRIPTION

The Siebel::Integration::Com modules are designed to remove the different method calls and error checking between the COM Data Control and COM Data Server interfaces. 
Changing between the two interfaces only requires a change in the parameters to Siebel::Integration::Com->new() rather than a rewrite of all calls.
Beyond just replicating the base functions of the interfaces it is hoped that additional methods will be added to these modules to extend the functionality provided by the Siebel COM framework.

All methods that have been exposed keep the same names so there is no additional learning curve, you can program in Perl using the same method names as eScript

=head2 Base Methods

=over 8

=item PS->Error()

	Returns the error text for the last operation, returns '' if no error.

=item PS->GetPropertyCount()

	Returns the number of Properties

=item PS->GetFirstProperty()

	Returns the first properties name or ''

=item PS->GetNextProperty()

	Returns the next properties name or ''

=item PS->GetType()

	Returns the value of the type attribute of a property set or ''

=item PS->GetValue()

	Returns the value of the value attribute of a property set or ''

=item PS->GetProperty(PropName)

	Returns the value of the property, if property does not exist will return ''

=item PS->PropertyExists(PropName)

	Returns 0 (false) or 1 (true)

=item PS->SetProperty(PropName, PropValue)

	Returns 1 for success or undef for failure. A failure will set PS->Error

=item PS->GetChildCount()

	Returns the number of child property sets

=item PS->GetChild(Index)

	Returns a new Siebel::Integration::Com::PropSet object containing the Siebel property set at the specified index
	Returns undef on failure and sets PS->Error

=item PS->AddChild(ChildPS)

	Takes a Siebel::Integration::Com::PropSet or a raw Siebel property set
	Returns the index of the child property set
	Returns undef on failure and sets PS->Error

=item PS->Copy()

	Returns a new Siebel::Integration::Com::PropSet object containing a duplicated Siebel propery set. 
	Returns undef on failure and sets PS->Error

=item PS->Reset()

	Clears all Siebel property set data from the object. 
	Returns 1 for success. 
	Returns undef on failure and sets PS->Error

=item PS->SetType(Value)

	Sets the value for the type attribute of a property set
	Returns 1 for success. 
	Returns undef on failure and sets PS->Error

=item PS->SetValue(Value)

	Sets the value for the value attribute of a property set
	Returns 1 for success. 
	Returns undef on failure and sets PS->Error

=item PS->InsertChildAt(ChildObject, Index)

	Inserts a child property set in a parent property set at a specific location
	Returns 1 on success
	Returns undef on failure and sets PS->Error

=item PS->RemoveChild(Index)

	Removes a child property set from a parent property set
	Returns 1 on success
	Returns undef on failure and sets PS->Error

=item PS->RemoveProperty(PropName)

	Removes a property from a property set
	Returns 1 on success
	Returns undef on failure and sets PS->Error

=item PS->ConnectionType

	The current connection type Thin or Thick

=item New(ConnectionType=>'Thin/Thick', SApp=>Siebel::Integration::Com)

	Only called internally from Siebel::Integration::Com NewPropertySet()
	Returns a Siebel::Integration::Com::PropSet
	Sets PS->Error if an error occurs

=back

=head2 Extended Methods

=over 8

=item PS->ToXML

	Returns the property set in XML
	Example result:
	<PropertySet type='PropSetType' value='PropSetValue'>
	  <Prop2>This is Prop2's value</Prop2>
	  <Prop1>This is Prop1's value</Prop1>
	  <PropertySet0>
	    <ChildProp1>This is ChildProp1's value</ChildProp1>
	    <ChildProp2>This is ChildProp2's value</ChildProp2>
	    <PropertySet0>
	      <GChildProp2>This is GChildProp2's value</GChildProp2>
	      <GChildProp3>This is GChildProp3's value</GChildProp3>
	      <GChildProp4>This is GChildProp4's value</GChildProp4>
	      <GChildProp1>This is GChildProp1's value</GChildProp1>
	    </PropertySet0>
	  </PropertySet0>
	  <PropertySet1>
	    <Child2Prop1>This is Child2Prop1's value</Child2Prop1>
	    <Child2Prop2>This is Child2Prop2's value</Child2Prop2>
	  </PropertySet1>
	</PropertySet>

	

=item PS->ToText

	Returns the property set as text
	Example result:
	
	Property Set Type => PropSetType
	Property Set Value => PropSetValue
	--------------------------------------------------
	  Prop2=>This is Prop2's value
	  Prop1=>This is Prop1's value
	--------------------------------------------------
	    ChildProp1=>This is ChildProp1's value
	    ChildProp2=>This is ChildProp2's value
	--------------------------------------------------
	      GChildProp2=>This is GChildProp2's value
	      GChildProp3=>This is GChildProp3's value
	      GChildProp4=>This is GChildProp4's value
	      GChildProp1=>This is GChildProp1's value
	--------------------------------------------------
	    Child2Prop1=>This is Child2Prop1's value
	    Child2Prop2=>This is Child2Prop2's value

=back

=head1 REQUIREMENTS

See L<Siebel::Integration::Com>

=head1 TESTING

See L<Siebel::Integration::Com>

=head1 SEE ALSO

The documentation for L<Siebel::Integration::Com> contains additional information

=head2 REFERENCES

L<Oracle Help Property Set Methods|http://docs.oracle.com/cd/E14004_01/books/OIRef/OIRef_Siebel_eScript_Quick_Reference11.html>

=head1 AUTHOR

Kyle Mathers, C<< <kyle.perl at mathersit.com> >>

=head1 COPYRIGHT

The same as L<Siebel::Integration::Com>

=head1 VERSION

Version 0.02 March 2013

=cut


