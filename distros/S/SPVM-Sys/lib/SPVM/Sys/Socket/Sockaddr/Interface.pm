package SPVM::Sys::Socket::Sockaddr::Interface;

1;

=head1 Name

SPVM::Sys::Socket::Sockaddr::Interface - Interface for Sys::Socket::Sockaddr

=head1 Usage

  use Sys::Socket::Sockaddr::Interface;
  
=head1 Description

C<Sys::Socket::Sockaddr::Interface> is the class for the interface for L<Sys::Socket::Sockaddr|SPVM::Sys::Socket::Sockaddr>.

=head1 Interface Methods

=head2 has_interfaces

  required method has_interfaces : int ();

The required method.

=head2 sa_family

  method sa_family : int ()

Gets C<sa_family>.

=head2 sizeof

  method sizeof : int ()

The size of the structure internally used.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

