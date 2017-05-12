#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use Path::Class;

use ok 'Template::Multipass';

use File::Temp qw/tempdir/;

my $d = tempdir(CLEANUP => 1);

my $t = Template::Multipass->new(
    INCLUDE_PATH => [ file(__FILE__)->parent->subdir("templates")->stringify ],
    COMPILE_DIR  => "$d",
    MULTIPASS    => my $config = {
        VARS => {
            header => "[",
            footer => "]",
            array  => [
                { name => "foo", value => "ding" },
                { name => "bork", value => "moose" },
                { name => "angry", value => "steering wheel" },
                { name => "banana", value => "tasty" },
                { name => "giraffe", value => "diagonal" },
            ],
        },
    },
);

{
my $out;
ok( $t->process( "bar.tt", { blah => "42," }, \$out ) );

is( $out, <<'END', "simple meta template" );
[
42,
{foo: "ding",bork: "moose",angry: "steering wheel",banana: "tasty",giraffe: "diagonal"}
]
END

}

{
my $out;
ok( $t->process( "bar_meta.tt", { blah => "42," }, \$out ) );

is( $out, <<'END', "more meta template" );
[
42,
{foo: "ding",bork: "moose",angry: "steering wheel",banana: "tasty",giraffe: "diagonal"}
]
END

}

{
my $out;
ok( $t->process( "bar_meta.tt", { blah => "45," }, \$out ) );

is( $out, <<'END', "non meta vars don't get cached" );
[
45,
{foo: "ding",bork: "moose",angry: "steering wheel",banana: "tasty",giraffe: "diagonal"}
]
END

}

{
my $out;

ok( $t->process( "bar_meta.tt", { blah => "45," }, \$out, { meta_vars => { array => [ { name => "oink", value => "bah" } ] } } ) );

is( $out, <<'END', "deep meta vars get cached when using flat" );
[
45,
{foo: "ding",bork: "moose",angry: "steering wheel",banana: "tasty",giraffe: "diagonal"}
]
END

}

{
my $out;

ok( $t->process( "bar_meta.tt", { blah => "45," }, \$out, meta_vars => { header => '[[', footer => ']]', array => [ { name => "oink", value => "bah" } ] } ) );

is( $out, <<'END', "deep meta vars get cached when using flat" );
[[
45,
{oink: "bah"}
]]
END

}

{
my $out;

local $config->{MANGLE_HASH_VARS} = 1;

ok( $t->process( "bar_meta.tt", { blah => "45," }, \$out ) );

is( $out, <<'END', "re run of template" );
[
45,
{foo: "ding",bork: "moose",angry: "steering wheel",banana: "tasty",giraffe: "diagonal"}
]
END

}

{
my $out;

local $config->{MANGLE_HASH_VARS} = 1;

ok( $t->process( "bar_meta.tt", { blah => "45," }, \$out, meta_vars => { array => [ { name => "oink", value => "bah" } ] } ) );

is( $out, <<'END', "deep meta vars don't get cached when using hash" );
[
45,
{oink: "bah"}
]
END
}

{
my $out;

local $config->{MANGLE_HASH_VARS} = 1;

ok( $t->process( "bar_meta.tt", { blah => "45," }, \$out ) );

is( $out, <<'END', "re run of template" );
[
45,
{foo: "ding",bork: "moose",angry: "steering wheel",banana: "tasty",giraffe: "diagonal"}
]
END

}

SKIP: {
    skip "Test::Benchmark required", 1 unless eval { require Test::Benchmark };
    Test::Benchmark->import;

    my $out;
    is_faster(
        -1,
        sub { $t->process( "bar_meta.tt", { blah => "42," }, \$out ) },
        sub { $t->process( "bar.tt", { blah => "42," }, \$out ) },
        "meta vars + caching is faster",
    );
}
