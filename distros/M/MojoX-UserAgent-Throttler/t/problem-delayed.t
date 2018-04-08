use Mojo::Base -strict;
use lib 't';
use share;
use Mojo::UserAgent;
use Sub::Throttler qw( throttle_it );
use Sub::Throttler::Limit;


my ($ua, $throttle);

get '/slow' => sub {
    my $c = shift;
    $c->render_later;
    Mojo::IOLoop->timer(0.1 => sub {
        $c->render(text => 'slow');
    });
};


# test how DESTROY works with default throttling

throttle_it('Mojo::UserAgent::start');
$throttle = Sub::Throttler::Limit->new;
$throttle->apply_to_methods('Mojo::UserAgent');

$ua = Mojo::UserAgent->new;
$ua->get("$SITE/slow", sub { event('cb1') });
$ua->get("$SITE/slow", sub { event('cb2') });
wait_err();
undef $ua;
is_events ['cb1'],
    'cb is not called while DESTROY for delayed async request started before DESTROY';
like get_warn(), qr/\$done.*not called/ms,
    '$done was lost';
ok !$throttle->try_acquire('id','default',1),
    'resource was not released';


done_testing();
