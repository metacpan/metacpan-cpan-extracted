package URI::Fetch;

# Dummy URI::Fetch module for test.

use strict;
use vars qw($VERSION @dummy);
$VERSION = 0.03;

sub set_dummy {
    my $class = shift;
    my $ref = shift;
    @dummy = @$ref;
}

sub fetch {
    my $class = shift;
    my $url = shift;
    my $ref = shift(@dummy);
    $ref->{'url'} = $url;
    bless $ref,$class;
}

sub URI_GONE { 410 }

sub http_response { shift }
sub request { shift }
sub uri { shift }
sub headers { shift }

sub status { shift->{'status'} || 200 }
sub as_string { my $self = shift; $self->{'url'} ? $self->{'url'} eq 'http://redirect.example.com/' ? 'http://redirected.example.com/' : $self->{'url'} : "http://example.com/" }
sub content { shift->{'content'} || '<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns:openid="http://openid.net/xmlns/1.0"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      <Type>http://openid.net/signon/1.1</Type>
      <Type>http://openid.net/signon/1.0</Type>
      <URI>http://example.com/server</URI>
      <URI>http://example.com/server2</URI>
      <openid:Delegate>http://my.example.com/</openid:Delegate>
    </Service>
  </XRD>
</xrds:XRDS>' }

sub scan {
    my $self = shift;
    my $ref = shift;
    $ref->('Content-Type',$self->{'content-type'} || 'text/html');
    $ref->('X-YADIS-Location',$self->{'yadis-location'});
}

1;