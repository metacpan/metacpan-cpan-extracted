use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Cookie-backed sessions via enable 'Session'. The middleware sets/reads a
# session cookie and exposes the session on the context as $c->session (get/set/
# delete). A POST that changes session state then redirects (303), the
# Post/Redirect/Get pattern. The default store is in-memory (development only).
#
#     pagi-server app.pl
#     # carry the cookie jar across requests:
#     curl -c jar -b jar http://127.0.0.1:5000/
#     curl -c jar -b jar -d 'user=ada' http://127.0.0.1:5000/login -L
#     curl -c jar -b jar http://127.0.0.1:5000/
#     curl -c jar -b jar -X POST http://127.0.0.1:5000/logout -L

my $app = app {
    enable 'Session', secret => 'dev-secret-change-me';   # cookie + in-memory store

    get '/' => sub ($c) {
        # get('key', $default) is the lenient form; one-arg get dies if missing.
        my $views = $c->session->get('views', 0) + 1;
        $c->session->set(views => $views);
        {
            you_are            => $c->session->get('user', 'guest'),
            views_this_session => $views,
        };
    };

    post '/login' => async sub ($c) {
        my $attrs = await $c->params->required(
            'user',
            sub ($c, $missing) { $c->json({ error => 'missing', fields => $missing }, status => 400) },
        );
        $c->session->set(user => $attrs->{user});
        $c->redirect('/', 303);          # Post/Redirect/Get
    };

    post '/logout' => sub ($c) {
        $c->session->delete('user');
        $c->redirect('/', 303);
    };
};

$app;
