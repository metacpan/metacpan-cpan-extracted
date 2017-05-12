use strict;
use warnings;
use Cwd;

use Test::More tests => 11;
my $class;

BEGIN{
    $class = 'Simple::SAX::Serializer::Handler';
    use_ok($class, ':all');
    use_ok('Simple::SAX::Serializer');
}




{
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
    
    $xml->handler('node', &array_handler);
    $xml->handler('nodeA', &array_handler);
    $xml->handler('root', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        $element->children_result;
    });
    my $result = $xml->parse_string($xml_content);
    is_deeply($result, {node => ['value1' ,'value2'], nodeA => ['value1', 'value2']}, 'should get array values');
}


{
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
    
    $xml->handler('object1', ::array_of_objects_handler('Object1'));
    $xml->handler('object2', ::array_of_objects_handler(\&object2));
    $xml->handler('root', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        $element->children_result;
    });
    my $result = $xml->parse_string($xml_content);
    ::is_deeply($result, [
        Object1->new(attr1 => 1),
        Object1->new(attr1 => 2),
        Object2->new(attr1 => 3),
        Object2->new(attr1 => 4),
    ], 'should get array of objects');
}

{
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
    ::is_deeply($result, {
        objects => [Object1->new(attr1 => 1), Object1->new(attr1 => 2),],
        objects2 => [Object2->new(attr1 => 3), Object2->new(attr1 => 4),]
    }, 'should have  hash item of child value');
}


{
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
    
    my $result = $xml->parse_string($xml_content);
    ::is_deeply($result, Root->new(
        attr1 => 1, attr2 => 2,
        objects => [Object1->new(attr1 => 1), Object1->new(attr1 => 2),],
        object2 => [3, 4]
    ), 'should have  hash item of child value');
}

{
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
    is_deeply($result, Root->new(node => {key1 => 'value1', key2 => 'value2', key3 => 'value3'}), 'should have hash value');
}


{
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
    $xml->parse_string($xml_content);
    is_deeply($result,{my_key => [
        {name => 'key1', attr1 => '1', optional_attr1 => undef, attr2 => 2},
        {name => 'key2', attr1 => '2', optional_attr1 => undef, attr2 => 2}
        ]
    }, 'should have custom array value');
}




{
my $xml_content = <<XML;
<?xml version="1.0"?>
<root>
    <object1 attr1="1" />
</root>
XML

    my $xml = Simple::SAX::Serializer->new;
    $xml->handler('root', root_object_handler('Root'));
    $xml->handler('object1', object_handler('Object1', undef, undef, 'my_key'));
    my $result = $xml->parse_string($xml_content);
    is_deeply($result, Root->new(my_key => Object1->new(attr1 => 1)), 'should have object value');
}


{
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
    is_deeply($result, Root->new(object1 => [Object1->new(attr1 => 1),Object1->new(attr1 => 2)]), 'should have hash_of_object_array_handler');
}


{
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
    is_deeply($result, Root->new(object1 => [{attr1 => 1}, {attr1 => 2}]), 'should have hash_of_object_array_handler');
}

