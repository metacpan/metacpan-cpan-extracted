#!/usr/bin/perl

use strict;
use warnings;

use Encode qw(encode decode);
use Test::More;
use SVN::Web::action;

my $action = SVN::Web::action->new;

{
    my $uri = decode('utf8','svn://test.my/repo');
    my $svn_uri = 'svn://test.my/repo';
    is $action->encode_svn_uri($uri), $svn_uri, 'encode: simple svn-schema uri';
    is $action->decode_svn_uri($svn_uri), $uri, 'decode: simple svn-schema uri';
}

{
    my $uri = decode('utf8','svn://test.my/repo/dir with spaces/file.txt');
    my $svn_uri = 'svn://test.my/repo/dir%20with%20spaces/file.txt';
    is $action->encode_svn_uri($uri), $svn_uri, 'encode: path with spaces';
    is $action->decode_svn_uri($svn_uri), $uri, 'decode: path with spaces';
}

{
    my $uri = decode('utf8','svn://test.my/repo/абвгд.txt');
    my $svn_uri = 'svn://test.my/repo/%D0%B0%D0%B1%D0%B2%D0%B3%D0%B4.txt';
    is $action->encode_svn_uri($uri), $svn_uri, 'encode: path with unicode symbols';
    is $action->decode_svn_uri($svn_uri), $uri, 'decode: path with unicode symbols';
}

done_testing;
