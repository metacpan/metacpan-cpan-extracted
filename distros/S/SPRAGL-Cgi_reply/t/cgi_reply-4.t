#!/usr/bin/perl
# t/cgi_reply-4.t
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

my $out = capture { try { SPRAGL::Cgi_reply::fail(307, redirect => 'https://metacpan.org/'); }; };
ok ($out =~ m/ ^
    (?:
        Content-Type: \s text\/html; \s charset=utf-8 \r\n |
        Pragma: \s no-cache \r\n |
        Status: \s 307 \s Temporary \s Redirect \r\n |
        Date: \s [^\v]* UTC \r\n |
        Location: \s https:\/\/metacpan\.org\/ \r\n
        )+
    \r\n
    <html><head><\/head><body><a \s href="https:\/\/metacpan\.org\/">https:\/\/metacpan\.org\/<\/a><\/body><\/html> $ /x
    );

__END__
