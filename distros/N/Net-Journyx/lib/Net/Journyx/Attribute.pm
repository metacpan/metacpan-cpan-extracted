package Net::Journyx::Attribute;
use Moose;

extends 'Net::Journyx::Object';
with 'Net::Journyx::Object::Loadable' => {
    check_on => [qw(delete)],
    drop_on => [qw(create delete)],
};

use constant jx_record_class => 'AttributeTypeRecord';
use constant jx_strip_record_suffix => 1;

my @jx_columns = ();
has jx_columns => (
    is       => 'ro',
    init_arg => undef,
    isa      => 'ArrayRef[Str]',
    lazy     => 1,
    default  => sub {
        return [@jx_columns] if @jx_columns;
        my %columns = $_[0]->jx->soap->record_columns( $_[0]->jx_record_class );
        @jx_columns = keys %columns;
        return [@jx_columns];
    },
);

has jx_record => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => undef,
    default  => sub { {} },
);

my @valid_object_types = ();
has valid_object_types => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => 0,
    lazy     => 1,
    default  => sub {
        return [@valid_object_types] if @valid_object_types;
        my $res = (shift)->jx->soap->basic_call('getAttributeObjectTypes');
        @valid_object_types = sort ref($res) eq 'ARRAY'? @$res : $res;
        return [@valid_object_types];
    },
);

sub is_valid_type {
    my $self = shift;
    my $type = shift;

    local $@;
    my $response = eval { $self->jx->soap->basic_call(
        'checkAttributeDataType', data_type => $type
    ) };
    return $response;
}

sub id { return $_[0]->jx_record->{'id_attr_type'} }
sub data_type { return $_[0]->jx_record->{'attr_type'} }

sub load {
    my $self = shift;
    my %args = (
        object => undef,
        name   => undef,
        @_,
    );
    unless ( blessed($args{'object'})
        && $args{'object'}->isa('Moose::Object')
        && $args{'object'}->does('Net::Journyx::Object::WithAttrs')
    ) {
        die "object argument must consume 'Net::Journyx::ObjectWithAttrs' role";
    }

    $args{'object_type'} = $args{'object'}->object_type_for_attributes;
    $args{'type_name'}   = delete $args{'name'};

    my $response = $self->jx->soap->basic_call(
        'getAttributeTypeRecordByName',
        %args
    );

    my $jx_class = $self->jx_record_class;
    my $record = $response->{ $jx_class };
    unless ( $record ) {
        die "No '$jx_class' in response ". Dumper($response);
    }

    foreach my $k ( keys %$record ) {
        if ( $k =~ /^_+(.*)$/ && !exists $record->{ $1 } ) {
            $record->{ $1 } = delete $record->{ $k };
        }
    }

    $self->jx_record( $record );
    $self->_is_loaded(1) if $record->{'id_attr_type'};

    return $self;
}

sub create {
    my $self = shift;
    my %args = (
        object => undef,
        name   => undef,
        type   => undef,
        @_,
    );

    unless ( blessed($args{'object'})
        && $args{'object'}->isa('Moose::Object')
        && $args{'object'}->does('Net::Journyx::Object::WithAttrs')
    ) {
        die "object argument must consume 'Net::Journyx::Object::WithAttrs' role";
    }

    my %create_args = ();

    $create_args{'object_type'} = $args{'object'}->object_type_for_attributes;
    $create_args{'data_type'}   = $args{'type'};
    $create_args{'pname'}       = $args{'name'};

    my $response = $self->jx->soap->basic_call(
        'addAttributeType', %create_args
    );

    # XXX: we created, but looks like we can not load by id :)
    return $self->load( %args );
}

sub update {
    die "This object has no update method, it can be implemented,"
        ." but use other methods at this point";
}

# note that only admin can delete an attribute type
sub delete {
    my $self = shift;
    return $self->jx->soap->basic_call(
        'deleteAttributeType',
        id_attr_type => $self->id,
    );
}

sub default_value {
    my $self = shift;
    die "not loaded" unless $self->is_loaded;

    my $operation = 'getAttributeTypeDefaultValue';

    my $data_type = $self->data_type;
    if ( $data_type eq 'NUMBER' || $data_type eq 'INTEGER') {
        $operation .= ucfirst lc $data_type;
    }

    return $self->jx->soap->basic_call(
        $operation,
        id_attr_type => $self->id,
    );
}

sub set_default_value {
    my $self = shift;
    my $value = shift;

    return $self->delete_default_value
        unless defined $value and length $value;

    die "not loaded" unless $self->is_loaded;

    my $operation = 'setAttributeTypeDefaultValue';
    my $data_type = $self->data_type;
    if ( $data_type eq 'NUMBER' || $data_type eq 'INTEGER') {
        $operation .= ucfirst lc $data_type;
    }

    return $self->jx->soap->basic_call(
        $operation,
        id_attr_type => $self->id,
        default_value => $value,
    );
}

sub delete_default_value {
    my $self = shift;
    die "not loaded" unless $self->is_loaded;

    return $self->jx->soap->basic_call(
        'removeAttributeTypeDefaultValue',
        id_attr_type => $self->id,
    );
}

1;
