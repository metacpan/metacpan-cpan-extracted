package SPVM::Mojo::SSE;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::SSE - Server-Sent Events

=head1 Description

Mojo::SSE class in L<SPVM> implements the Server-Sent Events protocol. Note that this module is B<EXPERIMENTAL> and may change
without warning!

=head1 Usage

  use Mojo::SSE;

=head1 Class Methods

=head2 build_event

C<static method build_event : string ($event : L<Mojo::SSE::Event|SPVM::Mojo::SSE::Event>);>

Build Server-Sent Event.

=head2 parse_event

C<static method parse_event : L<Mojo::SSE::Event|SPVM::Mojo::SSE::Event> ($buffer_ref : string[]);>

Parse Server-Sent Event. Returns C<undef> if no complete event was found.

=head1 See Also

=over 2

=item * L<Mojo::Content|SPVM::Mojo::Content>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License
