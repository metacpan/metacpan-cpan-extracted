package SPVM::Eg::DOM::Implementation;



1;

=head1 Name

SPVM::Eg::DOM::Implementation - DOMImplementation in JavaScript

=head1 Description

The Eg::DOM::Implementation class in L<SPVM> represents an object providing methods which are not dependent on any particular document.

This class is a port of L<DOMImplementation|https://developer.mozilla.org/ja/docs/Web/API/DOMImplementation> in JavaScript.

=head1 Usage

  my $xml_document = Eg->document->implementation->create_document("http://www.w3.org/1999/xhtml", "html");
  
  my $html_document = Eg->document->implementation->create_html_document("Title");

=head1 Instance Methods

=head2 create_document

C<method create_document : L<Eg::Node::Document::XML|SPVM::Eg::Node::Document::XML> ($namespace_uri : string, $qualified_name_str : string, $document_type : L<Eg::Node::DocumentType|SPVM::Eg::Node::DocumentType> = undef);>

Creates and returns an L<Eg::Node::Document::XML|SPVM::Eg::Node::Document::XML>.

For details, see L<DOMImplementation.createDocument|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocument> in JavaScript.

=head2 create_document_type

  method create_document_type : L<Eg::Node::DocumentType|SPVM::Eg::Node::DocumentType> ($qualified_name_str : string, $public_id : string, $system_id : string);

Creates and returns a L<Eg::Node::DocumentType|SPVM::Eg::Node::DocumentType> object. 

For details, see L<DOMImplementation.createDocumentType|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createDocumentType> in JavaScript.

=head2 create_html_document

  method create_html_document : L<Eg::Node::Document|SPVM::Eg::Node::Document> ($title : string = undef);

Creates and returns a new L<Eg::Node::Document|SPVM::Eg::Node::Document> object.

For details, see L<DOMImplementation.createHTMLDocument|https://developer.mozilla.org/en-US/docs/Web/API/DOMImplementation/createHTMLDocument> in JavaScript.

=head1 Related Classes

=over 2

=item * L<Eg::Node::Document::XML|SPVM::Eg::Node::Document::XML>

=item * L<Eg::Node::Document|SPVM::Eg::Node::Document>

=item * L<Eg::Node::Document|SPVM::Eg::Node::Document>

=item * L<Eg::Node::DocumentType|SPVM::Eg::Node::DocumentType>

=back

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

