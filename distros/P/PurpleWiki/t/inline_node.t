# inline_node.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 16 };

use PurpleWiki::InlineNode;

#########################

# Basic data.  (5 tests)

my $text01 = 'No formatting, no special characters.  Just the business.';

my $inlineNode = PurpleWiki::InlineNode->new('type'=>'text',
    'content'=>$text01);
ok(ref $inlineNode eq 'PurpleWiki::InlineNode');
ok($inlineNode->type eq 'text');
ok(!defined $inlineNode->href);
ok($inlineNode->content eq $text01);
ok(!defined $inlineNode->children);

# Link.  (5 tests)

my $text02 = 'WikiWord';
my $link02 = 'http://www.blueoxen.net/wiki/WikiWord';

$inlineNode = PurpleWiki::InlineNode->new('type'=>'link',
    'href'=>$link02, 'content'=>$text02);
ok(ref $inlineNode eq 'PurpleWiki::InlineNode');
ok($inlineNode->type eq 'link');
ok($inlineNode->href eq $link02);
ok($inlineNode->content eq $text02);
ok(!defined $inlineNode->children);

# Bold sentence.  (6 tests)

my $text03 = 'Bold sentence.';

$inlineNode = PurpleWiki::InlineNode->new('type'=>'b',
    'children'=>[PurpleWiki::InlineNode->new('type'=>'text',
                                             'content'=>$text03)]);
ok($inlineNode->type eq 'b');
ok(!defined $inlineNode->content);
ok(scalar @{$inlineNode->children} == 1);
ok(ref $inlineNode->children->[0] eq 'PurpleWiki::InlineNode');
ok($inlineNode->children->[0]->type eq 'text');
ok($inlineNode->children->[0]->content eq $text03);
