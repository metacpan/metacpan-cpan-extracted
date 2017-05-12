#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('SVG::SpriteMaker') };

# Don't warn, we intentionally have a duplicate ID
local $ENV{SVG_SPRITEMAKER_NO_DUPLICATE_WARNINGS} = 1;
my $sprite = make_sprite frag => <t/*.svg>;
my @elements = $sprite->getFirstChild->getChildren;

ok $sprite->getElementByID('frag-rect'), 'sprite contains #frag-rect';
ok $sprite->getElementByID('frag-circle'), 'sprite contains #frag-circle';
like $sprite->xmlify, qr/id="thing"/, 'sprite contains #thing';
like $sprite->xmlify, qr/id="thing_"/, 'sprite contains #thing_';
