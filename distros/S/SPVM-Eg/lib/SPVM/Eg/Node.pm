package SPVM::Eg::Node;



1;

=head1 Name

SPVM::Eg::Node - Node in JavaScript.

=head1 Description

The Eg::Node class in L<SPVM> is an abstract base class upon which many other DOM API objects are based, thus letting those object types to be used similarly and often interchangeably.

This class is a port of L<Node|https://developer.mozilla.org/en-US/docs/Web/API/Node> in JavaScript.

=head1 Instance Methods

=head2 node_name

C<method node_name : string ();>

Returns the name of the current node as a string.

For details, see L<Node.nodeName|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeName> in JavaScript.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

