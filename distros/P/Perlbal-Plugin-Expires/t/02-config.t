use strict;

use Test::More;
use Perlbal::Test ();
use Perlbal::Test::WebClient ();
use FindBin;
use HTTP::Date;

my $port = Perlbal::Test::new_port();

my $conf = <<"CONF";
LOAD Expires
CREATE SERVICE web
  SET role    = web_server
  SET listen  = 127.0.0.1:$port
  SET docroot = $FindBin::Bin/docs
  SET plugins = Expires
  Expires default = access plus 10 days
  Expires web text/css = access plus 11 days
ENABLE web
CONF

## _base_time() use time() to calculate the time when 'access' is set as type.
## so it should be returned the fixed value from that function for tests.
my $now = time;
{
    no warnings 'once';
    *CORE::GLOBAL::time = sub { $now };
}

my $msock = Perlbal::Test::start_server($conf);
ok $msock;

my $client = Perlbal::Test::WebClient->new;
$client->server('127.0.0.1:' . $port);
$client->keepalive(1);
$client->http_version('1.0');

my $res = $client->request('/index.html');
ok $res;
is $res->code, '200';
is $res->header('Expires'), HTTP::Date::time2str($now + 10*24*60*60);

$res = $client->request('/style.css');
ok $res;
is $res->code, '200';
is $res->header('Expires'), HTTP::Date::time2str($now + 11*24*60*60);

$res = $client->request('/script.js');
ok $res;
is $res->code, '200';
is $res->header('Expires'), HTTP::Date::time2str($now + 10*24*60*60);

ok !Perlbal::Test::manage('Expires web image/gif = aces plus 1 days', quiet_failure => 1), 'wrong base time string';
ok !Perlbal::Test::manage('Expires web image/gif = now plus 0x10 days', quiet_failure => 1), 'wrong number';
ok !Perlbal::Test::manage('Expires web image/gif = modification plus 1 mins', quiet_failure => 1), 'wrong time unit';

done_testing;
