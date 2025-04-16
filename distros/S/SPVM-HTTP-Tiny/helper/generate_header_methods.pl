use strict;
use warnings;

while (my $line = <DATA>) {
  
  chomp $line;
  
  my $header_name = $line;
  
  my $method_name = lc $line;
  $method_name =~ s/-/_/g;
  
  my $get = '';
  
  if ($method_name eq 'set_cookie') {
    $get = 'get_'
  }
  
  my $getter = <<"EOS";
  method $get$method_name : string () {
    
    my \$value = \$self->{headers_h}->get_string("$header_name");
    
    return \$value;
  }
EOS

  my $setter = <<"EOS";
  method set_$method_name : void (\$value : string) {
    
    \$self->{headers_h}->set("$header_name" => \$value);
  }
EOS
  
  print "$getter\n";
  
  print "$setter\n";
  
}

__DATA__
Accept
Accept-Charset
Accept-Encoding
Accept-Language
Accept-Ranges
Access-Control-Allow-Origin
Allow
Authorization
Cache-Control
Connection
Content-Disposition
Content-Encoding
Content-Language
Content-Length
Content-Location
Content-Range
Content-Security-Policy
Content-Type
Cookie
DNT
Date
ETag
Expect
Expires
Host
If-Modified-Since
If-None-Match
Last-Modified
Link
Location
Origin
Proxy-Authenticate
Proxy-Authorization
Range
Sec-WebSocket-Accept
Sec-WebSocket-Extensions
Sec-WebSocket-Key
Sec-WebSocket-Protocol
Sec-WebSocket-Version
Server
Server-Timing
Set-Cookie
Status
Strict-Transport-Security
TE
Trailer
Transfer-Encoding
Upgrade
User-Agent
Vary
WWW-Authenticate
