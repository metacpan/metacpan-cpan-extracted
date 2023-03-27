# Lower http/https layer using the HTTP::Tiny module
# SSL options are documented at https://metacpan.org/pod/IO::Socket::SSL
# There is no vadility at passed arguments, because they are checked from the ElasticDirect

package Search::ElasticDirectHttp;

use strict;
use warnings;
use HTTP::Tiny;

our $VERSION   = '2.1.0';
our @ISA       = qw/Exporter/;
our @EXPORT    = qw//; # export now
our @EXPORT_OK = qw//;

# Check if the module HTTP::Tiny can connect using ssl
unless (HTTP::Tiny::can_ssl()) {
print STDERR "HTTP::Tiny can not use https protocol because of missing modules\n";
CORE::exit 1
}



#   HTTP::Tiny object using SSL_ca_file, SSL_key_file, SSL_cert_file
#   for SearchGuard ssl connections
sub HTTP_Tiny_https_certca_cert_key
{
  HTTP::Tiny->new(
  timeout     => $_[0],
  keep_alive  => $_[1],
  verify_SSL  => $_[2],
  SSL_options => { SSL_verify_mode => $_[2], SSL_ca_file => $_[3], SSL_cert_file => $_[4], SSL_key_file => $_[5] },
  agent       => 'ElasticDriver',
  max_size    => 4294967296,
  max_redirect=> 5
  ) or CORE::die 'Could not create HTTP::Tiny object';
}


#   HTTP::Tiny object using SSL_ca_file
#   for normal https connections using the SSL_ca_file when you have self signed certificates
sub HTTP_Tiny_https_certca
{
  HTTP::Tiny->new(
  timeout     => $_[0],
  keep_alive  => $_[1],
  verify_SSL  => $_[2],
  SSL_options => { SSL_verify_mode => $_[2], SSL_ca_file => $_[3] },
  agent       => 'ElasticDriver',
  max_size    => 4294967296,
  max_redirect=> 5
  ) or CORE::die 'Could not create HTTP::Tiny object';
}


#   HTTP::Tiny object https
#   There is no need to use the CA certificate because you are using signed certificated
sub HTTP_Tiny_https
{
  HTTP::Tiny->new(
  timeout     => $_[0],
  keep_alive  => $_[1],
  verify_SSL  => $_[2],
  SSL_options => { SSL_verify_mode => $_[2] },
  agent       => 'ElasticDriver',
  max_size    => 4294967296,
  max_redirect=> 5
  ) or CORE::die 'Could not create HTTP::Tiny object';
}


#   HTTP::Tiny object http
sub HTTP_Tiny_http
{
  HTTP::Tiny->new(
  timeout     => $_[0],
  keep_alive  => $_[1],
  agent       => 'ElasticDriver',
  max_size    => 4294967296,
  max_redirect=> 5
  ) or CORE::die 'Could not create HTTP::Tiny object';
}


# This server, short hostname
sub HostnameShort
{
local $_ = undef;

  if (exists $ENV{COMPUTERNAME}) {
  $_=$ENV{COMPUTERNAME}
  }
  elsif (exists $ENV{HOSTNAME}) {
  $_=$ENV{HOSTNAME}
  }
  elsif (-f '/etc/hostname') {
  local $/ = undef;
  open __FILE, '<', '/etc/hostname' or CORE::die "Could not read file /etc/hostname because $!\n";
  ($_=readline __FILE) =~s/\v*$//;
  close __FILE;
  }
  else {
  ($_=qx[hostname]) =~s/\v*$//
  }

s/\..*$//;
$_
}


1;#END

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::ElasticDirectHttp

=head1 VERSION

version 2.5.2

=head1 AUTHOR

George Bouras <george.mpouras@yandex.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by George Bouras.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
