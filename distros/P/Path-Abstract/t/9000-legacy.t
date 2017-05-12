#!perl -T

use strict;
use warnings;

use Test::Most;
use Test::Lazy qw/template try/;
use Scalar::Util qw/refaddr/;

plan qw/no_plan/;

use Path::Abstract qw/path/;

use vars qw/$c $d/;
sub get { return path(@_)->path }
my $path = path;
$path = new Path::Abstract;

my $red = Path::Abstract::Underload->new("red");
my $blue = Path::Abstract::Underload->new("blue");
$path = Path::Abstract->new($red, $blue);
is($path, "red/blue");

my $template = template(\<<_END_);
Path::Abstract->new
Path::Abstract->new( qw!/! )
Path::Abstract->new( qw!a! )
Path::Abstract->new( qw!/a! )
Path::Abstract->new( qw!a b! )
Path::Abstract->new( qw!/a b! )
Path::Abstract->new( qw!a b c! )
Path::Abstract->new( qw!/a b c! )
Path::Abstract->new( qw!a b c! )->set
Path::Abstract->new( qw!/a b c! )->set
Path::Abstract->new( qw!a b c! )->push( qw!d! )
_END_

# new {{{
$template->test("ref(%?)" => is => "Path::Abstract");
# }}}
# path {{{
# }}}
# clone {{{
$template->test([
	[ "%?->clone" => is => "" ],
	[ "%?->clone" => is => "/" ],
	[ "%?->clone" => is => "a" ],
	[ "%?->clone" => is => "/a" ],
	[ "%?->clone" => is => "a/b" ],
	[ "%?->clone" => is => "/a/b" ],
	[ "%?->clone" => is => "a/b/c" ],
	[ "%?->clone" => is => "/a/b/c" ],
	[ "%?->clone" => is => "" ],
	[ "%?->clone" => is => "" ],
	[ "%?->clone" => is => "a/b/c/d" ],
]);
# }}} 
# _canonize {{{
# }}}
# set {{{ 
$template->test("%?->set()" => is => "");
$template->test("%?->set(qw!a/!)" => is => "a/");
$template->test("%?->set(qw!/a!)" => is => "/a");
$template->test("%?->set(qw!a b!)" => is => "a/b");
$template->test("%?->set(qw!/a b!)" => is => "/a/b");
$template->test("%?->set(qw!/a b c/!)" => is => "/a/b/c/");
# }}}
# is_empty {{{
$template->test([
	[ "%?->is_empty" => is => "1" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "" ],
	[ "%?->is_empty" => is => "1" ],
	[ "%?->is_empty" => is => "1" ],
	[ "%?->is_empty" => is => "" ],
]);
# }}}
# is_root {{{
$template->test([
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "1" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
	[ "%?->is_root" => is => "" ],
]);
# }}}
# is_tree {{{
$template->test([
	[ "%?->is_tree" => is => "" ],
	[ "%?->is_tree" => is => "1" ],
	[ "%?->is_tree" => is => "" ],
	[ "%?->is_tree" => is => "1" ],
	[ "%?->is_tree" => is => "" ],
	[ "%?->is_tree" => is => "1" ],
	[ "%?->is_tree" => is => "" ],
	[ "%?->is_tree" => is => "1" ],
	[ "%?->is_tree" => is => "" ],
	[ "%?->is_tree" => is => "" ],
	[ "%?->is_tree" => is => "" ],
]);
# }}}
# is_branch {{{
$template->test([
	[ "%?->is_branch" => is => "1" ],
	[ "%?->is_branch" => is => "" ],
	[ "%?->is_branch" => is => "1" ],
	[ "%?->is_branch" => is => "" ],
	[ "%?->is_branch" => is => "1" ],
	[ "%?->is_branch" => is => "" ],
	[ "%?->is_branch" => is => "1" ],
	[ "%?->is_branch" => is => "" ],
	[ "%?->is_branch" => is => "1" ],
	[ "%?->is_branch" => is => "1" ],
	[ "%?->is_branch" => is => "1" ],
]);
# }}}
# to_tree {{{
$template->test([
	[ "%?->to_tree" => is => "/" ],
	[ "%?->to_tree" => is => "/" ],
	[ "%?->to_tree" => is => "/a" ],
	[ "%?->to_tree" => is => "/a" ],
	[ "%?->to_tree" => is => "/a/b" ],
	[ "%?->to_tree" => is => "/a/b" ],
	[ "%?->to_tree" => is => "/a/b/c" ],
	[ "%?->to_tree" => is => "/a/b/c" ],
	[ "%?->to_tree" => is => "/" ],
	[ "%?->to_tree" => is => "/" ],
	[ "%?->to_tree" => is => "/a/b/c/d" ],
]);
# }}}
# to_branch {{{
$template->test([
	[ "%?->to_branch" => is => "" ],
	[ "%?->to_branch" => is => "" ],
	[ "%?->to_branch" => is => "a" ],
	[ "%?->to_branch" => is => "a" ],
	[ "%?->to_branch" => is => "a/b" ],
	[ "%?->to_branch" => is => "a/b" ],
	[ "%?->to_branch" => is => "a/b/c" ],
	[ "%?->to_branch" => is => "a/b/c" ],
	[ "%?->to_branch" => is => "" ],
	[ "%?->to_branch" => is => "" ],
	[ "%?->to_branch" => is => "a/b/c/d" ],
]);
# }}}
# list {{{
$template->test([
	[ "%?->list" => is => [] ],
	[ "%?->list" => is => [] ],
	[ "%?->list" => is => ["a"] ],
	[ "%?->list" => is => ["a"] ],
	[ "%?->list" => is => ["a","b"] ],
	[ "%?->list" => is => ["a","b"] ],
	[ "%?->list" => is => ["a", "b", "c"] ],
	[ "%?->list" => is => ["a", "b", "c"] ],
	[ "%?->list" => is => [] ],
	[ "%?->list" => is => [] ],
	[ "%?->list" => is => ["a", "b", "c", "d"] ],
]);
# }}}
# first {{{
$template->test([
	[ "%?->first" => is => [''] ],
	[ "%?->first" => is => [''] ],
	[ "%?->first" => is => ["a"] ],
	[ "%?->first" => is => ["a"] ],
	[ "%?->first" => is => ["a"] ],
	[ "%?->first" => is => ["a"] ],
	[ "%?->first" => is => ["a"] ],
	[ "%?->first" => is => ["a"] ],
	[ "%?->first" => is => [''] ],
	[ "%?->first" => is => [''] ],
	[ "%?->first" => is => ["a"] ],
]);
# }}}
# last {{{
$template->test([
	[ "%?->last" => is => [''] ],
	[ "%?->last" => is => [''] ],
	[ "%?->last" => is => ["a"] ],
	[ "%?->last" => is => ["a"] ],
	[ "%?->last" => is => ["b"] ],
	[ "%?->last" => is => ["b"] ],
	[ "%?->last" => is => ["c"] ],
	[ "%?->last" => is => ["c"] ],
	[ "%?->last" => is => [''] ],
	[ "%?->last" => is => [''] ],
	[ "%?->last" => is => ["d"] ],
]);
# }}}
# get {{{
$template->test([
	[ "%?->get" => is => "" ],
	[ "%?->get" => is => "/" ],
	[ "%?->get" => is => "a" ],
	[ "%?->get" => is => "/a" ],
	[ "%?->get" => is => "a/b" ],
	[ "%?->get" => is => "/a/b" ],
	[ "%?->get" => is => "a/b/c" ],
	[ "%?->get" => is => "/a/b/c" ],
	[ "%?->get" => is => "" ],
	[ "%?->get" => is => "" ],
	[ "%?->get" => is => "a/b/c/d" ],
]);
# }}}
# push {{{
$c = Path::Abstract->new(qw|a|);
$d = $c->push(qw|b|);
try("::refaddr(\$::c) == ::refaddr(\$::d)" => is => 1);

$template->test([
	[ "%?->push( qw |e| )" => is => "e" ],
	[ "%?->push( qw |e| )" => is => "/e" ],
	[ "%?->push( qw |e| )" => is => "a/e" ],
	[ "%?->push( qw |e| )" => is => "/a/e" ],
	[ "%?->push( qw |e| )" => is => "a/b/e" ],
	[ "%?->push( qw |e| )" => is => "/a/b/e" ],
	[ "%?->push( qw |e| )" => is => "a/b/c/e" ],
	[ "%?->push( qw |e| )" => is => "/a/b/c/e" ],
	[ "%?->push( qw |e| )" => is => "e" ],
	[ "%?->push( qw |e| )" => is => "e" ],
	[ "%?->push( qw |e| )" => is => "a/b/c/d/e" ],
]);
# }}}
# child {{{
$c = Path::Abstract->new(qw|a|);
$d = $c->child(qw|b|);
try("::refaddr(\$::c) == ::refaddr(\$::d)" => is => '');

$template->test([
	[ "%?->child( qw|e| )" => is => "e" ],
	[ "%?->child( qw|e| )" => is => "/e" ],
	[ "%?->child( qw|e| )" => is => "a/e" ],
	[ "%?->child( qw|e| )" => is => "/a/e" ],
	[ "%?->child( qw|e| )" => is => "a/b/e" ],
	[ "%?->child( qw|e| )" => is => "/a/b/e" ],
	[ "%?->child( qw|e| )" => is => "a/b/c/e" ],
	[ "%?->child( qw|e| )" => is => "/a/b/c/e" ],
	[ "%?->child( qw|e| )" => is => "e" ],
	[ "%?->child( qw|e| )" => is => "e" ],
	[ "%?->child( qw|e| )" => is => "a/b/c/d/e" ],
]);
# }}}
# pop {{{
$template->test([
	[ "%?->pop" => is => "" ],
	[ "%?->pop" => is => "" ],
	[ "%?->pop" => is => "a" ],
	[ "%?->pop" => is => "a" ],
	[ "%?->pop" => is => "b" ],
	[ "%?->pop" => is => "b" ],
	[ "%?->pop" => is => "c" ],
	[ "%?->pop" => is => "c" ],
	[ "%?->pop" => is => "" ],
	[ "%?->pop" => is => "" ],
	[ "%?->pop" => is => "d" ],
]);

$template->test([
	[ "%?->pop(2)" => is => "" ],
	[ "%?->pop(2)" => is => "" ],
	[ "%?->pop(2)" => is => "a" ],
	[ "%?->pop(2)" => is => "a" ],
	[ "%?->pop(2)" => is => "a/b" ],
	[ "%?->pop(2)" => is => "a/b" ],
	[ "%?->pop(2)" => is => "b/c" ],
	[ "%?->pop(2)" => is => "b/c" ],
	[ "%?->pop(2)" => is => "" ],
	[ "%?->pop(2)" => is => "" ],
	[ "%?->pop(2)" => is => "c/d" ],
]);
# }}}
# up {{{
$template->test([
	[ "%?->up" => is => "" ],
	[ "%?->up" => is => "/" ],
	[ "%?->up" => is => "" ],
	[ "%?->up" => is => "/" ],
	[ "%?->up" => is => "a" ],
	[ "%?->up" => is => "/a" ],
	[ "%?->up" => is => "a/b" ],
	[ "%?->up" => is => "/a/b" ],
	[ "%?->up" => is => "" ],
	[ "%?->up" => is => "" ],
	[ "%?->up" => is => "a/b/c" ],
]);

$template->test([
	[ "%?->up(2)" => is => "" ],
	[ "%?->up(2)" => is => "/" ],
	[ "%?->up(2)" => is => "" ],
	[ "%?->up(2)" => is => "/" ],
	[ "%?->up(2)" => is => "" ],
	[ "%?->up(2)" => is => "/" ],
	[ "%?->up(2)" => is => "a" ],
	[ "%?->up(2)" => is => "/a" ],
	[ "%?->up(2)" => is => "" ],
	[ "%?->up(2)" => is => "" ],
	[ "%?->up(2)" => is => "a/b" ],
]);
# }}}
# parent {{{
$template->test([
	[ "%?->parent" => is => "" ],
	[ "%?->parent" => is => "/" ],
	[ "%?->parent" => is => "" ],
	[ "%?->parent" => is => "/" ],
	[ "%?->parent" => is => "a" ],
	[ "%?->parent" => is => "/a" ],
	[ "%?->parent" => is => "a/b" ],
	[ "%?->parent" => is => "/a/b" ],
	[ "%?->parent" => is => "" ],
	[ "%?->parent" => is => "" ],
	[ "%?->parent" => is => "a/b/c" ],
]);
# }}}

#[ "Unix->catfile('a','b','c')",         'a/b/c'  ],
#[ "Unix->catfile('a','b','./c')",       'a/b/c'  ],
#[ "Unix->catfile('./a','b','c')",       'a/b/c'  ],
#[ "Unix->catfile('c')",                 'c' ],
#[ "Unix->catfile('./c')",               'c' ],

#[ "Unix->splitpath('file')",            ',,file'            ],
#[ "Unix->splitpath('/d1/d2/d3/')",      ',/d1/d2/d3/,'      ],
#[ "Unix->splitpath('d1/d2/d3/')",       ',d1/d2/d3/,'       ],
#[ "Unix->splitpath('/d1/d2/d3/.')",     ',/d1/d2/d3/.,'     ],
#[ "Unix->splitpath('/d1/d2/d3/..')",    ',/d1/d2/d3/..,'    ],
#[ "Unix->splitpath('/d1/d2/d3/.file')", ',/d1/d2/d3/,.file' ],
#[ "Unix->splitpath('d1/d2/d3/file')",   ',d1/d2/d3/,file'   ],
#[ "Unix->splitpath('/../../d1/')",      ',/../../d1/,'      ],
#[ "Unix->splitpath('/././d1/')",        ',/././d1/,'        ],

#[ "Unix->catpath('','','file')",            'file'            ],
#[ "Unix->catpath('','/d1/d2/d3/','')",      '/d1/d2/d3/'      ],
#[ "Unix->catpath('','d1/d2/d3/','')",       'd1/d2/d3/'       ],
#[ "Unix->catpath('','/d1/d2/d3/.','')",     '/d1/d2/d3/.'     ],
#[ "Unix->catpath('','/d1/d2/d3/..','')",    '/d1/d2/d3/..'    ],
#[ "Unix->catpath('','/d1/d2/d3/','.file')", '/d1/d2/d3/.file' ],
#[ "Unix->catpath('','d1/d2/d3/','file')",   'd1/d2/d3/file'   ],
#[ "Unix->catpath('','/../../d1/','')",      '/../../d1/'      ],
#[ "Unix->catpath('','/././d1/','')",        '/././d1/'        ],
#[ "Unix->catpath('d1','d2/d3/','')",        'd2/d3/'          ],
#[ "Unix->catpath('d1','d2','d3/')",         'd2/d3/'          ],

#[ "Unix->splitdir('')",           ''           ],
#[ "Unix->splitdir('/d1/d2/d3/')", ',d1,d2,d3,' ],
#[ "Unix->splitdir('d1/d2/d3/')",  'd1,d2,d3,'  ],
#[ "Unix->splitdir('/d1/d2/d3')",  ',d1,d2,d3'  ],
#[ "Unix->splitdir('d1/d2/d3')",   'd1,d2,d3'   ],

#[ "Unix->catdir()",                     ''          ],
#[ "Unix->catdir('/')",                  '/'         ],
#[ "Unix->catdir('','d1','d2','d3','')", '/d1/d2/d3' ],
#[ "Unix->catdir('d1','d2','d3','')",    'd1/d2/d3'  ],
#[ "Unix->catdir('','d1','d2','d3')",    '/d1/d2/d3' ],
#[ "Unix->catdir('d1','d2','d3')",       'd1/d2/d3'  ],
#[ "Unix->catdir('/','d2/d3')",          '/d2/d3'    ],

#[ "Unix->canonpath('///../../..//./././a//b/.././c/././')",   '/a/b/../c' ],
#[ "Unix->canonpath('')",                       ''               ],
## rt.perl.org 27052
#[ "Unix->canonpath('a/../../b/c')",            'a/../../b/c'    ],
#[ "Unix->canonpath('/.')",                     '/'              ],
#[ "Unix->canonpath('/./')",                    '/'              ],
#[ "Unix->canonpath('/a/./')",                  '/a'             ],
#[ "Unix->canonpath('/a/.')",                   '/a'             ],
#[ "Unix->canonpath('/../../')",                '/'              ],
#[ "Unix->canonpath('/../..')",                 '/'              ],

#[  "Unix->abs2rel('/t1/t2/t3','/t1/t2/t3')",          '.'                  ],
#[  "Unix->abs2rel('/t1/t2/t4','/t1/t2/t3')",          '../t4'              ],
#[  "Unix->abs2rel('/t1/t2','/t1/t2/t3')",             '..'                 ],
#[  "Unix->abs2rel('/t1/t2/t3/t4','/t1/t2/t3')",       't4'                 ],
#[  "Unix->abs2rel('/t4/t5/t6','/t1/t2/t3')",          '../../../t4/t5/t6'  ],
##[ "Unix->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
#[  "Unix->abs2rel('/','/t1/t2/t3')",                  '../../..'           ],
#[  "Unix->abs2rel('///','/t1/t2/t3')",                '../../..'           ],
#[  "Unix->abs2rel('/.','/t1/t2/t3')",                 '../../..'           ],
#[  "Unix->abs2rel('/./','/t1/t2/t3')",                '../../..'           ],
##[ "Unix->abs2rel('../t4','/t1/t2/t3')",              '../t4'              ],
#[  "Unix->abs2rel('/t1/t2/t3', '/')",                 't1/t2/t3'           ],
#[  "Unix->abs2rel('/t1/t2/t3', '/t1')",               't2/t3'              ],
#[  "Unix->abs2rel('t1/t2/t3', 't1')",                 't2/t3'              ],
#[  "Unix->abs2rel('t1/t2/t3', 't4')",                 '../t1/t2/t3'        ],

#[ "Unix->rel2abs('t4','/t1/t2/t3')",             '/t1/t2/t3/t4'    ],
#[ "Unix->rel2abs('t4/t5','/t1/t2/t3')",          '/t1/t2/t3/t4/t5' ],
#[ "Unix->rel2abs('.','/t1/t2/t3')",              '/t1/t2/t3'       ],
#[ "Unix->rel2abs('..','/t1/t2/t3')",             '/t1/t2/t3/..'    ],
#[ "Unix->rel2abs('../t4','/t1/t2/t3')",          '/t1/t2/t3/../t4' ],
#[ "Unix->rel2abs('/t1','/t1/t2/t3')",            '/t1'             ],
