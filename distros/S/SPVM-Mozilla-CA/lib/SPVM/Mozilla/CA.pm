package SPVM::Mozilla::CA;

our $VERSION = "0.001";

1;

=head1 Name

SPVM::Mozilla::CA - Mozilla's CA cert bundle in PEM format

=head1 Description

The Mozilla::CA class of L<SPVM> has methods to get Mozilla's CA cert bundle in PEM format.

=head1 Usage

  use Mozilla::CA;
  
  my $ssl_ca = Mozilla::CA->SSL_ca;

=head1 Class Methods

  static method SSL_ca : string ();

Returns the content of the Mozilla's CA cert bundle PEM file.

This is the same file content returned by L<Perl's Mozilla::CA::SSL_ca_file|Mozilla::CA/"SSL_ca_file">.

The content is synced periodically.

=head1 Repository

L<SPVM::Mozilla::CA - Github|https://github.com/yuki-kimoto/SPVM-Mozilla-CA>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

