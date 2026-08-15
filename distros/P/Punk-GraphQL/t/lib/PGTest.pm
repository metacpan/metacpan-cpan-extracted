package PGTest;
use 5.024;
use strict;
use warnings;
use Exporter 'import';
use File::Raw::JSON ();

our @EXPORT = qw(sdl resolvers hit jdec);

# One schema for the whole conformance suite: a nested list, arguments,
# a mutation, and a field that dies on demand.
sub sdl {
    return <<'SDL';
type User {
  id: ID!
  name: String!
  email: String!
  active: Boolean!
}
type Query {
  users(first: Int): [User!]!
  user(id: ID!): User
  boom: String
}
type Mutation {
  rename(id: ID!, name: String!): User
}
SDL
}

our @USERS = map +{
    id     => "$_",
    name   => "user$_",
    email  => "user$_\@example.com",
    active => $_ % 2 ? 1 : 0,
}, 1 .. 25;

# resolvers(%hooks): counters land in the hashref you pass so tests can
# assert how often the engine called into Perl
sub resolvers {
    my (%hooks) = @_;
    my $calls = $hooks{calls} // {};
    return {
        Query => {
            users => sub {
                my (undef, $args, $ctx) = @_;
                $calls->{users}++;
                my $n = $args->{first} // scalar @USERS;
                $n = @USERS if $n > @USERS;
                return [ @USERS[0 .. $n - 1] ];
            },
            user => sub {
                my (undef, $args, $ctx) = @_;
                $calls->{user}++;
                return $ctx && $ctx->{loader}
                    ? $ctx->{loader}->load($args->{id})
                    : $USERS[$args->{id} - 1];
            },
            boom => sub { die "kaboom\n" },
        },
        Mutation => {
            rename => sub {
                my (undef, $args) = @_;
                $calls->{rename}++;
                return { %{ $USERS[$args->{id} - 1] },
                         name => $args->{name} };
            },
        },
    };
}

# hit($app, %opts): one PSGI request, in process. Returns the triplet.
sub hit {
    my ($app, %o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body or die $!;
    return $app->({
        REQUEST_METHOD => $o{method} // 'POST',
        PATH_INFO      => $o{path} // '/graphql',
        QUERY_STRING   => $o{query} // '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 80,
        'psgi.version' => [1, 1],
        'psgi.url_scheme' => 'http',
        'psgi.errors'  => \*STDERR,
        CONTENT_TYPE   => exists $o{type} ? $o{type}
                        : ($body ne '' ? 'application/json' : ''),
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        %{ $o{env} // {} },
    });
}

sub jdec { File::Raw::JSON::file_json_decode($_[0][2][0]) }

1;
