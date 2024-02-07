package SPVM::Eg::Node::CDATASection;



1;

=head1 Name

SPVM::Eg::Node::CDATASection - CDATASection in JavaScript

=head1 Description

The Eg::Node::CDATASection class in L<SPVM> represents a CDATA section that can be used within XML to include extended portions of unescaped text.

This class is a port of L<CDATASection|https://developer.mozilla.org/en-US/docs/Web/API/CDATASection> in JavaScript.

=head1 Usage

  my $cdata_section_node = Eg->document->create_cdata_section("Some Data");

=head1 Inheritance

L<Eg::Node::CharacterData|SPVM::Eg::Node::CharacterData>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
