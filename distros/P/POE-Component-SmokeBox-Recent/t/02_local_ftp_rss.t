use strict;
use warnings;
use Test::More;
#sub POE::Component::Client::FTP::DEBUG () { 1 }
use POE qw(Component::SmokeBox::Recent);
use Test::POE::Server::TCP;

my @data = qw|
<?xml version="1.0"?>
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

my $size = length( join "\n", @data );

my @tests = qw(
T/TO/TOKUHIROM/Router-Simple-0.07.tar.gz
T/TO/TOBYINK/JSON-T-0.100.tar.gz
T/TO/TOBYINK/JSON-JOM-Plugins-JsonT-0.001.tar.gz
S/SH/SHIRIRU/WebService-GData-0.0102.tar.gz
B/BO/BOBTFISH/Catalyst-Runtime-5.80027.tar.gz
S/SA/SALVA/Bit-Grep-0.01.tar.gz
);

my %tests = (
   'USER anonymous'     => '331 Any password will work',
   'PASS anon@anon.org' => '230 Any password will work',
#   'SIZE /pub/CPAN/RECENT' => '213 ' . $size,
   'QUIT'               => '221 Goodbye.',
);

plan tests => 9;

POE::Session->create(
   package_states => [
	main => [qw(
			_start
			_stop
			testd_registered
			testd_connected
			testd_disconnected
			testd_client_input
                        testd_client_input
                        datac_socket_failed
                        datac_connected
                        datac_client_flushed
			_recent
		)],
   ],
   heap => { tests => \%tests, },
);

$poe_kernel->run();
exit 0;

sub _start {
  my $heap = $_[HEAP];
  $heap->{testd} = Test::POE::Server::TCP->spawn(
    address => '127.0.0.1',
  );
  my $port = $heap->{testd}->port;
  $heap->{url} = "ftp://127.0.0.1:$port/pub/CPAN/";
  return;
}

sub _stop {
  pass("Done");
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

sub testd_connected {
  my ($kernel,$heap,$id,$client_ip,$client_port,$server_ip,$server_port) = @_[KERNEL,HEAP,ARG0..ARG4];
  diag("$client_ip,$client_port,$server_ip,$server_port\n");
  my @banner = (
	'220---------- Welcome to Pure-FTPd [privsep] ----------',
	'220-You are user number 228 of 1000 allowed.',
	'220-Local time is now 18:46. Server port: 21.',
	'220-Only anonymous FTP is allowed here',
	'220 You will be disconnected after 30 minutes of inactivity.',
  );
  pass("Client connected");
  $heap->{testd}->send_to_client( $id, $_ ) for @banner;
  return;
}

sub testd_disconnected {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  pass("Client disconnected");
  $heap->{testd}->shutdown();
  delete $heap->{testd};
  return;
}

sub testd_client_input {
  my ($kernel, $heap, $id, $input) = @_[KERNEL, HEAP, ARG0, ARG1];
  diag($input);
  if ( defined $heap->{tests}->{ $input } ) {
     pass($input);
     my $response = delete $heap->{tests}->{ $input };
     $heap->{testd}->disconnect( $id ) unless scalar keys %{ $heap->{tests} };
     $heap->{testd}->send_to_client( $id, $response );
  }
  if ( $input =~ /^PASV/ ) {
     $heap->{client} = $id;
     $heap->{datac} = Test::POE::Server::TCP->spawn(
	address => '127.0.0.1',
	prefix => 'datac',
     );
     my $port = $heap->{datac}->port;
     $heap->{testd}->send_to_client( $id, '227 Entering Passive Mode (' . join(',', split(/\./,'127.0.0.1'), (int($port / 256), $port % 256) ) . ').' );
  }
  if ( $input =~ /^RETR/ ) {
    $heap->{testd}->send_to_client( $heap->{client}, '150 Opening ASCII mode data connection for file list' );
    $heap->{client} = $id;
    return unless $heap->{dataconn};
    $heap->{datac}->send_to_client( $heap->{dataconn}, shift @data );
    $heap->{nlst} = \@data;
  }
  return;
}

sub datac_socket_failed {
}

sub datac_connected {
  my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];
#  diag("Data connection: $id\n");
  $heap->{dataconn} = $id;
  return;
}

sub datac_client_flushed {
  my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];
  my $data = shift @{ $heap->{nlst} };
  if ( $data ) {
    $heap->{datac}->send_to_client( $id, $data );
    return;
  }
  delete $heap->{nlst};
  $heap->{testd}->send_to_client( $heap->{client}, '226 Closing data connection.' );
  $heap->{datac}->shutdown();
  delete $heap->{datac};
  return;
}

sub _recent {
  my ($heap,$hashref) = @_[HEAP,ARG0];
  ok( $hashref->{recent}, 'We got a RECENT listing' );
  is_deeply( $hashref->{recent}, \@tests, 'What we got matched' );
  ok( $hashref->{context} eq 'Blah Blah Blah', 'Context was okay' );
#  $heap->{testd}->shutdown();
#  delete $heap->{testd};
  return;
}

 sub _default {
     my ($event, $args) = @_[ARG0 .. $#_];
     return 0 if $event eq '_child';
     my @output = ( "$event: " );

     for my $arg (@$args) {
         if ( ref $arg eq 'ARRAY' ) {
             push( @output, '[' . join(' ,', @$arg ) . ']' );
         }
         else {
             push ( @output, "'$arg'" );
         }
     }
     print join ' ', @output, "\n";
     return 0;
 }
