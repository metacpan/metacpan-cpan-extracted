package SPVM::Eg::Node::DocumentType;



1;

=head1 Name

SPVM::Eg::Node::DocumentType - DocumentType in JavaScript

=head1 Description

The Eg::Node::DocumentType class in L<SPVM> represents a node containing a doctype.

This class is a port of L<DocumentType|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType> in JavaScript.

=head1 Usage

  my $dt = Eg->document->implementation->create_document_type(
    "svg:svg",
    "-//W3C//DTD SVG 1.1//EN",
    "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd",
  );
  
  my $name = $dt->name;

=head1 Inheritance

L<Eg::Node|SPVM::Eg::Node>

=head1 Fields

=head2 name

C<has name : ro string;>

Retunrs the type of the document.

For details, see L<DocumentType.name|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/name> in JavaScript.

=head2 public_id

C<has public_id : ro string;>

Retunrs a formal identifier of the document.

For details, see L<DocumentType.publicId|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/publicId> in JavaScript.

=head2 system_id

C<has system_id : ro string;>

Retunrs the URL of the associated DTD.

For details, see L<DocumentType.systemId|https://developer.mozilla.org/en-US/docs/Web/API/DocumentType/systemId> in JavaScript.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

