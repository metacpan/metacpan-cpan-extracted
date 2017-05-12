use strict;
use warnings;
use Test::More tests => 4;
use ONE qw( Timer=sleep );

my $ii = 0;
my $idle = ONE->on( idle => sub { $ii ++ } );

# We're also testing loop and stop here
ONE::Timer->after( 0.1 => sub { ONE->stop } );
ONE->loop;

cmp_ok( $ii, '>', 1000, "The idle counter ticked a reasonable number of times." );

ONE->remove_listener( idle =>$idle );

$ii = 0;

sleep .1;

is( $ii, 0, "The idle counter did not tick after we removed it" );

my $alarm = 0;
ONE->on( SIGALRM => sub { $alarm ++ } );
alarm(1);
sleep 1.1;
alarm(0);

is( $alarm, 1, "The alarm signal triggered" );

my $cnt = 0;

collect {
    ONE::Timer->every( 0.2 => sub { $cnt ++ } );
    ONE::Timer->every( 0.5 => sub { $cnt += 10 } );
};
is( $cnt, 12, "We collected three event triggers of the right kinds" );

done_testing( 4 );