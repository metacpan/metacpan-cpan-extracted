package SPVM::Eg::Node::Document::XML;



1;

=head1 Name

SPVM::Eg::Node::Document::XML - XMLDocument in JavaScript

=head1 Description

The Eg::Node::Document::XML class in L<SPVM> represents an XML document.

This class is a port of L<XMLDocument|https://developer.mozilla.org/en-US/docs/Web/API/XMLDocument> in JavaScript.

=head1 Usage

  my $xml_document = Eg->document->implementation->create_document(
    "http://www.w3.org/1999/xhtml",
    "html",
  );
  
  my $element = $xml_document->create_element("div");

=head1 Inheritance

L<Eg::Node::Document|SPVM::Eg::Node::Document>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

