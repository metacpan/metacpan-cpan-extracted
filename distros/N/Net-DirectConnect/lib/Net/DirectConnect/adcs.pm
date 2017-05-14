#$Id: adc.pm 858 2011-10-10 22:56:04Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/lib/Net/DirectConnect/adc.pm $

=CERTS

mkdir certs

windows-only?: add to certs/cfg:
------------------------
[ req ]
default_bits	       = 1024
default_keyfile	       = certs/key.pem
distinguished_name     = req_distinguished_name

[ req_distinguished_name ]
countryName		       = Country Name (2 letter code)
countryName_default	       = RU
countryName_min		       = 2
countryName_max		       = 2

localityName		       = Locality Name (eg, city)
organizationName               = Organization Name(eg, org)
organizationalUnitName	       = Organizational Unit Name (eg, section)

commonName		       = Common Name (eg, YOUR name)
commonName_max		       = 64

emailAddress		       = Email Address
emailAddress_max	       = 40
-------------------------
for non-windows delete -config certs/cfg :
#openssl req -new -x509 -out certs/cert.pem -config certs/cfg

openssl genrsa -des3 -out certs/key.pem 
openssl req -new -key certs/key.pem -out certs/cert.pem  -config certs/cfg

debug:
openssl s_server -accept 413 -cert certs/cert.pem -key certs/key.pem
openssl s_client -debug -connect 127.0.0.1:413

=cut
package    #hide from cpan
  Net::DirectConnect::adcs;
use strict;
no strict qw(refs);
use warnings "NONFATAL" => "all";
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use IO::Socket::SSL;
#use IO::Socket::SSL qw(debug4);
use Data::Dumper;    #dev only
#$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
sub init {
  my $self = shift if ref $_[0];
  $self->module_load('adc');
  #$self->log( 'ssl', $self->{'protocol'}, $self->{'auto_listen'} );
  $self->{'protocol_supported'}{'ADCS/0.10'} = 'adcs';
  #$self->log( 'dev', 'sslinit', $self->{'protocol'} ),
  $self->{'socket_class'} = 'IO::Socket::SSL'
    if
    #!$self->{hub} and
    $self->{'protocol'} eq 'adcs'
    #and !$self->{'auto_listen'}
    ;
  local %_ = (
    'recv' => 'read',
    'send' => 'syswrite',
    'protocol_connect'   => 'ADCS/0.10',
  );
  $self->{$_} = $_{$_} for keys %_;
  #$self->log( 'dev', 'adcsset', $self->{'protocol_connect'});
  local %_ = (
    SSL_server      => $self->{'auto_listen'},
    SSL_verify_mode => 0,
    SSL_version     => 'TLSv1',
  );
  $self->{'socket_options'}{$_} = $_{$_} for keys %_;
# $self->log( 'dev',  'sockopt',      %{$self->{'socket_options'}},);
#IO::Socket::SSL->start_SSL( SSL_server => 1, $self->{'socket'}, %{ $self->{'socket_options'} || {} } )    if $self->{'socket'} and $self->{'proto}col'} eq 'adcs' and $self->{'incoming'};
  if (
    !$self->{'no_listen'}    #) {
#$self->log( 'dev', 'nyportgen',"$self->{'M'} eq 'A' or !$self->{'M'} ) and !$self->{'auto_listen'} and !$self->{'incoming'}" );
#    if (
    and
    #( $self->{'M'} eq 'A' or !$self->{'M'} )  and
    !$self->{'incoming'} and !$self->{'auto_listen'}
    )
  {
    $self->log( 'dev', "making listeners: tls", "h=$self->{'hub'}" );
    $self->{'clients'}{'listener_tls'} = $self->{'incomingclass'}->new(
      'parent'      => $self,
      'protocol'    => 'adcs',
      'auto_listen' => 1,
    );
    $self->{'myport_tls'} = $self->{'clients'}{'listener_tls'}{'myport'};
    #$self->log( 'dev', 'nyportgen', $self->{'myport_sctp'} );
    $self->log( 'err', "cant listen tls" ) unless $self->{'myport_tls'};
    if ( $self->{'dev_sctp'} ) {
      $self->log( 'dev', "making listeners: tls sctp", "h=$self->{'hub'}" );
      $self->{'clients'}{'listener_tls_sctp'} = $self->{'incomingclass'}->new(
        'parent'      => $self,
        'Proto'       => 'sctp',
        'protocol'    => 'adcs',
        'auto_listen' => 1,
      );
      $self->{'myport_tls_sctp'} = $self->{'clients'}{'listener_tls_sctp'}{'myport'};
      #$self->log( 'dev', 'nyportgen', $self->{'myport_sctp'} );
      $self->log( 'err', "cant listen tls sctp" ) unless $self->{'myport_tls_sctp'};
    }
  }
}
6;
