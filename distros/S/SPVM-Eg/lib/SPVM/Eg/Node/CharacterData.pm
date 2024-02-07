package SPVM::Eg::Node::CharacterData;



1;

=head1 Name

SPVM::Eg::Node::CharacterData - CharacterData in JavaScript

=head1 Description

The Eg::Node::CharacterData class in L<SPVM> represents a Node object that contains characters. This is an abstract class.

This class is a port of L<CharacterData|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData> in JavaScript.

=head1 Instance Methods

=head1 Inheritance

L<Eg::Node|SPVM::Eg::Node>

=head2 data

C<method data : string ();>

Returns the value of the current object's data.

For details, see L<CharacterData.data|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/data> in JavaScript.

=head2 length

C<method length : int ();>

Returns the number of characters in the contained data, as a positive integer.

For details, see L<CharacterData.length|https://developer.mozilla.org/en-US/docs/Web/API/CharacterData/length> in JavaScript.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

