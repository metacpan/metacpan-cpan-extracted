use strict;
use Test::More tests => 12;

BEGIN
{
    use_ok("Mvalve::QueueSet");
}

can_ok( "Mvalve::QueueSet" => qw(
    all_queues as_q4m_args
) );

my $queues = Mvalve::QueueSet->new;
{
    ok( $queues );
    isa_ok( $queues, "Mvalve::QueueSet" );
}

{
    my( @queues ) = $queues->all_queues;
    is( @queues , 3 );
    is( (shift @queues)->{table}, 'q_emerg' );
    is( (shift @queues)->{table}, 'q_timed' );
    is( (shift @queues)->{table}, 'q_incoming' );
}

{
    my( @queues ) = $queues->as_q4m_args;
    is( @queues, 3 );
    is( shift @queues, 'q_emerg' );
    like( shift @queues, qr/q_timed:ready<\d+/ );
    is( shift @queues, 'q_incoming' );
}
