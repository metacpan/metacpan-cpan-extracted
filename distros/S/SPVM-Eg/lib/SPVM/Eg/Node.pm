package SPVM::Eg::Node;



1;

=head1 Name

SPVM::Eg::Node - HTML Nodes, Attributes, Node::Text.

=head1 Description

The Eg::Node class in L<SPVM> has methods to manipulate HTML nodes, attributes, text.

=head1 Usage

  use Eg::Node;
  
  {
    my $text = Eg->text("foo");
    
    my $text_string = $text->text->to_string
  }
  
  {
    my $ul = Eg->ul(
      [
        Eg->li([Eg->text("1")]),
        Eg->li([Eg->text("2")]),
        Eg->li([Eg->text("3")]),
      ],
      {class => "foo bar", id => "foo", style => "color:red"}
    );
    
    # 1
    my $li1 = $ul->nodes->get(0)->(Eg::Node);
    my $text_string1 = $li1->nodes->get(0)->(Eg::Node)->text->to_string;
    
    # 2
    my $li2 = $ul->nodes->get(1)->(Eg::Node);
    my $text_string2 = $li2->nodes->get(0)->(Eg::Node)->text->to_string;
    
    # color:red
    my $attr = $div->attributes->get_string("style")
  }

=head1 Enumerations

=head2 Type Constant Values

The constant values for the L</"type"> field.

  enum {
    TYPE_ELEMENT_NODE = 1,
    TYPE_ATTRIBUTE_NODE = 2,
    TYPE_TEXT_NODE = 3,
    TYPE_CDATA_SECTION_NODE = 4,
    TYPE_PROCESSING_INSTRUCTION_NODE = 7,
    TYPE_COMMENT_NODE = 8,
    TYPE_DOCUMENT_NODE = 9,
    TYPE_DOCUMENT_TYPE_NODE = 10,
    TYPE_DOCUMENT_FRAGMENT_NODE = 11,
  }

=head1 Fields

  has type : ro int;
  
  has child_nodes_list : ro List of Eg::Node;
  
  has attributes_h : ro Hash of string;
  
  has styles_h : ro Hash of string;
  
  has tag_name : ro string;
  
  has value_buffer : ro StringBuffer;
  
  has parent : ro Eg::Node;
  
=head1 Class Methods

  static method new : Eg::Node ($type : int, $child_nodes : Eg::Node[] = undef);
  
  static method new_document : Eg::Node ($root_node : Eg::Node);
  
  static method new_element : Eg::Node ($tag_name : string, $attribute_pairs : object[] = undef, $child_nodes : Eg::Node[] = undef);
  
  static method new_text : Eg::Node ($text : string);

=head1 Instance Methods

  method css : string ($name : string);
  
  method set_css : void ($name : string, $value : string);
  
  method attr : string ($name : string);
  
  method set_attr : void ($name : string, $value : string);
  
  method text : string ();
  
  method set_text : string ($text : string);

  method attr : string ($name : string);
  
  method set_attr : void ($name : string, $value : string);
  
  method exists_attr : int ($name : string);
  
  method remove_attr : void ($name : string);
  
  method attribute_pairs : string[] ();
  
  method css : string ($name : string);
  
  method set_css : void ($name : string, $value : string);
  
  method exists_css : int ($name : string);
  
  method remove_css : void ($name : string);
  
  method style_pairs : string[] ();
  
=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

