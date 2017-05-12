use strict;
use warnings;
use Cwd;

use Test::More tests => 19;
my $class;

BEGIN{
    $class = 'Simple::SAX::Serializer';
    use_ok($class);
}


my $xml_content = <<XML;
<?xml version="1.0"?>
<root xmlns:lm="http://www.webapp.strefa.pl/layout_manager" attr1="1">
 <child attr="1"  />
 <child attr="2" lm:grid_with="3" >
    <child_a id="1" />
    <child_a id="2" />
 </child>
 <child attr="3" lm:grid_with="2" />
 <element attr="3" lm:grid_with="2" />
</root>
XML

{
    package Root;
    use Abstract::Meta::Class ':all';
    has '$.children';
    has '$.lm';
}


{
    package ChildA;
    use Abstract::Meta::Class ':all';
    has '$.id';
    
}

{
    package Child;
    use Abstract::Meta::Class ':all';
    has '$.attr';
    has '$.grid_with';
    has '@.children_a';
}

{

    my $xml = $class->new;
    isa_ok($xml, $class);
    
    
    $xml->handler('child_a', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        my $children_result = $parent->children_array_result;
        my $result = $parent->children_result;
        push @$children_result, ChildA->new(%$attributes);
    });
    
    $xml->handler('root/child', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        my $children_a = $element->children_result;
        my $children_result = $parent->children_hash_result;
    
        my $result = $children_result->{child} ||= [];
        push @$result, Child->new(
            ($children_a ? (children_a => $children_a) : ()),
            attr      => $attributes->{attr},
            grid_with => $attributes->{_lm}->{grid_with},
        );
    });
    
    $xml->handler('root', sub {
        my ($self, $element) = @_;
        $element->validate_attributes(["attr1"], {attr2 => 1});
        my $attributes = $element->attributes;
        my $children_result = $element->children_result;
        Root->new(
          lm       => $attributes->{_xmlns}->{lm},
          children => $children_result->{child}
        )
    });
    
    
    eval {
        $xml->parse('string', $xml_content);
    };
    like($@, qr{missing handler for root/elemen}, 'should catch missing handler');
    $xml->handler('element', sub {});
    
    
    my $root = $xml->parse('string', $xml_content);
    is($root->lm, 'http://www.webapp.strefa.pl/layout_manager', 'should have lm');
    my $children = $root->children;
    is(@$children, 3, 'should have 3 children');
    ok($children->[0], 'should have child 1');
    is($children->[0]->attr, 1, 'should have attr');
    ok($children->[1], 'should have child 2');
    is($children->[1]->attr, 2,  'should have attr');
    my $children_a = $children->[1]->children_a;
    is(@$children_a, 2, 'should have 2 ChildA object');
    is($children_a->[0]->id, 1, 'should have id 1');
    is($children_a->[1]->id, 2, 'should have id 2');
    ok($children->[2], 'should have child 3');
    is($children->[2]->attr, 3,  'should have attr');
    
    my $froot = $xml->parse('file', "t/xml/test.xml");
    isa_ok($froot, 'Root');

}



{
    
    my $xml_content = <<XML;
<?xml version="1.0"?>
<root attr1="1">
 <child attr="1"  />
 <child attr="2" grid_with="3" />
 <element attr="3" grid_with="2" />
</root>
XML
    my $xml = $class->new;
    isa_ok($xml, $class);

    $xml->handler('*', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        my $children_result = $parent->children_array_result;
        push @$children_result, $element->name, [%$attributes];
    });

    $xml->handler('root', sub {
        my ($self, $element) = @_;
        $element->validate_attributes(["attr1"], {attr2 => 1});
        my $attributes = $element->attributes;
        my $children_result = $element->children_result;
        [prop => $attributes,
         children => $children_result];
    });

    my $root = $xml->parse('string', $xml_content);
    is_deeply($root, [
        prop     => {attr2 => 1, attr1 => '1'},
        children => [
            child => [attr => 1],
            child => [grid_with => 3, attr => 2],
            element => [grid_with => 2, attr => 3]]
        ], 'should have serialzed data structure');
}



#root args

{
    
    my $xml_content = <<XML;
<?xml version="1.0"?>
<root attr1="1">
 <child attr="1"  />
</root>
XML

    my $xml = $class->new;
    isa_ok($xml, $class);

    $xml->handler('*', sub {
        my ($self, $element, $parent) = @_;
        my $attributes = $element->attributes;
        my $children_result = $parent->children_array_result;
        push @$children_result, $element->name, [%$attributes];
    });

    $xml->handler('root', sub {
        my ($self, $element) = @_;
        $element->validate_attributes(["attr1"], {attr2 => 1});
        my $attributes = $element->attributes;
        my $children_result = $element->children_result;
        my $args = $self->root_args;
        {
         prop => $attributes,
         children => $children_result,
         %$args
        };
    });

    my $result = $xml->parse('string', $xml_content, {root_param1 => 1, root_param2 => 2});
    is_deeply($result, {
        prop => { 'attr2' => 1, 'attr1' => '1' },
        children => [ 'child', [ 'attr', '1' ]],
        root_param1 => 1,
        root_param2 => 2,}, 'should have root args'
    );
    

}
