package SPVM::Eg::Node::Document;



1;

=head1 Name

SPVM::Eg::Node::Document - Document in JavaScript

=head1 Description

The Eg::Node::Document class in L<SPVM> represents any XML/HTML page which is the DOM tree. This class itself is an abstruct class.

This class is a port of L<Document|https://developer.mozilla.org/en-US/docs/Web/API/Document> in JavaScript.

=head1 Usage

  my $html_document = Eg->document->implementation->create_html_document("Title");
  
  my $xml_document = Eg->document->implementation->create_document(
    "http://www.w3.org/1999/xhtml",
    "html",
  );

=head1 Inheritance

L<Eg::Node|SPVM::Eg::Node>

=head1 Fields

=head2 doctype

C<has doctype : ro protected L<Eg::Node::DocumentType|SPVM::Eg::Node::DocumentType>>;

The Document Type Declaration (DTD) associated with current document.

For details, see L<Document.doctype|https://developer.mozilla.org/en-US/docs/Web/API/Document/doctype> in JavaScript.

=head2 implementation

C<has implementation : ro L<Eg::DOM::Implementation|SPVM::Eg::DOM::Implementation>>;

An L<Eg::DOM::Implementation|SPVM::Eg::DOM::Implementation> object associated with the current document.

For details, see L<Document.implementation|https://developer.mozilla.org/en-US/docs/Web/API/Document/implementation> in JavaScript.

=head1 Instance Methods

=head2 title

C<method title : string ();>

Sets the current title of the document.

For details, see L<Document.title|https://developer.mozilla.org/en-US/docs/Web/API/Document/title> in JavaScript.

=head2 set_title

C<method set_title : string ($title : string);>

Returns the current title of the document.

For details, see L<Document.title|https://developer.mozilla.org/en-US/docs/Web/API/Document/title> in JavaScript.

=head2 create_element

C<method create_element : L<Eg::Node::Element|SPVM::Eg::Node::Element> ($tag_name : string);>

In an HTML document, this method creates the HTML element specified by $tag_name, or an L<Eg::Node::Element::HTML::Unknown|SPVM::Eg::Node::Element::HTML::Unknown> if $tag_name isn't recognized.

For details, see L<Document.createElement|https://developer.mozilla.org/en-US/docs/Web/API/Document/createElement> in JavaScript.

=head2 create_text_node

C<method create_text_node : L<Eg::Node::Text|SPVM::Eg::Node::Text> ($node_value : string);>

Creates and returns a new Text node.

For details, see L<Document.createTextNode|https://developer.mozilla.org/en-US/docs/Web/API/Document/createTextNode> in JavaScript.

=head2 create_comment

C<method create_comment : L<Eg::Node::Comment|SPVM::Eg::Node::Comment> ($node_value : string);>

Creates a new comment node, and returns it.

For details, see L<Document.createComment|https://developer.mozilla.org/en-US/docs/Web/API/Document/createComment> in JavaScript.

=head2 create_cdata_section

C<method create_cdata_section : L<Eg::Node::CDATASection|SPVM::Eg::Node::CDATASection> ($node_value : string);>

Creates a new CDATA section node, and returns it.

For details, see L<Document.createCDATASection|https://developer.mozilla.org/en-US/docs/Web/API/Document/createCDATASection> in JavaScript.

=head2 create_document_fragment

C<method create_document_fragment : L<Eg::Node::DocumentFragment|SPVM::Eg::Node::DocumentFragment> ();>

Creates a new empty DocumentFragment into which DOM nodes can be added to build an offscreen DOM tree.

For details, see L<Document.createDocumentFragment|https://developer.mozilla.org/en-US/docs/Web/API/Document/createDocumentFragment> in JavaScript.

=head2 create_attribute

C<method create_attribute : L<Eg::Node::Attr|SPVM::Eg::Node::Attr> ($name : string);>

Creates a new attribute node, and returns it.

For details, see L<Document.createAttribute|https://developer.mozilla.org/en-US/docs/Web/API/Document/createAttribute> in JavaScript.

=head2 create_attribute_ns

C<method create_attribute_ns : L<Eg::Node::Attr|SPVM::Eg::Node::Attr> ($namespace_uri : string, $qualified_name : string);>

Creates a new attribute node with the specified namespace URI and qualified name, and returns it.

For details, see L<Document.createAttributeNS|https://developer.mozilla.org/en-US/docs/Web/API/Document/createAttributeNS> in JavaScript.

=head2 create_processing_instruction

C<method create_processing_instruction : L<Eg::Node::ProcessingInstruction|SPVM::Eg::Node::ProcessingInstruction> ($target : string, $data : string);>

Generates a new processing instruction node and returns it.

For details, see L<Document.createProcessingInstruction|https://developer.mozilla.org/en-US/docs/Web/API/Document/createProcessingInstruction> in JavaScript.

=head2 document_element

C<method document_element : L<Eg::Node::Element|SPVM::Eg::Node::Element> ();>

Returns the element that is the root element of the document (for example, the <html> element for HTML documents).

For details, see L<Document.documentElement|https://developer.mozilla.org/en-US/docs/Web/API/Document/documentElement> in JavaScript.

=head2 head

C<method head : L<Eg::Node::Element|SPVM::Eg::Node::Element> ();>

Returns the head element of the current document.

For details, see L<Document.head|https://developer.mozilla.org/en-US/docs/Web/API/Document/head> in JavaScript.

=head2 body

C<method body : L<Eg::Node::Element|SPVM::Eg::Node::Element> ();>

Returns the <body> or <frameset> node of the current document, or undef if no such element exists.

For details, see L<Document.body|https://developer.mozilla.org/en-US/docs/Web/API/Document/body> in JavaScript.

=head1 Well Known Child Classes

=over 2

=item * L<Eg::Node::Document|SPVM::Eg::Node::Document>

=item * L<Eg::Node::Document::XML|SPVM::Eg::Node::Document::XML>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

