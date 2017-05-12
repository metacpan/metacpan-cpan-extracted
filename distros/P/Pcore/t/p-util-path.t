#!/usr/bin/env perl

package main v0.1.0;

use Pcore;
use Test::More;

our $TESTS = 74;

plan tests => $TESTS;

# normalization, without base
ok( P->path(q[./aaa]) eq q[aaa], q[normalization_1] );
ok( P->path(q[./aaa]) eq q[aaa], q[normalization_2] );
ok( P->path(q[D:\\123\\]) eq ( $MSWIN ? q[d:/123/] : q[D:/123/] ), q[normalization_3] );
ok( P->path(q[./a../././aa./.]) eq q[a../aa./],                q[normalization_4] );
ok( P->path(q[././aaa/.///bbb]) eq q[aaa/bbb],                 q[normalization_5] );
ok( P->path(q[.]) eq q[],                                      q[normalization_6] );
ok( P->path(q[/.]) eq q[/],                                    q[normalization_7] );
ok( P->path(q[/\\..]) eq q[/],                                 q[normalization_8] );
ok( P->path(q[..]) eq q[../],                                  q[normalization_9] );
ok( P->path(q[...]) eq q[...],                                 q[normalization_10] );
ok( P->path(q[///...]) eq q[/...],                             q[normalization_11] );
ok( P->path(q[\\///.\\/\\/]) eq q[/],                          q[normalization_12] );
ok( P->path(q[../]) eq q[../],                                 q[normalization_13] );
ok( P->path(q[../../aaa/./\\\\bbb././]) eq q[../../aaa/bbb./], q[normalization_14] );
ok( P->path(q[/]) eq q[/],                                     q[normalization_15] );
ok( P->path(q[././..]) eq q[../],                              q[normalization_16] );
ok( P->path(q[/././..]) eq q[/],                               q[normalization_17] );
ok( P->path(q[.../]) eq q[.../],                               q[normalization_18] );

# normalization with base
ok( P->path( q[/path/],   base => q[/path] ) eq q[/path/], q[normalization_base_1] );
ok( P->path( q[aaa/bbb],  base => q[path] ) eq q[aaa/bbb], q[normalization_base_2] );
ok( P->path( q[/aaa/bbb], base => q[] ) eq q[/aaa/bbb],    q[normalization_base_3] );
ok( P->path( q[/aaa/bbb], base => q[/] ) eq q[/aaa/bbb],   q[normalization_base_4] );

# is_dir
ok( P->path(q[])->is_dir == 1,     q[is_dir_1] );
ok( P->path(q[.])->is_dir == 1,    q[is_dir_2] );
ok( P->path(q[..])->is_dir == 1,   q[is_dir_3] );
ok( P->path(q[/])->is_dir == 1,    q[is_dir_4] );
ok( P->path(q[/.])->is_dir == 1,   q[is_dir_5] );
ok( P->path(q[/..])->is_dir == 1,  q[is_dir_6] );
ok( P->path(q[./])->is_dir == 1,   q[is_dir_7] );
ok( P->path(q[../])->is_dir == 1,  q[is_dir_8] );
ok( P->path(q[/...])->is_dir == 0, q[is_dir_9] );
ok( P->path(q[.../])->is_dir == 1, q[is_dir_10] );

# is abs
ok( P->path(q[bbb])->is_abs == 0,  q[is_abs_1] );
ok( P->path(q[/bbb])->is_abs == 1, q[is_abs_2] );
ok( P->path(q[D:\\bbb])->is_abs == ( $MSWIN ? 1 : 0 ), q[is_abs_3] );
ok( P->path(q[./bbb])->is_abs == 0,   q[is_abs_4] );
ok( P->path(q[\\./bbb])->is_abs == 1, q[is_abs_5] );
ok( P->path(q[.])->is_abs == 0,       q[is_abs_6] );
ok( P->path(q[])->is_abs == 0,        q[is_abs_7] );
ok( P->path(q[./])->is_abs == 0,      q[is_abs_8] );
ok( P->path(q[../])->is_abs == 0,     q[is_abs_9] );
ok( P->path(q[..])->is_abs == 0,      q[is_abs_10] );
ok( P->path()->is_abs == 0,           q[is_abs_11] );

# canon
ok( P->path(q[])->canonpath eq q[],   q[canon_1] );
ok( P->path(q[/])->canonpath eq q[/], q[canon_2] );
ok( P->path(q[c:/])->canonpath eq ( $MSWIN ? q[c:/] : q[c:] ), q[canon_3] );
ok( P->path(q[/aaa/bbb/])->canonpath eq q[/aaa/bbb], q[canon_4] );
ok( P->path(q[/aaa/bbb])->canonpath eq q[/aaa/bbb],  q[canon_5] );

# to_abs
ok( P->path( q[/aaa/bbb], base => q[/aaa] )->to_abs eq q[/aaa/bbb], q[to_abs_1] );
ok( P->path( q[aaa/bbb],  base => q[.] )->to_abs eq q[aaa/bbb],     q[to_abs_2] );

# realpath
ok( !defined P->path(q[./_fake_path_/])->realpath, q[realpath_1] );

my $p1 = P->path(q[C:///])->realpath;

if ($MSWIN) {
    ok( $p1 eq q[c:/], q[realpath_2] );
}
else {
    ok( !defined $p1, q[realpath_3] );
}

# dirname
ok( P->path(q[./aaa/])->dirname eq q[aaa/],         q[dirname_1] );
ok( P->path(q[./aaa])->dirname eq q[],              q[dirname_2] );
ok( P->path(q[./])->dirname eq q[],                 q[dirname_3] );
ok( P->path(q[../aaa])->dirname eq q[../],          q[dirname_4] );
ok( P->path(q[../a\\\\a/a])->dirname eq q[../a/a/], q[dirname_5] );
ok( P->path(q[../a\\\\a/a])->dirname eq q[../a/a/], q[dirname_6] );
ok( P->path( q[c:/../a\\\\a/a], mswin => 1 )->dirname eq q[c:/a/a/], q[dirname_7] );
ok( P->path(q[/])->dirname eq q[/],                            q[dirname_8] );
ok( P->path(q[.])->dirname eq q[],                             q[dirname_9] );
ok( P->path(q[./../..])->dirname eq q[../../],                 q[dirname_10] );
ok( P->path(q[aaa/bbb/ccc/ddd])->dirname eq q[aaa/bbb/ccc/],   q[dirname_11] );
ok( P->path(q[/aaa/bbb/ccc/ddd])->dirname eq q[/aaa/bbb/ccc/], q[dirname_12] );

# filename
ok( P->path(q[./.])->filename eq q[],              q[filename_1] );
ok( P->path(q[./..])->filename eq q[],             q[filename_2] );
ok( P->path(q[./...])->filename eq q[...],         q[filename_3] );
ok( P->path(q[./...txt])->filename eq q[...txt],   q[filename_4] );
ok( P->path(q[./..txt])->filename eq q[..txt],     q[filename_5] );
ok( P->path(q[./..txt.])->filename eq q[..txt.],   q[filename_6] );
ok( P->path(q[./..txt..])->filename eq q[..txt..], q[filename_7] );

# suffix
ok( P->path(q[../aaa])->suffix eq q[],      q[suffix_1] );
ok( P->path(q[../.aaa])->suffix eq q[],     q[suffix_2] );
ok( P->path(q[../..aaa])->suffix eq q[aaa], q[suffix_3] );

done_testing $TESTS;

1;
__END__
=pod

=encoding utf8

=cut
