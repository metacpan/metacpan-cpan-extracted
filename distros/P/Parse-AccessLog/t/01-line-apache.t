#!perl

use strict;
use warnings;
use Test::More tests => 27;

# only used for testing...
use Text::Diff;
use FreezeThaw qw(freeze);

BEGIN {
    use_ok( 'Parse::AccessLog' ) || print "Bail out!\n";
}

my $p = new_ok('Parse::AccessLog');

# apache
my $log_line = q{127.0.0.1 - - [22/Jan/2013:13:39:21 -0600] "HEAD /info.php HTTP/1.1" 200 - "-" "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5"};
my $log_line_unchomped = $log_line . "\n";

my $log_line_ipv6 = q{::1 - - [22/Jan/2013:13:39:17 -0600] "HEAD /info.php HTTP/1.1" 200 - "-" "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5"};

my ($rec, $rec_w_newline, $v6rec);

# ========================================================================
# lines with/wo newline should be transparently processed - 1 test
# ========================================================================
$rec = $p->parse($log_line);
$rec_w_newline = $p->parse($log_line_unchomped);
is( length(diff(\freeze($rec), \freeze($rec_w_newline))), 0,
    'newline transparently processed' );
undef $rec;
undef $rec_w_newline;

# ========================================================================
# parse() called as CLASS method - 8 tests
# ========================================================================
$rec = Parse::AccessLog->parse($log_line);
is($rec->{remote_addr}, '127.0.0.1',
    'parse() called as CLASS method - got IPv4');
is($rec->{request}    , 'HEAD /info.php HTTP/1.1', 'got request');
is($rec->{time_local} , '22/Jan/2013:13:39:21 -0600', 'got local time');
is($rec->{status}     , 200, 'got HTTP status code');
is($rec->{user_agent} ,
    "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5",
    'got user-agent string');
is($rec->{bytes_sent} , '-', 'got bytes_sent (apache uses "-" in place of 0)');
is($rec->{referer} , '-', 'got referer');
is($rec->{remote_user} , '-', 'got remote_user');
undef $rec;

# ========================================================================
# parse() called as OBJECT method - 8 tests
# ========================================================================
$rec = $p->parse($log_line);
is($rec->{remote_addr}, '127.0.0.1',
    'parse() called as OBJECT method - got IPv4');
is($rec->{request}    , 'HEAD /info.php HTTP/1.1', 'got request');
is($rec->{time_local} , '22/Jan/2013:13:39:21 -0600', 'got local time');
is($rec->{status}     , 200, 'got HTTP status code');
is($rec->{user_agent} ,
    "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5",
    'got user-agent string');
is($rec->{bytes_sent} , '-', 'got bytes_sent (apache uses "-" in place of 0)');
is($rec->{referer} , '-', 'got referer');
is($rec->{remote_user} , '-', 'got remote_user');
undef $rec;

# ========================================================================
# parse a line with IPV6 address - 8 tests
# ========================================================================
$v6rec = $p->parse($log_line_ipv6);
is($v6rec->{remote_addr}, '::1', 'Parsed IPV6 remote_addr');
is($v6rec->{request}    , 'HEAD /info.php HTTP/1.1', 'got request');
is($v6rec->{time_local} , '22/Jan/2013:13:39:17 -0600', 'got local time');
is($v6rec->{status}     , 200, 'got HTTP status code');
is($v6rec->{user_agent} ,
    "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5",
    'got user-agent string');
is($v6rec->{bytes_sent} , '-', 'got bytes_sent (apache uses "-" in place of 0)');
is($v6rec->{referer} , '-', 'got referer');
is($v6rec->{remote_user} , '-', 'got remote_user');
undef $v6rec;


__END__
::1 - - [22/Jan/2013:13:39:17 -0600] "HEAD /info.php HTTP/1.1" 200 - "-" "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5"
127.0.0.1 - - [22/Jan/2013:13:39:21 -0600] "HEAD /info.php HTTP/1.1" 200 - "-" "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5"
127.0.0.1 - - [22/Jan/2013:13:39:24 -0600] "HEAD /info.php HTTP/1.1" 200 - "-" "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5"
::1 - - [22/Jan/2013:13:39:27 -0600] "HEAD /info.php HTTP/1.1" 200 - "-" "curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5"

# remote_addr remote_user time_local request
# status bytes_sent referer user_agent

