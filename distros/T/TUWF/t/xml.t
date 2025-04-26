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
    div x => 1, '+' => 2, '+', 3, undef;
    div x => 1, '+' => 2, '+', undef, undef;
    div x => 1, '+' => undef, '+', 3, undef;
    div x => 1, '+' => undef, y => undef, '+', 3, undef;
    div x => undef, '+' => undef, y => undef, '+', 3, undef;
    div x => undef, '+' => undef, '+', 1, undef;
  };
}), '
<body t="&lt;/a&amp;>">
 <br />
 <p>
  <b>&lt;html &amp;text></b>
 </p>
 <strong a="1" c="" d="2" class="abc def">txt</strong>
 <div x="1 2 3" />
 <div x="1 2" />
 <div x="1 3" />
 <div x="1" y="3" />
 <div y="3" />
 <div x="1" />
</body>';
