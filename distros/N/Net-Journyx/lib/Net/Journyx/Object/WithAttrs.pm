package Net::Journyx::Object::WithAttrs;
use Moose::Role;

#requires 'jx'; Moose doesn't like that jx is only accessor

has object_type_for_attributes => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;

        require Net::Journyx::Attribute;
        my $valid_types = Net::Journyx::Attribute
            ->new(jx => $self->jx)
            ->valid_object_types;

        my $guessed_type = lc((split /::/, ref($self))[-1]).'s';

        return $guessed_type if grep $guessed_type eq $_, @$valid_types;

        die "Can not guess object type of ". ref($self) ." required for attributes."
            ." It's possible that this class can not have attributes at all";
    },
);

use Net::Journyx::Attribute;

sub attribute {
    my $self = shift;
    my $name = shift;
    return $self->get_attribute( $name ) unless @_;
    return $self->set_attribute( $name, @_ );
}

sub load_attribute {
    my $self = shift;
    my $name = shift;

    return Net::Journyx::Attribute->new(jx => $self->jx)->load(
        object => $self,
        name   => $name,
    );
}

sub get_attribute {
    my $self = shift;
    my $name = shift;

    my $attr = $self->load_attribute($name);

    my $operation = 'getAttribute';
    die "Unable to read ". $self->jx_record_class ." attribute '$name' in Journyx. This may indicate a misconfiguration of your Journyx database."
        unless $attr->id;

    my $data_type = $attr->data_type;
    if ( $data_type eq 'NUMBER' || $data_type eq 'INTEGER') {
        $operation .= ucfirst lc $data_type;
    }

    my $response = $self->jx->soap->basic_call(
        $operation,
        object_type  => $self->object_type_for_attributes,
        object_id    => $self->id,
        id_attr_type => $attr->id,
    );
    if ( ref($response) eq 'HASH' ) {
        # special case: empty value
        unless ( exists $response->{'Result'} ) {
            warn "expected that hash will have 'Result', but got: "
                . Dumper( $response->{'Result'} );
        }
        return undef unless defined $response->{'Result'} && length $response->{'Result'};
        return $response->{'Result'};
    }
    return $response;
}

sub set_attributes {
    my $self = shift;

    my %template = (
        object_type  => $self->object_type_for_attributes,
        object_id    => $self->id,
    );

    my @calls = ();
    while ( my ($name, $value) = splice @_, 0, 2 ) {
        my $attr = blessed($name)? $name : $self->load_attribute($name);

        die "Unable to set/remove ". $self->jx_record_class ." attribute '$name' in Journyx."
            ." This may indicate a misconfiguration of your Journyx database."
                unless $attr->id;

        unless ( defined $value ) {
            push @calls, 'deleteAttribute', { %template, id_attr_type => $attr->id };
        }
        else {
            # batch API has setAttribute for any type, no need in suffix
            push @calls, 'setAttribute', {
                %template,
                id_attr_type => $attr->id,
                value        => $value,
                overwrite_existing => 1,
            };
        }
    }

    return $self->jx->soap->batch_call( @calls );
}

sub set_attribute {
    my $self = shift;
    my $name = shift;
    my $value = shift;
    return $self->del_attribute( $name, @_ )
        unless defined $value;
    my %rest = (
        overwrite_existing => 1,
        @_
    );

    my $attr = blessed($name)? $name : $self->load_attribute($name);

    my $operation = 'setAttribute';

    die "Unable to update ". $self->jx_record_class ." attribute '$name' in Journyx. This may indicate a misconfiguration of your Journyx database."
        unless $attr->id;

    my $data_type = $attr->data_type;
    if ( $data_type eq 'NUMBER' || $data_type eq 'INTEGER') {
        $operation .= ucfirst lc $data_type;
    }

    return $self->jx->soap->basic_call(
        $operation,
        %rest,
        object_type  => $self->object_type_for_attributes,
        object_id    => $self->id,
        id_attr_type => $attr->id,
        value        => $value,
    );
}

sub del_attribute {
    my $self = shift;
    my $name = shift;

    my $attr = blessed($name)? $name : $self->load_attribute($name);

    my $operation = 'deleteAttribute';

    die "Unable to remove ". $self->jx_record_class ." attribute '$name' in Journyx. This may indicate a misconfiguration of your Journyx database."
        unless $attr->id;

    return $self->jx->soap->basic_call(
        $operation,
        object_type  => $self->object_type_for_attributes,
        object_id    => $self->id,
        id_attr_type => $attr->id,
    );
}

no Moose::Role;
1;
