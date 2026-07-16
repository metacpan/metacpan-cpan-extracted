use v5.40;
use experimental 'signatures';
use PAGI::Nano;

# Named routes and link generation, including across a mount in both directions.
#
# A route is named with the name() marker; $c->uri_for('name', \%params, \%query)
# builds its URL. Names form one flat namespace across the whole app, so a
# mounted sub-app can link to a name in the parent and the parent can link to a
# name in the mount (mount prefixes are applied automatically).
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/            # links to a mounted route
#     curl http://127.0.0.1:5000/api/users/7 # links back to the parent's route

my $api = app {
    get '/users/:id' => name('user') => sub ($c, $id) {
        {
            id       => $id,
            self     => $c->uri_for('user', { id => $id }),       # own name
            edit     => $c->uri_for('user', { id => $id }, { edit => 1 }),
            back_home => $c->uri_for('home'),                     # a name in the parent
        };
    };
};

my $app = app {
    get '/' => name('home') => sub ($c) {
        {
            page      => 'home',
            first_user => $c->uri_for('user', { id => 1 }),       # a name in the mount
        };
    };

    mount '/api' => $api;
};

$app;
