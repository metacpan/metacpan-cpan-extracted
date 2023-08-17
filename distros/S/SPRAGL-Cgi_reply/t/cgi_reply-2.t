#!/usr/bin/perl
# t/cgi_reply-2.t
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

my $out = capture { try { SPRAGL::Cgi_reply::fail(418); }; };
ok ($out =~ m/ ^
    (?:
        Content-Type: \s text\/plain; \s charset=utf-8 \r\n |
        Pragma: \s no-cache \r\n |
        Status: \s 418 \s I'm \s a \s teapot \r\n |
        Date: \s [^\v]* UTC \r\n
        )+
    \r\n
    418 \s I'm \s a \s teapot $ /x
    );

__END__
