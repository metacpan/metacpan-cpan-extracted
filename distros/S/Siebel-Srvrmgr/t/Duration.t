use warnings;
use strict;
use Test::Most 0.34 tests => 8;
use Test::Moose 2.1605;
use DateTime 1.26;
use lib 't';
use Test::Siebel::Srvrmgr::Fixtures qw(create_comp);

dies_ok { create_comp() }
'cannot create an instance without properly setting up the SIEBEL_TZ environment variable';
like( $@, qr/SIEBEL_TZ/, 'dies with expected error message' );
local $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';
my $start = DateTime->now();
note( 'Now is ' . $start );
my $end           = $start->clone;
my $interval      = 10;
my $interval_secs = $interval * 60;
note("Considering that component finished after $interval minutes");
$end->add( minutes => $interval );
note( 'End time will be ' . $end );
my $comp = create_comp( $start, $end );
is( $comp->get_duration, $interval_secs,
    "component executed for $interval_secs seconds" );
can_ok( $comp,
    qw(get_time_zone get_start get_current get_end fix_endtime is_running get_datetime get_duration)
);

foreach my $attrib (qw(start_datetime curr_datetime end_datetime time_zone)) {
    has_attribute_ok( $comp, $attrib, "instance has the attribute $attrib" );
}
