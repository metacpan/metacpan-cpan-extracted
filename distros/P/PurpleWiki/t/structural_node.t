# structural_node.t

use strict;
use warnings;
use Test;

BEGIN { plan tests => 18 };

use PurpleWiki::StructuralNode;
use PurpleWiki::InlineNode;

#########################

# Simple node.  (2 tests)

my $structuralNode = PurpleWiki::StructuralNode->new;
$structuralNode->type('section');
ok($structuralNode->type eq 'section');

$structuralNode->type('ul');
ok($structuralNode->type eq 'ul');

# Simple node with content.  (6 tests)

my $content = 'Paul Bunyan was a very tall man.';
$structuralNode = PurpleWiki::StructuralNode->new('type'=>'p',
    'content'=>[PurpleWiki::InlineNode->new('type'=>'text',
                                           'content'=>$content)]);

ok($structuralNode->type eq 'p');
ok(scalar @{$structuralNode->content} == 1);
ok(ref $structuralNode->content->[0] eq 'PurpleWiki::InlineNode');
ok($structuralNode->content->[0]->type eq 'text');
ok(!defined $structuralNode->content->[0]->href);
ok($structuralNode->content->[0]->content eq $content);

# Tree.  (10 tests)

my $rootNode = PurpleWiki::StructuralNode->new('type'=>'section');
my $currentNode = $rootNode->insertChild('type'=>'ul');
ok($currentNode->parent eq $rootNode);

$currentNode = $currentNode->insertChild('type'=>'li',
    'content'=>[PurpleWiki::InlineNode->new('type'=>'text',
                                            'content'=>'Item one.')]);
$currentNode = $currentNode->parent;
$currentNode = $currentNode->insertChild('type'=>'li',
    'content'=>[PurpleWiki::InlineNode->new('type'=>'text',
                                            'content'=>'Item two.')]);
ok(scalar @{$rootNode->children} == 1);
ok($rootNode->children->[0]->type eq 'ul');
$currentNode = $rootNode->children->[0];
ok(scalar @{$currentNode->children} == 2);
ok($currentNode->children->[0]->type eq 'li');
ok(scalar @{$currentNode->children->[0]->content} == 1);
ok($currentNode->children->[0]->content->[0]->content eq 'Item one.');
ok($currentNode->children->[1]->type eq 'li');
ok(scalar @{$currentNode->children->[1]->content} == 1);
ok($currentNode->children->[1]->content->[0]->content eq 'Item two.');
