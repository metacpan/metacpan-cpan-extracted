#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

my $str     = ' Foo ';    # uppercase breaks 2nd regex
my $pattern = 'foo';
utf8::upgrade($str);
utf8::upgrade($pattern);

my $re          = qr/$pattern/i;
my $re_optional = qr/(?i:.?)$pattern/i;

like( $str, $re,          "re" );
like( $str, $re_optional, "re_optional" );

