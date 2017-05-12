#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 42;

use Protocol::Yadis::Document;

my $d = Protocol::Yadis::Document->parse;
ok(not defined $d);

$d = Protocol::Yadis::Document->parse('');
ok(not defined $d);

$d = Protocol::Yadis::Document->parse('<asdasd');
ok(not defined $d);

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<foo xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
 </XRD>
</foo>

ok(not defined $d);

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
</xrds:XRDS>

ok(not defined $d);

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)"><XRD>
    <Service>
        <Type>http://openid.net/signon/1.0</Type>
        <URI>http://www.livejournal.com/openid/server.bml</URI>
    </Service>
</XRD></xrds:XRDS>

is($d->services->[0]->Type->[0]->content, 'http://openid.net/signon/1.0');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<XRDS xmlns="xri://$xrds">
 <XRD xmlns="xri://$xrd*($v*2.0)">
  <Service>
   <Type> http://lid.netmesh.org/sso/2.0 </Type>
  </Service>
  <Service>
   <Type> http://lid.netmesh.org/sso/1.0 </Type>
  </Service>
 </XRD>
</XRDS>

is($d->services->[0]->Type->[0]->content, 'http://lid.netmesh.org/sso/2.0');
is($d->services->[1]->Type->[0]->content, 'http://lid.netmesh.org/sso/1.0');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/2.0 </Type>
  </Service>
  <Service>
   <Type> http://lid.netmesh.org/sso/1.0 </Type>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->Type->[0]->content, 'http://lid.netmesh.org/sso/2.0');
is($d->services->[1]->Type->[0]->content, 'http://lid.netmesh.org/sso/1.0');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
  </Service>
  <Service>
   <Type> http://lid.netmesh.org/sso/4.0 </Type>
  </Service>
 </XRD>
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/2.0 </Type>
  </Service>
  <Service>
   <Type> http://lid.netmesh.org/sso/1.0 </Type>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->Type->[0]->content, 'http://lid.netmesh.org/sso/2.0');
is($d->services->[1]->Type->[0]->content, 'http://lid.netmesh.org/sso/1.0');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <ABC>
  <foo>bar</foo>
 </ABC>
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
  </Service>
  <Service>
   <Type> http://lid.netmesh.org/sso/4.0 </Type>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->Type->[0]->content, 'http://lid.netmesh.org/sso/3.0');
is($d->services->[1]->Type->[0]->content, 'http://lid.netmesh.org/sso/4.0');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
 </XRD>
</xrds:XRDS>

is(scalar @{$d->services}, 0);

$d->services([]);

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
   <Type> http://lid.netmesh.org/sso/4.0 </Type>
   <Type> http://lid.netmesh.org/sso/5.0 </Type>
   <Type> http://lid.netmesh.org/sso/6.0 </Type>
  </Service>
  <foo>bar</foo>
  <Service>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->Type->[0]->content, 'http://lid.netmesh.org/sso/3.0');
is($d->services->[0]->Type->[1]->content, 'http://lid.netmesh.org/sso/4.0');
is($d->services->[0]->Type->[2]->content, 'http://lid.netmesh.org/sso/5.0');
is($d->services->[0]->Type->[3]->content, 'http://lid.netmesh.org/sso/6.0');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
   <URI> http://example.com/1 </URI>
   <URI> http://example.com/2 </URI>
   <URI> http://example.com/3 </URI>
   <URI> http://example.com/4 </URI>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->URI->[0]->content, 'http://example.com/1');
is($d->services->[0]->URI->[1]->content, 'http://example.com/2');
is($d->services->[0]->URI->[2]->content, 'http://example.com/3');
is($d->services->[0]->URI->[3]->content, 'http://example.com/4');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service>
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
   <URI> http://example.com/1 </URI>
   <URI priority="2"> http://example.com/2 </URI>
   <URI> http://example.com/3 </URI>
   <URI priority="0"> http://example.com/4 </URI>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->URI->[0]->content, 'http://example.com/4');
is($d->services->[0]->URI->[1]->content, 'http://example.com/2');
is($d->services->[0]->URI->[2]->content, 'http://example.com/1');
is($d->services->[0]->URI->[3]->content, 'http://example.com/3');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service priority="2">
   <Type>http://openid.net/signon/1.0</Type>
   <URI>http://www.myopenid.com/server</URI>
  </Service>
  <Service>
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
   <URI> http://example.com/3 </URI>
  </Service>
  <Service priority="0">
   <Type> http://lid.netmesh.org/sso/3.0 </Type>
   <URI> http://example.com/1 </URI>
  </Service>
 </XRD>
</xrds:XRDS>

is($d->services->[0]->URI->[0]->content, 'http://example.com/1');
is($d->services->[1]->URI->[0]->content, 'http://www.myopenid.com/server');
is($d->services->[2]->URI->[0]->content, 'http://example.com/3');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)"
   xmlns:openid="http://openid.net/xmlns/1.0">
<XRD>
  <Service priority="10">
   <Type>http://openid.net/signon/1.0</Type>
   <URI>http://www.myopenid.com/server</URI>
   <openid:Delegate>http://smoker.myopenid.com/</openid:Delegate>
  </Service>
  <Service priority="50">
   <Type>http://openid.net/signon/1.0</Type>
   <Type>http://openid.net/signon/1.0</Type>
   <Type>http://openid.net/signon/1.0</Type>
   <URI>http://www.livejournal.com/openid/server.bml</URI>
   <openid:Delegate>
     http://www.livejournal.com/users/frank/
   </openid:Delegate>
  </Service>
  <Service priority="20">
   <Type>http://lid.netmesh.org/sso/2.0</Type>
   <URI>http://www.livejournal.com/openid/server.bml</URI>
   <URI>http://www.livejournal.com/openid/server.bml</URI>
  </Service>
  <Service>
   <Type>http://lid.netmesh.org/sso/1.0</Type>
   <URI>http://www.livejournal.com/openid/server.bml</URI>
  </Service>
  <Service>
   <URI>http://www.livejournal.com/openid/server.bml</URI>
  </Service>
 </XRD>
</xrds:XRDS>

is(@{$d->services}, 4);
is($d->services->[0]->attr('priority'), 10);
is($d->services->[0]->Type->[0]->content, 'http://openid.net/signon/1.0');
is($d->services->[0]->element('openid:Delegate')->[0]->content, 'http://smoker.myopenid.com/');

is($d->services->[1]->Type->[0]->content, 'http://lid.netmesh.org/sso/2.0');

is($d->services->[2]->URI->[0]->content, 'http://www.livejournal.com/openid/server.bml');

$d = Protocol::Yadis::Document->parse(<<'');
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS xmlns:xrds="xri://$xrds" xmlns="xri://$xrd*($v*2.0)">
 <XRD>
  <Service priority="10">
   <Type>http://lid.netmesh.org/sso/2.0</Type>
  </Service>
  <Service priority="20">
   <Type>http://lid.netmesh.org/sso/1.0</Type>
  </Service>
  <Service priority="30" xmlns:openid="http://openid.net/xmlns/1.0">
   <Type>http://openid.net/signon/1.0</Type>
   <URI>http://www.livejournal.com/openid/server.bml</URI>
   <openid:Delegate>
    http://www.livejournal.com/users/frank/
   </openid:Delegate>
  </Service>
  <Service>
   <Type>http://lid.netmesh.org/post/sender/2.0</Type>
  </Service>
  <Service>
   <Type>http://lid.netmesh.org/post/receiver/2.0</Type>
  </Service>
  <Service>
   <Type>http://lid.netmesh.org/relying-party/2.0</Type>
  </Service>
  <Service>
   <Type>http://lid.netmesh.org/traversal/2.0</Type>
  </Service>
  <Service>
   <Type>http://lid.netmesh.org/format-negotiation/2.0</Type>
  </Service>
 </XRD>
</xrds:XRDS>


my $document = "$d";
$d = Protocol::Yadis::Document->parse($document);

is(@{$d->services}, 8);
is($d->services->[0]->attr('priority'), 10);
is($d->services->[0]->Type->[0]->content, 'http://lid.netmesh.org/sso/2.0');

is($d->services->[1]->Type->[0]->content, 'http://lid.netmesh.org/sso/1.0');

is($d->services->[2]->URI->[0]->content, 'http://www.livejournal.com/openid/server.bml');
is($d->services->[2]->element('openid:Delegate')->[0]->content, 'http://www.livejournal.com/users/frank/');
