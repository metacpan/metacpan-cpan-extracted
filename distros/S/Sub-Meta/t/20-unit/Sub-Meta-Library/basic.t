use Test2::V0;

use Sub::Meta;
use Sub::Meta::Library;

{
    package Foo; ## no critic (RequireFilenameMatchesPackage)
    sub foo { }
    sub bar { }
}

sub hello { }
sub world { }

subtest 'register' => sub {
    my $meta = Sub::Meta->new(sub => \&hello);

    ok dies { Sub::Meta::Library->register }, 'arguments required coderef and submeta';
    ok dies { Sub::Meta::Library->register(\&hello) }, 'arguments required coderef and submeta';
    ok dies { Sub::Meta::Library->register('hello', $meta) }, 'required coderef';
    ok dies { Sub::Meta::Library->register({}, $meta) }, 'required coderef';
    ok dies { Sub::Meta::Library->register(\&hello, 'meta') }, 'required an instance of Sub::Meta';
    ok dies { Sub::Meta::Library->register(\&hello, bless {}, 'Some') }, 'required an instance of Sub::Meta';

    ok lives { Sub::Meta::Library->register(\&hello, $meta) };
};

subtest 'register_list' => sub {
    my $meta_hello = Sub::Meta->new(sub => \&hello);
    my $meta_world = Sub::Meta->new(sub => \&world);

    ok lives { Sub::Meta::Library->register_list([\&hello, $meta_hello], [\&world, $meta_world]) };
    ok lives { Sub::Meta::Library->register_list([\&hello, $meta_hello]) };
    ok dies { Sub::Meta::Library->register_list([ [\&hello, $meta_hello], [\&world, $meta_world] ] ) };
    ok dies { Sub::Meta::Library->register_list({ }) };
    ok dies { Sub::Meta::Library->register_list('hello') };
    ok dies { Sub::Meta::Library->register_list('hello', $meta_hello) };
};

subtest 'get' => sub {
    my $meta_hello = Sub::Meta->new(sub => \&hello);
    my $meta_world = Sub::Meta->new(sub => \&world);
    my $meta_foo   = Sub::Meta->new(sub => \&Foo::foo);
    my $meta_bar   = Sub::Meta->new(sub => \&Foo::bar);

    Sub::Meta::Library->register_list(
        [\&hello, $meta_hello],
        [\&world, $meta_world],
        [\&Foo::foo, $meta_foo],
        [\&Foo::bar, $meta_bar],
    );

    is( Sub::Meta::Library->get('hello'), undef, 'required coderef' );
    is( Sub::Meta::Library->get({}), undef, 'required coderef' );
    is( Sub::Meta::Library->get(\&hello), $meta_hello );
    is( Sub::Meta::Library->get(\&world), $meta_world );
    is( Sub::Meta::Library->get(sub { }), undef );

    subtest 'get_by_stash_subname' => sub {
        is( Sub::Meta::Library->get_by_stash_subname('main', 'hello'), $meta_hello );
        is( Sub::Meta::Library->get_by_stash_subname('Foo', 'foo'), $meta_foo );
        is( Sub::Meta::Library->get_by_stash_subname('Unknown', 'foo'), undef );
        is( Sub::Meta::Library->get_by_stash_subname('Foo', 'hoge'), undef );
    };

    subtest 'get_all_subnames_by_stash' => sub {
        is( Sub::Meta::Library->get_all_subnames_by_stash('main'), ['hello', 'world'] );
        is( Sub::Meta::Library->get_all_subnames_by_stash('Foo'), ['bar', 'foo'] );
        is( Sub::Meta::Library->get_all_subnames_by_stash('Unknown::Foo'), [ ] );
    };

    subtest 'get_all_submeta_by_stash' => sub {
        is( Sub::Meta::Library->get_all_submeta_by_stash('main'), [$meta_hello, $meta_world] );
        is( Sub::Meta::Library->get_all_submeta_by_stash('Foo'), [$meta_bar, $meta_foo] );
        is( Sub::Meta::Library->get_all_submeta_by_stash('Unknown::Baz'), [ ] );
    };
};

subtest 'remove' => sub {
    ok dies { Sub::Meta::Library->remove('hello') }, 'required coderef';
    ok dies { Sub::Meta::Library->remove({}) }, 'required coderef';
    is( Sub::Meta::Library->get(\&hello), Sub::Meta->new(sub => \&hello) );
    is( Sub::Meta::Library->remove(\&hello), Sub::Meta->new(sub => \&hello) );
    is( Sub::Meta::Library->get(\&hello), undef );
};

subtest 'package variable' => sub {
    ok %Sub::Meta::Library::INFO;
    ok %Sub::Meta::Library::INDEX;
};

done_testing;
