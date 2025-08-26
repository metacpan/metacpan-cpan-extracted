package SPVM::Mojo::UserAgent::Transactor::Endpoint;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::UserAgent::Transactor::Endpoint - Transaction endpoint

=head1 Description

Mojo::UserAgent::Transactor::Endpoint class in L<SPVM> represents a transaction endpoint.

=head1 Usage

  use Mojo::UserAgent::Transactor::Endpoint;

=head1 Interfaces

=over 2

=item * L<Stringable|SPVM::Stringable>

=back

=head1 Fields

=head2 protocol

C<has protocol : rw string;>

A protocol.

=head2 host

C<has host : rw string;>

A host.

=head2 port

C<has port : rw int;>

A port.

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::UserAgent::Transactor::Endpoint|SPVM::Mojo::UserAgent::Transactor::Endpoint> ();>

Create a new L<Mojo::UserAgent::Transactor::Endpoint|SPVM::Mojo::UserAgent::Transactor::Endpoint> object, and return it.

=head1 Instance Methods

=head2 to_string

C<method to_string : string ();>

Return the endpoint to a string.

=head1 See Also

=over 2

=item * L<Mojo::UserAgent::Transactor|SPVM::Mojo::UserAgent::Transactor>

=item * L<Mojo::UserAgent|SPVM::Mojo::UserAgent>

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

