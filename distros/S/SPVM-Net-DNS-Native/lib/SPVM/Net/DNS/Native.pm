package SPVM::Net::DNS::Native;

our $VERSION = "0.002";

1;

=head1 Name

SPVM::Net::DNS::Native - Short Description

=head1 Description

Net::DNS::Native class in L<SPVM> has methods to perform non-blocking L<getaddrinfo|SPVM::Sys::Socket#getaddrinfo> operation.

=head1 Usage

  use Net::DNS::Native;
  
  my $dns = Net::DNS::Native->new;
  
  my $domain = "google.com";
  my $service = (string)undef;
  my $hints = Sys::Socket::Addrinfo->new;
  $hints->set_ai_family(SOCKET->AF_INET);
  my $res_ref = new Sys::Socket::AddrinfoLinkedList[1];
  
  $dns->getaddrinfo($domain, $service, $hints, $res_ref);

=head1 Class Methods

=head2 new

C<static method new : Net::DNS::Native ();>

Creates a new L<Net::DNS::Native|SPVM::Net::DNS::Native> object and returns it.

=head1 Instance Methods

=head2 getaddrinfo

C<method getaddrinfo : void ($node : string, $service : string, $hints : L<Sys::Socket::Addrinfo|SPVM::Sys::Socket::Addrinfo>, $res_ref : L<Sys::Socket::AddrinfoLinkedList|SPVM::Sys::Socket::AddrinfoLinkedList>[]);>

Performs non-blocking L<getaddrinfo|SPVM::Sys::Socket#getaddrinfo> operation.

Implementation:

Thie methos creates a L<goroutine|SPVM::Go/"go">. The goroutine creates a L<thread|SPVM::Thread> that performs L<getaddrinfo|SPVM::Sys::Socket/"getaddrinfo"> operation.

The caller gorouine waits for the goroutine to be finised and transfers the control to the scheduler.

=head1 See Also

=over 2

=item * L<Thread|SPVM::Thread>

=item * L<Go|SPVM::Go>

=back

=head1 Porting

This class is a Perl's L<Net::DNS::Native> porting to L<SPVM>.

=head1 Copyright & License

Copyright (c) 2024 Yuki Kimoto

MIT License

