package SPVM::HTTP::Minimal::Message::Response;



1;

=head1 Name

SPVM::HTTP::Minimal::Message::Response - HTTP Response

=head1 Description

The HTTP::Minimal::Message::Response class of L<SPVM> has methods to manipulate HTTP responses.

=head1 Usage

  use HTTP::Minimal::Message::Response;
  
  my $is_success = $res->is_success;
  
  my $content = $res->content;

=head1  Fields

=head2 protocol

  has protocol : ro string;

The protocol of the HTTP response.

=head2 status

  has status : ro string;

The status code of the HTTP response.

=head2 reason

  has reason : ro string;

The reason of the status code of the HTTP response.

=head1 Instance Methods

=head2 is_success

  method is_success : int ();

If the response contains successful status code, returns 1. Otherwise returns 0.

=head2 content

  method content : string ();

Returns the content body of the response.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

