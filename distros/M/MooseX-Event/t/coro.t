use strict;
use warnings;
require Test::More;

eval 'use Coro';

if ( $@ ) {
    Test::More->import( skip_all => "Can't do Coro tests without Coro installed" );
    exit(0);
}
else  {
    Test::More->import( tests => 2);
}

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
