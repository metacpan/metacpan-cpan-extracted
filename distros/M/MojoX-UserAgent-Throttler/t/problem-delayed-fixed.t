use Mojo::Base -strict;
use lib 't';
use share;
use MojoX::UserAgent::Throttler;
use Sub::Throttler::Limit;


my ($ua, $throttle);

get '/slow' => sub {
    my $c = shift;
    $c->render_later;
    Mojo::IOLoop->timer(0.1 => sub {
        $c->render(text => 'slow');
    });
};


# test how DESTROY works with MojoX::UserAgent::Throttler

$throttle = Sub::Throttler::Limit->new;
$throttle->apply_to_methods('Mojo::UserAgent');

$ua = Mojo::UserAgent->new;
$ua->get("$SITE/slow", sub { event('cb1') });
$ua->get("$SITE/slow", sub { event('cb2') });
wait_err();
undef $ua;
is_events_anyorder ['cb1','cb2'],
    'cb is called while DESTROY for delayed async request started before DESTROY';
is get_warn(), q{},
    '$done was not lost';
ok $throttle->try_acquire('id','default',1),
    'resource was released';


done_testing();
