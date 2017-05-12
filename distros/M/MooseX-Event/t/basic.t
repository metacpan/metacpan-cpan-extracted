use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    package TestEvent;
    use strict;
    use warnings;
    use MooseX::Event;

    has_event 'ping';

    no MooseX::Event; 
    __PACKAGE__->meta->make_immutable();
}

my $te = TestEvent->new;

$te->on( ping => sub {
    pass( "Got first ping" );
    } );

$te->on( ping => sub {
    pass( "Got second ping" );
    } );

$te->emit( "ping" );

$te->remove_all_listeners('ping');

my $ping_count = 0;

my $listener = $te->on( ping => sub { ++$ping_count } );

$te->remove_listener( ping => $listener );
$te->emit( "ping" );
is( $ping_count, 0, "Remove listener actually removed the listener" );

$ping_count = 0;
$te->once( ping => sub { ++$ping_count } );

$te->emit( "ping" );
$te->emit( "ping" );
is( $ping_count, 1, "Once handler triggered only once" );

