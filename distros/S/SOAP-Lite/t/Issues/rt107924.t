use strict;
use warnings;
use Test::More tests => 2;
use SOAP::Lite;

my ($opts, $soap);
my $proxy = 'http://services.soaplite.com/echo.cgi';
my $cafile = '/foo/bar';

$opts = [ verify_hostname => 0, SSL_ca_file => $cafile ];
$soap = SOAP::Lite->proxy ($proxy, ssl_opts => $opts);
is ($soap->transport->ssl_opts ('SSL_ca_file'), $cafile, "ssl_opts as arrayref is honoured");

$opts = { verify_hostname => 0, SSL_ca_file => $cafile };
$soap = SOAP::Lite->proxy ($proxy, ssl_opts => $opts);
is ($soap->transport->ssl_opts ('SSL_ca_file'), $cafile, "ssl_opts as hashref is honoured");
