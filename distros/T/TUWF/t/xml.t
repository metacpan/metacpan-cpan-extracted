#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'TUWF::XML', qw/:html xml_string/ };

is xml_string(pretty => 1, sub {
  body t => '</a&>', sub {
    br;
    p;
      b '<html &text>';
    end;
    strong a => 1, '+class' => 'abc', b => undef, '+class' => undef, c => '', '+class' => 'def', d => 2, 'txt';
  };
}), '
<body t="&lt;/a&amp;>">
 <br />
 <p>
  <b>&lt;html &amp;text></b>
 </p>
 <strong a="1" c="" d="2" class="abc def">txt</strong>
</body>';
