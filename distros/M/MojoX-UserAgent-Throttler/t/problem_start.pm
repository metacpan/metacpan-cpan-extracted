use Mojo::Base -strict;
use lib 't';
use share;
use Mojo::UserAgent;
use Sub::Throttler qw( throttle_it );
use Sub::Throttler::Limit;


use vars qw( $ua $throttle );

get '/fast' => { text => 'fast' };
get '/slow' => sub {
    my $c = shift;
    $c->render_later;
    Mojo::IOLoop->timer(0.1 => sub {
        $c->render(text => 'slow');
    });
};


sub run_tests {
    my ($prefix) = @_;

    $ua = Mojo::UserAgent->new;
    $ua->get("$SITE/slow", sub {
        my ($this, $tx) = @_;
        event('cb');
    });
    wait_err();
    undef $ua;
    is_events ['cb'],
        $prefix.': cb is called while DESTROY for async request started before DESTROY';
    is get_warn(), q{};

    $ua = Mojo::UserAgent->new;
    $ua->get("$SITE/slow", sub {
        my ($this, $tx) = @_;
        event('cb1');
        event(trim($this->get("$SITE/fast")->res->text));
    });
    wait_err();
    undef $ua;
    is_events ['cb1','fast'],
        $prefix.': sync request is handled while DESTROY';
    is get_warn(), q{};

    $ua = Mojo::UserAgent->new;
    $ua->get("$SITE/slow", sub {
        my ($this, $tx) = @_;
        event('cb1');
        $this->get("$SITE/slow", sub {
            my ($this, $tx) = @_;
            event('cb2');
        });
    });
    wait_err();
    undef $ua;
    is_events ['cb1'],
        $prefix.': cb is not called while DESTROY for async request started while DESTROY';
}


1;
