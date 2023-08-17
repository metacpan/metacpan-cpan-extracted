#!/usr/bin/perl
# t/cgi_reply-3.t
use strict;
use experimental qw(signatures);

use Test::More 'no_plan';

my $dir;
BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    $dir = dirname(abs_path($0)) =~ s/[^\/]+$/lib/r;
    };

use Try::Tiny qw(try);
use Capture::Tiny qw(capture);
use lib $dir;
use SPRAGL::Cgi_reply qw(reply reply_html reply_json);

my $out = capture { try { SPRAGL::Cgi_reply::fail(307); }; };
ok ($out =~ m/ ^
    (?:
        Content-Type: \s text\/plain; \s charset=utf-8 \r\n |
        Pragma: \s no-cache \r\n |
        Status: \s 500 \s Internal \s Server \s Error \r\n |
        Date: \s [^\v]* UTC \r\n
        )+
    \r\n
    500 \s Internal \s Server \s Error $ /x
    );

__END__
