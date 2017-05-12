#!/usr/bin/perl
# test with TT variables
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
!!! 5
%html
 %head
  %meta{:charset => "utf-8"}
  %title hello
 %body
  %p hello world
  %ul
  [%- total=0; WHILE total < 5 %]
   %li [% total=total+1 %][% total %]
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
  <ul>
   <li>1</li>
   <li>2</li>
   <li>3</li>
   <li>4</li>
   <li>5</li>
  </ul>
 </body>
</html>
