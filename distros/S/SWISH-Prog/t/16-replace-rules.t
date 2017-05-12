#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use Data::Dump qw( dump );

use_ok('SWISH::Prog::ReplaceRules');
my $rules = SWISH::Prog::ReplaceRules->new(
    qq(replace "foo" "flip"),
    qq(remove  "bar/"),
    qq(prepend "http://"),
    qq(append  ".html"),
    qq(regex   "/baz/123/sgxi"),
);
my $uri = 'foo/bar/Baz';
ok( my $modified_uri = $rules->apply($uri), "basic SYNOPSIS" );
is( $modified_uri, qq(http://flip/123.html), "got expected string" );

#diag( dump $rules );
