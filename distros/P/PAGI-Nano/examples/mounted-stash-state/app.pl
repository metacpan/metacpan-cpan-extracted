use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Request;
use PAGI::Stash;
use PAGI::Nano;

# Demonstrates that a mounted sub-app sees the request stash set by the parent's
# middleware AND the lifecycle objects the parent put in app state at startup.
#
# Both ride the PAGI scope: the stash lives at $scope->{'pagi.stash'} and the
# shared state at $scope->{state}; mount passes the scope through, so the mounted
# app reads the very same objects.
#
#     pagi-server app.pl
#     curl -H 'X-User: Ada' http://127.0.0.1:5000/api/hello

# A lifecycle object: built once at startup, then shared (and mutated) for the
# app's lifetime. The greeting count proves the mounted app and the parent use
# the same instance.
package Greeter {
    use v5.40;
    use experimental 'signatures';
    sub new   ($class, %args) { bless { template => $args{template}, count => 0 }, $class }
    sub greet ($self, $name)  { $self->{count}++; sprintf($self->{template}, $name) }
    sub count ($self)         { $self->{count} }
}

# Parent middleware: stash the current user (from a header) on each request. The
# stash wraps $scope->{'pagi.stash'}, so whatever runs downstream — including the
# mounted app — sees it.
my $stash_user = async sub ($scope, $receive, $send, $next) {
    my $user = PAGI::Request->new($scope)->header('x-user') // 'guest';
    PAGI::Stash->new($scope)->set(user => $user);
    await $next->();
};

# The mounted sub-app. Its handlers never set up the greeter or the user; they
# just read them off the context that flowed down through the mount.
my $api = app {
    get '/hello' => sub ($c) {
        my $user    = $c->stash->get('user');      # set by parent middleware
        my $greeter = $c->state->{greeter};        # built by parent startup
        {
            from     => 'mounted /api app',
            user     => $user,
            greeting => $greeter->greet($user),
            greetings_so_far => $greeter->count,
        };
    };
};

my $app = app {
    startup async sub ($state) {
        $state->{greeter} = Greeter->new(template => 'Hello, %s!');
    };

    enable $stash_user;

    get '/' => sub ($c) {
        { hint => 'GET /api/hello with an X-User header' };
    };

    # The parent can see the same lifecycle object the mount uses.
    get '/greetings' => sub ($c) {
        { greetings_so_far => $c->state->{greeter}->count };
    };

    mount '/api' => $api;
};

$app;
