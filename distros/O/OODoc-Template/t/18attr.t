#!/usr/bin/perl

use warnings;
use strict;

use lib 'lib', '../lib', 't';
use Test::More tests => 78;

use OODoc::Template;
use Tools;

sub show($$$)
{   my $attr = $_[1];
    my @lines;
    foreach my $k (sort keys %$attr)
    {   push @lines, "'$k' => '$attr->{$k}'\n";
    }
    join '', @lines;
}

my $t = OODoc::Template->new(show => \&show, c => 10);

ok(defined $t, 'create object');
isa_ok($t, 'OODoc::Template');

is(do_process($t, "<!--{show}-->"), '');

is(do_process($t, "<!--{show a}-->"), <<__SHOW);
'a' => '1'
__SHOW

is(do_process($t, "<!--{show a b}-->"), <<__SHOW);
'a' => '1'
'b' => '1'
__SHOW

is(do_process($t, "<!--{show a, b}-->"), <<__SHOW);
'a' => '1'
'b' => '1'
__SHOW

is(do_process($t, "<!--{show a => 2 b}-->"), <<__SHOW);
'a' => '2'
'b' => '1'
__SHOW

is(do_process($t, "<!--{show a => 2 b => 3}-->"), <<__SHOW);
'a' => '2'
'b' => '3'
__SHOW

is(do_process($t, "<!--{show a => 2, b => 3}-->"), <<__SHOW);
'a' => '2'
'b' => '3'
__SHOW

is(do_process($t, "<!--{show a => 3.1415, b => .7e-3}-->"), <<__SHOW);
'a' => '3.1415'
'b' => '.7e-3'
__SHOW

is(do_process($t, "<!--{show a => 'aaa', b => 'bbb'}-->"), <<__SHOW);
'a' => 'aaa'
'b' => 'bbb'
__SHOW

is(do_process($t, '<!--{show a => "aaa", b => "bbb"}-->'), <<__SHOW);
'a' => 'aaa'
'b' => 'bbb'
__SHOW

is(do_process($t, "<!--{show a => '\${c}', b => 'a\${c}b'}-->"), <<'__SHOW');
'a' => '${c}'
'b' => 'a${c}b'
__SHOW

is(do_process($t, '<!--{show a => "${c}", b => "a${c}b"}-->'), <<__SHOW);
'a' => '10'
'b' => 'a10b'
__SHOW

is(do_process($t, '<!--{show a => "$c", b => "a $c b"}-->'), <<__SHOW);
'a' => '10'
'b' => 'a 10 b'
__SHOW

is(do_process($t, '<!--{show a => $c, b => ${c}}-->'), <<__SHOW);
'a' => '10'
'b' => '10'
__SHOW

is(do_process($t, '<!--{show a => ${show d}}-->'), <<__SHOW);
'a' => ''d' => '1'
'
__SHOW

is(do_process($t, '<!--{show a => "$c${show d}" }-->'), <<__SHOW);
'a' => '10'd' => '1'
'
__SHOW

is(do_process($t, '<!--{show a => "${show d}$c" }-->'), <<__SHOW);
'a' => ''d' => '1'
10'
__SHOW

is(do_process($t, '<!--{show a => "${c}${show d}${c}" }-->'), <<__SHOW);
'a' => '10'd' => '1'
10'
__SHOW

is(do_process($t, <<'__TEST'), <<'__SHOW');
<!--{show
      a
      b => 3
      c => 3.1415
      d => 'hoi'
      e => "yes?"
      f => ola
    }-->\
__TEST
'a' => '1'
'b' => '3'
'c' => '3.1415'
'd' => 'hoi'
'e' => 'yes?'
'f' => 'ola'
__SHOW
