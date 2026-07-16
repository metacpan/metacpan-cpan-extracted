use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# A REST resource exercising the full verb set — get/post/put/patch/del — over
# an in-memory collection, with the status codes a JSON API is expected to use
# (200 OK, 201 Created, 204 No Content) and a JSON 404 from not_found for any
# unmatched path.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/widgets
#     curl -X POST  -H 'content-type: application/json' -d '{"name":"sprocket"}' http://127.0.0.1:5000/widgets
#     curl -X PUT   -H 'content-type: application/json' -d '{"name":"cog","qty":3}' http://127.0.0.1:5000/widgets/1
#     curl -X PATCH -H 'content-type: application/json' -d '{"qty":9}'              http://127.0.0.1:5000/widgets/1
#     curl -X DELETE http://127.0.0.1:5000/widgets/1

my @widgets;          # the store: a list of { id, name, qty }
my $next_id = 1;
sub find_widget ($id) { (grep { $_->{id} == $id } @widgets)[0] }

my $app = app {
    get '/widgets' => sub ($c) { \@widgets };           # arrayref -> JSON list

    post '/widgets' => async sub ($c) {
        my $attrs = await $c->params->required(
            'name',
            sub ($c, $missing) { $c->json({ error => 'missing', fields => $missing }, status => 400) },
        );
        my $w = { id => $next_id++, name => $attrs->{name}, qty => 0 };
        push @widgets, $w;
        $c->json($w, status => 201);                     # 201 Created
    };

    get '/widgets/:id' => sub ($c, $id) {
        my $w = find_widget($id)
            or return $c->json({ error => 'not found' }, status => 404);
        $w;                                              # hashref -> JSON
    };

    put '/widgets/:id' => async sub ($c, $id) {
        my $w = find_widget($id)
            or return $c->json({ error => 'not found' }, status => 404);
        my $attrs = await $c->params->permitted('name', 'qty');
        %$w = (id => $w->{id}, name => $attrs->{name}, qty => $attrs->{qty} // 0);  # full replace
        $w;
    };

    patch '/widgets/:id' => async sub ($c, $id) {
        my $w = find_widget($id)
            or return $c->json({ error => 'not found' }, status => 404);
        my $attrs = await $c->params->permitted('name', 'qty');
        $w->{$_} = $attrs->{$_} for grep { defined $attrs->{$_} } keys %$attrs;     # partial merge
        $w;
    };

    del '/widgets/:id' => sub ($c, $id) {
        find_widget($id)
            or return $c->json({ error => 'not found' }, status => 404);
        @widgets = grep { $_->{id} != $id } @widgets;
        $c->response->empty;                             # 204 No Content
    };

    not_found sub ($c) { $c->json({ error => 'no such route' }, status => 404) };
};

$app;
