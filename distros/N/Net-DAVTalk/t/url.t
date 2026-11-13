#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Net::DAVTalk;

my $talk = Net::DAVTalk->new(url => 'https://dav.example.com/dav/calendars/user/a@b.com/');

# paths are unescaped: each segment is escaped once
is($talk->request_url('/dav/x/a@b.com/c d.ics'), 'https://dav.example.com:443/dav/x/a%40b.com/c%20d.ics',
  'absolute path: on the connection\'s server, escaped');
is($talk->request_url('Default/e.ics'), 'https://dav.example.com:443/dav/calendars/user/a@b.com/Default/e.ics',
  'relative path: under the connection\'s URL');
is($talk->request_url('https://other.example.com/x/a@b.ics'), 'https://other.example.com/x/a%40b.ics',
  'a full URL (as some servers give hrefs) is absolute');
is($talk->request_url(\'https://other.example.com/x/a@b.ics'), 'https://other.example.com/x/a%40b.ics',
  'and so is a reference to one, as before');
is($talk->request_url(''), 'https://dav.example.com:443/dav/calendars/user/a@b.com', 'no path: the URL');

# request_href: the escaped absolute path, for a request body
is($talk->request_href('/dav/x/a@b.com/c d.ics'), '/dav/x/a%40b.com/c%20d.ics', 'request_href: escaped');
is($talk->request_href('Default/e f.ics'), '/dav/calendars/user/a@b.com/Default/e%20f.ics',
  'request_href: a relative path becomes absolute');
is($talk->request_href('https://other.example.com/x/a@b.ics'), '/x/a%40b.ics', 'request_href: a full URL');
is($talk->request_href('/dav/x/%41'), '/dav/x/%2541', 'a % is a % (paths are unescaped)');

done_testing();
