package Simple::SAX::Serializer::Handler;

use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS $VERSION);
use base 'Exporter';

$VERSION = 0.02;

@EXPORT_OK = qw(array_handler array_of_objects_handler hash_handler hash_item_of_child_value_handler hash_of_object_array_handler hash_of_array_handler ignore_node_handler root_object_handler object_handler custom_array_handler);
%EXPORT_TAGS = (all => \@EXPORT_OK);


=head1 NAME

Simple::SAX::Serializer::Handler - Collections of the mapping handlers for Simple::SAX::Serializer.

=head1 SYNOPSIS

    use Simple::SAX::Serializer::Handler ':all';
    use Simple::SAX::Serializer;

    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('node', array_handler());
    ...
    my $result = $xml->parse_string($xml_content);


=head1 DESCRIPTION

Collections of the mapping handlers for Simple::SAX::Serializer.

=head1 EXPORT

array_handler
array_of_objects_handler
hash_handler
hash_item_of_child_value_handler
hash_of_object_array_handler
hash_of_array_handler
ignore_node_handler
custom_array_handler
object_handler
root_object_handler by ':all' tag

=head2 METHODS

=over

=cut

=item array_handler

Takes optionally storage key to the array(by default the element name).
Returns handler for transforming nodes value into array

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root >
        <node>value1</node>
        <node>value2</node>
        <nodeA>value1</nodeA>
        <nodeA>value2</nodeA>
    </root>
    XML


    my $xml = Simple::SAX::Serializer->new;

    $xml->handler('node', array_handler());
    $xml->handler('nodeA', array_handler());
    $xml->handler('root', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        my $result = $element->children_result;
    });
    my $result = $xml->parse_string($xml_content);
    #transforms $result to {{node => ['value1' ,'value2'], nodeA => ['value1', 'value2']}


=cut

sub array_handler {
    my ($parent_key) = @_;
    sub {
        my ($self, $element, $parent) = @_;
        my $result = $parent->children_hash_result;
        my $key = $parent_key || $element->name;
        my $array  = $result->{$key} ||= [];
        push @$array, $element->value(1);
    };
}

=item array_of_objects_handler

Returns handler for transforming nodes attribute into array of the objects.
Takes class name or constructor code reference as parameter,
array ref of the required attributes, hash_ref of the optional attributes,

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <object1 attr1="1" />
        <object1 attr1="2" />
        <object2 attr1="3" />
        <object2 attr1="4" />
    </root>
    XML

    package Object1;
    sub new {
        my $class = shift;
        bless {@_}, $class
    };

    package Object2;
    sub new {
        my $class = shift;
        bless {@_}, $class
    };

    sub object2{
        Object2->new(@_);
    }

    my $xml = Simple::SAX::Serializer->new;

    $xml->handler('object1', ::array_of_objects_handler('Object1', ['attr1']));
    $xml->handler('object2', ::array_of_objects_handler(\&object2, ['attr1']));
    $xml->handler('root', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        $element->children_result;
    });
    my $result = $xml->parse_string($xml_content);

    #transforms $result to [
        Object1->new(attr1 => 1),
        Object1->new(attr1 => 2),
        Object2->new(attr1 => 3),
        Object2->new(attr1 => 4),
    ];

=cut

sub array_of_objects_handler {
    my ($object_constructor, $required_attributes, $optional_attributes) = @_;
    my $result;
    if (ref($object_constructor) eq 'CODE') {
        $result = sub {
            my ($self, $element, $parent) = @_;
            $element->validate_attributes($required_attributes, $optional_attributes)
                if ($required_attributes || $optional_attributes);
            my $children_result = $element->children_result || {};
            my $attributes = $element->attributes;
            my $result = $parent->children_array_result;
            push @$result, $object_constructor->(%$attributes, %$children_result);
        }
    } else {
        $result = sub {
            my ($self, $element, $parent) = @_;
            $element->validate_attributes($required_attributes, $optional_attributes)
                if ($required_attributes || $optional_attributes);
            my $children_result = $element->children_result || {};
            my $attributes = $element->attributes;
            my $result = $parent->children_array_result;
            push @$result, $object_constructor->new(%$attributes, %$children_result);
        }
    }
    $result;
}



=item hash_of_object_array_handler

Returns handler for transforming nodes attribute into array of the objects, that
is stored as hash item of the parent node.
Takes class name or constructor code reference as parameter,
array ref of the required attributes, hash_ref of the optional attributes,
storage key to the array(by default the element name).

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <object1 attr1="1" />
        <object1 attr1="2" />
    </root>
    XML

    my $xml = Simple::SAX::Serializer->new;

    $xml->handler('object1', hash_of_object_array_handler('Object1', ['attr1']));
    $xml->handler('root', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        $element->children_result;
    });
    my $result = $xml->parse_string($xml_content);

    #transforms $result to [
        Object1->new(attr1 => 1),
        Object1->new(attr1 => 2),
        Object2->new(attr1 => 3),
        Object2->new(attr1 => 4),
    ];

=cut

sub hash_of_object_array_handler {
    my ($object_constructor, $required_attributes, $optional_attributes, $parent_key) = @_;
    my $result;
    if (ref($object_constructor) eq 'CODE') {
        $result = sub {
            my ($self, $element, $parent) = @_;
            $element->validate_attributes($required_attributes, $optional_attributes)
                if ($required_attributes || $optional_attributes);
            my $children_result = $element->children_result || {};
            my $attributes = $element->attributes;
            my $result = $parent->children_hash_result;
            my $key = $parent_key || $element->name;
            my $array = $result->{$key} ||= [];
            push @$array, $object_constructor->(%$attributes, %$children_result);
        }
    } else {
        $result = sub {
            my ($self, $element, $parent) = @_;
            $element->validate_attributes($required_attributes, $optional_attributes)
                if ($required_attributes || $optional_attributes);
            my $children_result = $element->children_result || {};
            my $attributes = $element->attributes;
            my $result = $parent->children_hash_result;
            my $key = $parent_key || $element->name;
            my $array = $result->{$key} ||= [];
            push @$array, $object_constructor->new(%$attributes, %$children_result);
        }
    }
    $result;
}


=item hash_of_array_handler

Returns handler for transforming nodes attribute into array of the hash items, that
is stored as hash item of the parent node.
Takes array ref of the required attributes, hash_ref of the optional attributes,
storage key to the array(by default the element name).

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <object1 attr1="1" />
        <object1 attr1="2" />
    </root>
    XML

    my $xml = Simple::SAX::Serializer->new;

    $xml->handler('object1', hash_of_array_handler(['attr1']));
    $xml->handler('root', root_object_handler('Root'));

    my $result = $xml->parse_string($xml_content);
    #converts result to 
    Root->new(object1 => [{attr1 => 1}, {attr1 => 2}]);

=cut

sub hash_of_array_handler {
    my ($required_attributes, $optional_attributes, $parent_key) = @_;
    sub {
        my ($self, $element, $parent) = @_;
        $element->validate_attributes($required_attributes, $optional_attributes)
            if ($required_attributes || $optional_attributes);
        my $children_result = $element->children_result || {};
        my $attributes = $element->attributes;
        my $result = $parent->children_hash_result;
        my $key = $parent_key || $element->name;
        my $array = $result->{$key} ||= [];
        push @$array, {%$attributes, %$children_result};
    }
}


=item hash_handler

Takes optionally parent storage key to the hash item (by default the element name).
optionally attribute name for the hash key (by default name).
Returns handler for transforming node into hash item.
Key of the hash is evaluated from the name node's attribute.
Value of the hash is evaluated from the node's value.

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <node name="key1">value1</node>
        <node name="key2">value2</node>
        <node name="key3">value3</node>
    </root>
    XML

    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('node', hash_handler());
    $xml->handler('root', root_object_handler('Root'));
    my $result = $xml->parse_string($xml_content);

    #transforms $result to Root->new(node => {key1 => 'value1', key2 => 'value2', key3 => 'value3'})

=cut

sub hash_handler {
    my ($parent_key, $hash_key_attribute) = @_;
    sub {
        my ($self, $element, $parent) = @_;
        my $hash_key = $hash_key_attribute || 'name';
        $element->validate_attributes([$hash_key]);
        my $attributes = $element->attributes;
        my $result = $parent->children_hash_result;
        my $key = $parent_key || $element->name;
        my $hash = $result->{$key} ||= {};
        $hash->{$attributes->{$hash_key}} = $element->value(1);
    };
};


=item hash_item_of_child_value_handler

Takes optionally parent storage key to the hash item (by default the element name).
Returns handler for transforming child node value into hash value
Key of the hash is evaluated from current element name.


    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <objects>
            <object1 attr1="1" />
            <object1 attr1="2" />
        </objects>
        <objects2>
            <object2 attr1="3" />
            <object2 attr1="4" />
        </objects2>
    </root>
    XML

    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('objects', hash_item_of_child_value_handler());
    $xml->handler('object1', array_of_objects_handler('Object1'));

    $xml->handler('objects2', hash_item_of_child_value_handler());
    $xml->handler('object2', array_of_objects_handler('Object2'));
    $xml->handler('root', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        $element->children_result;
    });
    my $result = $xml->parse_string($xml_content);
    #transforms $result to {
        objects => [Object1->new(attr1 => 1), Object1->new(attr1 => 2),],
        objects2 => [Object2->new(attr1 => 3), Object2->new(attr1 => 4),]
    };

=cut


sub hash_item_of_child_value_handler {
    my ($parent_key) = @_;
    sub {
        my ($self, $element, $parent) = @_;
        my $columns = $element->children_result;
        my $result = $parent->children_hash_result;
        my $key = $parent_key || $element->name;
        $result->{$key} =  $columns;
    }
}


=item root_object_handler

Returns handler for transforming root node into an object,

Takes class name or constructor code reference, optionally code reference to customize return values,
array ref of the required attributes, hash_ref of the optional attributes,

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root attr1="1" attr2="2">
        <objects>
            <object1 attr1="1" />
            <object1 attr1="2" />
        </objects>
        <object2>3</object2>
        <object2>4</object2>

    </root>
    XML

    {
        package Root;
        sub new {
            my $class = shift;
            bless {@_}, $class
        };
    }

    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('objects', hash_item_of_child_value_handler());
    $xml->handler('object1', array_of_objects_handler('Object1'));
    $xml->handler('object2', array_handler());
    $xml->handler('root', root_object_handler('Root'));

    #transforms $result to 
    Root->new(
        attr1 => 1, attr2 => 2,
        objects => [Object1->new(attr1 => 1), Object1->new(attr1 => 2),],
        object2 => [3, 4]
    );

=cut

sub root_object_handler {
    my ($object_constructor, $code, $required_attributes, $optional_attributes) = @_;
    my $result;
    if (ref($object_constructor) eq 'CODE') {
        $result = sub {
            my ($self, $element, $parent) = @_;
            my $args = $self->root_args;
            $element->validate_attributes($required_attributes, $optional_attributes)
                if ($required_attributes || $optional_attributes);
            my $attributes = $element->attributes;
            my $children_result = $element->children_result || {};
            my $result = $object_constructor->(
                    %$attributes,
                    %$children_result,
                    %$args
                );
            $code ? $code->($result) : $result;
        }
    } else {
        $result = sub {
            my ($self, $element, $parent) = @_;
            my $args = $self->root_args;
            $element->validate_attributes($required_attributes, $optional_attributes)
                if ($required_attributes || $optional_attributes);
            my $attributes = $element->attributes;
            my $children_result = $element->children_result || {};
            my $result = $object_constructor->new(
                %$attributes,
                %$children_result,
                %$args
            );
            $code ? $code->($result) : $result;
        }
    }
    $result;
}


=item ignore_node_handler

=cut

sub ignore_node_handler {
    sub {
        my ($self, $element, $parent) = @_;
    };
}


=item custom_array_handler

Returns handler for transforming roo node to object,
Takes hash ref as custom result storage, optionally array ref of the required attributes, hash_ref of the optional attributes,
custom storage key to the hash item (by default the element name).
This options allows parsing only part of the xml document.

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <node name="key1" attr1="1" />
        <node name="key2" attr1="2" />
    </root>
    XML


    my $result = {};
    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('root', ignore_node_handler());
    $xml->handler('node', custom_array_handler($result, ['name', 'attr1'], {optional_attr1 => undef, attr2 => '2'}, 'my_key'));

    #or without attributes validation
    $xml->handler('node', custom_array_handler($result, undef, undef, 'my_key'));

    $xml->parse_string($xml_content);

    #transforms $result to ,{ my_key => [
        {name => 'key1', attr1 => '1', optional_attr1 => undef, attr2 => 2},
        {name => 'key2', attr1 => '2', optional_attr1 => undef, attr2 => 2}
        ]
    };

=cut

sub custom_array_handler {
    my ($custom_storage, $required_attributes, $optional_attributes, $storage_key) = @_;
    sub {
        my ($this, $element, $parent) = @_;
        $element->validate_attributes($required_attributes, $optional_attributes)
            if ($required_attributes || $optional_attributes);
        my $attributes = $element->attributes;
        my $children_result = $element->children_result || {};
        my $key = $storage_key || $element->name;
        my $array = $custom_storage->{$key} ||= [];
        push @$array, {%$attributes, %$children_result};
    }
}


=item object_handler

Returns handler for transforming node into an object,
Takes class name or constructor code reference, optionally array ref of the required attributes, hash_ref of the optional attributes,
parent storage key to the hash item (by default the element name).

    my $xml_content = <<XML;
    <?xml version="1.0"?>
    <root>
        <object1 attr1="1" />
        <object1 attr1="2" />
    </root>
    XML

    my $xml = Simple::SAX::Serializer->new;

    $xml->handler('object1', hash_of_object_array_handler('Object1', ['attr1']));
    $xml->handler('root', root_object_handler('Root'));

    my $result = $xml->parse_string($xml_content);
    #transforms result to 
    Root->new(object1 => [Object1->new(attr1 => 1),Object1->new(attr1 => 2)]);

=cut

sub object_handler {
    my ($object_constructor, $required_attributes, $optional_attributes, $parent_key) = @_;
    my $result;
    if (ref($object_constructor) eq 'CODE') {
        $result = sub {
            my ($self, $element, $parent) = @_;
            my $children_result = $element->children_result || {};
            my $attributes = $element->attributes;
            my $result = $parent->children_hash_result;
            my $key = $parent_key || $element->name;
            $result->{$key} = $object_constructor->(%$attributes, %$children_result);
        }
    } else {
        $result = sub {
            my ($self, $element, $parent) = @_;
            my $children_result = $element->children_result || {};
            my $attributes = $element->attributes;
            my $result = $parent->children_hash_result;
            my $key = $parent_key || $element->name;
            $result->{$key} = $object_constructor->new(%$attributes, %$children_result);
        }
    }
    $result;
}

1;


__END__

=back

=head1 SEE ALSO

L<Simple::SAX::Serializer::Element>

=head1 COPYRIGHT AND LICENSE

The Simple::SAX::Serializer::Handler module is free software. You may distribute under the terms of
either the GNU General Public License or the Artistic License, as specified in
the Perl README file.

=head1 AUTHOR

Adrian Witas, adrian@webapp.strefa.pl

=cut

1;
