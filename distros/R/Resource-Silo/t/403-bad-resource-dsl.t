#!/usr/bin/env perl

=head1 DESCRIPTION

Various errors in DSL.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

subtest 'resource names' => sub {
    throws_ok {
        resource;
    } qr(^resource: .*identifier), 'no undef names';

    throws_ok {
        resource [], sub { };
    } qr(^resource: .*identifier), 'no refs in names';

    throws_ok {
        resource 42, sub { };
    } qr(^resource: .*identifier), 'names must be identifiers';

    throws_ok {
        resource '$', sub { };
    } qr(^resource: .*identifier), 'names must be identifiers';

    throws_ok {
        resource 'identifier_followed_by_$', sub { };
    } qr(^resource: .*identifier), 'names must be identifiers';
};

subtest 'names clash' => sub {
    throws_ok {
        resource new => sub { };
    } qr(^resource: .*replace.*method), 'known method = no go';
    my $where = (quotemeta __FILE__)." line ".(__LINE__-2);
    like $@, qr($where), 'error attributed correctly';

    throws_ok {
        resource ctl => sub { };
    } qr(^resource: .*replace.*method), 'known method = no go';

    throws_ok {
        resource dup => sub { };
        resource dup => sub { };
    } qr(^resource: .*redefine.*resource), 'no duplicates';
};

throws_ok {
    resource bar => supercharge => 42, init => sub { };
} qr(^resource 'bar': .*unknown), 'unknown parameters = no go';

subtest 'initializer' => sub {
    throws_ok {
        resource 'naked';
    } qr(^resource 'naked': .*init), 'init missing = no go';

    throws_ok {
        resource bad_init => [];
    } qr(^resource 'bad_init': .*init), 'init of wrong type = no go';

    throws_ok {
        resource bad_init_2 => "my_func";
    } qr(^resource 'bad_init_2': .*init), 'init of wrong type = no go (2)';
};

throws_ok {
    resource with_param => argument => 42, sub { };
} qr(^resource 'with_param': .*argument.*regex), 'wrong argument spec';

subtest 'cleanup' => sub {
    throws_ok {
        resource bad_order => cleanup_order => 'never', sub { };
    } qr(^resource 'bad_order': .*cleanup_order.*number), 'wrong cleanup order spec';

    throws_ok {
        resource bad_cleanup => cleanup => {}, sub { };
    } qr(^resource 'bad_cleanup': .*\bcleanup\b.*function), 'wrong cleanup method spec';

    throws_ok {
        resource bad_cleanup_2 => cleanup => "function", sub { };
    } qr(^resource '\w+': .*\bcleanup\b.*function), 'wrong cleanup method spec';

    throws_ok {
        resource bad_f_cleanup => fork_cleanup => {}, sub { };
    } qr(^resource '\w+': .*\bfork_cleanup\b.*function), 'wrong cleanup method spec';

    throws_ok {
        resource bad_f_cleanup_2 => fork_cleanup => "function", sub { };
    } qr(^resource '\w+': .*\bfork_cleanup\b.*function), 'wrong cleanup method spec';

    throws_ok {
        resource cleanup_wo_cache =>
            cleanup                 => sub {},
            ignore_cache            => 1,
            init                    => sub {};
    } qr(^resource '\w+':.*'cleanup\*'.*'ignore_cache'), 'cleanup incompatible with nocache';

    throws_ok {
        resource cleanup_wo_cache_2 =>
            fork_cleanup            => sub {},
            ignore_cache            => 1,
            init                    => sub {};
    } qr(^resource '\w+':.*'cleanup\*'.*'ignore_cache'), 'cleanup incompatible with nocache';
};

subtest 'dependencies' => sub {
    throws_ok {
        resource deps_1 =>
            dependencies    => \"foo",
            init            => sub {};
    } qr(^resource '\w+': 'dependencies'.*array), "dependencies must be array";

    throws_ok {
        resource deps_2 =>
            dependencies    => [42],
            init            => sub {};
    } qr(^resource '\w+': illegal dependenc), "dependencies must be array";

    throws_ok {
        resource deps_3 =>
            dependencies    => [\"foo"],
            init            => sub {};
    } qr(^resource '\w+': illegal dependenc), "dependencies must be array";
};

subtest 'Bread::Board-like DI' => sub {
    throws_ok {
        resource class_di_1 =>
            class               => 'My::Resource',
            init                => sub { };
    } qr(^resource '\w+': 'class' .*incompatible.*init), "class + init = no go";

    throws_ok {
        resource class_di_2 =>
            class               => 'lib/My/Resource.pm',
            dependencies        => {};
    } qr(^resource '\w+': 'class' .* package .* 'lib/My), "bad package name";

    throws_ok {
        resource class_di_3 =>
            class               => 'My::Resource',
            dependencies        => \"foo::bar";
    } qr(^resource '\w+': 'class'.*'dependencies'), "bad dependency spec";

    throws_ok {
        resource class_di_4 =>
            class               => 'My::Resource',
            dependencies        => {
                foo => [ '$name' ],
            };
    } qr(^resource '\w+': dependency 'foo'.*format), "bad new() parameter spec";

    throws_ok {
        resource class_di_5 =>
            class               => 'My::Resource',
            dependencies        => {
                foo => [ name => 1 => 2 => 3 ],
            };
    } qr(^resource '\w+': dependency 'foo'.*format), "bad new() parameter spec (2)";

    throws_ok {
        resource class_di_6 =>
            class               => 'My::Resource',
            dependencies        => {
                foo => {},
            };
    } qr(^resource '\w+': dependency 'foo'.*format), "bad new() parameter spec (3)";
};

subtest 'require modules' => sub {
    throws_ok {
        resource req_1 =>
            require         => {},
            init            => sub {};
    } qr(^resource '\w+': 'require' .*module name.*list), "bad require type";

    throws_ok {
        resource req_2 =>
            require         => [ '-foo', 42 ],
            init            => sub {};
    } qr(^resource '\w+': 'require'), "bad module names";
};

subtest 'literal' => sub {
    throws_ok {
        resource const_1 =>
            literal         => 42,
            init            => sub { 'foo' };
    } qr(^resource '\w+': 'literal'.*incompatible.*'init'), "literal + init = no go";

    throws_ok {
        resource const_1 =>
            literal         => 42,
            class           => 'Foo::Bar',
            dependencies    => {};
    } qr(^resource '\w+': 'literal'.*incompatible.*'class'), "literal + init = no go";
};

is_deeply [ silo->ctl->meta->list ], [ 'dup' ]
    , "no reqources except duplicate present";

done_testing;

