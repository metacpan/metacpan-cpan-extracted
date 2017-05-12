# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 66;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;
my $code;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

is    ($css->type,                 'sheet',      'upgrades to selector type');

$code = 'key : value;';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'property',   'upgrades to selector type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '/* hello */;';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'comment',    'upgrades to comment type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = ' 	 ;';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'whitespace', 'upgrades to selector type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = 'foobar';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'text',       'upgrades to text type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '.valid { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'selector',   'upgrades to selector type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@charset { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'charset',    'upgrades to charset type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@font-face { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'fontface',   'upgrades to font type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@import url(test);';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'import',     'upgrades to import type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@keyframes { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'keyframes',  'upgrades to keyframes type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@namespace { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'namespace',  'upgrades to namespace type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@page { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'page',       'upgrades to page type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@supports { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'supports',   'upgrades to supports type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@viewport { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'viewport',   'upgrades to viewport type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@ { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'extended',   'upgrades to extended type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@foobar { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'extended',   'upgrades to extended type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];

$code = '@media (max-width: 300px) { ... }';
$rv = $css->parse($code);
is    ($rv,                        $css,         'parse returns ourself');
is    ($css->children->[-1]->type, 'media',      'upgrades to media type');
is    ($css->render,               $code,        'renders the same as parsed');
is    ($css->clone(1)->render,     $code,        'clone renders the same as parsed');

$css->{'children'} = [];
