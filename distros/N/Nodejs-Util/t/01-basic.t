#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

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
        is_deeply(nodejs_module_path("/not-found"), undef);
        is_deeply(nodejs_module_path("$tempdir/lib/a"), "$tempdir/lib/a.json");
        is_deeply(nodejs_module_path("$tempdir/lib/a.node"), "$tempdir/lib/a.node");
    };

    subtest "argument is relative path" => sub {
        is_deeply(nodejs_module_path("./not-found"), undef);
        is_deeply(nodejs_module_path("./lib/a"), "./lib/a.json");
        is_deeply(nodejs_module_path("./lib/a.node"), "./lib/a.node");
        {
            local $CWD = "$tempdir/lib/node_modules";
            is_deeply(nodejs_module_path("../a"), "../a.json");
        }
    };

    subtest "argument is filename" => sub {
        is_deeply(nodejs_module_path("not-found"), undef);
        # searching node_modules from current to root
        {
            local $CWD = "$tempdir/lib";
            is_deeply(nodejs_module_path("a"), "$tempdir/lib/node_modules/a.js");
        }
        {
            local $CWD = "$tempdir/lib/two";
            is_deeply(nodejs_module_path("a"), "$tempdir/lib/node_modules/a.js");
        }

        # searching folder
        {
            local $CWD = "$tempdir/lib";
            is_deeply(nodejs_module_path("b"), "$tempdir/lib/node_modules/b/index.js");
            is_deeply(nodejs_module_path("c"), "$tempdir/lib/node_modules/c/package.json");
            is_deeply(nodejs_module_path("d"), undef);
            is_deeply(nodejs_module_path("e"), undef);
        }
    };

    subtest "NODE_PATH" => sub {
        local $ENV{NODE_PATH} = "$tempdir/node_path";
        is_deeply(nodejs_module_path("a"), "$tempdir/node_path/a.js");
    };

    subtest '$HOME/.node_modules' => sub {
        local $ENV{HOME} = "$tempdir";
        is_deeply(nodejs_module_path("g1"), "$tempdir/.node_modules/g1.js");
    };

    subtest '$HOME/.node_libraries' => sub {
        local $ENV{HOME} = "$tempdir";
        is_deeply(nodejs_module_path("g2"), "$tempdir/.node_libraries/g2.js");
    };

    subtest '$PREFIX/lib/node' => sub {
        local $ENV{PREFIX} = "$tempdir";
        is_deeply(nodejs_module_path("g3"), "$tempdir/lib/node/g3.js");
    };

    subtest "option all=1" => sub {
        is_deeply(nodejs_module_path({all=>1}, "./not-found"), []);
        is_deeply(nodejs_module_path({all=>1}, "./lib/a"), ["./lib/a.json", "./lib/a.node"]);
    };
};

DONE_TESTING:
done_testing;
