package SPVM::Sys::Socket::AddrinfoLinkedList;

1;

=head1 Name

SPVM::Sys::Socket::AddrinfoLinkedList - Linked List of struct addrinfo in the C language

=head1 Description

The Sys::Socket::AddrinfoLinkedList class in L<SPVM> represents the linked list of L<struct addrinfo|https://linux.die.net/man/3/getaddrinfo> in the C language.

=head1 Usage

  use Sys::Socket::AddrinfoLinkedList;

=head1 Instance Methods

=head2 DESTROY

C<method DESTROY : void ();>

The destructor.

=head2 to_array

C<method to_array : L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo>[]> ();>

Converts this instance to the array of the L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo> class and returns it.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

