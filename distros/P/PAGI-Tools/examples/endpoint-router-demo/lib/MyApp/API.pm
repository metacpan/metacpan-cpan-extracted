package MyApp::API;
use parent 'PAGI::Endpoint::Router';
use strict;
use warnings;
use Future::AsyncAwait;

my @USERS = (
    { id => 1, name => 'Alice', email => 'alice@example.com' },
    { id => 2, name => 'Bob', email => 'bob@example.com' },
);

sub routes {
    my ($self, $r) = @_;

    $r->get('/info' => 'get_info');
    $r->get('/users' => 'list_users');
    $r->get('/users/:id' => 'get_user');
    $r->post('/users' => 'create_user');
}

async sub get_info {
    my ($self, $ctx) = @_;
    $ctx->state->{metrics}{requests}++;

    my $config = $ctx->state->{config};

    return $ctx->json({
        app     => $config->{app_name},
        version => $config->{version},
        api     => 'v1',
    });
}

async sub list_users {
    my ($self, $ctx) = @_;
    $ctx->state->{metrics}{requests}++;
    return $ctx->json(\@USERS);
}

async sub get_user {
    my ($self, $ctx) = @_;
    $ctx->state->{metrics}{requests}++;

    my $id = $ctx->request->path_param('id');
    my ($user) = grep { $_->{id} == $id } @USERS;

    if ($user) {
        return $ctx->json($user);
    } else {
        return $ctx->json({ error => 'User not found' }, status => 404);
    }
}

async sub create_user {
    my ($self, $ctx) = @_;
    $ctx->state->{metrics}{requests}++;

    my $data = await $ctx->request->json;

    my $new_user = {
        id    => scalar(@USERS) + 1,
        name  => $data->{name},
        email => $data->{email},
    };
    push @USERS, $new_user;

    return $ctx->json($new_user, status => 201);
}

1;
