#! /usr/bin/perl -w
use strict;
use warnings;
use Parse::RecDescent;
use Test::More tests => 3;

my $grammar = <<'END_OF_GRAMMAR';
    foo_with_dynamic_skip:
                     <skip: $::skip_pattern>
                     item(s) eotext { $return = $item[1] }
    item:            name value { [ @item[1,2] ] }
    name:            'whatever' | 'another'
    value:           /\S+/
    eotext:          /\s*\z/
END_OF_GRAMMAR

my $text = <<'END_OF_TEXT';
whatever value

# some spaces, newlines and a comment too!

another value

END_OF_TEXT

my $parser = Parse::RecDescent->new($grammar);
ok($parser, 'got a parser');

{
   local $::skip_pattern = qr/XXXXX/;
   my $outskip = $parser->foo_with_dynamic_skip($text);
   ok(!defined $outskip, 'foo()');
}

{
   no warnings 'once';
   local $::skip_pattern = qr/(?mxs: \s+ |\# .*?$)*/;
   my $outskip = $parser->foo_with_dynamic_skip($text);
   ok($outskip, 'foo() with string $::skip');
}
