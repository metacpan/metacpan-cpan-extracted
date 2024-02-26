package SPVM::HTTP::Tiny::Message::Response;



1;

=head1 Name

SPVM::HTTP::Tiny::Message::Response - HTTP Response

=head1 Description

The HTTP::Tiny::Message::Response class of L<SPVM> has methods to manipulate HTTP responses.

=head1 Usage
  
  my $response = HTTP::Tiny->new->get('http://example.com/');
  
  my $success = $response->success;
  
  my $status = $response->status;
  
  my $content = $response->content;

=head1 Inheritance

L<HTTP::Tiny::Message|SPVM::HTTP::Tiny::Message>

=head1 Fields

=head2 protocol

C<has protocol : ro string;>

The protocol of the HTTP response.

=head2 status

C<has status : ro string;>

The status code of the HTTP response.

=head2 success

C<has success : ro byte;>

The success field of the response will be true if the status code is 2XX.

=head2 reason

C<has reason : ro string;>

The reason of the status code of the HTTP response.

=head1 Instance Methods

=head2 content

C<method content : string ();>

Returns the content body of the response.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

