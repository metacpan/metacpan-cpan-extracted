package SPVM::Mojo::SSE::Event;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::SSE::Event - SSE Event

=head1 Description

Mojo::SSE::Event class in L<SPVM> represents a SSE(Server-Sent Events) event.

This class is B<EXPERIMENTAL>.

=head1 Usage

  use Mojo::SSE::Event;

=head1 Fields

=head2 id

C<has id : rw string;>

C<id> field of a SSE event.

=head2 type

C<has type : rw string;>

C<event> field of a SSE event.

=head2 texts

C<has texts : rw string[];>

C<data> fields of a SSE event.

=head2 text

C<has text : virtual rw string;>

A virtual method to get/set L</"texts"> field.

The input/output is split/joined by newlines.

=head2 comments

C<has comments : rw string[];>

Comments of a SSE event.

=head2 comment

C<has comment : virtual rw string;>

A virtual method to get/set L</"comments"> field.

The input/output is split/joined by newlines.

=head1 Class Methods

C<static method new : L<Mojo::SSE::Event|SPVM::Mojo::SSE::Event> ();>

Creates a new L<Mojo::SSE::Event|SPVM::Mojo::SSE::Event> object, and returns it.

=head1 See Also

=over 2

=item * L<Mojo::SSE|SPVM::Mojo::SSE>

=item * L<Mojo::Content|SPVM::Mojo::Content>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
