package Mojolicious::Plugin::Fondation::TestWorkflow;

# ABSTRACT: Test helper plugin — exposes routes that call $c->workflow()

use Mojo::Base 'Mojolicious::Plugin', -signatures;

sub register ($self, $app, $config) {

    # POST /test/create — create a new workflow, return { id, state }
    $app->routes->post('/test/create')->to(cb => sub ($c) {
        my $body = $c->req->json // {};
        my $type = $body->{type} // 'ticket';
        my $wf;
        eval { $wf = $c->workflow($type); };
        if ($@) {
            return $c->render(json => { error => "workflow error: $@" }, status => 500);
        }
        return $c->render(json => { error => 'no proxy' }, status => 500)
            unless $wf;

        $c->render(json => { id => $wf->id, state => $wf->state });
    });

    # GET /test/fetch/:id — fetch a workflow by id
    $app->routes->get('/test/fetch/:id')->to(cb => sub ($c) {
        my $type = $c->param('type') // 'ticket';
        my $wf   = $c->workflow($type, $c->param('id'));
        return $c->render(json => { error => 'not found' }, status => 404)
            unless $wf;

        $c->render(json => { id => $wf->id, state => $wf->state });
    });

    # POST /test/actions — create workflow, return actions list
    $app->routes->post('/test/actions')->to(cb => sub ($c) {
        my $body = $c->req->json // {};
        my $type = $body->{type} // 'ticket';
        my $wf   = $c->workflow($type);
        return $c->render(json => { error => 'no proxy' }, status => 500)
            unless $wf;

        $c->render(json => $wf->actions);
    });

    # POST /test/execute — create workflow, execute action, return new state
    $app->routes->post('/test/execute')->to(cb => sub ($c) {
        my $body = $c->req->json // {};
        my $type = $body->{type} // 'ticket';
        my $wf   = $c->workflow($type);
        return $c->render(json => { error => 'no proxy' }, status => 500)
            unless $wf;

        my $new_state;
        eval { $new_state = $wf->execute($body->{action}, $body->{params} // {}); };
        if ($@) {
            return $c->render(json => { error => "execute error: $@" }, status => 500);
        }
        $c->render(json => { state => $new_state });
    });

    # POST /test/can — create workflow, check if action is allowed
    $app->routes->post('/test/can')->to(cb => sub ($c) {
        my $body = $c->req->json // {};
        my $type = $body->{type} // 'ticket';
        my $wf   = $c->workflow($type);
        return $c->render(json => { error => 'no proxy' }, status => 500)
            unless $wf;

        $c->render(json => { can => $wf->can($body->{action}) ? 1 : 0 });
    });

    # POST /test/history — create workflow, execute, return history
    $app->routes->post('/test/history')->to(cb => sub ($c) {
        my $body = $c->req->json // {};
        my $type = $body->{type} // 'ticket';
        my $wf   = $c->workflow($type);
        return $c->render(json => { error => 'no proxy' }, status => 500)
            unless $wf;

        eval { $wf->execute($body->{action}, $body->{params} // {}); };
        if ($@) {
            return $c->render(json => { error => "execute error: $@" }, status => 500);
        }
        $c->render(json => $wf->history);
    });
}

1;
