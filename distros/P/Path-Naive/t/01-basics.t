#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use Path::Naive qw(
    abs_path
    concat_path
    concat_and_normalize_path
    normalize_path
    is_abs_path
    is_rel_path
    split_path
              );

subtest abs_path => sub {
    dies_ok { abs_path() };
    dies_ok { abs_path(undef) };
    dies_ok { abs_path("") };
    dies_ok { abs_path("a", "b") } "base not absolute";
    is(abs_path("a", "/b")              , "/b/a");
    is(abs_path(".", "/b")              , "/b");
    is(abs_path("a/c//..", "/b/")       , "/b/a");
    is(abs_path("/a", "/b/c")           , "/a");
};

subtest concat_path => sub {
    dies_ok { concat_path() };
    dies_ok { concat_path(undef) };
    dies_ok { concat_path("") };
    is(concat_path("a", "b")            , "a/b");
    is(concat_path("a/", "c")           , "a/c");
    is(concat_path("a", "c/")           , "a/c/");
    is(concat_path("a", "../d/")        , "a/../d/");
    is(concat_path("a/b", ".././e")     , "a/b/.././e");
    is(concat_path("../", ".././c/")    , "../.././c/");
    is(concat_path("a/b/c", "/f/a")     , "/f/a");

    is(concat_path("a", "/b", "g")      , "/b/g");
};

subtest concat_and_normalize_path => sub {
    dies_ok { concat_and_normalize_path() };
    dies_ok { concat_and_normalize_path(undef) };
    dies_ok { concat_and_normalize_path("") };
    is(concat_and_normalize_path("a", "b")          , "a/b");
    is(concat_and_normalize_path("a/", "b")         , "a/b");
    is(concat_and_normalize_path("a", "b/")         , "a/b");
    is(concat_and_normalize_path("a", "../b/")      , "b");
    is(concat_and_normalize_path("a/b", ".././c")   , "a/c");
    is(concat_and_normalize_path("../", ".././c/")  , "../../c");
    is(concat_and_normalize_path("a/b/c", "/f/a")   , "/f/a");

    is(concat_and_normalize_path("a/b/c", "/f/a/")  , "/f/a");
    is(concat_and_normalize_path("a", "/b", "g")    , "/b/g");
};

subtest is_abs_path => sub {
    dies_ok { is_abs_path() };
    dies_ok { is_abs_path(undef) };
    dies_ok { is_abs_path("") };
    is(is_abs_path("/")                , 1);
    is(is_abs_path("/a")               , 1);
    is(is_abs_path("/..")              , 1);
    is(is_abs_path(".")                , 0);
    is(is_abs_path("./b")              , 0);
    is(is_abs_path("b/c/")             , 0);
};

subtest is_rel_path => sub {
    dies_ok { is_rel_path() };
    dies_ok { is_rel_path(undef) };
    dies_ok { is_rel_path("") };
    is(is_rel_path("/")                , 0);
    is(is_rel_path("a/b")              , 1);
};

subtest normalize_path => sub {
    dies_ok { normalize_path() };
    dies_ok { normalize_path(undef) };
    dies_ok { normalize_path("") };
    is(normalize_path("/")             , "/");
    is(normalize_path("..")            , "..");
    is(normalize_path("./")            , ".");
    is(normalize_path("//")            , "/");
    is(normalize_path("a/b/.")         , "a/b");
    is(normalize_path("a/c/./")        , "a/c");
    is(normalize_path("d/e/..")        , "d");
    is(normalize_path("e/f/../")       , "e");
    is(normalize_path("/a/./../f")     , "/f");
    is(normalize_path("/a/../../g")    , "/g");

    is(normalize_path(".")             , ".");
    is(normalize_path("./h")           , "h");
    is(normalize_path("i/.")           , "i");
    is(normalize_path("././j/.")       , "j");
    is(normalize_path("./.")           , ".");
    is(normalize_path("/.")            , "/");
    is(normalize_path("/./.")          , "/");
    is(normalize_path("../k")          , "../k");
    is(normalize_path("l/..")          , "l/..");
    is(normalize_path("m/a/..")        , "m");
    is(normalize_path("./n/..")        , "n/..");
    is(normalize_path("o/./..")        , "o/..");
    is(normalize_path("p/a/./..")      , "p");
    is(normalize_path("a/../q")        , "q");
    is(normalize_path("a/../.")        , ".");
};

subtest split_path => sub {
    dies_ok { split_path() };
    dies_ok { split_path(undef) };
    dies_ok { split_path("") };
    is_deeply([split_path("/")]        , []);
    is_deeply([split_path("a")]        , ["a"]);
    is_deeply([split_path("/b")]       , ["b"]);
    is_deeply([split_path("/c/")]      , ["c"]);
    is_deeply([split_path("../d")]     , ["..", "d"]);
    is_deeply([split_path("./e")]      , [".", "e"]);
    is_deeply([split_path("../../f")]  , ["..", "..", "f"]);
    is_deeply([split_path(".././../g")], ["..", ".", "..", "g"]);
    is_deeply([split_path("h/i/j/..")] , ["h", "i", "j", ".."]);

    is_deeply([split_path("k///l//")]  , ["k", "l"]);
};

DONE_TESTING:
done_testing;
