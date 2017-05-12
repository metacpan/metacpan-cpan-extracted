# vim: filetype=perl ts=2 sw=2 expandtab

use strict;
use warnings;

use Test::More tests => 4;

use_ok("POE::Filter::Line");
use_ok("POE::Filter::HTTPHead");

use IO::Handle;
use IO::File;

STDOUT->autoflush(1);
my $request_number = 8;

my $http_head_filter = POE::Filter::HTTPHead->new();

sysseek(DATA, tell(DATA), 0);
while (<DATA>) {
  $http_head_filter->get_one_start([ $_ ]);
}

my $http_header = $http_head_filter->get_one()->[0];
ok($http_header->isa("HTTP::Response"), "headers received");

my $line_filter = POE::Filter::Line->new();
$line_filter->get_one_start( $http_head_filter->get_pending() || [] );

my $line_data = $line_filter->get_one()->[0];
is($line_data, "Test Content.", "content received");

# Below is an HTTP response that consists solely of a status line and
# some content.

__DATA__
HTTP/1.0 200 OK

Test Content.
