package MooseX::NestedAttributesConstructor::Trait::Class;
use Moose::Role;

around new_object => sub {
    my $orig = shift;
    my $self = shift;
    my $argz = @_ == 1 ? $_[0] : {@_};
    return $self->$orig(_construct($self, $argz));
};

sub _construct
{
    my ($class, $options) = @_;
    return $options unless $class->can('meta');

    while( my ($name, $val) = each %$options ) {

	# May or may not be a metaclass
	my $attr  = $class->can('get_attribute') ? $class->get_attribute($name) : $class->meta->get_attribute($name);
	my $vtype = ref($val);

	next unless $attr
	    and ($vtype eq 'ARRAY' or $vtype eq 'HASH')
	    and !blessed($val)
	    and $attr->does('NestedAttribute')
	    and $attr->has_type_constraint
	    and ($attr->type_constraint->isa('Moose::Meta::TypeConstraint::Class') or
		 $attr->type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized'));

	my $ctype;
	my $param = 1;

	if($attr->type_constraint->isa('Moose::Meta::TypeConstraint::Parameterized')) {
	    $ctype = $attr->type_constraint->type_parameter->class;
	}
	else {
	    $ctype = $attr->type_constraint->class;
	    $param = 0;
	}

	if($vtype eq 'HASH') {
	    $val = _construct_hash($ctype, $val, $param);
	}
	elsif($param && ref($val->[0]) eq 'HASH') {
	    $val = _construct_array($ctype, $val);
	}

	$options->{$name} = $val;
    }

    return $options;
}

sub _construct_array
{
    my ($class, $val) = @_;
    my $collection = [];
    for(@$val) {
	my $options = _construct($class, $_);
	push @$collection, $class->new(%$options);
    }

    $collection;
}

sub _construct_hash
{
    my ($class, $val, $is_param) = @_;

    if($is_param) {
	my $collection = {};
	for(keys %$val) {
	    my $options = _construct($class, $val->{$_});
	    $collection->{$_} = $class->new(%$options);
	}

	return $collection;
    }

    $class->new(%$val);
}

1;
