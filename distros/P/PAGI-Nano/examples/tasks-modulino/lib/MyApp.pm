package MyApp;

use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# The "grows up" run shape: a modulino. Loading the file returns the app (the
# last expression), so it runs directly:
#
#     pagi-server -Ilib lib/MyApp.pm
#
# It is also dual-use: `use MyApp; my $app = MyApp->to_app` for tests, or
# `mount '/tasks' => MyApp->to_app` to nest it inside a larger app. Same app
# value either way — no rewrite from the single-file form.

# The handlers initialize their slice of shared state defensively (//= []). This
# keeps the modulino robust in both run shapes: standalone, startup seeds the
# state; mounted inside a larger app, the router does not forward lifespan events
# to mounted children, so the outer app owns lifecycle and the defensive init
# covers the gap.
sub to_app ($class) {
    return app {
        startup async sub ($state) { $state->{tasks} //= [] };

        get '/' => sub ($c) { $c->state->{tasks} //= [] };

        get '/:id' => sub ($c, $id) {
            ($c->state->{tasks} //= [])->[$id - 1]
                // $c->json({ error => 'not found' }, status => 404);
        };

        post '/' => async sub ($c) {
            my $attrs = await $c->params->required(
                'title', +{ tags => [] },
                sub ($c, $missing) {
                    $c->json({ error => 'missing', fields => $missing }, status => 400);
                },
            );
            my $tasks = $c->state->{tasks} //= [];
            push @$tasks, { id => scalar(@$tasks) + 1, %$attrs };
            $c->json($tasks->[-1], status => 201);
        };
    };
}

__PACKAGE__->to_app;
