package SPVM::Eg::Node::ProcessingInstruction;



1;

=head1 Name

SPVM::Eg::Node::ProcessingInstruction - ProcessingInstruction in JavaScript

=head1 Description

The Eg::Node::ProcessingInstruction class in L<SPVM> represents a node containing a doctype.

This class is a port of L<ProcessingInstruction|https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction> in JavaScript.

=head1 Usage

  my $pi = Eg->document->implementation->create_processing_instruction(
    "xml-stylesheet",
    'href="mycss.css"',
  );
  
  my $target = $pi->target;

=head1 Inheritance

L<Eg::Node|SPVM::Eg::Node>

=head1 Fields

=head2 target

C<has target : ro string;>

Returns the application to which the ProcessingInstruction is targeted.

For details, see L<ProcessingInstruction.target|https://developer.mozilla.org/en-US/docs/Web/API/ProcessingInstruction/target> in JavaScript.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

