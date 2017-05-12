#!perl -T

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Path::Abstract qw/path --no_0_093_warning/;

{
    my $path;

    $path = path [qw/a b c d ef g h/];
    is($path, "a/b/c/d/ef/g/h");
    $path = $path->child([qw/.. ij k lm/]);
    is($path, "a/b/c/d/ef/g/h/../ij/k/lm");

    $path = path "/a/b/c/d";
    is($path, "/a/b/c/d");
    $path->pop(8);
    is($path, "/");

    {
        my $path;
        $path = path 'a.html.tar.gz';
        $path->pop;
        is($path, '');

        $path = path '/a.html.tar.gz';
        $path->pop;
        is($path, '/');

        $path = path 'a.html.tar.gz';
        $path->up;
        is($path, '');

        $path = path '/a.html.tar.gz';
        $path->up;
        is($path, '/');
    }

    {
        cmp_deeply([ path( 'a/b/c' )->list ], [qw/ a b c /]);
        cmp_deeply([ path( '/a/b/c' )->list ], [qw/ a b c /]);
        cmp_deeply([ path( '/a/b/c/' )->list ], [qw/ a b c /]);
        cmp_deeply([ path( 'a/b/c/' )->list ], [qw/ a b c /]);

        cmp_deeply([ path( 'a/b/c' )->split ], [qw( a b c )]);
        cmp_deeply([ path( '/a/b/c' )->split ], [qw( /a b c )]);
        cmp_deeply([ path( '/a/b/c/' )->split ], [qw( /a b c/ )]);
        cmp_deeply([ path( 'a/b/c/' )->split ], [qw( a b c/ )]);
    }

    {
        my $path;
        # .append
        $path = path();

        $path->append("c/d");
        is("c/d", $path.'');
        is("d", $path->last());

        $path->append("ef");
        is("c/def", $path.'');
        is("def", $path->last());

        $path->append("", "g/");
        is("c/def/g/", $path.'');
        is("g", $path->last());
    }

    {
        my $path;
        # .extension
        $path = path("a.tar.gz.html");

        is(".html", $path->extension());
        is(".gz.html", $path->extension({ match => 2 }));
        is(".tar.gz.html", $path->extension({ match => 3 }));
        is(".tar.gz.html", $path->extension({ match => 4 }));
        is("a", $path->clone()->extension("", { match => 4 }));

        is("a.tar.gz.txt", $path->clone()->extension(".txt").'');
        is("a.tar.txt", $path->clone()->extension(".txt", 2).'');
        is("a.txt", $path->clone()->extension(".txt", 3).'');
        is("a.tar", $path->clone()->extension(".txt", 3)->extension(".tar").'');
        is("a", $path->clone()->extension(".txt", 3)->extension("").'');

        $path->set("");
        is("", $path->extension());
        is(".html", $path->clone()->extension("html").'');
        is(".html", $path->clone()->extension(".html").'');
        is("", $path->clone()->extension("").'');

        $path->set("/");
        is("", $path->extension());
        is("/.html.gz", $path->clone()->extension("html.gz").'');
        is("/.html.gz", $path->clone()->extension(".html.gz").'');
        is("/", $path->clone()->extension("").'');

        is(".html", path( "a/b/c.html" )->extension());
        is("", path( "a/b/c" )->extension());
        is(".gz", path( "a/b/c.tar.gz" )->extension());
        is(".tar.gz", path( "a/b/c.tar.gz" )->extension({ match => "*" }));
        is("a/b/c.txt", path( "a/b/c.html" )->extension( ".txt" ));
        is("a/b/c.zip", path( "a/b/c.html" )->extension( "zip" ));
        is("a/b/c", path( "a/b/c.html" )->extension( "" ));
        is("a/b/c.", path( "a/b/c.html" )->extension( "." ));

        $path = path("a/b/c");
        is("a/b/c.html", $path->extension(".html").'');
        is("a/b/c.html", $path->extension(".html").'');
    }

    {
        # non-greedy
        my $path = path;

        $path->set('a/');
        is($path->pop, 'a');
        is($path->get, '');
        is($path->pop, '');
        is($path->get, '');

        $path->set('/a/');
        is($path->pop, 'a');
        is($path->get, '/');
        is($path->pop, '');
        is($path->get, '/');

        $path->set('/a');
        is($path->pop, 'a');
        is($path->get, '/');
        is($path->pop, '');
        is($path->get, '/');

        $path->set('/a/b/c/');
        is($path->pop, 'c');
        is($path->get, '/a/b');
        is($path->pop, 'b');
        is($path->get, '/a');
        is($path->pop, 'a');
        is($path->get, '/');

        $path->set('a/');
        $path->up;
        is($path->get, '');
        $path->up;
        is($path->get, '');

        $path->set('/a/');
        $path->up;
        is($path->get, '/');
        $path->up;
        is($path->get, '/');

        $path->set('/a');
        $path->up;
        is($path->get, '/');
        $path->up;
        is($path->get, '/');

        $path->set('/a/b/c/');
        $path->up;
        is($path->get, '/a/b');
        $path->up;
        is($path->get, '/a');
        $path->up;
        is($path->get, '/');
    }


    {
        # greedy ^
        my $path = path;

        $path->set('a/');
        is($path->pop('^'), 'a');
        is($path->get, '');
        is($path->pop('^'), '');
        is($path->get, '');

        $path->set('/a/');
        is($path->pop('^'), '/a');
        is($path->get, '');
        is($path->pop('^'), '');
        is($path->get, '');

        $path->set('/a');
        is($path->pop('^'), '/a');
        is($path->get, '');
        is($path->pop('^'), '');
        is($path->get, '');

        $path->set('/a/b/c/');
        is($path->pop('^'), 'c');
        is($path->get, '/a/b');
        is($path->pop('^'), 'b');
        is($path->get, '/a');
        is($path->pop('^'), '/a');
        is($path->get, '');

        $path->set('a/');
        $path->up('^');
        is($path->get, '');
        $path->up('^');
        is($path->get, '');

        $path->set('/a/');
        $path->up('^');
        is($path->get, '');
        $path->up('^');
        is($path->get, '');

        $path->set('/a');
        $path->up('^');
        is($path->get, '');
        $path->up('^');
        is($path->get, '');

        $path->set('/a/b/c/');
        $path->up('^');
        is($path->get, '/a/b');
        $path->up('^');
        is($path->get, '/a');
        $path->up('^');
        is($path->get, '');
    }

    {
        # greedy *
        my $path = path;

        $path->set('a/');
        is($path->pop('*'), 'a/');
        is($path->get, '');
        is($path->pop('*'), '');
        is($path->get, '');

        $path->set('/a/');
        is($path->pop('*'), '/a/');
        is($path->get, '');
        is($path->pop('*'), '');
        is($path->get, '');

        $path->set('/a');
        is($path->pop('*'), '/a');
        is($path->get, '');
        is($path->pop('*'), '');
        is($path->get, '');

        $path->set('/a/b/c/');
        is($path->pop('*'), 'c/');
        is($path->get, '/a/b');
        is($path->pop('*'), 'b');
        is($path->get, '/a');
        is($path->pop('*'), '/a');
        is($path->get, '');

        $path->set('a/');
        $path->up('*');
        is($path->get, '');
        $path->up('*');
        is($path->get, '');

        $path->set('/a/');
        $path->up('*');
        is($path->get, '');
        $path->up('*');
        is($path->get, '');

        $path->set('/a');
        $path->up('*');
        is($path->get, '');
        $path->up('*');
        is($path->get, '');

        $path->set('/a/b/c/');
        $path->up('*');
        is($path->get, '/a/b');
        $path->up('*');
        is($path->get, '/a');
        $path->up('*');
        is($path->get, '');
    }

    {
        my $path;

        # non-greedy
        is(($path = path('a/b/c'))->pop('4'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0'), '');
        is($path->get, 'a/b/c');

        # greedy-^
        is(($path = path('a/b/c'))->pop('4^'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3^'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2^'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1^'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0^'), '');
        is($path->get, 'a/b/c');

        # greedy-$
        is(($path = path('a/b/c'))->pop('4$'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3$'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2$'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1$'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0$'), '');
        is($path->get, 'a/b/c');

        # greedy-*
        is(($path = path('a/b/c'))->pop('4*'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3*'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2*'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1*'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0*'), '');
        is($path->get, 'a/b/c');

        # non-greedy /.
        is(($path = path('/a/b/c'))->pop('4'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c'))->pop('3'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c'))->pop('2'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0'), '');
        is($path->get, '/a/b/c');

        # greedy-^ /.
        is(($path = path('/a/b/c'))->pop('4^'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('3^'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('2^'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1^'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0^'), '');
        is($path->get, '/a/b/c');

        # greedy-$ /.
        is(($path = path('/a/b/c'))->pop('4$'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c'))->pop('3$'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c'))->pop('2$'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1$'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0$'), '');
        is($path->get, '/a/b/c');

        # greedy-* /.
        is(($path = path('/a/b/c'))->pop('4*'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('3*'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('2*'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1*'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0*'), '');
        is($path->get, '/a/b/c');

        # non-greedy /./
        is(($path = path('/a/b/c/'))->pop('4'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c/'))->pop('3'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c/'))->pop('2'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0'), '');
        is($path->get, '/a/b/c/');

        # greedy-^ /./
        is(($path = path('/a/b/c/'))->pop('4^'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('3^'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('2^'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1^'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0^'), '');
        is($path->get, '/a/b/c/');

        # greedy-$ /./
        is(($path = path('/a/b/c/'))->pop('4$'), 'a/b/c/');
        is($path->get, '/');

        is(($path = path('/a/b/c/'))->pop('3$'), 'a/b/c/');
        is($path->get, '/');

        is(($path = path('/a/b/c/'))->pop('2$'), 'b/c/');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1$'), 'c/');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0$'), '');
        is($path->get, '/a/b/c/');

        # greedy-* /./
        is(($path = path('/a/b/c/'))->pop('4*'), '/a/b/c/');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('3*'), '/a/b/c/');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('2*'), 'b/c/');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1*'), 'c/');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0*'), '');
        is($path->get, '/a/b/c/');

        # non-greedy ./
        is(($path = path('a/b/c/'))->pop('4'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('3'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('2'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c/'))->pop('1'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c/'))->pop('0'), '');
        is($path->get, 'a/b/c/');

        # greedy-^ ./
        is(($path = path('a/b/c/'))->pop('4^'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('3^'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('2^'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c/'))->pop('1^'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c/'))->pop('0^'), '');
        is($path->get, 'a/b/c/');

        # greedy-$ ./
        is(($path = path('a/b/c/'))->pop('4$'), 'a/b/c/');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('3$'), 'a/b/c/');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('2$'), 'b/c/');
        is($path->get, 'a');

        is(($path = path('a/b/c/'))->pop('1$'), 'c/');
        is($path->get, 'a/b');

        is(($path = path('a/b/c/'))->pop('0$'), '');
        is($path->get, 'a/b/c/');

        # greedy-* ./
        is(($path = path('a/b/c/'))->pop('4*'), 'a/b/c/');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('3*'), 'a/b/c/');
        is($path->get, '');

        is(($path = path('a/b/c/'))->pop('2*'), 'b/c/');
        is($path->get, 'a');

        is(($path = path('a/b/c/'))->pop('1*'), 'c/');
        is($path->get, 'a/b');

        is(($path = path('a/b/c/'))->pop('0*'), '');
        is($path->get, 'a/b/c/');
    }

    {
        my $path = path;

        # .get
        $path = path("a/b", "c/d", "e");
        is("a/b/c/d/e", $path->get());

        # .set
        $path->set("");
        is("", $path->get());

        $path->set("/");
        is("/", $path->get());

        $path->set("a", "b/c//");
        is("a/b/c/", $path->get());

        $path->set("a/b/c/d/e");
        is("a/b/c/d/e", $path->get());

        # .pop
        $path->pop();
        is("a/b/c/d", $path->get());

        $path->pop(2);
        is("a/b", $path->get());

        $path->pop(3);
        is("", $path->get());

        $path = path("/a/b/c");
        $path->pop(10);
        is("/", $path->get());

        $path->set("/");
        $path->pop();
        is("/", $path->get());

        # .push
        $path->push("a");
        is("/a", $path->get());

        $path->push("a", "b/c//");
        is("/a/a/b/c/", $path->get());

        $path->push($path.'');
        is("/a/a/b/c/a/a/b/c/", $path->get());

        is("/a/a/b/c/a/a/b/c/", $path->get());

        # .up .down
        $path->set("a");
        $path->up();
        is("", path.'');

        $path->down("a/b/c")->up();
        is("a/b", $path.'');

        $path->down("/h/i/j//")->up()->up()->up();
        is("a/b", $path.'');

        $path->down("/h/i/j//")->up(3);
        is("a/b", $path.'');

        $path->set("/");
        $path->up();
        is("/", $path.'');

        $path->down("a");
        is("/a", $path.'');

        $path->down(1);
        is("/a/1", $path.'');
    }

    {
        my $path;
        $path = path();
        is("", $path . "");
        is("", $path->get());
        is("", $path->at(0));
        is("", $path->at(-1));
        is("", $path->at(1));
        is("", $path->first());
        is("", $path->last());
        is("", $path->beginning());
        is("", $path->ending());
        ok($path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok($path->is_branch());
        cmp_deeply([], [ $path->list ]);

        $path = path("/");
        is("/", $path . "");
        is("/", $path->get());
        is("", $path->at(0));
        is("", $path->at(-1));
        is("", $path->at(1));
        is("", $path->first());
        is("", $path->last());
        is("/", $path->beginning());
        is("/", $path->ending());
        cmp_deeply([], [ $path->list ]);
        ok(!$path->is_empty());
        ok($path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("a");
        is("a", $path . "");
        is("a", $path->get());
        is("a", $path->at(0));
        is("a", $path->at(-1));
        is("", $path->at(1));
        is("a", $path->first());
        is("a", $path->last());
        is("a", $path->beginning());
        is("a", $path->ending());
        cmp_deeply([ 'a' ], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok($path->is_branch());

        $path = path("/a");
        is("/a", $path . "");
        is("/a", $path->get());
        is("a", $path->at(0));
        is("a", $path->at(-1));
        is("", $path->at(1));
        is("a", $path->first());
        is("a", $path->last());
        is("/a", $path->beginning());
        is("a", $path->ending());
        cmp_deeply([qw/ a /], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("/a/b");
        is("/a/b", $path . "");
        is("/a/b", $path->get());
        is("a", $path->at(0));
        is("b", $path->at(-1));
        is("b", $path->at(1));
        is("a", $path->first());
        is("b", $path->last());
        is("/a", $path->beginning());
        is("b", $path->ending());
        cmp_deeply([qw/ a b /], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("/a/b/");
        is("/a/b/", $path . "");
        is("/a/b/", $path->get());
        is("a", $path->at(0));
        is("b", $path->at(-1));
        is("b", $path->at(1));
        is("a", $path->first());
        is("b", $path->last());
        is("/a", $path->beginning());
        is("b/", $path->ending());
        cmp_deeply([qw/ a b /], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("/a/b/c");
        is("/a/b/c", $path . "");
        is("/a/b/c", $path->get());
        is("a", $path->at(0));
        is("c", $path->at(-1));
        is("b", $path->at(1));
        is("a", $path->first());
        is("c", $path->last());
        is("/a", $path->beginning());
        is("c", $path->ending());
        cmp_deeply([qw/ a b c /], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok($path->is_tree());
        ok(!$path->is_branch());

        $path = path("a/b/c");
        is("a/b/c", $path . "");
        is("a/b/c", $path->get());
        is("a", $path->at(0));
        is("c", $path->at(-1));
        is("b", $path->at(1));
        is("a", $path->first());
        is("c", $path->last());
        is("a", $path->beginning());
        is("c", $path->ending());
        cmp_deeply([qw/ a b c /], [ $path->list ]);
        ok(!$path->is_empty());
        ok(!$path->is_empty());
        ok(!$path->is_root());
        ok(!$path->is_tree());
        ok($path->is_branch());
    }
}


__END__

    {
        # greedy +
        my $path = path;

        $path->set('a/');
        is($path->pop('+'), 'a');
        is($path->get, '');
        is($path->pop('+'), '');
        is($path->get, '');

        $path->set('/a/');
        is($path->pop('+'), '/a');
        is($path->get, '');
        is($path->pop('+'), '');
        is($path->get, '');

        $path->set('/a');
        is($path->pop('+'), '/a');
        is($path->get, '');
        is($path->pop('+'), '');
        is($path->get, '');

        $path->set('/a/b/c/');
        is($path->pop('+'), 'c');
        is($path->get, '/a/b');
        is($path->pop('+'), 'b');
        is($path->get, '/a');
        is($path->pop('+'), '/a');
        is($path->get, '');

        $path->set('a/');
        $path->up('+');
        is($path->get, '');
        $path->up('+');
        is($path->get, '');

        $path->set('/a/');
        $path->up('+');
        is($path->get, '');
        $path->up('+');
        is($path->get, '');

        $path->set('/a');
        $path->up('+');
        is($path->get, '');
        $path->up('+');
        is($path->get, '');

        $path->set('/a/b/c/');
        $path->up('+');
        is($path->get, '/a/b');
        $path->up('+');
        is($path->get, '/a');
        $path->up('+');
        is($path->get, '');
    }

    {
        # greedy *
        my $path = path;

        $path->set('a/');
        is($path->pop('*'), 'a/');
        is($path->get, '');
        is($path->pop('*'), '');
        is($path->get, '');

        $path->set('/a/');
        is($path->pop('*'), '/a/');
        is($path->get, '');
        is($path->pop('*'), '');
        is($path->get, '');

        $path->set('/a');
        is($path->pop('*'), '/a');
        is($path->get, '');
        is($path->pop('*'), '');
        is($path->get, '');

        $path->set('/a/b/c/');
        is($path->pop('*'), 'c/');
        is($path->get, '/a/b');
        is($path->pop('*'), 'b');
        is($path->get, '/a');
        is($path->pop('*'), '/a');
        is($path->get, '');

        $path->set('a/');
        $path->up('*');
        is($path->get, '');
        $path->up('*');
        is($path->get, '');

        $path->set('/a/');
        $path->up('*');
        is($path->get, '');
        $path->up('*');
        is($path->get, '');

        $path->set('/a');
        $path->up('*');
        is($path->get, '');
        $path->up('*');
        is($path->get, '');

        $path->set('/a/b/c/');
        $path->up('*');
        is($path->get, '/a/b');
        $path->up('*');
        is($path->get, '/a');
        $path->up('*');
        is($path->get, '');
    }

    {
        my $path;

        # non-greedy
        is(($path = path('a/b/c'))->pop('4'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0'), '');
        is($path->get, 'a/b/c');

        # greedy-+
        is(($path = path('a/b/c'))->pop('4+'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3+'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2+'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1+'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0+'), '');
        is($path->get, 'a/b/c');

        # greedy-*
        is(($path = path('a/b/c'))->pop('4*'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('3*'), 'a/b/c');
        is($path->get, '');

        is(($path = path('a/b/c'))->pop('2*'), 'b/c');
        is($path->get, 'a');

        is(($path = path('a/b/c'))->pop('1*'), 'c');
        is($path->get, 'a/b');

        is(($path = path('a/b/c'))->pop('0*'), '');
        is($path->get, 'a/b/c');

        # non-greedy /.
        is(($path = path('/a/b/c'))->pop('4'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c'))->pop('3'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c'))->pop('2'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0'), '');
        is($path->get, '/a/b/c');

        # greedy-+ /.
        is(($path = path('/a/b/c'))->pop('4+'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('3+'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('2+'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1+'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0+'), '');
        is($path->get, '/a/b/c');

        # greedy-* /.
        is(($path = path('/a/b/c'))->pop('4*'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('3*'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c'))->pop('2*'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c'))->pop('1*'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c'))->pop('0*'), '');
        is($path->get, '/a/b/c');

        # non-greedy /./
        is(($path = path('/a/b/c/'))->pop('4'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c/'))->pop('3'), 'a/b/c');
        is($path->get, '/');

        is(($path = path('/a/b/c/'))->pop('2'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0'), '');
        is($path->get, '/a/b/c/');

        # greedy-+ /./
        is(($path = path('/a/b/c/'))->pop('4+'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('3+'), '/a/b/c');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('2+'), 'b/c');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1+'), 'c');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0+'), '');
        is($path->get, '/a/b/c/');

        # greedy-* /./
        is(($path = path('/a/b/c/'))->pop('4*'), '/a/b/c/');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('3*'), '/a/b/c/');
        is($path->get, '');

        is(($path = path('/a/b/c/'))->pop('2*'), 'b/c/');
        is($path->get, '/a');

        is(($path = path('/a/b/c/'))->pop('1*'), 'c/');
        is($path->get, '/a/b');

        is(($path = path('/a/b/c/'))->pop('0*'), '');
        is($path->get, '/a/b/c/');
    }
