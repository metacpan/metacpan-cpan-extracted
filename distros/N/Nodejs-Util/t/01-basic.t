#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Cwd qw(abs_path);
use File::chdir;
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Nodejs::Util qw(
                       nodejs_path
                       nodejs_module_path
               );

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
if ($ENV{DEBUG}) {
    note "tempdir=$tempdir";
}
mkdir "$tempdir/node_modules";
mkdir "$tempdir/lib";
mkdir "$tempdir/lib/node_modules";
mkdir "$tempdir/lib/node_modules/b";
mkdir "$tempdir/lib/node_modules/c";
mkdir "$tempdir/lib/node_modules/d";
mkdir "$tempdir/lib/node_modules/e";
mkdir "$tempdir/lib/node";
mkdir "$tempdir/lib/two";
mkdir "$tempdir/node_path";
mkdir "$tempdir/node_path/node_modules";
mkdir "$tempdir/.node_modules";
mkdir "$tempdir/.node_libraries";
write_text("$tempdir/lib/node_modules/a.js", "");
write_text("$tempdir/lib/node_modules/b/index.js", "");
write_text("$tempdir/lib/node_modules/c/package.json", "");
write_text("$tempdir/lib/node_modules/d/foo", "");
write_text("$tempdir/lib/a.node", "");
write_text("$tempdir/lib/a.json", "");
write_text("$tempdir/node_path/a.js", "");
write_text("$tempdir/node_path/node_modules/a.node", "");
write_text("$tempdir/.node_modules/g1.js", "");
write_text("$tempdir/.node_libraries/g2.js", "");
write_text("$tempdir/lib/node/g3.js", "");

subtest nodejs_path => sub {
    note "nodejs_path = ", nodejs_path();
    ok(1);
};

subtest nodejs_module_path => sub {
    local $CWD = "$tempdir";

    subtest "argument is absolute path" => sub {
        path_eq(nodejs_module_path("/not-found"), undef);
        path_eq(nodejs_module_path("$tempdir/lib/a"), "$tempdir/lib/a.json");
        path_eq(nodejs_module_path("$tempdir/lib/a.node"), "$tempdir/lib/a.node");
    };

    subtest "argument is relative path" => sub {
        path_eq(nodejs_module_path("./not-found"), undef);
        path_eq(nodejs_module_path("./lib/a"), "./lib/a.json");
        path_eq(nodejs_module_path("./lib/a.node"), "./lib/a.node");
        {
            local $CWD = "$tempdir/lib/node_modules";
            path_eq(nodejs_module_path("../a"), "../a.json");
        }
    };

    subtest "argument is filename" => sub {
        path_eq(nodejs_module_path("not-found"), undef);
        # searching node_modules from current to root
        {
            local $CWD = "$tempdir/lib";
            path_eq(nodejs_module_path("a"), "$tempdir/lib/node_modules/a.js");
        }
        {
            local $CWD = "$tempdir/lib/two";
            path_eq(nodejs_module_path("a"), "$tempdir/lib/node_modules/a.js");
        }

        # searching folder
        {
            local $CWD = "$tempdir/lib";
            path_eq(nodejs_module_path("b"), "$tempdir/lib/node_modules/b/index.js");
            path_eq(nodejs_module_path("c"), "$tempdir/lib/node_modules/c/package.json");
            path_eq(nodejs_module_path("d"), undef);
            path_eq(nodejs_module_path("e"), undef);
        }
    };

    subtest "NODE_PATH" => sub {
        local $ENV{NODE_PATH} = "$tempdir/node_path";
        path_eq(nodejs_module_path("a"), "$tempdir/node_path/a.js");
    };

    subtest '$HOME/.node_modules' => sub {
        local $ENV{HOME} = "$tempdir";
        path_eq(nodejs_module_path("g1"), "$tempdir/.node_modules/g1.js");
    };

    subtest '$HOME/.node_libraries' => sub {
        local $ENV{HOME} = "$tempdir";
        path_eq(nodejs_module_path("g2"), "$tempdir/.node_libraries/g2.js");
    };

    subtest '$PREFIX/lib/node' => sub {
        local $ENV{PREFIX} = "$tempdir";
        path_eq(nodejs_module_path("g3"), "$tempdir/lib/node/g3.js");
    };

    subtest "option all=1" => sub {
        paths_eq(nodejs_module_path({all=>1}, "./not-found"), []);
        paths_eq(nodejs_module_path({all=>1}, "./lib/a"), ["./lib/a.json", "./lib/a.node"]);
    };
};

DONE_TESTING:
done_testing;

sub path_eq {
    no warnings 'uninitialized';

    my ($path1, $path2) = @_;
    if (defined($path1) xor defined($path2)) {
        ok(0, "path '$path1' does not equal path '$path2'");
    } elsif (!defined($path1) and !defined($path2)) {
        ok(1, "path1 and path2 are both undef");
    } else {
        is(abs_path($path1), abs_path($path2), "path $path1 eq path $path2");
    }
}

sub paths_eq {
    my ($paths1, $paths2) = @_;

    if (@$paths1 != @$paths2) {
        diag("paths1 = ", explain $paths1);
        diag("paths2 = ", explain $paths2);
        ok(0, "paths1 ne paths2 (different length)");
    }
    for my $i (0..$#{$paths1}) {
        note "Comparing paths[$i]: ", explain($paths1->[$i]), " vs ", explain($paths2->[$i]);
        path_eq($paths1->[$i], $paths2->[$i]);
    }
}
