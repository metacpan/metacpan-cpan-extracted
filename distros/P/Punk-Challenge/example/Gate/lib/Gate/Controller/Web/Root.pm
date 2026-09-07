package Gate::Controller::Web::Root;

use Punk::Controller;

our $VERSION = '0.01';

sub index {
    my ($c) = @_;
    return $c->render('index', {
        title   => 'Gate',
        cleared => $c->challenge_cleared ? 1 : 0,
        name    => $c->session->{name} // '',
    });
}

# Reached only with a clearance: the `always` rule on /login answers every
# other request with the puzzle, and the browser comes back here once it
# has solved it.
sub form {
    my ($c) = @_;
    return $c->render('login', {
        title => 'Sign in',
        csrf  => $c->csrf_field,
        error => '',
    });
}

sub login {
    my ($c) = @_;
    my $name = $c->param('name') // '';
    $name =~ s/^\s+|\s+$//g;
    if (!length $name || length $name > 40) {
        return $c->render('login', {
            title => 'Sign in',
            csrf  => $c->csrf_field,
            error => 'A name, up to forty characters.',
        }, status => 422);
    }
    $c->session->{name} = $name;
    return $c->redirect($c->url_for('welcome'), 303);
}

sub welcome {
    my ($c) = @_;
    my $name = $c->session->{name};
    return $c->redirect($c->url_for('login'), 303) unless defined $name;
    return $c->render('welcome', {
        title => "Hello, $name",
        name  => $name,
        csrf  => $c->csrf_field,
    });
}

sub logout {
    my ($c) = @_;
    $c->session_expire;
    return $c->redirect($c->url_for('home'), 303);
}

# Under the `after` rule: free until the limit, a puzzle past it. A program
# gets the 403 JSON, solves, and presents the solution as
# X-Challenge-Response or keeps the clearance as X-Clearance.
sub time {
    my ($c) = @_;
    return $c->json({ now => scalar gmtime, cleared => $c->challenge_cleared ? 1 : 0 });
}

1;

__END__
