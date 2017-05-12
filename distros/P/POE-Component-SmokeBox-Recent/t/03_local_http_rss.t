use strict;
use warnings;
use Test::More tests => 6;
use POE qw(Component::SmokeBox::Recent Filter::HTTP::Parser);
use Test::POE::Server::TCP;
use HTTP::Date qw( time2str );
use HTTP::Response;

my $xmldata = q|<?xml version="1.0"?>
<rss version="2.0"
  xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
><channel>
<title>Recent CPAN Uploads</title>
<description>The 150 most recent modules uploaded to CPAN</description>
<link>http://www.cpan.org/modules/01modules.mtime.html</link>
<language>en</language>
<sy:updateFrequency>3</sy:updateFrequency>
<sy:updatePeriod>daily</sy:updatePeriod>
<sy:updateBase>1970-01-01T12:24+00:00</sy:updateBase>
<ttl>480</ttl>
<webMaster>cpan&#64;perl.org</webMaster>

<item>
  <title>Bit-Grep-0.01 : Salva</title>
  <link>http://www.cpan.org/modules/by-authors/id/S/SA/SALVA/Bit-Grep-0.01.tar.gz</link>
  <description>Salva uploaded S/SA/SALVA/Bit-Grep-0.01.tar.gz (45k) on 02 Sep 2010</description>
  <guid isPermaLink="false">Bit-Grep-0.01.tar.gz</guid>
  <comments>http://search.cpan.org/~salva/Bit/</comments>
</item>

<item>
  <title>Catalyst-Runtime-5.80027 : Bobtfish</title>
  <link>http://www.cpan.org/modules/by-authors/id/B/BO/BOBTFISH/Catalyst-Runtime-5.80027.tar.gz</link>
  <description>Bobtfish uploaded B/BO/BOBTFISH/Catalyst-Runtime-5.80027.tar.gz (246k) on 02 Sep 2010</description>
  <guid isPermaLink="false">Catalyst-Runtime-5.80027.tar.gz</guid>
  <comments>http://search.cpan.org/~bobtfish/Catalyst/</comments>
</item>

<item>
  <title>WebService-GData-0.0102 : Shiriru</title>
  <link>http://www.cpan.org/modules/by-authors/id/S/SH/SHIRIRU/WebService-GData-0.0102.tar.gz</link>
  <description>Shiriru uploaded S/SH/SHIRIRU/WebService-GData-0.0102.tar.gz (27k) on 02 Sep 2010</description>
  <guid isPermaLink="false">WebService-GData-0.0102.tar.gz</guid>
  <comments>http://search.cpan.org/~shiriru/WebService/</comments>
</item>

<item>
  <title>JSON-JOM-Plugins-JsonT-0.001 : Tobyink</title>
  <link>http://www.cpan.org/modules/by-authors/id/T/TO/TOBYINK/JSON-JOM-Plugins-JsonT-0.001.tar.gz</link>
  <description>Tobyink uploaded T/TO/TOBYINK/JSON-JOM-Plugins-JsonT-0.001.tar.gz (28k) on 02 Sep 2010</description>
  <guid isPermaLink="false">JSON-JOM-Plugins-JsonT-0.001.tar.gz</guid>
  <comments>http://search.cpan.org/~tobyink/JSON/</comments>
</item>

<item>
  <title>JSON-T-0.100 : Tobyink</title>
  <link>http://www.cpan.org/modules/by-authors/id/T/TO/TOBYINK/JSON-T-0.100.tar.gz</link>
  <description>Tobyink uploaded T/TO/TOBYINK/JSON-T-0.100.tar.gz (37k) on 02 Sep 2010</description>
  <guid isPermaLink="false">JSON-T-0.100.tar.gz</guid>
  <comments>http://search.cpan.org/~tobyink/JSON/</comments>
</item>

<item>
  <title>Router-Simple-0.07 : Tokuhirom</title>
  <link>http://www.cpan.org/modules/by-authors/id/T/TO/TOKUHIROM/Router-Simple-0.07.tar.gz</link>
  <description>Tokuhirom uploaded T/TO/TOKUHIROM/Router-Simple-0.07.tar.gz (33k) on 02 Sep 2010</description>
  <guid isPermaLink="false">Router-Simple-0.07.tar.gz</guid>
  <comments>http://search.cpan.org/~tokuhirom/Router/</comments>
</item>

</channel></rss>
|;

my @tests = qw(
T/TO/TOKUHIROM/Router-Simple-0.07.tar.gz
T/TO/TOBYINK/JSON-T-0.100.tar.gz
T/TO/TOBYINK/JSON-JOM-Plugins-JsonT-0.001.tar.gz
S/SH/SHIRIRU/WebService-GData-0.0102.tar.gz
B/BO/BOBTFISH/Catalyst-Runtime-5.80027.tar.gz
S/SA/SALVA/Bit-Grep-0.01.tar.gz
);

POE::Session->create(
   package_states => [
        main => [qw(_start _stop testd_registered testd_client_input _recent)],
   ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    filter => POE::Filter::HTTP::Parser->new( type => 'server' ),
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{url} = "http://127.0.0.1:$port/";
  return;
}

sub _stop {
  pass('Everything has stopped');
  return;
}

sub testd_registered {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  POE::Component::SmokeBox::Recent->recent(
      url => $heap->{url},
      event => '_recent',
      context => 'Blah Blah Blah',
      rss => 1,
  );
  return;
}

sub testd_client_input {
  my ($kernel, $heap, $id, $req) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($req->as_string);
  isa_ok($req, 'HTTP::Request');
  is( $req->uri->path, '/modules/01modules.mtime.rss', 'Requested /modules/01modules.mtime.rss' );
  my $resp = HTTP::Response->new( 200 );
  $resp->protocol('HTTP/1.1');
  $resp->header('Content-Type', 'application/rss+xml');
  $resp->header('Date', time2str(time));
  $resp->header('Server', 'Test-POE-Server-TCP/' . $Test::POE::Server::TCP::VERSION);
  $resp->header('Connection', 'close');
  $resp->content( $xmldata );
  use bytes;
  $resp->header('Content-Length', length $resp->content);
  $heap->{testd}->send_to_client($id, $resp);
  return;
}

sub _recent {
  my ($heap,$hashref) = @_[HEAP,ARG0];
  ok( $hashref->{recent}, 'We got a RECENT listing' );
  is_deeply( $hashref->{recent}, \@tests, 'What we got matched' );
  ok( $hashref->{context} eq 'Blah Blah Blah', 'Context was okay' );
  $heap->{testd}->shutdown();
  delete $heap->{testd};
  return;
}
