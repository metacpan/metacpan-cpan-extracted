package Notify::Controller::Web::Root;

use Punk::Controller;

our $VERSION = '0.01';

sub index {
    my ($c) = @_;
    my $user = $c->auth_id;
    # What the last send reported, one request ago.
    my $flash = $c->flash || {};
    return $c->render('welcome', {
        sent     => $flash->{sent} || [],
        asked    => $flash->{asked},
        # Stencil's `if` is a truthiness test, not an expression language, so
        # which option is selected is decided here rather than in the template.
        urgencies => [ map +{ name => $_, selected => ($_ eq 'normal') },
                       qw(very-low low normal high) ],
        title    => 'Notify',
        user     => $user,
        # The browser needs this to subscribe. Inlining it saves a fetch;
        # /push/key serves the same bytes for anything that would rather ask.
        push_key => $c->push_key,
        subs     => $user
            ? [ Punk::Plugin::Push->for_user($c->app, $user) ] : [],
    });
}

sub login_form {
    my ($c) = @_;
    return $c->render('login', { title => 'Sign in' });
}

sub login {
    my ($c) = @_;

    # check_password takes the user ROW, not an email: it burns the same PBKDF2
    # work when there is no user, so response time does not reveal which
    # addresses exist. Look the row up first, then hand it over.
    my $email = lc($c->param('email') // '');
    my $page  = $c->model('User')->search({ email => $email }, { limit => 1 });
    my ($user) = @{ (ref $page eq 'HASH' ? $page->{rows} : $page) || [] };

    return $c->render('login', { title => 'Sign in', error => 1 })
        unless $user && $c->check_password($user, $c->param('password'));

    $c->login($user);
    return $c->redirect('/');
}

sub logout {
    my ($c) = @_;
    $c->logout;
    return $c->redirect('/');
}

# The send. In a real application this would be something that happened - a
# report finished, an order shipped - rather than a button on a page.
# What a payload may carry. The plugin imposes no schema - the service worker
# decides what it understands - so this is the shape root/push-sw.js reads.
our @PAYLOAD = qw(title body url icon badge tag);

# What a single send may override, beyond the plugin's configured defaults.
our @OPTIONS = qw(ttl urgency topic);

# The send. In a real application this would be something that happened - a
# report finished, an order shipped - rather than a form.
sub notify {
    my ($c) = @_;
    my $user = $c->auth_id or return $c->redirect('/login');

    # Empty fields are left out rather than sent as "": an icon of "" is a
    # broken image, and a topic of "" would collapse every notification into
    # one.
    my %payload = map { my $v = $c->param($_);
                        (defined $v && length $v) ? ($_ => $v) : () } @PAYLOAD;
    my %opts    = map { my $v = $c->param($_);
                        (defined $v && length $v) ? ($_ => $v) : () } @OPTIONS;

    $payload{title} = 'Notify'                    unless exists $payload{title};
    $payload{body}  = 'Hello from Punk::Push.'    unless exists $payload{body};

    my @results = $c->push_send($user, \%payload, %opts);

    # flash takes PAIRS, not a hashref.
    $c->flash(
        sent => [ map +{
            endpoint  => $_->endpoint,
            status    => $_->status,
            error     => $_->error,
            delivered => $_->delivered,
            pruned    => $_->pruned,
        }, @results ],
        # what was actually asked for, so the page can show it back
        asked => join(', ',
            (map { "$_=$payload{$_}" } grep { exists $payload{$_} } @PAYLOAD),
            (map { "$_=$opts{$_}" }    grep { exists $opts{$_} }    @OPTIONS)),
    );

    return $c->redirect('/');
}

1;

__END__
