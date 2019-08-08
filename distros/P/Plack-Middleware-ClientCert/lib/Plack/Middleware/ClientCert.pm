package Plack::Middleware::ClientCert;
use strict;
use warnings;

use parent qw(Plack::Middleware);

our $VERSION = '0.100';

sub client_cert
 {
  my ($env) = @_;
  my %cert = ();
  my $prefix = 'client_';

  my $ssl_env = "SSL_CLIENT_S_DN";

  my $dn = $env->{ CERT_SUBJECT } || $env->{ $ssl_env } || '';

  #
  # If headers are passed in by a proxy, they are prefixed by HTTP_
  #
  if (!$dn && $env->{ "HTTP_$ssl_env" }) {
    $ssl_env = "HTTP_$ssl_env";
    $dn = $env->{ $ssl_env };
   }

  #
  # Apache on Linux does the parsing for us.  The parts to the DN are
  # all in SSL_CLIENT_S_DN_xx
  #
  my @keys = grep s/^${ssl_env}_(.*)/$1/, (keys %{ $env });
  if (@keys) {
    for my $key (@keys) {
      $env->{ $prefix . lc( $key ) } = $env->{ "${ssl_env}_${key}" };
     }
   }
  #
  # The DN can be delimited by commas or slashes (/).  Assume commas unless
  # the very first character is a slash.
  #
  elsif ($dn =~ /^\//) {
    # Iterate through the DN while there are still 'field=value' pairs
    while ($dn =~ /=/) {
      #
      # Match the leading slash, then the field name, equals sign,
      # and value.  Finally, match the next slash seperator or the
      # end of the line.
      #
      $dn =~ s/^\/(.*?)=(.*?)(\/|$)/$3/;
      $env->{ $prefix . lc( $1 ) } = $2;
     }
   }
  else {
    # Iterate through the DN while there are still 'field=value' pairs
    while ($dn =~ /=/) {
      #
      # The first match is the field.   Then match 0 or 1 quotation mark(s).
      # The third match is the value.  Match the closed quote (or nothing).
      # Finally, match the comma seperator and blank space, or the end
      #
      $dn =~ s/^(.*?)=(\"*)(.*?)\2(,\s*|$)//;
      $env->{ $prefix . lc( $1 ) } = $3;
     }
   }

  # Add serial number if appropriate
  my $serial_key = $ssl_env;
  $serial_key =~ s/S_DN/M_SERIAL/;

  $env->{ "${prefix}serial" } = $env->{ $serial_key } || '';

  return;

 } # End of client_cert()

sub call {
    my($self, $env) = @_;

    client_cert( $env );

    return $self->app->($env);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::ClientCert

=head1 VERSION

version 0.100

=head1 SYNOPSIS

Parse a client certificate and put details in the env

      use Plack::Builder;
  
      my $app = sub {
          my $env = shift;
          return [
              200,
              [ 'Content-Type' => 'text/plain' ],
              [ "Hello $env->{ client_cn } from $env->{ client_ou } of $env->{ c  lent_o }" ],
          ];
      };
  
      builder {
          enable 'ClientCert';
          $app;
      };

=head1 DESCRIPTION

Plack::Middleware::ClientCert parses the fields of a digital certificate
in either Apache or IIS. The certificate distinguished name is either
slash-delimited or comma delimited in the form:

'C=US, O=Agents Virtual Community, OU="My Insurance, Inc.", CN=Troy O'Leary

Any fields containing a comma are double-quoted.

The keys for the certificate are:

client_cn
client_ou
client_o

=head1 NAME

Plack::Middleware::ClientCert - Parse a client certificate and put details in the env

=head1 AUTHOR

Keith Carangelo

=head1 AUTHOR

Keith Carangelo <mail@kcaran.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Keith Carangelo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
