#!/usr/bin/perl
use strict;
use warnings;
use Template;
use Template::Plugin::Haml;
use Template::Test;

$Template::Test::DEBUG = 1;

my $tt = Template->new;

test_expect(\*DATA, $tt);

__DATA__
--test--
[%- USE Haml -%]
[%- FILTER haml -%]
[% WRAPPER t/templates/wrapper.tt -%]
 %head
  %meta{:charset => "utf-8"}
  %title hello
 %body
  %p hello world
[%- END -%]
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
