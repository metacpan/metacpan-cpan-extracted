package SPVM::Eg::Node::Element;



1;

=head1 Name

SPVM::Eg::Node::Element - Element in JavaScript.

=head1 Description

The Eg::Node::Element class in L<SPVM> is the most general base class from which all element objects.

This class is a port of L<Element|https://developer.mozilla.org/en-US/docs/Web/API/Element> in JavaScript.

=head1 Usage

  use Eg::Node::Element;
  
  my $xml_document = Eg->document->implementation->create_document(
    "http://www.w3.org/1999/xhtml",
    "html",
  );
  
  my $element = $xml_document->create_element("div");

=head1 Inheritance

L<Eg::Node|SPVM::Eg::Node>

=head1 Fields

=head2 namespace_uri

C<has namespace_uri : ro protected string;>

The namespace URI of the element.

For details, see L<Element.namespaceURI|https://developer.mozilla.org/en-US/docs/Web/API/Element/namespaceURI> in JavaScript.

=head1 Instance Methods

=head2 get_attribute

C<method get_attribute : string ($name : string);>

Returns the value of a specified attribute on the element.

For details, see L<Element.getAttribute|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttribute> in JavaScript.

=head2 set_attribute

C<method set_attribute : void ($name : string, $value : string);>

Sets the value of an attribute on the specified element.

For details, see L<Element.setAttribute|https://developer.mozilla.org/en-US/docs/Web/API/Element/setAttribute> in JavaScript.

=head2 remove_attribute

C<method remove_attribute : void ($name : string);>

Removes the attribute with the specified name from the element.

For details, see L<Element.removeAttribute|https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute> in JavaScript.

=head2 has_attribute

C<method has_attribute : int ($name : string);>

Returns a boolean value indicating whether the specified element has the specified attribute or not.

For details, see L<Element.hasAttribute|https://developer.mozilla.org/en-US/docs/Web/API/Element/hasAttribute> in JavaScript.

=head2 get_attribute_names

C<method get_attribute_names : string[] ();>

Returns the attribute names of the element as an array of strings.

For details, see L<Element.getAttributeNames|https://developer.mozilla.org/en-US/docs/Web/API/Element/getAttributeNames> in JavaScript.

=head2 tag_name

C<method tag_name : string ();>

Returns the tag name of the element on which it's called.

For details, see L<Element.tagName|https://developer.mozilla.org/en-US/docs/Web/API/Element/tagName> in JavaScript.

=head1 Well Known Classes

=over 2

L<Eg::Node::Element::HTML|SPVM::Eg::Node::Element::HTML>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

