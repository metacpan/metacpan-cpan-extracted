#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use Data::Dumper;

my (@responses,@requests);
sub collect_response {
  my ($res,$req,$conn) = @_;
  push @responses, [$res,$req];
};
sub collect_request {
  my ($req,$conn) = @_;
  push @requests, $req;
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
            skip "Did not find any capture device", 7;
        };
        exit
    };
};

my $stale_count;

my $s = Sniffer::HTTP->new(
  callbacks => {
    log      => sub { diag $_[0] },
    #tcp_log  => sub { diag "TCP: $_[0]" },
    request  => \&collect_request,
    response => \&collect_response,
  },
  stale_connection => sub { $stale_count++ },
);

my $err;
my $fn = "t/03-libpcap_dump/libpcap.dump";
$s->run_file($fn,"tcp port 80");

my $request1 = bless({
                 '_protocol' => 'HTTP/1.1',
                 '_content' => '',
                 '_uri' => bless( do{\(my $o = 'http://corion.net/does_not_exists')}, 'URI::http' ),

                 '_headers' => bless( {
                                        'accept-charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                                        'user-agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7',
                                        'connection' => 'keep-alive',
                                        'keep-alive' => '300',
                                        'accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
                                        'accept-language' => 'en-us,en;q=0.5',
                                        'accept-encoding' => 'gzip,deflate',
                                        'host' => 'corion.net'
                                      }, 'HTTP::Headers' ),
                 '_method' => 'GET'
               }, 'HTTP::Request' );
my $request2 = bless( {
                   '_protocol' => 'HTTP/1.1',
                   '_content' => '',
                   '_uri' => bless( do{\(my $o = 'http://corion.net/favicon.ico')}, 'URI::http' ),
                   '_headers' => bless( {
                                          'accept-charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                                          'user-agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7',
                                          'connection' => 'keep-alive',
                                          'keep-alive' => '300',
                                          'accept' => 'image/png,*/*;q=0.5',
                                          'accept-language' => 'en-us,en;q=0.5',
                                          'accept-encoding' => 'gzip,deflate',
                                          'host' => 'corion.net'
                                        }, 'HTTP::Headers' ),
                   '_method' => 'GET'
                 }, 'HTTP::Request' );

my $response1 = bless( {
                     '_protocol' => 'HTTP/1.1',
                     '_content' => '<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<HTML><HEAD>
<TITLE>404 Not Found</TITLE>
</HEAD><BODY>
<H1>Not Found</H1>
The requested URL /does_not_exists was not found on this server.<P>
</BODY></HTML>
',
                     '_rc' => '404',
                     '_headers' => bless( {
                                            'content-type' => 'text/html; charset=iso-8859-1',
                                            'connection' => 'Keep-Alive',
                                            'keep-alive' => 'timeout=3, max=100',
                                            'transfer-encoding' => 'chunked',
                                            'date' => 'Fri, 04 Nov 2005 15:28:40 GMT',
                                            'server' => 'Apache/1.3.31 (Unix)',
                                          }, 'HTTP::Headers' ),
                     '_msg' => "Not Found"
                   }, 'HTTP::Response' );


my $response2 = bless( {
                   '_protocol' => 'HTTP/1.1',
                   '_content' => qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">\n<HTML><HEAD>\n<TITLE>404 Not Found</TITLE>\n</HEAD><BODY>\n<H1>Not Found</H1>\nThe requested URL /favicon.ico was not found on this server.<P>\n</BODY></HTML>\n},
                                       '_rc' => '404',
                    '_headers' => bless( {
                                           'content-type' => 'text/html; charset=iso-8859-1',
                                           'connection' => 'Keep-Alive',
                                           'keep-alive' => 'timeout=3, max=99',
                                           'transfer-encoding' => 'chunked',
                                           'date' => 'Fri, 04 Nov 2005 15:28:41 GMT',
                                           'server' => 'Apache/1.3.31 (Unix)',
                                         }, 'HTTP::Headers' ),
                    '_msg' => "Not Found",
                 }, 'HTTP::Response' );
delete $_->{_headers}->{'::std_case'} for @requests;
delete $response1->{_headers}->{'::std_case'};
delete $response2->{_headers}->{'::std_case'};
is_deeply(\@requests, [$request1,$request2], "Got the expected requests");

#my $c1 = $response2->content;
#my $e1 = $responses[1]->[0]->content;
#for ($c1,$e1) {
#  s!\r\n!\\r\\n\r\n!mg;
#}
#diag "Expected :$c1";
#diag "     Got :$e1";

for my $pair (@responses) {
    delete $pair->[0]->{_headers}->{'::std_case'};
    delete $pair->[1]->{_headers}->{'::std_case'};
};

is_deeply(\@responses, [[$response1,$request1],[$response2,$request2]], "Got the expected responses")
  or diag Dumper \$responses[1];

my @stale = $s->stale_connections(10,1131119068);
is_deeply(\@stale,[],"No stale connections back in time");

my @live = $s->live_connections(10,1131119068);
is scalar(@live), 1, "One connection is open";

@stale = $s->stale_connections();
is scalar(@stale),1,"One stale connection now";

@live = $s->live_connections();
is scalar(@live), 0, "No live connections now";

is $stale_count, 11, "11 stale connections/packets detected.";
