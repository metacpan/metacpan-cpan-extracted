#!/usr/bin/perl -w
use strict;
use Test::More tests => 58;

use_ok('Net::Pachube');

delete $ENV{PACHUBE_API_KEY}; # ignore users key if any
my $pachube = Net::Pachube->new();
ok($pachube, 'constructor');
is($pachube->url, 'http://www.pachube.com/api', 'url');
eval { $pachube->feed(1); };
like($@, qr/^No pachube api key defined\./, 'no key defined - get');
is($pachube->key('blahblahblah'), 'blahblahblah', 'key set');

{
  package MockUA;
  sub new {
    bless { }, 'MockUA';
  }
  sub default_header {
    $_[0]->{default_header} = $_[1];
  }
  sub request {
    push @{$_[0]->{req}}, $_[1];
    shift @{$_[0]->{resp}};
  }
  sub req {
    shift @{$_[0]->{req}};
  }
  sub response {
    my $self = shift;
    @{$self->{resp}} = @_;
    $self->{req} = [];
  }
  1;
}
my $ua = MockUA->new;
ok($pachube = Net::Pachube->new(user_agent => $ua,
                                key => 'blah'), 'constructor w/arguments');
is($pachube->user_agent, $ua, 'set user_agent to mock object');
is($pachube->url('http://localhost/api'), 'http://localhost/api', 'url');
$ua->response(HTTP::Response->new( '401', 'Unauthorized'));
is($pachube->feed(1), undef, 'new feed GET failed');
is($pachube->http_response->status_line, '401 Unauthorized',
     'not authorized error');

$ua->response(
  HTTP::Response->new('200', 'OK', undef,
                      q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="5" xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd">
  <environment updated="2009-04-30T22:24:11Z" id="1" creator="http://www.haque.co.uk">
    <title>Temperature</title>
    <feed>http://www.pachube.com/api/1.xml</feed>
    <status>live</status>
    <description>Temperature</description>
    <location domain="physical" exposure="outdoor" disposition="fixed">
      <name>Winchester, UK</name>
      <lat>51.0</lat>
      <lon>-1.3</lon>
    </location>
    <data id="0">
      <tag>temperature</tag>
      <value minValue="0.0" maxValue="34.0">22.3</value>
    </data>
  </environment>
</eeml>
}));
my $feed = $pachube->feed(1);
ok($feed, 'feed GET successful');
is($feed->title, 'Temperature', 'title');
is($feed->description, 'Temperature', 'description');
is($feed->feed_id, '1', 'id');
is($feed->feed_url, 'http://www.pachube.com/api/1.xml', 'feed');
is($feed->creator, 'http://www.haque.co.uk', 'creator');
is($feed->status, 'live', 'status');
is($feed->number_of_streams, 1, 'number of streams');
is($feed->data_value, 22.3, 'data value');
is(int $feed->data_min, 0, 'data min');
is(int $feed->data_max, 34, 'data max');
is($feed->data_tags, 'temperature', 'data tag');
is_deeply([sort keys %{$feed->location}],
          [qw/disposition domain exposure lat lon name/],
          'location structure');
is($feed->location('domain'), 'physical', 'location element');

$ua->response(
  HTTP::Response->new('200', 'OK', undef,
                      q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd" version="5">
    <environment updated="2007-05-04T18:13:51.0Z" creator="http://www.haque.co.uk" id="1">
        <title>A Room Somewhere</title>
        <feed>http://www.pachube.com/feeds/1.xml</feed>
        <status>frozen</status>
        <description>This is a room somewhere</description>
        <icon>http://www.roomsomewhere/icon.png</icon>
        <website>http://www.roomsomewhere/</website>
        <email>myemail@roomsomewhere</email>
        <location exposure="indoor" domain="physical" disposition="fixed">
            <name>My Room</name>
            <lat>32.4</lat>
            <lon>22.7</lon>
            <ele>0.2</ele>
        </location>
        <data id="0">
            <tag>temperature</tag>
            <value minValue="23.0" maxValue="48.0">36.2</value>
            <unit symbol="C" type="derivedSI">Celsius</unit>
        </data>
        <data id="1">
            <tag>blush</tag>
            <tag>redness</tag>
            <tag>embarrassment</tag>
            <value minValue="0.0" maxValue="100.0">84.0</value>
            <unit type="contextDependentUnits">blushesPerHour</unit>
        </data>
        <data id="2">
            <tag>length</tag>
            <tag>distance</tag>
            <tag>extension</tag>
            <value minValue="0.0">12.3</value>
            <unit symbol="m" type="basicSI">meter</unit>
        </data>
    </environment>
</eeml>
}));
ok($feed->get, 'feed refresh successful');
is($feed->number_of_streams, 3, 'new number of streams');
is_deeply([$feed->data_tags(4)], [], 'data tag');
is_deeply([$feed->data_tags(2)], [qw/length distance extension/], 'data tag 2');
is($feed->data_value(2), 12.3, 'data 2');
is($feed->data_min(2), '0.0', 'data min 2');
is($feed->data_max(2), undef, 'data max 2');

$ua->response(HTTP::Response->new('200', 'OK', undef, q{ }));
ok($feed->update(data => [9.2, 44]), 'put successful');
my $request = $ua->req;
is($request->uri, 'http://localhost/api/1.csv', 'request->uri');
is($request->method, 'PUT', 'request->method');
is($request->content, '9.2,44', 'request->content');

$ua->response(HTTP::Response->new('200', 'OK', undef, q{ }));
ok($feed->update(data => 44), 'put successful 2');
$request = $ua->req;
is($request->uri, 'http://localhost/api/1.csv', 'request->uri 2');
is($request->method, 'PUT', 'request->method 2');
is($request->content, '44', 'request->content 2');

$ua->response(
  HTTP::Response->new('201', 'OK',
                      [ Location => "http://www.pachube.com/api/2.xml" ],
                      q{ }),
  HTTP::Response->new('200', 'OK', undef,
                      q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="5" xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd">
  <environment updated="2009-04-30T22:24:11Z" id="2" creator="http://www.haque.co.uk">
    <title>Temperature</title>
    <feed>http://www.pachube.com/api/2.xml</feed>
    <status>live</status>
    <description>Temperature</description>
    <location domain="physical" exposure="outdoor" disposition="fixed">
      <name>Winchester, UK</name>
      <lat>51.0</lat>
      <lon>-1.3</lon>
    </location>
    <data id="0">
      <tag>temperature</tag>
      <value minValue="0.0" maxValue="34.0">22.3</value>
    </data>
  </environment>
</eeml>
}));
$feed = $pachube->create(title => "Outside Temperature");
ok($feed, 'create successful');
is($ua->req->content,
   q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd" version="5">
<environment>
  <title>Outside Temperature</title>
</environment>
</eeml>
}, 'post first request content');
is($ua->req->method, 'GET', 'second request is GET');
is($feed->feed_url, 'http://www.pachube.com/api/2.xml',
   'post result - new feed location');
is($feed->feed_id, '2', 'post result - new feed id');


$ua->response(HTTP::Response->new('200', 'OK but no location', undef, q{ }));
ok(!$pachube->create(title => "Outside Temperature"), 'post unsuccessful');
is($pachube->http_response->status_line,
   '200 OK but no location', 'status line');

$ua->response(HTTP::Response->new('422', 'Invalid', undef, q{ }));
ok(!$pachube->create(title => "Outside Temperature"), 'post unsuccessful');

$ua->response(
  HTTP::Response->new('200', 'OK',
                      [ Location => "http://www.pachube.com/api.xml" ],
                      q{ }));
ok(!$pachube->create(title => "Outside Temperature"), 'post unsuccessful');
is($pachube->http_response->header('Location'),
   'http://www.pachube.com/api.xml', 'post result - not a feed location');

eval { $pachube->create; };
like($@, qr/^New feed should have a 'title' attribute\./,
     'no title - post');

$ua->response(
  HTTP::Response->new('201', 'OK',
                      [ Location => "http://www.pachube.com/api/22.xml" ],
                      q{ }),
  HTTP::Response->new('200', 'OK', undef,
                      q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="5" xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd">
  <environment updated="2009-04-30T22:24:11Z" id="22" creator="http://www.haque.co.uk">
    <title>Temperature</title>
    <feed>http://www.pachube.com/api/22.xml</feed>
    <status>live</status>
    <description>Temperature</description>
    <location domain="physical" exposure="outdoor" disposition="fixed">
      <name>Winchester, UK</name>
      <lat>51.0</lat>
      <lon>-1.3</lon>
    </location>
    <data id="0">
      <tag>temperature</tag>
      <value minValue="0.0" maxValue="34.0">22.3</value>
    </data>
  </environment>
</eeml>
}));

$feed = $pachube->create(title => 'Outside Humidity',
                         description => 'Humidity outside',
                         website => 'http://www.example.com/',
                         icon => 'http://www.example.com/icon.png',
                         email => 'no-one@example.com',
                         exposure => 'outdoor',
                         disposition => 'fixed',
                         domain => 'mobile',
                         location_name => 'Middle of nowhere',
                         lat => 1,
                         lon => 2,
                         ele => 100,
                      );
is($ua->req->content,
   q{<?xml version="1.0" encoding="UTF-8"?>
<eeml xmlns="http://www.eeml.org/xsd/005"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="http://www.eeml.org/xsd/005 http://www.eeml.org/xsd/005/005.xsd" version="5">
<environment>
  <description>Humidity outside</description>
  <email>no-one@example.com</email>
  <icon>http://www.example.com/icon.png</icon>
  <location disposition="fixed" domain="mobile" exposure="outdoor">
    <name>Middle of nowhere</name>
    <ele>100</ele>
    <lat>1</lat>
    <lon>2</lon>
  </location>
  <title>Outside Humidity</title>
  <website>http://www.example.com/</website>
</environment>
</eeml>
}, 'post request->content - 2');
ok($feed, 'post successful');
is($feed->feed_url, 'http://www.pachube.com/api/22.xml',
   'post result - new feed location');
is($feed->feed_id, '22', 'post result - new feed id');

$ua->response(HTTP::Response->new('200', 'OK', undef, q{ }));
$feed = $pachube->feed(1, 0);
ok($feed->delete(), 'delete successful');
$request = $ua->req;
is($request->uri, 'http://localhost/api/1', 'request->uri');
is($request->method, 'DELETE', 'request->method');
is($request->content, '', 'request->content');
