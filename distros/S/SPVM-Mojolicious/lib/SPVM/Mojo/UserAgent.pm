package SPVM::Mojo::UserAgent;



1;

=head1 Name

SPVM::Mojo::UserAgent - HTTP Client

=head1 Description

Mojo::UserAgent class in L<SPVM> is a HTTP client.

=head1 Usage

  use Mojo::UserAgent;
  
  my $url = "http://google.com";
  
  my $ua = Mojo::UserAgent->new;
  
  my $res = $ua->get($url)->result;
  
  my $body = $res->body;
  
  my $code = $res->code;
  
=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

