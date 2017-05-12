#!/usr/bin/perl
# test with TT variables
use strict;
use warnings;
use Template;
use Template::Plugin::Haml;
use Template::Test;

$Template::Test::DEBUG = 1;

my $tt = Template->new;

my $vars = {
	var0 => 'world',
};

test_expect(\*DATA, $tt, $vars);

__DATA__
--test--
[%- USE Haml -%]
[%- FILTER haml -%]
!!! 5
%html
 %head
  %meta{:charset => "utf-8"}
  %title hello
 %body
  %p hello [% var0 %]
[%- END -%]
--expect--
<!DOCTYPE html>
<html>
 <head>
  <meta charset='utf-8' />
  <title>hello</title>
 </head>
 <body>
  <p>hello world</p>
 </body>
</html>
