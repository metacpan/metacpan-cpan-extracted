package Template::Direct::Data;

use strict;
use warnings;

=head1 NAME

Template::Direct::Data - Creates a dataset handeler

=head1 SYNOPSIS

  use Template::Direct::Data;

  my $data = Template::Direct::Data->new( [ Data ] );

  $datum = $data->getDatum( 'datum_name' );
  $data  = $data->getData( 'datum_name' );

  If you want to add more data you can push another namespace level
  This will force the data checking to check this data first then
  the one before until it reaches the last one.

  $data->pushData( [ More Data ] )
  $data->pushDatum( 'datum_name' )
  $data = $data->popData()

=head1 DESCRIPTION

  Control a set of data namespaces which are defined by the top level
  set of names in a hash ref.

  All Data should be in the form { name => value } where value can be
  any hash ref, scalar, or array ref (should work with overridden objects too)

  Based on L<Template::Direct::Compile> (version 2.0) which this replaces

=head1 METHODS

=cut

use Carp;

=head2 I<class>->new( $data )

  Create a new Data instance.

=cut
sub new {
    my ($class, $data) = @_;
	my $self = bless { sets => [ ] }, $class;
	$self->pushData($data) if $data;
	return $self;
}


=head2 I<$data>->pushData( $data )

  Add a new data to this data set stack

=cut
sub pushData {
	my ($self, $data) = @_;
	if(defined($data)) {
		if(UNIVERSAL::isa($data, 'ARRAY')) {
			push @{$self->{'sets'}}, @{$data};
		} else {
			push @{$self->{'sets'}}, $data;
		}
		return 1;
	}
	return undef;
}


=head2 I<$data>->pushNew( $data )

  Returns a new Data object with $object data plus
  The new data.

=cut
sub pushNew {
	my ($self, $adddata) = @_;
	my $newobject = undef;
	foreach my $data (@{$self->{'sets'}}) {
		if(not $newobject) {
			$newobject = Template::Direct::Data->new( $data );
		} else {
			$newobject->pushData( $data );
		}
	}
	$newobject->pushData( $adddata );
	return $newobject;
}


=head2 I<$data>->pushDatum( $name )

  Find an existing data structure within myself
  And add it as a new namespace; thus bringing it
  into scope.

  Returns 1 if found and 0 if failed to find substruct

=cut
sub pushDatum {
	my ($self, $name) = @_;
	my $data = $self->getDatum( $name );
	return $self->push( $data );
}


=head2 I<$data>->pushNewDatum( $name )

  Find an existing data structure within myself and create
  A new object to contain my own data and this new sub scope.

  ( believe it or not this is useful)

=cut
sub pushNewDatum {
	my ($self, $name) = @_;
	my $data = $self->getDatum( $name );
	return $self->pushNew( $data );
}

=head2 I<$data>->popData( )

  Remove the last pushed data from the stack

=cut
sub popData {
	my ($self) = @_;
	return pop @{$self->{'sets'}};
}


=head2 I<$data>->getDatum( $name, forceString => 1, maxDepth => undef )

  Returns the structure or scalar found in the name.
  The name can be made up of multiple parts:

  name4_45_value is the same as $data{'name4'}[45]{'value'}

  forceString - ensures the result is a string and not an array ref
                or undef values.
  maxDepth    - Maximum number of depths to try before giving up and
                returning nothing, default: infinate.

=cut
sub getDatum {
	my ($self, $name, %p) = @_;

	return '' if not defined $name or $name eq '';
	my $depth = $p{'maxDepth'} || -1;

	# This is a special data controler for
	# printing the current scopes data to the template.
	# Useful for debugging and seeing what is available.
	if($name eq 'doc_debug_print') {
		return $self->dataDump();
	}

	# Search backwards for the value
	foreach my $data (reverse(@{$self->{'sets'}})) {

		# Control how many of the record sets should be used
		last if $depth == 0;
		$depth--;

		# Prefix will tell you if we are in any loops
		my $pdata = $self->_getSubStructure( $name, $data );
		next if not defined $pdata;

		# Print the size of the array when required
		$pdata = scalar(@{$pdata}) if $p{'forceString'} and UNIVERSAL::isa($pdata, 'ARRAY');
		
		# Only return defined values
		return $pdata if defined($pdata);
	}
	return $p{'forceString'} ? '' : undef;
}

=head2 I<$data>->getArrayDatum( $name )

  Like getDatum but forces output to be an array ref or undef if not valid

=cut
sub getArrayDatum {
	my ($self, $name, %p) = @_;
	return $self->_makeArray($name) if $name =~ /^\-?\d+$/;
	return $self->_makeArray($self->getDatum($name, %p));
}

=head2 I<$data>->dataDump()

  Dumps all data using the current variable scope.

=cut
sub dataDump {
	my ($self) = @_;
	return "<br/>".$self->_debugArray($self->{'sets'}, undef)."<br/>";
}

sub _debugArray {
	my ($self, $array, $prefix) = @_;

	my $result = '';	
	my $index  = 0;
	foreach my $item (@{$array}) {
		$result .= $self->_debugItem($item, (defined $prefix ? $prefix.'_'.$index : undef) );
		$index++;
	}
	return $result;
}

sub _debugHash {
	my ($self, $hash, $prefix) = @_;
	my $result = '';
	foreach my $name (keys(%{$hash})) {
		if($name ne 'parent') {
			$result .= $self->_debugItem($hash->{$name}, (defined $prefix ? $prefix.'_'.$name : $name) );
		}
	}
	return $result;
}

sub _debugItem {
	my ($self, $item, $prefix) = @_;
	return '' if not defined $item;
	if(UNIVERSAL::isa($item, 'ARRAY')) {
		return $self->_debugArray( $item, $prefix );
	} elsif(UNIVERSAL::isa($item, 'HASH')) {
		return $self->_debugHash( $item, $prefix );
	}
	return $prefix.": '".$item."'<br/>" if defined $item;
}


=head2 I<$data>->_getSubStructure( $name, $data )

=cut
sub _getSubStructure {
	my ($self, $name, $data) = @_;
	my $pdata = $data;

	foreach my $part (split(/_/, $name)) {
		if(not defined($pdata)) {
			last;
		}

		if($part =~ /^\-?\d+$/) {
			if($part < 0) {
				my $a = $self->_makeArray($pdata);
				$pdata = $a->[@{$a}+$part];
			} else {
				$pdata = $self->_makeArray($pdata)->[$part];
			}
		} else {
			$pdata = $self->_makeHash($pdata)->{$part};
		}

	}
	return $pdata;
}


=head2 I<$data>->_makeArray( $data )

  Forces the data input to be an array ref:

  Integer  -> Array of indexes [ 0, 1, 2 ... $x ]
  Code     -> Returned from code execution (cont)
  Array    -> Returned Directly
  Hash     -> Returns [ { name => $i, value => $j }, ... ]

=cut

sub _makeArray
{
	my ($self, $data) = @_;
	return undef if not defined($data);
	if(not ref($data)) {
		my ($from, $to) = (1, 0);
		if($data =~ /^\d+$/) {
			$to = $data;
		}
		if($to >= $from) {
			my @result;
			for(my $i = $from; $i <= $to; $i++ ) {
				push @result, $i;
			}
			return \@result;
		}
	}
	if(UNIVERSAL::isa($data, 'CODE')) {
		$data = &$data;
	}
	# This is to deal with overloaded variables
	if(my $sub = overload::Method($data, '@{}')) {
		return \@{$data};
	}
	if(my $sub = overload::Method($data, '%{}')) {
		$data = \%{$data};
	}
	return $data if UNIVERSAL::isa($data, 'ARRAY');
	if(UNIVERSAL::isa($data, 'HASH')) {
		my @tmparray;
		foreach my $name (keys(%{$data})) {
			my $value = $data->{$name};
			push(@tmparray, {'name' => $name, 'value' => $value});
		}
		return \@tmparray;
	}
	return undef;
}


=head2 I<$data>->_makeHash( $data )

  Forces the data input to be an hash ref:

  Code    -> Returned from code execution (cont)
  Hash    -> Returned Directly
  Other   -> { value => $data }

=cut

sub _makeHash
{
	my ($self, $data) = @_;
	return if not defined($data);
	if(UNIVERSAL::isa($data, 'CODE')) {
		$data = &$data;
	}
	if(my $sub = overload::Method($data, '%{}')) {
		$data = \%{$data};
	}
	return $data if UNIVERSAL::isa($data, 'HASH');
	return { value => $data };
}

=head1 AUTHOR

  Martin Owens - Copyright 2007, AGPL

=cut
1;
