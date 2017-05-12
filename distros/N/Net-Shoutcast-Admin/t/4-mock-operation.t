# $Id: 4-mock-operation.t 317 2008-03-19 00:21:48Z davidp $

# mock tests for Net::Shoutcast::Admin
# use Test::MockObject::Extends to fake communication with a Shoutcast server,
# returning the contents of example.xml, so we can test that the module
# handles it correctly and gives us the data we expect.

use strict;
use warnings;
use Test::More;
use lib '../lib';

eval "use Test::MockObject::Extends";
plan skip_all => "Test::MockObject::Extends required for mock testing" 
    if $@;

# OK, we have Test::MockObject::Extends, we're good to go
plan tests => 12;


use_ok( 'Net::Shoutcast::Admin' );

my $shoutcast = Net::Shoutcast::Admin->new(
    host => 'testhost',
    port => 1234,
    admin_password => 'testpass',
);

# This wraps the ua so that methods can be overridden for testing purposes
my $mocked_ua = 
    $shoutcast->{ua} = Test::MockObject::Extends->new( $shoutcast->{ua} );

$mocked_ua->mock("get", \&mock_get);
$mocked_ua->mock("is_success", sub { 1 });

my $example_xml = join '', <DATA>;

sub mock_get {
    my ($self, $url) = @_;
    
    is($url, "http://testhost:1234/admin.cgi?pass=testpass&mode=viewxml",
        "URL for status XML is correct");
    
    # prepare a fake response object to return:
    my $res = Test::MockObject->new();
    $res->set_true( "is_success" );
    
    
    $res->set_always('content', $example_xml);
    return $res;
}


# right, now try a few requests;

my $song = $shoutcast->currentsong;
isa_ok($song, 'Net::Shoutcast::Admin::Song',
    '->currentsong returned an N::S::A::Song object');
    
is($song->title, 'Fake Song Title', 'Current song title is correct');



my $listeners_count = $shoutcast->listeners;
is($listeners_count, 2, '->listeners() returns 2 listeners in scalar context');


my @listeners = $shoutcast->listeners;
is(@listeners, 2, '->listeners returned 2 listeners in scalar context');
isa_ok($listeners[0], 'Net::Shoutcast::Admin::Listener',
    'first element of listeners list is a N::S::A::Listener object');
    
is($listeners[0]->host, '127.0.0.1', 'first listener has correct host');
is($listeners[0]->agent, 'testclient/1.2.3', 'first listener has correct agent');
is($listeners[0]->listen_time, 67, 'first listener has correct listen_time');


#diag("Total listeners: " . $shoutcast->listeners);

#diag("Current song: "    . $shoutcast->currentsong->title);


__DATA__
<?xml version="1.0" encoding="utf-8"?>
<SHOUTCASTSERVER>
    <CURRENTLISTENERS>2</CURRENTLISTENERS>
    <PEAKLISTENERS>16</PEAKLISTENERS>
    <MAXLISTENERS>64</MAXLISTENERS>
    <REPORTEDLISTENERS>2</REPORTEDLISTENERS>
    <AVERAGETIME>26255</AVERAGETIME>
    <SERVERGENRE>mixed</SERVERGENRE>
    <SERVERURL>http://example.com/</SERVERURL>
    <SERVERTITLE>Fake Radio Stream</SERVERTITLE>
    <SONGTITLE>Fake Song Title</SONGTITLE>
    <SONGURL>http://www.example.net/</SONGURL>
    <IRC>#example</IRC>
    <ICQ />
    <AIM />
    <WEBHITS>163038</WEBHITS>
    <STREAMHITS>11574</STREAMHITS>
    <STREAMSTATUS>1</STREAMSTATUS>
    <BITRATE>128</BITRATE>
    <CONTENT>audio/mpeg</CONTENT>
    <VERSION>1.9.8</VERSION>
    <WEBDATA>
        <INDEX>1828</INDEX>
        <LISTEN>755</LISTEN>
        <PALM7>0</PALM7>
        <LOGIN>0</LOGIN>
        <LOGINFAIL>51</LOGINFAIL>
        <PLAYED>17</PLAYED>
        <COOKIE>5</COOKIE>
        <ADMIN>155</ADMIN>
        <UPDINFO>20059</UPDINFO>
        <KICKSRC>117</KICKSRC>
        <KICKDST>0</KICKDST>
        <UNBANDST>0</UNBANDST>
        <BANDST>0</BANDST>
        <VIEWBAN>1</VIEWBAN>
        <UNRIPDST>0</UNRIPDST>
        <RIPDST>0</RIPDST>
        <VIEWRIP>1</VIEWRIP>
        <VIEWXML>139881</VIEWXML>
        <VIEWLOG>1</VIEWLOG>
        <INVALID>158</INVALID>
    </WEBDATA>
    <LISTENERS>
        <LISTENER>
            <HOSTNAME>127.0.0.1</HOSTNAME>
            <USERAGENT>testclient/1.2.3</USERAGENT>
            <UNDERRUNS>3</UNDERRUNS>
            <CONNECTTIME>67</CONNECTTIME>
            <POINTER>0</POINTER>
            <UID>11575</UID>
        </LISTENER>
        <LISTENER>
            <HOSTNAME>127.0.0.2</HOSTNAME>
            <USERAGENT>badgerous/3.2.1</USERAGENT>
            <UNDERRUNS>0</UNDERRUNS>
            <CONNECTTIME>351</CONNECTTIME>
            <POINTER>0</POINTER>
            <UID>11577</UID>
        </LISTENER>
    </LISTENERS>
    <SONGHISTORY>
        <SONG>
            <PLAYEDAT>1205868797</PLAYEDAT>
            <TITLE>15 9PM (Till I Come) (Signum Mix)</TITLE>
        </SONG>
        <SONG>
            <PLAYEDAT>1205868345</PLAYEDAT>
            <TITLE>14 - I Get Lost - Eric Clapton</TITLE>
        </SONG>
        <SONG>
            <PLAYEDAT>1205868066</PLAYEDAT>
            <TITLE>01 - Headstrong - Trapt</TITLE>
        </SONG>
        <SONG>
            <PLAYEDAT>1205867953</PLAYEDAT>
            <TITLE>03 - Blur - Song 2</TITLE>
        </SONG>
        <SONG>
            <PLAYEDAT>1205867567</PLAYEDAT>
            <TITLE>20 - Lynyrd Skynyrd - Free Bird</TITLE>
        </SONG>
    </SONGHISTORY>
</SHOUTCASTSERVER>
