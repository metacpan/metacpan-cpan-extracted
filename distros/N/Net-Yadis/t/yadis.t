#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 27;

use Net::Yadis;

package testFetcher;

use Test::More;
use HTTP::Response;
use LWP::UserAgent;
sub new {
    bless {realAgent => LWP::UserAgent->new}
}

my $GOOD_XRDS = '<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)"
    xmlns:openid="http://openid.net/xmlns/1.0">
  <XRD>

    <Service priority="10">
      <Type>http://openid.net/signon/1.0</Type>
    </Service>

  </XRD>
</xrds:XRDS>
';
my $HTML_PAGE = "<html><head></head><body>foo!</body></html>";
my $HTML_EQUIV_PAGE = "<html><head><meta http-equiv='x-xrds-location' content='http://xrds.as.text/'></head><body>foo!</body></html>";
my $HTML_EQUIV_COMPAT_PAGE = "<html><head><meta http-equiv='x-yadis-location' content='http://xrds.as.text/'></head><body>foo!</body></html>";

sub get {
    my $self = shift;
    my $uri = shift;
    my %headers = @_;

    my $response = HTTP::Response->new;

    if ($uri eq 'http://content.negotiation/') {
        $response->code(200);
        if($headers{'Accept'} eq 'application/xrds+xml') {
            $response->header('Content-Type', 'application/xrds+xml');
            $response->content($GOOD_XRDS);
            $response->header('Content-Location', $uri);
        }
        else {
            $response->header('Content-Type', 'text/plain');
            $response->content("ERROR: yadis lib doesn't send accept header");
            $response->header('Content-Location', $uri);
        }
    }
    elsif ($uri eq 'http://http.header/') {
        $response->code(200);
        $response->header('X-XRDS-Location', 'http://xrds.as.text/');
        $response->content($HTML_PAGE);
        $response->header('Content-Location', $uri);
    }
    elsif ($uri eq 'http://http.equiv/') {
        $response->code(200);
        $response->content($HTML_EQUIV_PAGE);
        $response->header('Content-Location', $uri);
    }
    elsif ($uri eq 'http://not.found/') {
        $response->code(404);
    }
    elsif ($uri eq 'http://xrds.as.text/') {
        $response->code(200);
        $response->header('Content-Type', 'text/plain');
        $response->content($GOOD_XRDS);
        $response->header('Content-Location', $uri);
    }
    elsif ($uri eq 'http://network.error/') {
        $response = $self->{realAgent}->get($uri);
    }
    elsif ($uri eq 'http://redirect.me/') {
        $response->code(200);
        $response->content($HTML_EQUIV_PAGE);
        $response->header('Content-Location', 'http://redirect.ed/');
    }
    elsif ($uri eq 'http://http.compat.header/') {
        $response->code(200);
        $response->header('X-Yadis-Location', 'http://xrds.as.text/');
        $response->content($HTML_PAGE);
        $response->header('Content-Location', $uri);
    }
    elsif ($uri eq 'http://http.compat.equiv/') {
        $response->code(200);
        $response->content($HTML_EQUIV_COMPAT_PAGE);
        $response->header('Content-Location', $uri);
    }
    return $response;
}

sub post {
};

package YadisTest;
use Test::More;

Net::Yadis::_userAgentClass('testFetcher');

my ($yadis, $svc, $svb, @services, @types, @uris);

# discovery failures
eval {$yadis = Net::Yadis->discover('http://network.error/');};
ok($@, "Network error dies");

eval {$yadis = Net::Yadis->discover('http://not.found/');};
ok($@, "404 dies");

eval {$yadis = Net::Yadis->discover('http://xrds.as.text/');};
ok($@, "Not a Yadis URL dies");

# discovery successes
eval {$yadis = Net::Yadis->discover('http://content.negotiation/');};
is($yadis->url, 'http://content.negotiation/',
        "Content Negotiation correct yadis url");
is($yadis->xrds_url, 'http://content.negotiation/',
        "CN correct xrds URL");
eval {$yadis = Net::Yadis->discover('http://http.header/');};
is($yadis->url, 'http://http.header/',
        "Http header correct yadis url");
is($yadis->xrds_url, 'http://xrds.as.text/',
        "header correct xrds URL");
eval {$yadis = Net::Yadis->discover('http://http.equiv/');};
print $@ if $@;
is($yadis->url, 'http://http.equiv/',
        "Http equiv correct yadis url");
is($yadis->xrds_url, 'http://xrds.as.text/',
        "equiv correct xrds URL");
eval {$yadis = Net::Yadis->discover('http://http.compat.header/');};
is($yadis->url, 'http://http.compat.header/',
        "Http old header correct yadis url");
is($yadis->xrds_url, 'http://xrds.as.text/',
        "old header correct xrds URL");
eval {$yadis = Net::Yadis->discover('http://http.compat.equiv/');};
is($yadis->url, 'http://http.compat.equiv/',
        "Http old equiv correct yadis url");
is($yadis->xrds_url, 'http://xrds.as.text/',
        "old equiv correct xrds URL");
eval {$yadis = Net::Yadis->discover('http://redirect.me/');};
is($yadis->url, 'http://redirect.ed/',
        "yadis url follows redirects");



# test prioritizing and getting attributes of tags in the service
my $xrds_xml = '<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)"
    xmlns:openid="http://openid.net/xmlns/1.0">
  <XRD>

    <Service priority="10">
      <Type>http://openid.net/signon/1.0</Type>
      <URI>http://www.myopenid.com/servir</URI>
      <URI priority="57">http://www.myopenid.com/servor</URI>
      <URI priority="64">http://www.myopenid.com/server</URI>
      <openid:Delegate>http://frank.livejournal.com/</openid:Delegate>
      <junk>Ton Cents</junk>
    </Service>

    <Service priority="5">
      <Type>http://openid.net/signon/1.0</Type>
      <URI>http://www.myclosedid.com/servir</URI>
      <URI priority="57">http://www.myclosedid.com/servor</URI>
      <URI priority="64">http://www.myclosedid.com/server</URI>
      <openid:Delegate>http://frank.livejournal.com/</openid:Delegate>
      <junk>Con Tents</junk>
    </Service>

  </XRD>
</xrds:XRDS>
';

eval{
    $yadis = Net::Yadis->new("http://foobar.voodoo.com/", 
                             "http://foobar.voodoo.com/xrds",
                             $xrds_xml);
    };
isa_ok($yadis, "Net::Yadis", "New from foodoo voobar example")
    or diag($@);

$svc = $yadis->service_of_type("^http://openid.net/signon/");
is($svc->uri, "http://www.myclosedid.com/servor", "foobar.voodoo.com svc 1 URI 1");
is($svc->uri, "http://www.myclosedid.com/server", "foobar.voodoo.com svc 1 URI 2");
is($svc->uri, "http://www.myclosedid.com/servir", "foobar.voodoo.com svc 1 URI 3");
is($svc->uri, undef, "foobar.voodoo.com svc1 has 3 URIs");
my ($contents, $attrs) = $svc->findTag("junk");
is($contents, "Con Tents", "foobar.voodoo.com svc 1 findTag junk contents");
is($svc->getAttribute("priority"), "5", "svc->getAttribute works");

$svc = $yadis->service_of_type("^http://openid.net/signon/");
is($svc->uri, "http://www.myopenid.com/servor", "foobar.voodoo.com svc 2 URI 1");
is($svc->uri, "http://www.myopenid.com/server", "foobar.voodoo.com svc 2 URI 2");
is($svc->uri, "http://www.myopenid.com/servir", "foobar.voodoo.com svc 2 URI 3");
is($svc->uri, undef, "foobar.voodoo.com svc 2 has 3 URIs");
($contents, $attrs) = $svc->findTag("junk");
is($contents, "Ton Cents", "foobar.voodoo.com svc 2 findTag junk contents");
is($svc->getAttribute("priority"), "10", "svc->getAttribute still works");

