package SPVM::Eg::Node::Text;



1;

=head1 Name

SPVM::Eg::Node::Text - Text in JavaScript

=head1 Description

The Eg::Node::Text class in L<SPVM> represents a text node in a DOM tree.

This class is a port of L<Text|https://developer.mozilla.org/en-US/docs/Web/API/Text> in JavaScript.

=head1 Usage

  my $text_node = Eg->document->create_text_node("Hello World!");

=head1 Inheritance

L<Eg::Node::CharacterData|SPVM::Eg::Node::CharacterData>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
