#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use Data::Dumper;

BEGIN { use_ok('Nginx::ParseLog') };

my $test = <<DOC;
127.0.0.1 - - [28/Mar/2009:20:55:27 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:55:37 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:56:02 +0300] "GET / HTTP/1.1" 200 1706 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"
127.0.0.1 - - [28/Mar/2009:20:56:27 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:56:37 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:57:02 +0300] "GET / HTTP/1.1" 200 1706 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"
127.0.0.1 - - [28/Mar/2009:20:57:27 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:57:37 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:58:02 +0300] "GET / HTTP/1.1" 200 1706 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"
127.0.0.1 - - [28/Mar/2009:20:58:27 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:58:37 +0300] "-" 400 0 "-" "-"
92.241.180.118 - - [28/Mar/2009:20:59:02 +0300] "GET / HTTP/1.1" 200 1706 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"
fd83:3e92:dd56::1 - - [26/Jul/2016:17:26:02 +0300] "GET / HTTP/1.1" 200 1706 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7"
DOC

my $deparsed = [
	 {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:55:27 +0300',
          'ip' => '127.0.0.1',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
         },
	 {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:55:37 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => 'GET / HTTP/1.1',
          'user_agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
          'status' => '200',
          'time' => '28/Mar/2009:20:56:02 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '1706',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:56:27 +0300',
          'ip' => '127.0.0.1',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:56:37 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => 'GET / HTTP/1.1',
          'user_agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
          'status' => '200',
          'time' => '28/Mar/2009:20:57:02 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '1706',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:57:27 +0300',
          'ip' => '127.0.0.1',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:57:37 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => 'GET / HTTP/1.1',
          'user_agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
          'status' => '200',
          'time' => '28/Mar/2009:20:58:02 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '1706',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:58:27 +0300',
          'ip' => '127.0.0.1',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => '-',
          'user_agent' => '-',
          'status' => '400',
          'time' => '28/Mar/2009:20:58:37 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '0',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => 'GET / HTTP/1.1',
          'user_agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
          'status' => '200',
          'time' => '28/Mar/2009:20:59:02 +0300',
          'ip' => '92.241.180.118',
          'bytes_send' => '1706',
          'remote_user' => '-',
          'referer' => '-'
        },
        {
          'request' => 'GET / HTTP/1.1',
          'user_agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7',
          'status' => '200',
          'time' => '26/Jul/2016:17:26:02 +0300',
          'ip' => 'fd83:3e92:dd56::1',
          'bytes_send' => '1706',
          'remote_user' => '-',
          'referer' => '-'
        },
];

my $cnt = 0;

for (split "\n", $test) {
    is_deeply( Nginx::ParseLog::parse($_), $deparsed->[$cnt++] );
}


sub get_top {
    my $global_count = { };

    while (<>) {
        my $deparsed = Nginx::ParseLog::parse($_);

        unless ($deparsed->{user_agent}) {  print $_ }

        $global_count->{ "$deparsed->{user_agent}" }++;
    }

    for ( keys %$global_count) {
        if ($global_count->{$_} > 20000) {
            print "$global_count->{$_} $_\n";
        }
    }
}




