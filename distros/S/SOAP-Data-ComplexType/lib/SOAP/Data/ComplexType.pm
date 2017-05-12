package SOAP::Data::ComplexType;
our $VERSION = 0.044;

use strict;
use warnings;
use Carp ();
use Scalar::Util;


use constant OBJ_URI 	=> undef;
use constant OBJ_TYPE	=> undef;	#format: ns:type
use constant OBJ_FIELDS => {};		#format: name=>[type, uri, attr]

use vars qw($AUTOLOAD);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $data = shift;	#can be HASH ref or SOAP::SOM->result object
	my $obj_fields = shift;	#href: name=>[(scalar)type, (href)attr]; or name=>[[(scalar)type, href], (href)attr]; or name=>[[(scalar)type, [(scalar)type, href]], (href)attr]; ...
	my $self = { _sdb_obj => SOAP::Data::ComplexType::Builder->new(readable=>1) };
	bless($self, $class);
	my $data_in = $self->_convert_object_to_raw($data);
	$self->_parse_obj_fields($data_in, $obj_fields, undef);
	return $self;
}

sub _convert_object_to_raw {	#recursive method: convert any object elements into perl primitives
	my $self = shift;
	my $obj = shift;
	my $ancestors = shift;
	
	my $addr = Scalar::Util::refaddr($obj);
	if (defined $ancestors) {
		if (grep(/^$addr$/, @{$ancestors})) {
			warn "Recursive processing halted: Circular reference with ancestor $addr detected\n";
			return undef;
		}
		push @{$ancestors}, $addr;
	}
	else {
		$ancestors = [$addr];
	}

	my $ret;
	if (UNIVERSAL::isa($obj, 'Array')) {	#special case: complex type Array is stored as a hash, needs conversion to native perl
		push @{$ret}, ref($obj->{$_}) ? $self->_convert_object_to_raw($obj->{$_}, $ancestors) : $obj->{$_} foreach (keys %{$obj});
	}	
	elsif (UNIVERSAL::isa($obj, 'HASH')) {
		$ret->{$_} = ref($obj->{$_}) ? $self->_convert_object_to_raw($obj->{$_}, $ancestors) : $obj->{$_} foreach (keys %{$obj});
	}
	elsif (UNIVERSAL::isa($obj, 'ARRAY')) {
		push @{$ret}, ref($_) ? $self->_convert_object_to_raw($_, $ancestors) : $_ foreach (@{$obj});
	}
	elsif (UNIVERSAL::isa($obj, 'SCALAR')) {	#future: do we *really* want to deref scalarref?
		$ret = ref(${$obj}) ? $self->_convert_object_to_raw(${$obj}, $ancestors) : ${$obj};
	}
	else {	#base case
		$ret = $obj;
	}
	return $ret;
}

sub _parse_obj_fields {	#recursive method
	my $self = shift;
	my $data = shift;
	my $obj_fields = shift;
	my $parent_obj = shift;
	my $parent_obj_is_arraytype = shift;

	### validate parameters ###
	unless (UNIVERSAL::isa($data, 'HASH')) {
		Carp::confess "Input data not expected ref type: HASH";
	}
	unless (UNIVERSAL::isa($obj_fields, 'HASH') && scalar keys %{$obj_fields} > 0) {
		Carp::confess "Object field definitions invalid or undefined.";
	}

	### generate data structures ###
	foreach my $key (keys %{$obj_fields}) {
		my $key_regex = quotemeta $key;
		if ($parent_obj_is_arraytype) {	#array special case: define child object that becomes parent of array values
			my ($type, $uri, $attributes) = @{$obj_fields->{$key}};
			my $value = $data;
#			if ($required) {
#				Carp::cluck "Warning: Required field '$key' is null" && next unless (UNIVERSAL::isa($value, 'HASH') && scalar keys %{$value}) || (UNIVERSAL::isa($value, 'ARRAY') && @{$value});
#			}
			my ($c_type, $c_fields);
			if (UNIVERSAL::isa($type, 'ARRAY')) {
				($c_type, $c_fields) = @{$type};
			}
			my $obj = $self->{_sdb_obj}->add_elem(
				name		=> $key,
				value		=> undef,
				type		=> defined $c_type ? $c_type : $type,	#if array of complex type, else array of simple type
				uri			=> $uri,
				attributes	=> $attributes,
				parent		=> $parent_obj
			);					
			my @values = UNIVERSAL::isa($value, 'ARRAY') ? @{$value} : ($value);
			foreach my $val (@values) {
				if (UNIVERSAL::isa($type, 'ARRAY')) {	#recursion case: complex subtype up to N levels deep
					if (UNIVERSAL::isa($val, 'HASH')) { $self->_parse_obj_fields($val, $c_fields, $obj, $c_type =~ m/(^|.+:)Array$/o ? 1 : 0); }
					else { Carp::cluck "Warning: Expected hash ref value for key '$key', found scalar. Ignoring data value '$val'" if defined $val; }
				}
				else {	#base case
					$self->{_sdb_obj}->add_elem(
						name		=> $key,
						value		=> $val,
						type		=> $type,
						uri			=> $uri,
						attributes	=> $attributes,
						parent		=> $obj
					);
				}
			}
		}
		elsif (grep(/^$key_regex$/, keys %{$data})) {	#base object processing
			my ($type, $uri, $attributes) = @{$obj_fields->{$key}};
			my $value = $data->{$key};
#			if ($required) {
#				Carp::cluck "Warning: Required field '$key' is null" && next unless (UNIVERSAL::isa($value, 'HASH') && scalar keys %{$value}) || (UNIVERSAL::isa($value, 'ARRAY') && @{$value});
#			}
			if (UNIVERSAL::isa($type, 'ARRAY')) {
				my ($c_type, $c_fields) = @{$type};
				my $array_obj;
				if ($c_type =~ m/(^|.+:)Array$/o) {	#complex array
					$array_obj = $self->{_sdb_obj}->add_elem(
						name		=> $key,
						value		=> undef,
						type		=> $c_type,
						uri			=> $uri,
						attributes	=> $attributes,
						parent		=> $parent_obj
					);
				}
				my @values = UNIVERSAL::isa($value, 'ARRAY') ? @{$value} : ($value);
				foreach my $val (@values) {
					my $obj = $c_type =~ m/(^|.+:)Array$/o 
						? $array_obj	#complex array
						: $self->{_sdb_obj}->add_elem(	#simple array
							name		=> $key,
							value		=> undef,
							type		=> $c_type,
							uri			=> $uri,
							attributes	=> $attributes,
							parent		=> $parent_obj
						);
#warn "Added element $key\n";
					if (UNIVERSAL::isa($val, 'HASH')) { $self->_parse_obj_fields($val, $c_fields, $obj, $c_type =~ m/(^|.+:)Array$/o ? 1 : 0); }
					else { Carp::cluck "Warning: Expected hash ref value for key '$key', found scalar. Ignoring data value '$val'" if defined $val; }
				}
			}
			else {	#base case
#				if ($required) {
#					Carp::cluck "Warning: Required field '$key' is null" && next unless defined $value;
#				}
				my @values = UNIVERSAL::isa($value, 'ARRAY') ? @{$value} : ($value);
				$self->{_sdb_obj}->add_elem(
					name		=> $key,
					value		=> $_,
					type		=> $type,
					uri			=> $uri,
					attributes	=> $attributes,
					parent		=> $parent_obj
				) foreach (@values);
#warn "Added element $key=$value\n";
			}
		}
	}
}

sub DESTROY {}
sub CLONE {}

sub AUTOLOAD {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = $AUTOLOAD;
	my $value = shift;
	$name =~ s/.*://o;   # strip fully-qualified portion
	my $elem;
	my @res = defined $value ? $self->set($name, $value) : $self->get($name);
	return wantarray ? @res : $res[0];
}

sub get_elem {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = shift;
	my $elem;
	unless (defined ($elem = $self->{_sdb_obj}->get_elem($name))) {
		Carp::cluck "Can't access '$name' element object in class $class";
	}
	return $elem;
}

sub get {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = shift;
	my $elem;
	return wantarray ? () : undef unless defined ($elem = $self->get_elem($name));
	my $res = $elem->value();
	if ($elem->{type} =~ m/(^|.+:)Array$/o) {
		return wantarray ? @{$res} : scalar @{$res} if defined $res;
		return wantarray ? () : 0;
	}
	else {
		return defined $res ? $res->[0] : undef;
	}
}

sub set {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = shift;
	my $value = shift;
	
	### validate input is valid object or list of objects ###
	if (ref $value) {
		if (ref($value) eq 'ARRAY') {
			foreach (@{$value}) {
				Carp::cluck "Value ".ref($_)." is not a valid SOAP::Data::ComplexType::Builder::Element object" if ref($_) && UNIVERSAL::isa($_, 'SOAP::Data::ComplexType::Builder::Element');
				return wantarray ? () : undef;
			}
		} else {
			Carp::cluck "Value ".ref($_)." is not a valid SOAP::Data::ComplexType::Builder::Element object" unless UNIVERSAL::isa($value, 'SOAP::Data::ComplexType::Builder::Element');
			return wantarray ? () : undef;
		}
	}
	
	my $elem;
	return wantarray ? () : undef unless ($elem = $self->get_elem($name));
	my $res = $elem->value(ref($value) eq 'ARRAY' ? $value : [$value]);
	if ($elem->{type} =~ m/(^|.+:)Array$/o) {
		return wantarray ? @{$res} : scalar @{$res} if defined $res;
		return wantarray ? () : 0;
	}
	else {
		return defined $res ? $res->[0] : undef;
	}
}

sub as_soap_data {
	my $self = shift;
	return @_ ? $self->{_sdb_obj}->get_elem($_[0])->get_as_data : $self->{_sdb_obj}->to_soap_data;
}

sub as_soap_data_instance {
	my $self = shift;
	my $class = ref($self);
	my %args = @_;
	no strict 'refs';
	return SOAP::Data->new(
		exists $args{name} ? (name	=> $args{name}) : (),
		type	=> exists $args{type} ? $args{type} : &{"$class\::OBJ_TYPE"},
		uri		=> exists $args{uri} ? $args{uri} : &{"$class\::OBJ_URI"},
		attr 	=> exists $args{attr} ? $args{attr} : {},
		value	=> \SOAP::Data->value($self->as_soap_data)
	);
}

sub as_xml_data {
	return shift->{_sdb_obj}->serialise(@_);
}

sub as_xml_data_instance {
	my $self = shift;
	my $serialized = SOAP::Serializer->autotype($self->{_sdb_obj}->autotype)->readable($self->{_sdb_obj}->readable)->serialize( $self->as_soap_data_instance(@_) );
}

sub as_raw_data {
	my $self = shift;
	my $data;
	if (@_) {
		$data = eval { $self->{_sdb_obj}->get_elem($_[0])->get_as_raw; };
		warn $@ if $@;
		$data = $data->{(keys %{$data})[0]} if ref($data) eq 'HASH' && scalar keys %{$data} == 1;	#remove parent key in this case
	}
	else {
		$data = $self->{_sdb_obj}->to_raw_data;
	}
	return $data;
}

package SOAP::Data::ComplexType::Builder;
#adds type, uri field to Builder object

use strict;
use warnings;
use SOAP::Data::Builder 0.8;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::Builder);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	return bless($self, $class);
}

sub add_elem {
	my ($self,%args) = @_;
	my $elem = SOAP::Data::ComplexType::Builder::Element->new(%args);
	if ( defined $args{parent} ) {
		my $parent = $args{parent};
		unless (UNIVERSAL::isa($parent, 'SOAP::Data::ComplexType::Builder::Element')) {
			$parent = $self->get_elem($args{parent});
		}
		$parent->add_elem($elem);
	} else {
		push(@{$self->{elements}},$elem);
	}
	return $elem;
}

sub find_elem {
	my ($self,$elem,$key,@keys) = @_;
	return UNIVERSAL::isa($elem, 'SOAP::Data::ComplexType::Builder::Element') ? $elem->find_elem($key,@keys) : undef;
}

sub get_as_data {
	my $self = shift;
	my $elem = shift;
	return UNIVERSAL::isa($elem, 'SOAP::Data::ComplexType::Builder::Element') ? $elem->get_as_data() : undef;
}

sub to_raw_data {
	my $self = shift;
	my @data = ();
	foreach my $elem ( $self->elems ) {
		my $raw = $self->get_as_raw($elem);
		push(@data,ref($raw) eq 'HASH' ? %{$raw} : ref($raw) eq 'ARRAY' ? @{$raw} : $raw);
	}
	return {@data};
}

sub get_as_raw {
	my $self = shift;
	my $elem = shift;
	return UNIVERSAL::isa($elem, 'SOAP::Data::ComplexType::Builder::Element') ? $elem->get_as_raw() : undef;
}

sub serialise {
	my $self = shift;
	my $data = @_
		? eval { SOAP::Data->value( $self->get_elem($_[0])->get_as_data ); }
		: SOAP::Data->name('SOAP:ENV' => \SOAP::Data->value( $self->to_soap_data ) );
	warn $@ if $@;
	my $serialized = SOAP::Serializer->autotype($self->autotype)->readable($self->readable)->serialize( $data );
}

package SOAP::Data::ComplexType::Builder::Element;
#supports type and uri; correctly handles '0' data value

use strict;
use warnings;
use SOAP::Data::Builder::Element;
use vars qw(@ISA);
@ISA = qw(SOAP::Data::Builder::Element);
use Carp ();
use Scalar::Util;

use vars qw($AUTOLOAD);

sub new {
	my ($class,%args) = @_;
	my $self = {};
	bless ($self,ref $class || $class);
	foreach my $key (keys %args) {
		$self->{lc $key} = defined $args{$key} ? $args{$key} : undef;
	}
	if ($args{parent}) {
		Scalar::Util::weaken($self->{parent}) if ref $args{parent};
		$self->{fullname} = (ref $args{parent} ? $args{parent}->{fullname} : $args{parent})."/$args{name}";
	}
	$self->{fullname} ||= $args{name};
	$self->{VALUE} = defined $args{value} ? [ $args{value} ] : [];
	return $self;
}

sub DESTROY {}
sub CLONE {}

sub AUTOLOAD {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = $AUTOLOAD;
	my $value = shift;
	$name =~ s/.*://o;   # strip fully-qualified portion
	my $elem;
	my @res = defined $value ? $self->set($name, $value) : $self->get($name);
	return wantarray ? @res : $res[0];
}

sub get_elem {
    my ($self,$name) = (@_,'');
    my ($a,$b);
    my @keys = split (/\//,$name);
    foreach my $elem ( $self->get_children()) {
		next unless ref $elem;
		if ($elem->name eq $keys[0]) {
		    $a = $elem;
		    $b = shift(@keys);
		    last;
		}
    }

	Carp::cluck "Can't access '$name' element object in class ".ref($self) unless defined $a;
    my $elem = $a;
    $b = shift(@keys);
    if ($b) {
		$elem = $elem->find_elem($b,@keys);
    }
	
	Carp::cluck "Can't access '$name' element object in class ".ref($self) unless defined $elem;
    return $elem;
}

sub find_elem {
    my ($self,$key,@keys) = @_;
    my ($a,$b);
	foreach my $elem ( $self->get_children()) {
		next unless ref $elem;
		if ($elem->{name} eq $key) {
			$a = $elem;
			$b = $key;
			last;
		}
	}

    my $elem = $a;
    undef($b);
    while ($b = shift(@keys) ) {
        $elem = $elem->find_elem($b,@keys);
    }
    return $elem;
}

sub get {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = shift;
	my $elem;
	return wantarray ? () : undef unless defined ($elem = $self->get_elem($name));
	my $res = $elem->value();
	if ($elem->{type} =~ m/(^|.+:)Array$/o) {
		return wantarray ? @{$res} : scalar @{$res} if defined $res;
		return wantarray ? () : 0;
	}
	else {
		return defined $res ? $res->[0] : undef;
	}
}

sub set {
	my $self = shift;
	my $class = ref($self) || Carp::confess "'$self' is not an object";
	my $name = shift;
	my $value = shift;
	
	### validate input is valid object or list of objects ###
	if (ref $value) {
		if (ref($value) eq 'ARRAY') {
			foreach (@{$value}) {
				Carp::cluck "Value ".ref($_)." is not a valid SOAP::Data::ComplexType::Builder::Element object" if ref($_) && UNIVERSAL::isa($_, 'SOAP::Data::ComplexType::Builder::Element');
				return wantarray ? () : undef;
			}
		} else {
			Carp::cluck "Value ".ref($_)." is not a valid SOAP::Data::ComplexType::Builder::Element object" unless UNIVERSAL::isa($value, 'SOAP::Data::ComplexType::Builder::Element');
			return wantarray ? () : undef;
		}
	}
	
	my $elem;
	return wantarray ? () : undef unless ($elem = $self->get_elem($name));
	my $res = $elem->value(ref($value) eq 'ARRAY' ? $value : [$value]);
	if ($elem->{type} =~ m/(^|.+:)Array$/o) {
		return wantarray ? @{$res} : scalar @{$res} if defined $res;
		return wantarray ? () : 0;
	}
	else {
		return defined $res ? $res->[0] : undef;
	}
}

sub add_elem {
    my $self = shift;
    my $elem;
    if (UNIVERSAL::isa($_[0], __PACKAGE__)) {
		$elem = $_[0];
		push(@{$self->{VALUE}},$elem);
    } else {
    	my $class = ref $self;
		push(@{$self->{VALUE}},$class->new(@_));
    }
    return $elem;
}

sub name {
	my $self = shift;
	my $value = shift;
	if (defined $value) {
		$self->{name} = $value;
	} else {
		$value = $self->{name};
	}
	return $value;
}

sub value {
	my $self = shift;
	my $value = shift;
	my $last_value;
	if (defined $value) {
		if (ref $value) {
			$last_value = $self->{VALUE};
			$self->{VALUE} = $value;
		} else {
			$last_value = $self->{VALUE};
			$self->{VALUE} = defined $value ? [$value] : [];
		}
	} else {
		$last_value = $value = $self->{VALUE};
	}
	return $last_value;
}

sub get_as_data {
	my $self = shift;
	my @values;
	foreach my $value ( @{$self->{VALUE}} ) {
		next unless (defined $value);
		if (ref $value) {
			push(@values,$value->get_as_data())
		} else {
			push(@values,$value);
		}
	}

	my @data = ();

	if (ref $values[0]) {
		$data[0] = \SOAP::Data->value( @values );
	} else {
		@data = @values;
	}

	my %attributes = %{$self->attributes()};
	my $arrayTypeAttr = (grep(/(^|.+:)arrayType$/, keys %attributes))[0];
	$attributes{$arrayTypeAttr} = $attributes{$arrayTypeAttr}.'['.(scalar @values).']' if defined $arrayTypeAttr;
	if ($self->{header}) {
		$data[0] = SOAP::Header->name($self->{name} => $data[0])->attr(\%attributes)->type($self->{type})->uri($self->{uri});
	} else {
		if ($self->{isMethod}) {
			@data = ( SOAP::Data->name($self->{name})->attr(\%attributes)->type($self->{type})->uri($self->{uri}) 
				=> SOAP::Data->value(@values)->type($self->{type})->uri($self->{uri}) );
		} else {
			$data[0] = SOAP::Data->name($self->{name} => $data[0])->attr(\%attributes)->type($self->{type})->uri($self->{uri});
		}
	}

	return @data;
}

sub get_as_raw {
	my $self = shift;
	my $is_parent_arraytype = shift;
	my @values;
	foreach my $value ( @{$self->{VALUE}} ) {
		if (ref $value) {	#ref => object
			push(@values,$value->get_as_raw($self->{type} =~ m/(^|.+:)Array$/o ? 1 : 0))
		} else {
			push(@values,$value);
		}
	}
	push @values, undef unless @values;	#insure undef value has the value undef
	my $data;
	if ($self->{type} =~ m/(^|.+:)Array$/o) {
		$data->{$self->{name}} = \@values;
	}
	else {
		foreach my $value (@values) {
			if ($is_parent_arraytype) {
				if (ref $value eq 'HASH') {
					$data->{$_} = $value->{$_} foreach keys %{$value};
				} else {
					$data = $value;
				}
			} else {
				if (ref $value eq 'HASH') {
					$data->{$self->{name}}->{$_} = $value->{$_} foreach keys %{$value};
				} else {
					$data->{$self->{name}} = $value;
				}
			}
		}
	}

	return $data;
}

1;

__END__
=pod

=head1 NAME

SOAP::Data::ComplexType - An abstract class for creating and handling complex SOAP::Data objects

=head1 SYNOPSIS

	package My::SOAP::Data::ComplexType::Foo;
	use strict;
	use warnings;
	use SOAP::Data::ComplexType;
	use vars qw(@ISA);
	@ISA = qw(SOAP::Data::ComplexType);

	use constant OBJ_URI    => 'http://foo.bar.baz';
	use constant OBJ_TYPE   => 'ns1:myFoo';
	use constant OBJ_FIELDS => {
		field1              => ['string', undef, undef],
		field2              => ['int', undef, undef],
		field3              => ['xsd:dateTime', undef, undef]
	};

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $data = shift;
		my $obj_fields = shift;
		$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
		my $self = $class->SUPER::new($data, $obj_fields);
		return bless($self, $class);
	}

	package My::SOAP::Data::ComplexType::Bar;
	use strict;
	use warnings;
	use SOAP::Data::ComplexType;
	use vars qw(@ISA);
	@ISA = qw(SOAP::Data::ComplexType);

	use constant OBJ_URI    => 'http://bar.baz.uri';
	use constant OBJ_TYPE   => 'ns1:myBar';
	use constant OBJ_FIELDS => {
		val1                => ['string', undef, undef],
		val2                => [
			[
				My::SOAP::Data::ComplexType::Foo::OBJ_TYPE,
				My::SOAP::Data::ComplexType::Foo::OBJ_FIELDS
			],
			My::SOAP::Data::ComplexType::Foo::OBJ_URI, undef
		]
	};

	sub new {
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $data = shift;
		my $obj_fields = shift;
		$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
		my $self = $class->SUPER::new($data, $obj_fields);
		return bless($self, $class);
	}

	########################################################################
	package main;

	my $request_obj = My::SOAP::Data::ComplexType::Bar->new({
		val1    => 'sometext',
		val2    => {
			field1  => 'moretext',
			field2  => 12345,
			field3  => '2005-10-26T12:00:00.000Z'
		}
	});
	print $request_obj->as_xml_data;

	use SOAP::Lite;
	
	my $result = SOAP::Lite
			->uri($uri)
			->proxy($proxy)
			->somemethod($request_obj->as_soap_data_instance( name => 'objInstance' ))
			->result;
	# An equivalent call...
	my $result2 = SOAP::Lite
			->uri($uri)
			->proxy($proxy)
			->somemethod(SOAP::Data->new(
					name => 'objInstance'
					type => &My::SOAP::Data::ComplexType::Bar::OBJ_TYPE,
					uri  => &My::SOAP::Data::ComplexType::Bar::OBJ_URI,
					attr => {}
				)->value(\SOAP::Data->value($request_obj->as_soap_data()))
			->result;

	#assuming the method returns an object of type Foo...
	if (ref($result) eq 'Foo') {
		my $result_obj = My::SOAP::Data::ComplexType::Foo->new($result);
		print "$_=".$result_obj->$_."\n" foreach keys %{+My::SOAP::Data::ComplexType::Foo::OBJ_FIELDS};
	}

=head1 ABSTRACT

SOAP::Data::ComplexType defines a structured interface to implement classes that 
represent infinitely complex SOAP::Data objects.  Object instances can dynamically 
generate complex SOAP::Data structures or pure XML as needed.  Fields of an object 
may be easily accessed by making a method call with name of the field as the method, 
and field values can be changed after object construction by using the same method 
with one parameter.

Blessed objects returned by a SOAP::Lite method's SOAP::SOM->result may be
used to reconstitute the object back into an equivalent ComplexType, thus solving 
shortcomings of SOAP::Lite's handling of complex types and allowing users
to access their objects in a much more abstract and intuive way.  This is also
exceptionally useful for applications that need use SOAP result objects in future
SOAP calls.

=head1 DESCRIPTION

This module is intended to make it much easier to create complex SOAP::Data objects 
in an object-oriented class-structure, as users of SOAP::Lite must currently craft SOAP
data structures manually.  It uses L<SOAP::Data::Builder> internally to store and generate 
object data.

I hope this module will greatly improve productivity of any SOAP::Lite programmer, 
especially those that deal with many complex datatypes or work with SOAP apps that 
implement inheritance.

=head1 IMPLEMENTATION

=head2 Creating a SOAP ComplexType class

Every class must define the following compile-time constants:

	OBJ_URI:    URI specific to this complex type
	OBJ_TYPE:   namespace and type of the complexType (formatted like 'myNamespace1:myDataType')
	OBJ_FIELDS: hashref containing name => arrayref pairs; see L<ComplexType field definitions>

When creating your constructor, if you plan to support inheritance, you must perform the following action:

	my $obj_fields = $_[1];	#second param from untouched @_
	$obj_fields = defined $obj_fields && ref($obj_fields) eq 'HASH' ? {%{+OBJ_FIELDS}, %{$obj_fields}} : OBJ_FIELDS;
	my $self = $class->SUPER::new($data, $obj_fields);

which insures that you support child class fields and pass a combination of them and your fields to
the base constructor.  Otherwise, you can simply do the following:

	my $self = $class->SUPER::new($data, OBJ_FIELDS);

(Author's Note: I don't like this kludgy constructor design, and will likely change it in a future release)


=head2 ComplexType field definitions

When defining a ComplexType field's arrayref properties, there are 4 values you must specify within an arrayref:

	type: (simple) SOAP primitive datatype, OR (complex) arrayref with [type, fields] referencing another ComplexType
	uri:  specific to this field
	attr: hashref containing any other SOAP::Data attributes

So, for example, given a complexType 'Foo' with 

	object uri='http://foo.bar.baz', 
	object type='ns1:myFoo'

and two fields (both using simple SOAP type formats)

	field1: type=string, uri=undef, attr=undef
	field2: type=int, uri=undef, attr=undef

we would define our class exactly as seen in the L<SYNOPSYS> for
package My::SOAP::Data::ComplexType::Foo.


The second form of the type field may be an arrayref with the following elements:

	type
	fields hashref

So, for example, given a complexType 'Bar' with

	object uri='http://bar.baz.uri', 
	object type='ns1:myBar'

and two fields (one using simple SOAP type, the other using complexType 'myFoo')

	field1: type=string, uri=undef, attr=undef
	field2: type=myFoo, uri=undef, attr=undef

we would define our class exactly as seen in the L<SYNOPSYS> for
package My::SOAP::Data::ComplexType::Bar.

=head1 Class Methods

=head2 My::SOAP::Data::ComplexType::Example->new( HASHREF )

Constructor.  Expects HASH ref (or reference to blessed SOAP::SOM->result object).

An example might be:

	{ keya => { subkey1 => val1, subkey2 => val2 }, keyb => { subkey3 => val3 } }

=head3 Using arrays and Array type fields

When you have a ComplexType that allows for multiple elements of the same name
(i.e. xml attribute maxOccurs > 1), use the following example form for simpleType 
values:

	{ keya => [ val1, val2, val3 ] }
	
or, for complexType values:
	
	{ keya => [ {key1 => val1}, {key1 => val2}, {key1 => val3} ] }

In such cases, the field type definition B<must> be 'ns:Array' (e.g. SOAP-ENC:Array)
and you B<must> define an 'arrayType' attribute (e.g. SOAP-ENC:arrayType); otherwise,
it will be assumed that your field can only support scalar values.  This is primarily
due to functional requirements of how SOAP::Lite handles arrays, but also has implications
on how ComplexType data values are returned by the various accessor methods.
Specifically, if your object is a SOAP Array type, then accessor methods will return
a list of elements in array context, or the number of elements in scalar context;
however, if your object is any other type, then accessor methods will return all
values in scalar context.

See L<SOAP::Data::ComplexType::Array> for additional information and definition examples.

=head1 Object Methods

=head2 $obj->get( NAME )

Returns the value of the request element.  If the element is not at the top level
in a hierarchy of ComplexTypes, this method will recursively parse through the
entire datastructure until the first matching element name is found.

If you wish to get a specific element nested deeply in a ComplexType hierarchy,
use the following format for the NAME parameter:

	PATH/TO/YOUR/NAME
	
This example would expect to find the element in the following hierarchy:

	<PATH>
		<TO>
			<YOUR>
				<NAME>
					value
				</NAME>
			</YOUR>
		</TO>
	</PATH>
	
=head2 $obj->get_elem( NAME )

Returns the object representing the request element.  Rules for how the NAME parameter
is used are the same as those defined for the L<"$obj->get( NAME )"> method.

=head2 $obj->set( NAME, NEW_VALUE )

Sets the value of the element NAME to the value NEW_VALUE.  Rules for what may be
used for valid NAME parameters and how they are used are explained in documentation
for get_elem object method.

=head2 $obj->FIELDNAME( [ NEW_VALUE ] )

Returns (or sets) the value of the given FIELDNAME field in your object. 
NEW_VALUE is optional, and changes the current value of the object.

=head2 $obj->as_soap_data_instance( name => INSTANCE_NAME )

Returns a SOAP::Data instance of the object, named INSTANCE_NAME.

=head2 $obj->as_soap_data

Returns all object fields as a list of SOAP::Data objects.  Best for use with SOAP::Lite
client stubs (subclasses), such as those generated by SOAP::Lite's L<stubmaker.pl|SOAP::Lite>.

=head2 $obj->as_xml_data_instance( name => INSTANCE_NAME )

Returns an instance of the object, named INSTANCE_NAME, formatted as an XML string.

=head2 $obj->as_xml_data

Returns all object fields as a list, formatted as an XML string.

=head2 $obj->as_raw_data

Returns all data formatted as a Perl hashref.

=head1 Other supported SOAP classes

=head2 SOAP::Data::ComplexType::Array

This is an abstract class that represents the native Array complex type in SOAP.  See
L<SOAP::Data::ComplexType::Array> for more information and usage.

=head1 TODO

Finish rewriting internals to use a single complextype package instead of two, such
that all methods can be used at any level of the hierarchy.  This should simplify
syntax needed for data mining lookup objects, and reduce complexity of manipulating the
object overall.

Add a test suite to test expected list vs. scalar result sets for Array type complex
objects and simple type objects.

Support for more properties of a SOAP::Data object.  Currently only type, uri, attributes,
and value are supported.

A WSDL (and perhaps even an ASMX) parser may be included in the future to auto-generate 
ComplexType classes, thus eliminating nearly all the usual grunt effort of integrating a 
Perl application with complex applications running under modern SOAP services such as
Apache Axis or Microsoft .NET.

Add support for restriction and range definitions (properties supported in a normal XML
spec).

=head1 CAVIATS

Multi-dimensional and sparse arrays of B<simple> type data are not yet supported, due to 
limitations of array data serialization capabilities in SOAP::Lite.

The OBJ_FIELD data structure may change in future versions to more cleanly support 
SOAP::Data parameters.  For now, I plan to keep it an array reference and simply append
on new SOAP::Data parameters as they are implemented.  Simple accessor methods may change
as well, as the current interface is a little weak--it only returns first matched occurance
of an element in the tree if there are multiple same-named elements.

=head1 BUGS

Bug reports and design suggestions are always welcome.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2006 by Eric Rybski, All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<SOAP::Lite> L<SOAP::Data::Builder>

=cut
