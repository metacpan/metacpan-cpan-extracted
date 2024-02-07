package SPVM::Eg::Node::Comment;



1;

=head1 Name

SPVM::Eg::Node::Comment - Comment in JavaScript

=head1 Description

The Eg::Node::Comment class in L<SPVM> represents textual notations within markup.

This class is a port of L<Comment|https://developer.mozilla.org/en-US/docs/Web/API/Comment> in JavaScript.

=head1 Usage

  my $comment_node = Eg->document->create_comment("Comment");

=head1 Inheritance

L<Eg::Node::CharacterData|SPVM::Eg::Node::CharacterData>

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License
