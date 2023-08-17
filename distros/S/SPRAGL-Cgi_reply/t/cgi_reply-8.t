#!/usr/bin/perl
# t/cgi_reply-8.t
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
use SPRAGL::Cgi_reply qw(reply_file);

my $filename = $dir =~ s/[^\/]+$/t\/cgi_reply-8.txt/r;
my $filesize = -s $filename;

my $out = capture { try { reply_file($filename); }; };
ok ($out =~ m/ ^
    (?:
        Content-Type: \s application\/octet-stream \r\n |
        Content-Length: \s ${filesize} \r\n |
        Content-Disposition: \s attachment; \s filename="cgi_reply-8.txt" \r\n |
        Pragma: \s no-cache \r\n |
        Status: \s 200 \s OK \r\n |
        Date: \s [^\v]* UTC \r\n
        )+
    \r\n
    Det \s Røde \s Hus \s /x
    );

__END__
