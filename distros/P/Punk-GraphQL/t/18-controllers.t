#!perl
use 5.024;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PGTest;

# The controller classes, defined inline exactly as Punk's router allows:
# resolution requires the class only when it is not already in memory.
{
    package CtrlApp::Controller::Books;
    sub users {
        my (undef, $args) = @_;
        my $n = $args->{first} // 2;
        return [ @PGTest::USERS[0 .. $n - 1] ];
    }
    sub user {
        my (undef, $args) = @_;
        return $PGTest::USERS[$args->{id} - 1];
    }
    sub _private { die "never wired\n" }

    package CtrlApp::Controller::Admin;
    sub check {
        my ($c) = @_;
        return if ($c->req->header('X-Token') // '') eq 'sesame';
        return [401, ['Content-Type' => 'application/json',
                      'Content-Length' => 33],
                ['{"errors":[{"message":"denied"}]}']];
    }
    sub ctx { my ($c) = @_; return ({ who => 'controller' }) }

    package CtrlApp::Controller::Mut;
    sub rename {
        my (undef, $args) = @_;
        return { %{ $PGTest::USERS[$args->{id} - 1] },
                 name => $args->{name} };
    }
}

# field-level 'Controller#method', type-level controller class, and
# route-style guard + context, all in one app
{
    package CtrlApp;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/graphql' => PGTest::sdl(), {
        resolvers => {
            Query    => 'Books',                       # type-level class
            Mutation => { rename => 'Mut#rename' },    # route-style field
        },
        guard   => 'Admin#check',
        context => 'Admin#ctx',
    };
    plugin 'GraphQL';
}
my $app = CtrlApp->to_app;
my %auth = (env => { HTTP_X_TOKEN => 'sesame' });

# type-level wiring
{
    my $r = hit($app, %auth,
        body => '{"query":"{ users(first: 3) { id name } }"}');
    is $r->[0], 200, 'type-level controller field executes';
    is scalar @{ jdec($r)->{data}{users} }, 3, 'through the class method';

    $r = hit($app, %auth,
        body => '{"query":"{ user(id: 2) { name } }"}');
    is jdec($r)->{data}{user}{name}, 'user2', 'second wired field too';

    $r = hit($app, %auth, body => '{"query":"{ boom }"}');
    is $r->[0], 200, 'a field with no matching method keeps the default';
    is jdec($r)->{data}{boom}, undef, 'and resolves to null on a hashless root';
}

# field-level target
{
    my $r = hit($app, %auth, body =>
        '{"query":"mutation { rename(id: 1, name: \"kim\") { name } }"}');
    is jdec($r)->{data}{rename}{name}, 'kim',
        'Controller#method field target executes';
}

# route-style guard
{
    my $r = hit($app, body => '{"query":"{ boom }"}');
    is $r->[0], 401, 'Controller#method guard denies';
}

# boot-time croaks, naming what failed. Resolution is per-app-namespace,
# so each throwaway app gets its own minimal controller inline.
{
    package BadMethod::Controller::Books;  sub users  { }
    package BadType::Controller::Books;    sub users  { }
    package NoOverlap::Controller::Mut;    sub rename { }
    package BadGuard::Controller::Admin;   sub check  { }
}
{
    package BadMethod;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl(), {
        resolvers => { Query => { users => 'Books#nosuchmethod' } },
    };
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/Books#nosuchmethod/, 'field target typo croaks at boot');
    ::like($err, qr/no method 'nosuchmethod'/, 'naming the missing method');
}
{
    package BadClass;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl(), {
        resolvers => { Query => 'NoSuchController' },
    };
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/NoSuchController.*does not load/,
        'type-level class that cannot load croaks at boot');
}
{
    package BadType;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl(), {
        resolvers => { NoSuchType => 'Books' },
    };
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/SDL defines no such type/,
        'type-level class on an unknown type croaks at boot');
}
{
    package NoOverlap;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl(), {
        resolvers => { Query => 'Mut' },   # Mut has no Query fields
    };
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/no method matching any field of 'Query'/,
        'a controller matching nothing croaks at boot');
}
{
    package BadGuard;
    use Punk;
    use Punk::Plugin::GraphQL;
    graphql '/gql' => PGTest::sdl(), {
        resolvers => PGTest::resolvers(),
        guard     => 'Admin#nosuch',
    };
    my $err = do { local $@; eval { plugin 'GraphQL' }; $@ };
    ::like($err, qr/guard.*no method 'nosuch'/s,
        'guard target typo croaks at boot');
}

done_testing();
