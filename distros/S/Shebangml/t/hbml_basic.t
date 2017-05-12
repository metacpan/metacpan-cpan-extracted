#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib';
use Test::More;
use ShebangmlTest qw(no_plan);

hbml_is('hello{}', '<hello></hello>');
hbml_is('foo[]', '<foo />');
hbml_is('foo[@thing =bar :this]',
  '<foo class="thing" id="bar" name="this" />');
hbml_is('foo[=bar @thing :this]',
  '<foo id="bar" class="thing" name="this" />');
hbml_is('foo[att="val"]', '<foo att="val" />');

# dashes
hbml_is('foo-bar{}', '<foo-bar></foo-bar>');

# collapsing whitespace
hbml_is spaceless1 => 'foo{\ }', '<foo></foo>';
hbml_is spaceless2 => 'foo{\ bar[]\  }', '<foo><bar /></foo>';
hbml_is spaceless3 => <<IN, <<OUT;
foo{\\
  whatever\\
 bar[]\\
     
  }
IN
<foo>whatever<bar /></foo>
OUT

TODO: {
  local $TODO = "parse termination trouble?";
hbml_is entities => '\#9660;', '&#9660;';
}

hbml_is hockeystick => 'x{\n;\_;\_;\n;\n;}',
  '<x><br/>&nbsp;&nbsp;<br/><br/></x>';
hbml_is entities => 'x{\#9660;}', '<x>&#9660;</x>';

TODO:  {
  local $TODO = "assertion misparse";
eval {
hbml_is entities => <<'IN', <<'OUT';
  html{
    u{more} small{\#9660;}
  }
IN
  <html>
    <u>more</u> <small>&#9660;</small>
OUT
}; if(my $err = $@) {ok(0, 'entities'); diag($err)}
}

hbml_is multiline_att => <<'IN', <<'OUT';
  foo[
    =bar
    @thing
    :this
  ]
IN
  <foo id="bar" class="thing" name="this" />
OUT
#/ # grumble vim syntax grumblegrumble

hbml_is('foo[att=quoteme]', '<foo att="quoteme" />');
hbml_is('foo[=thing att=quoteme]', '<foo id="thing" att="quoteme" />');

hbml_from 'examples/markup/style.hbml' => <<OUT;
<html>
  <head>
    <style>
      P {font: 16px}
    </style>
  </head>
<body id="bar" name="bam" class="baz">
  <p>whee!</p>
</body>
</html>
OUT

# and now with .include[]
hbml_is '.include[src="examples/markup/style.hbml"]' => <<OUT;
<html>
  <head>
    <style>
      P {font: 16px}
    </style>
  </head>
<body id="bar" name="bam" class="baz">
  <p>whee!</p>
</body>
</html>
OUT

hbml_from 't/samples/comment.hbml' => <<OUT;
  <html>
    <head>
      <title>whatever</title>
    </head>
  <body>
    <p>some random text and junk</p>
    <p>and more text
    </p>
  </body>
  </html>
OUT
hbml_from 't/samples/fatquote.hbml' => <<OUT;
  <blah>
  <style>
    body{ font-family:foo,bar }
    #whatever{ height:18px;}
  </style>
  <inline> this{is{{)){{}} } ok} </inline> <and_then>more of this</and_then>
  <inline with="atts"> this{is ok too} </inline>

  <bacon has="atts">
    so{none of this matters}
  </bacon>
  <chunky_bacon might="have" lots="of attributes">
    and this is still thick bacon
  </chunky_bacon>
  </blah>
OUT

# vim:ts=2:sw=2:et:sta
