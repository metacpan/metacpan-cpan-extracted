#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 6;
use Test::Fake::HTTPD;
use HTTP::Response;

### Test 1: require
use_ok('Shout');
ok($Shout::VERSION, 'Version');

my $fail = 0;
foreach my $constname (qw(
	SHOUTERR_BUSY SHOUTERR_CONNECTED SHOUTERR_INSANE SHOUTERR_MALLOC
	SHOUTERR_METADATA SHOUTERR_NOCONNECT SHOUTERR_NOLOGIN SHOUTERR_SOCKET
	SHOUTERR_SUCCESS SHOUTERR_UNCONNECTED SHOUTERR_UNSUPPORTED
	SHOUT_FORMAT_MP3 SHOUT_FORMAT_OGG SHOUT_FORMAT_VORBIS
	SHOUT_PROTOCOL_HTTP SHOUT_PROTOCOL_ICY SHOUT_PROTOCOL_XAUDIOCAST
	SHOUT_THREADSAFE)) {
  next if (eval "my \$a = Shout::$constname(); 1");
  if ($@ =~ /^Your vendor has not defined Shout macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}

ok( $fail == 0 , 'Constants' );

my $httpd = run_http_server {
    my $req = shift;
    if (!$req->header('Authorization') || $req->header('Authorization') ne 'Basic c291cmNlOnBhJCR3b3JkIQ==') {
        return HTTP::Response->new( 401, "Need authorization" );
    }
    return HTTP::Response->new( 200 );
};

### Test 2: constructor
my $streamer = Shout->new(
	host		=> "127.0.0.1",
	port		=> $httpd->port,
	mount		=> "testing",
	password	=> 'pa$$word!',
);
ok( defined $streamer, 'Constructor' );

### Test 3: connect
ok($streamer->open(), 'Connect');
ok(!$streamer->get_errno, 'Errno');

$streamer->close;
