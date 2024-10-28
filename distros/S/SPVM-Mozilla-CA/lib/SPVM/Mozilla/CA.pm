package SPVM::Mozilla::CA;

our $VERSION = "0.002";

1;

=head1 Name

SPVM::Mozilla::CA - Mozilla's CA cert bundle in PEM format

=head1 Description

Mozilla::CA class in L<SPVM> has methods to get Mozilla's CA cert bundle in PEM format.

=head1 Usage

  use Mozilla::CA;
  
  my $ssl_ca = Mozilla::CA->SSL_ca;

=head1 Class Methods

  static method SSL_ca : string ();

Returns the content of the Mozilla's CA cert bundle PEM file.

The return value is the same as the content of L<Mozilla::CA#SSL_ca_file|Mozilla::CA/"SSL_ca_file"> method of the version 20240924.

=head1 Repository

L<SPVM::Mozilla::CA - Github|https://github.com/yuki-kimoto/SPVM-Mozilla-CA>

=head1 Porting

This class is Perl's L<Mozilla::CA> porting to L<SPVM>.

=head1 FAQ

=head2 Why is there no SSL_ca_file method?

SPVM programming language does not have the ability to bundle files.

If you want to output it to a file, you need to use a temporary file.
  
  my $ssl_ca = Mozilla::CA->SSL_ca;
  
  my $tmp_dir = File::Temp->newdir;
  
  my $ssl_ca_file = "$tmp_dir/cacert.pem";
  
  my $fh = IO->open(">", $ssl_ca_file);
  
  $fh->write($ssl_ca);
  
  $fh->close;

See also L<File::Temp|SPVM::File::Temp> and L<IO|SPVM::IO>.

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

