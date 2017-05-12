#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use Data::Dumper;
#use Text::Diff;

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
my $fn = "t/04-other_port/other-port.dump";
$s->run_file($fn,"tcp port 8888");

my $request1 = bless({
                 '_protocol' => 'HTTP/1.1',
                 '_content' => '',
                 '_uri' => bless( do{\(my $o = 'http://desert-island.dynodns.net:8888/does_not_exist')}, 'URI::http' ),

                 '_headers' => bless( {
                                        'accept-charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                                        'user-agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7',
                                        'connection' => 'keep-alive',
                                        'keep-alive' => '300',
                                        'accept' => 'text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5',
                                        'accept-language' => 'en-us,en;q=0.5',
                                        'accept-encoding' => 'gzip,deflate',
                                        'host' => 'desert-island.dynodns.net:8888'
                                      }, 'HTTP::Headers' ),
                 '_method' => 'GET'
               }, 'HTTP::Request' );
my $request2 = bless( {
                    '_protocol' => 'HTTP/1.1',
                    '_content' => '',
                    '_uri' => bless( do{\(my $o = 'http://desert-island.dynodns.net:8888/favicon.ico')}, 'URI::http' ),
                    '_headers' => bless( {
                                           'accept-charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.7',
                                           'user-agent' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.7.12) Gecko/20050915 Firefox/1.0.7',
                                           'connection' => 'keep-alive',
                                           'keep-alive' => '300',
                                           'accept' => 'image/png,*/*;q=0.5',
                                           'accept-language' => 'en-us,en;q=0.5',
                                           'accept-encoding' => 'gzip,deflate',
                                           'host' => 'desert-island.dynodns.net:8888'
                                         }, 'HTTP::Headers' ),
                    '_method' => 'GET'
                  }, 'HTTP::Request' );

my $response1 = bless( {
                     '_protocol' => 'HTTP/1.1',
                     '_content' => qq{<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>Object not found!</title>
<link rev="made" href="mailto:%5bno%20address%20given%5d" />
<style type="text/css"><!--/*--><![CDATA[/*><!--*/ \n    body { color: #000000; background-color: #FFFFFF; }
    a:link { color: #0000CC; }
    p, address {margin-left: 3em;}
    span {font-size: smaller;}
/*]]>*/--></style>
</head>

<body>
<h1>Object not found!</h1>
<p>

    The requested URL was not found on this server.
\n  \n
    If you entered the URL manually please check your
    spelling and try again.
\n  \n
</p>
<p>
If you think this is a server error, please contact
the <a href="mailto:%5bno%20address%20given%5d">webmaster</a>.

</p>

<h2>Error 404</h2>
<address>
  <a href="/">desert-island.dynodns.net</a><br />
  \n  <span>Fri Nov  4 19:06:34 2005<br />
  Apache/2.0.49 (Linux/SuSE)</span>
</address>
</body>
</html>

},
                     '_rc' => '404',
                     '_headers' => bless( {
                                            'content-type' => 'text/html; charset=iso-8859-1',
                                            'connection' => 'Keep-Alive',
                                            'keep-alive' => 'timeout=15, max=100',
                                            'transfer-encoding' => 'chunked',
                                            'date' => 'Fri, 04 Nov 2005 19:06:34 GMT',
                                            'server' => 'Apache/2.0.49 (Linux/SuSE)',
                                            'accept-ranges' => 'bytes',
                                            'vary' => 'accept-language,accept-charset',
                                            'content-language' => 'en',
                                          }, 'HTTP::Headers' ),
                     '_msg' => "Not Found\r"
                   }, 'HTTP::Response' );
$response1->{_content} =~ s!\r\n!\n!mg;

my $response2 = bless( {
                     '_protocol' => 'HTTP/1.1',
                     '_content' => qq{<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title>Object not found!</title>
<link rev="made" href="mailto:%5bno%20address%20given%5d" />
<style type="text/css"><!--/*--><![CDATA[/*><!--*/ \n    body { color: #000000; background-color: #FFFFFF; }
    a:link { color: #0000CC; }
    p, address {margin-left: 3em;}
    span {font-size: smaller;}
/*]]>*/--></style>
</head>

<body>
<h1>Object not found!</h1>
<p>

    The requested URL was not found on this server.
\n  \n
    If you entered the URL manually please check your
    spelling and try again.
\n  \n
</p>
<p>
If you think this is a server error, please contact
the <a href="mailto:%5bno%20address%20given%5d">webmaster</a>.

</p>

<h2>Error 404</h2>
<address>
  <a href="/">desert-island.dynodns.net</a><br />
  \n  <span>Fri Nov  4 19:06:35 2005<br />
  Apache/2.0.49 (Linux/SuSE)</span>
</address>
</body>
</html>

},
                     '_rc' => '404',
                     '_headers' => bless( {
                                            'content-type' => 'text/html; charset=iso-8859-1',
                                            'connection' => 'Keep-Alive',
                                            'keep-alive' => 'timeout=15, max=99',
                                            'transfer-encoding' => 'chunked',
                                            'date' => 'Fri, 04 Nov 2005 19:06:35 GMT',
                                            'server' => 'Apache/2.0.49 (Linux/SuSE)',
                                            'accept-ranges' => 'bytes',
                                            'vary' => 'accept-language,accept-charset',
                                            'content-language' => 'en',
                                          }, 'HTTP::Headers' ),
                     '_msg' => "Not Found\r"
                   }, 'HTTP::Response' );
$response2->{_content} =~ s!\r\n!\n!mg;

delete $_->{_headers}->{'::std_case'} for @requests;
is_deeply(\@requests, [$request1,$request2], "Got the expected requests")
  or diag Dumper \@requests;

delete $_->[0]->{_headers}->{'::std_case'} for @responses;
is_deeply(\@responses, [[$response1,$request1],[$response2,$request2]], "Got the expected responses")
  or diag Dumper \@responses;

#my $diff = diff \($response1->content, $responses[0]->[0]->content);
#my $diff = diff \($response2->content, $responses[1]->[0]->content);
#diag $diff;

my @stale = $s->stale_connections(10,1131132141);
is_deeply(\@stale,[],"No stale connections at a certain point back in time");

my @live = $s->live_connections(10,1131132141);
is scalar(@live), 1, "One connection was open back in time";

@stale = $s->stale_connections();
is scalar(@stale),1,"One stale connection now";

@live = $s->live_connections();
is scalar(@live), 0, "No live connections now";

is $stale_count, 13, "13 stale connections/packets detected.";
