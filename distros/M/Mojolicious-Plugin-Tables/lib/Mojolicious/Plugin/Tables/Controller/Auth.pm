package Mojolicious::Plugin::Tables::Controller::Auth;

use Mojo::Base 'Mojolicious::Controller';

sub fail {
    my ($c,$error) = @_;
    $error ||= 'unspecified';
    my $msg = "Table-level auth error was $error";
    $c->app->log->error($msg);
    $c->render('exception', exception=>$msg, status=>401);
    return;
}

sub ok {
    my $c = shift;

    # apply site-wide session, cookie, or request-based authorisation here..
    # and set authorised username into the session.
    if (1) {
        $c->stash(user_id=>'administrator');
        return 1
    }

    if (($c->stash('format')||'x') eq 'json') {
        $c->fail;
        return;
    }

    $c->add_flash(errors => 'Please sign in first using your Google ID.');
    $c->redirect_to('/');
    return;
}

1;
