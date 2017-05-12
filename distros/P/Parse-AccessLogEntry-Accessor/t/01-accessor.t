use strict;
use Test::More tests => 12;
use Parse::AccessLogEntry::Accessor;


my $line = q{192.168.0.1 - - [21/Jul/2008:22:26:57 +0900] "GET /index.html HTTP/1.1" 200 44 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1"};

my $pager = Parse::AccessLogEntry::Accessor->new;
$pager->parse($line);

# host
is($pager->host(), '192.168.0.1', "instance method: host");

# user
is($pager->user(), '-', "instance method: user");

# date
is($pager->date(), '21/Jul/2008', "instance method: date");

# time
is($pager->time(), '22:26:57', "instance method: time");

# diffgmt
is($pager->diffgmt(), '+0900', "instance method: diffgmt");

# rtype
is($pager->rtype(), 'GET', "instance method: rtype");

# file
is($pager->file(), '/index.html', "instance method: file");

# proto
is($pager->proto(), 'HTTP/1.1', "instance method: proto");

# code
is($pager->code(), '200', "instance method: code");

# bytes
is($pager->bytes(), '44', "instance method: bytes");

# refer
is($pager->refer(), '-', "instance method: refer");

# agent
is($pager->agent(), 'Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1', "instance method: agent");
