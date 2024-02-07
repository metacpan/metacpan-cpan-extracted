package SPVM::Eg::Node::Attr;



1;

=head1 Name

SPVM::Eg::Node::Attr - Attr in JavaScript

=head1 Description

The Eg::Node::Attr class in L<SPVM> represents one of an element's attributes as an object.

This class is a port of L<Attr|https://developer.mozilla.org/en-US/docs/Web/API/Attr> in JavaScript.

=head1 Usage

  my $attr = Eg->document->create_attribute("class");
  
  my $attr = Eg->document->create_attribute_ns(
    "http://www.mozilla.org/ns/specialspace",
    "class"
  );
  
  my $name = $attr->name;
  
  my $value = $attr->value;
  
  my $namespace_uri = $attr->namespace_uri;

=head1 Inheritance

L<Eg::Node|SPVM::Eg::Node>

=head1 Fields

=head2 name

C<has name : ro string;>

Returns the qualified name of an attribute.

For details, see L<Attr.name|https://developer.mozilla.org/en-US/docs/Web/API/Attr/name> in JavaScript.

=head2 value

C<has value : ro string;>

C<method set_value : void ($value : string);>

Returns and sets the value of the attribute.

For details, see L<Attr.value|https://developer.mozilla.org/en-US/docs/Web/API/Attr/value> in JavaScript.

=head2 namespace_uri

C<has namespace_uri : ro string;>

Returns the namespace URI of the attribute.

For details, see L<Attr.namespaceURI|https://developer.mozilla.org/en-US/docs/Web/API/Attr/namespaceURI> in JavaScript.

=head2 owner_element

C<has owner_element : ro L<Eg::Node::Element|SPVM::Eg::Node::Element>;>

Returns the Element the attribute belongs to.

For details, see L<Attr.ownerElement|https://developer.mozilla.org/en-US/docs/Web/API/Attr/ownerElement> in JavaScript.

=head1 Instance Method

=head2 local_name

  method local_name : string ();

Returns the local part of the qualified name of an attribute.

For details, see L<Attr.localName|https://developer.mozilla.org/en-US/docs/Web/API/Attr/localName> in JavaScript.

=head2 prefix

  method prefix : string ();

Returns the namespace prefix of the attribute.

For details, see L<Attr.prefix|https://developer.mozilla.org/en-US/docs/Web/API/Attr/prefix> in JavaScript.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
