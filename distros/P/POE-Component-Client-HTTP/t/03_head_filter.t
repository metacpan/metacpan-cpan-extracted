# vim: filetype=perl ts=2 sw=2 expandtab

use strict;
use warnings;

use IO::Handle;
use Test::More;

plan tests => 10;

use_ok('POE::Filter::HTTPHead');

autoflush STDOUT 1;
autoflush STDERR 1;
my $request_number = 1;

my $filter = POE::Filter::HTTPHead->new;

my @content = qw(content);
my $state = 'head';
while (<DATA>) {
  #warn "($state) LINE: $_";
  if (substr ($_, 0, 5)  eq '--end') {
    my $data = $filter->get_one;
    $data = $data->[0];
    isa_ok($data, 'HTTP::Response');
    #warn $data->as_string;
    if ($request_number == 4) {
      isnt(defined($data->header('Connection')), 'ignore bogus header');
    }
    if ($state eq 'data') {
      my $data = $filter->get_pending;
      use Data::Dumper;
      $data = $data->[0];
      chomp($data);
      is($data, shift @content, 'got the right content');
      #warn Dumper $data;
      $filter = POE::Filter::HTTPHead->new;
    } elsif ($request_number == 1) {
      my $data = $filter->get_pending;
      cmp_ok(@$data, '==', 0, "Nothing left");
    }
    $state = 'head';
    $request_number++;
  } elsif (substr ($_, 0, 6) eq '--data') {
    $state = 'data';
  } else {
    $filter->get_one_start([$_]);
  }
}

# below is a list of the heads of HTTP responses (i.e with no content)
# these are used to drive the tests.
# Note that the last one does have a line of content, so we get more
# coverage because we switch filters for it
# If you want to add a head to test, put it as the first one,
# and add a $response_number == n and ok(1, foo) statement to the
# input subroutine n should be the number $response_number gets
# initialized to right now. Then increase the initialization and
# the number of tests planned.

__DATA__
HTTP/1.1 202 Accepted

--end--
HTTP/1.1 203 Ok
Date: Mon, 08 Nov 2004 21:37:20 GMT
Server: Apache/2.0.50 (Debian GNU/Linux) DAV/2 SVN/1.0.1-dev mod_ssl/2.0.50 OpenSSL/0.9.7d
Last-Modified: Sat, 24 Nov 2001 16:48:12 GMT
ETag: "6e-100e-18d96b00"
Accept-Ranges: bytes
Content-Length: 4110
Connection: close
Content-Type: text/html;
        charset=ISO-8859-1

--end-- this gets treated as a HTTP/0.9 response. 0.9 was silly.
garble
--end--
HTTP/1.1 204 Ok
Date: Mon, 08 Nov 2004 21:37:20 GMT
Server: Apache/2.0.50 (Debian GNU/Linux) DAV/2 SVN/1.0.1-dev mod_ssl/2.0.50 OpenSSL/0.9.7d
Last-Modified: Sat, 24 Nov 2001 16:48:12 GMT
ETag: "6e-100e-18d96b00"
Accept-Ranges: bytes
Content-Length: 4110
Connection close
Content-Type: text/html;
        charset=ISO-8859-1

--end--
209 Ok
Date: Mon, 08 Nov 2004 21:37:20 GMT
Server: Apache/2.0.50 (Debian GNU/Linux) DAV/2 SVN/1.0.1-dev mod_ssl/2.0.50 OpenSSL/0.9.7d
Last-Modified: Sat, 24 Nov 2001 16:48:12 GMT
ETag: "6e-100e-18d96b00"
Accept-Ranges: bytes
Content-Length: 4110
Connection: close
Content-Type: text/html;
        charset=ISO-8859-1

--end--
HTTP/1.1 210 Ok
Date: Mon, 08 Nov 2004 21:37:20 GMT
Server: Apache/2.0.50 (Debian GNU/Linux) DAV/2 SVN/1.0.1-dev mod_ssl/2.0.50 OpenSSL/0.9.7d
Last-Modified: Sat, 24 Nov 2001 16:48:12 GMT
ETag: "6e-100e-18d96b00"
Accept-Ranges: bytes
Content-Length: 4110
Connection: close
Content-Type: text/html;
        charset=ISO-8859-1

--data--
content
--end--
