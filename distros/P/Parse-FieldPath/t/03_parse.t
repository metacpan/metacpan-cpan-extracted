use strict;
use warnings;

use Test::More tests => 11;
use Test::Deep;

use Parse::FieldPath;

sub build_tree {
    goto &Parse::FieldPath::_build_tree;
}

cmp_deeply( build_tree(''), { } );
cmp_deeply( build_tree('*'), { '*' => {} } );
cmp_deeply( build_tree('a'), { a => {} } );
cmp_deeply( build_tree('a,b'), { a => {}, b => {} } );
cmp_deeply( build_tree('a(b)'),   { a => { b => {} } } );
cmp_deeply( build_tree('a(b,c)'), { a => { b => {}, c => {} } } );
cmp_deeply( build_tree('a/b'),    { a => { b => {} } } );
cmp_deeply( build_tree('a/b/c'),    { a => { b => { c => {} } } } );
cmp_deeply( build_tree('a/b(c,d)'), { a => { b => { c => {}, d => {} } } } );
cmp_deeply( build_tree('a/b(c,d/e)'), { a => { b => { c => {}, d => { e => {} } } } } );
cmp_deeply( build_tree('a/b/*'),    { a => { b => { '*' => {} } } } );
