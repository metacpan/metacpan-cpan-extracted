use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    package TestEvent;
    use strict;
    use warnings;
    use MooseX::Event '-alias' => {
        on => 'listen_on',
        once => 'listen_once',
        emit => 'emit_event',
    };

    has_event 'ping';

    sub alert {
        my $self = shift;
        $self->emit_event( ping => "test" );
    }

    no MooseX::Event; 
    __PACKAGE__->meta->make_immutable();
}

my $te = TestEvent->new;

$te->listen_on( ping => sub {
    pass( "Got first ping" );
    } );

$te->listen_on( ping => sub {
    pass( "Got second ping" );
    } );

$te->alert();

$te->remove_all_listeners('ping');

my $ping_count = 0;

my $listener = $te->listen_on( ping => sub { ++$ping_count } );

$te->remove_listener( ping => $listener );
$te->alert();
is( $ping_count, 0, "Remove listener actually removed the listener" );

$ping_count = 0;
$te->listen_once( ping => sub { ++$ping_count } );

$te->alert();
$te->alert();
is( $ping_count, 1, "Once handler triggered only once" );

