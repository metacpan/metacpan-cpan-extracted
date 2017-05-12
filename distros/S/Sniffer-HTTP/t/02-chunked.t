#!/usr/bin/perl -w
use strict;
use Test::More tests => 4;
use Data::Dumper;

use NetPacket::TCP;

my (@responses,@requests);
sub collect_response {
  my ($res,$req,$conn) = @_;
  push @responses, [$res,$req];
  #diag $res->code,"\n";
};
sub collect_request {
  my ($req,$conn) = @_;
  push @requests, $req;
  #diag $res->code,"\n";
};

use Sniffer::HTTP;
use Net::Pcap::FindDevice;

if ($^O ne "MSWin32" and $> != 0) {
    diag "You're not running the tests as root - they might fail";
};

my $name;
my $ok = eval { $name = find_device(); 1 };
{
    my $err = $@;
    if (not $ok) {
        SKIP: {
            skip "Did not find any capture device", 4;
        };
        exit
    };
};

my $s = Sniffer::HTTP->new(
  callbacks => {
    log      => sub { diag $_[0] },
    #tcp_log  => sub { diag "TCP: $_[0]" },
    request  => \&collect_request,
    response => \&collect_response,
  },
  stale_connection => sub {},
);

my @packets = glob "t/02-chunked/dump-raw.pl-dump-raw.*.*.dump";

for (@packets) {
  #diag $_;
  open my $fh, "<", $_
    or die "Couldn't read $_: $!";
  binmode $fh;
  my $data = do { local $/; <$fh> };

  my $tcp = NetPacket::TCP->decode( $data );
  #diag $tcp->{data};
  #diag sprintf "%s:%s\t%s\t%s\t%s\t(%s)\n", @{$tcp}{qw(src_port dest_port seqnum acknum)}, $tcp->{seqnum} + length($tcp->{data}), length ($tcp->{data});

  $s->handle_tcp_packet($tcp);
};

my $request = bless( {
                   '_protocol' => 'HTTP/1.1',
                   '_content' => '',
                   '_uri' => bless( do{\(my $o = 'http://www.corion.net/does_not_exist')}, 'URI::http' ),
                   '_headers' => bless( {
                                          'user-agent' => 'lwp-request/2.06',
                                          'connection' => 'TE, close',
                                          'te' => 'deflate,gzip;q=0.3',
                                          'host' => 'www.corion.net'
                                        }, 'HTTP::Headers' ),
                   '_method' => 'GET'
                 }, 'HTTP::Request' );
my $response = bless( {
                     '_protocol' => 'HTTP/1.1',
                     '_content' => '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD>
<TITLE>404 Not Found</TITLE>
</HEAD><BODY>
<H1>Not Found</H1>
The requested URL /does_not_exist was not found on this server.<P>
</BODY></HTML>
',
                     '_rc' => '404',
                     '_headers' => bless( {
                                            'content-type' => 'text/html; charset=iso-8859-1',
                                            'connection' => 'close',
                                            'transfer-encoding' => 'chunked',
                                            'date' => 'Sun, 23 Oct 2005 19:58:38 GMT',
                                            'server' => 'Apache/1.3.31 (Unix)'
                                          }, 'HTTP::Headers' ),
                     '_msg' => "Not Found\r"
                   }, 'HTTP::Response' );

is_deeply(\@requests, [$request], "Got the expected requests");
is_deeply(\@responses, [[$response,$request]], "Got the expected responses")
  or diag Dumper \@responses;

my @stale = $s->stale_connections;
is_deeply(\@stale,[],"No stale connections");

my @live = $s->live_connections;
is_deeply \@live, [], "All connections were closed"
    or do {
      diag $_->flow
          for @live;
    };
