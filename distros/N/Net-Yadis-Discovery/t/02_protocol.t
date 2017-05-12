use Test::More tests => 21;
use lib './t/lib';
use URI::Fetch;
use Data::Dumper;

BEGIN { use_ok('Net::Yadis::Discovery') };

my $disc = Net::Yadis::Discovery->new();

# Test1: Redirecting URL and indicating XRD direcry test

URI::Fetch->set_dummy(
[{
  'content-type' => 'application/xrds+xml',
}]);
my @xrd = $disc->discover("http://redirect.example.com/");
is ($disc->identity_url,"http://redirected.example.com/");
is ($disc->xrd_url,"http://redirected.example.com/");

# Test2: Object test

my $srv = $xrd[0];
is ($srv->priority,0);
my @type = $srv->Type();
is ($type[0],'http://openid.net/signon/1.1');
is ($type[1],'http://openid.net/signon/1.0');
my $type = $srv->Type();
is ($type->[0],'http://openid.net/signon/1.1');
is ($type->[1],'http://openid.net/signon/1.0');
my @URI = $srv->URI();
is ($URI[0],'http://example.com/server');
is ($URI[1],'http://example.com/server2');
my $URI = $srv->URI();
is ($URI->[0],'http://example.com/server');
is ($URI->[1],'http://example.com/server2');
is ($srv->extra_field('Delegate','http://openid.net/xmlns/1.0'),'http://my.example.com/');

# Test3: One hop test

URI::Fetch->set_dummy(
[{
  'yadis-location' => 'http://example.com/yadis.xml',
},
{
  'content-type' => 'application/xrds+xml',
}]);

$xrd = $disc->discover("http://id.example.com/");
is ($disc->identity_url,"http://id.example.com/");
is ($disc->xrd_url,"http://example.com/yadis.xml");

# Test4: Two hops test

URI::Fetch->set_dummy(
[{
},
{
  'yadis-location' => 'http://example.com/yadis.xml',
},
{
  'content-type' => 'application/xrds+xml',
}]);

$xrd = $disc->discover("http://id.example.com/");
is ($disc->identity_url,"http://id.example.com/");
is ($disc->xrd_url,"http://example.com/yadis.xml");

# Test5: Both content-type and x-yadis-location headers included test

URI::Fetch->set_dummy(
[
{
  'content-type' => 'application/xrds+xml',
  'yadis-location' => 'http://example.com/yadis2.xml',
},
{
  'content-type' => 'application/xrds+xml',
}]);

$xrd = $disc->discover("http://example.com/yadis.xml");
is ($disc->identity_url,"http://example.com/yadis.xml");
is ($disc->xrd_url,"http://example.com/yadis2.xml");


# Test6: More hops.. cannot found X-YADIS-Location header test

URI::Fetch->set_dummy(
[{
},
{
},
{
  'yadis-location' => 'http://example.com/yadis.xml',
},
{
  'content-type' => 'application/xrds+xml',
}]);

$xrd = $disc->discover("http://id.example.com/");
is ($disc->errcode,"no_yadis_document");

# Test7: More hops.. cannot found XRD on X-YADIS-Location URL test

URI::Fetch->set_dummy(
[{
  'yadis-location' => 'http://example.com/yadis.xml',
},
{
}]);

$xrd = $disc->discover("http://id.example.com/");
is ($disc->errcode,"too_many_hops");


