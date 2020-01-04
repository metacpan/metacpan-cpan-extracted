#!perl

use 5.010001;
#use strict;
#use warnings;
use Test::Exception;
use Test::More 0.98;

use Scalar::Util qw(blessed);
use Module::FatPack qw(fatpack_modules);

my $class;
{
    no warnings 'once';
    $class = "FatPacked::".(0+\%main::fatpacked);
}

# XXX test module_names

subtest "default options" => sub {
    my $res = fatpack_modules(
        module_srcs => {
            'Module::FatPack::Test::Foo::Bar' => 'package Module::FatPack::Test::Foo::Bar; sub f1 { "foo" } 1;',
            'Module::FatPack::Test::Baz'      => 'package Module::FatPack::Test::Baz;      sub f1 { "baz" } 1;',
        },
    );
    is($res->[0], 200, "status") or do {
        diag explain $res;
        return;
    };

    {
        local @INC = @INC;
        local %INC = %INC;
        eval $res->[2];
        if ($@) { diag explain $res; die }
        ok(blessed($INC[0]), "hook installed at the beginning");
        require Module::FatPack::Test::Foo::Bar;
        is(Module::FatPack::Test::Foo::Bar::f1(), "foo", "module code loaded 1");
        require Module::FatPack::Test::Baz;
        is(Module::FatPack::Test::Baz::f1(), "baz", "module code loaded 2");
    }
};

subtest "option:pm" => sub {
    my $res1 = fatpack_modules(
        pm => 1,
        module_srcs => {
            'Module::FatPack::Test::Foo::Bar' => 'package Module::FatPack::Test::Foo::Bar; sub f2 { "foo2" } 1;',
            'Module::FatPack::Test::Baz'      => 'package Module::FatPack::Test::Baz;      sub f2 { "baz2" } 1;',
        },
    );
    is($res1->[0], 200, "status 1") or do {
        diag explain $res1;
        return;
    };
    my $res2 = fatpack_modules(
        pm => 1,
        module_srcs => {
            'Module::FatPack::Test::Qux'      => 'package Module::FatPack::Test::Qux;      sub f2 { "qux2" } 1;',
        },
    );
    is($res2->[0], 200, "status 2") or do {
        diag explain $res2;
        return;
    };

    {
        local @INC = @INC;
        local %INC = %INC;

        eval $res1->[2];
        if ($@) { diag explain $res1; die }
        ok(blessed($INC[-1]), "hook installed at the end");
        require Module::FatPack::Test::Foo::Bar;
        is(Module::FatPack::Test::Foo::Bar::f2(), "foo2", "module code loaded 1");
        require Module::FatPack::Test::Baz;
        is(Module::FatPack::Test::Baz::f2(), "baz2", "module code loaded 2");

        my @INC2 = @INC;

        eval $res2->[2];
        if ($@) { diag explain $res1; die }
        ok(@INC2 == @INC, "hook does not get doubly installed");
        require Module::FatPack::Test::Qux;
        is(Module::FatPack::Test::Qux::f2(), "qux2", "module code loaded 3");
    }
};

# XXX test add_begin_block
# XXX test preamble & postamble
# XXX test output, overwrite
# XXX test assume_strict=1
# XXX test put_hook_at_the_end
# XXX test stripper option

done_testing;
