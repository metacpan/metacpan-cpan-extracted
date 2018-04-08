use Mojo::Base -strict;
use Test::More;
use ojo;
use Mojo::Util qw( monkey_patch trim );
use vars qw( $SITE );
no if $] >= 5.020, feature => 'signatures';

# avoid (in cleanup) error (should be fixed in Mojolicious-5.69)
my $orig_DESTROY = \&Mojo::UserAgent::DESTROY;
monkey_patch 'Mojo::UserAgent', DESTROY => sub {
    $_[0]->ioloop(undef) if (${^GLOBAL_PHASE}||q{}) eq 'DESTRUCT';
    goto &$orig_DESTROY;
};

# make sure blocking $ua requests use main ioloop
monkey_patch 'Mojo::UserAgent', ioloop => sub { Mojo::IOLoop->singleton };

# setup local http server on random port
our $SITE = 'http://127.0.0.1';
our $_daemon = Mojo::Server::Daemon->new(app=>app, listen=>["$SITE:0"], silent=>1)->start;
$SITE .= ':' . Mojo::IOLoop->acceptor($_daemon->acceptors->[0])->handle->sockport;

### lazy helpers
sub start () { Mojo::IOLoop->start }
sub stop () { Mojo::IOLoop->stop }
sub diag_tx ($;$) {
    my ($tx, $pfx) = @_;
    $pfx .= ': ' if defined $pfx;
    diag $pfx, $tx->error ? $tx->error->{message} : $tx->res->text;
}

### Test async events
# $cb = sub { event('e1'); ... };
# is_events ['e1', ...], 'optional description';

sub event {
    state @events;
    return [ delete @events[0 .. $#events] ] if !@_;
    push @events, @_;
    return;
}

sub is_events ($;$) {
    unshift @_, event();
    goto &is_deeply;
}

sub is_events_anyorder ($;$) {
    unshift @_, [ sort @{ event() } ];
    $_[1] = [ sort @{ $_[1] } ];
    goto &is_deeply;
}

### Intercept warn/die/carp/croak messages
# wait_err();
# … test here …
# like get_warn(), qr/…/;
# like get_die(),  qr/…/;

my ($DieMsg, $WarnMsg);

sub wait_err {
    $DieMsg = $WarnMsg = q{};
    $::SIG{__WARN__} = sub { $WarnMsg .= $_[0] };
    $::SIG{__DIE__}  = sub { $DieMsg  .= $_[0] };
}

sub get_warn {
    $::SIG{__DIE__} = $::SIG{__WARN__} = undef;
    return $WarnMsg;
}

sub get_die {
    $::SIG{__DIE__} = $::SIG{__WARN__} = undef;
    return $DieMsg;
}


1;
