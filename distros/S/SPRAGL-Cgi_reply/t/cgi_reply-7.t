#!/usr/bin/perl
# t/cgi_reply-7.t
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

my $out = capture { try { reply('Araucaria' , testheader => 'Det Røde Hus'); }; };
ok ($out =~ m/ ^
    (?:
        Content-Type: \s text\/plain; \s charset=utf-8 \r\n |
        Pragma: \s no-cache \r\n |
        Status: \s 200 \s OK \r\n |
        Date: \s [^\v]* UTC \r\n |
        Testheader: \s Det \s Røde \s Hus \r\n
        )+
    \r\n
    Araucaria $ /x
    );

__END__
