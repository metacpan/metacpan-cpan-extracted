use warnings;
use strict;
use Data::Printer;
use Test2::V0 '!meta';

use OmniDisco::Prometheus;


my $b = OD::Prometheus::Metric->new(
        line => 'http_request_duration_microseconds{plain="prometheus",backslash="\\\\",newline="\n",quote="\"",quantile="0.5"} 7.1',
        comments => [
                '#    HELP  http_request_duration_microseconds      one line\nsecond line and backslash:\\\\\nthird item',
                '# TYPE http_request_duration_microseconds gauge',
                '# And when the entire mountain is chiseled away, the first second of eternity will have passed',
        ]
);
my $b2 = OD::Prometheus::Metric->new(
        line => 'http_request_duration_microseconds{plain="prometheus",backslash="\\\\",newline="\n",quote="\"",quantile="0.5"} NaN',
        comments => [
                '#    HELP  http_request_duration_microseconds      one line\nsecond line and backslash:\\\\\nthird item',
                '# TYPE http_request_duration_microseconds gauge',
                '# And when the entire mountain is chiseled away, the first second of eternity will have passed',
        ]
);
my $m = OD::Prometheus::Metric->new( metric_name=>'foo',labels=>{ bar => 'baz'},values=>[[1551972804,'xxx'],[1551972854,'yyy']] );
my $m2 = OD::Prometheus::Metric->new( metric_name=>'foo',labels=>{ bar => 'baz'},value=>1234,timestamp=>1551972854 );
my $all = OD::Prometheus::Set->new;
$all->push( $m, $m2 );

ok( $m->size == 2, 'Size method works');
ok( $m2->size == 1, 'Size method works yet again');
ok( $all->size == 3, 'Size also reflects correctly in Sets');
is( $m->values, [[1551972804,'xxx'],[1551972854,'yyy']],'Values were set correctly');
is( $m->ordered, [[1551972804,'xxx'],[1551972854,'yyy']],'Ordered values work correctly');
is( $m->valuehash, { 1551972804=>'xxx',1551972854=>'yyy' } ,'valuehash method works');
is( $m->latest, 'yyy', 'latest method works');
is( $m->latest_timestamp, 1551972854, 'latest_timestamp method works');
is( $m->earliest, 'xxx', 'earliest method works');
is( $m->earliest_timestamp, 1551972804, 'earliest_timestamp method works');
is( $m2->value, 1234, 'Value also works');
is( $b->value, 7.1, 'Value works yet again');
is( $m2->timestamp, 1551972854, 'Timestamp works');
ok( dies { $m->value },'calling value on metric with multiple values should die');
ok( dies { $m->timestamp },'calling timestamp on metric with multiple values should die');
is( $m->to_string,"# TYPE untyped\nfoo{bar=\"baz\"} xxx 1551972804\nfoo{bar=\"baz\"} yyy 1551972854", 'to_string works okay');


my $s = OD::Prometheus::Set->new;

isa_ok( $s, 'OD::Prometheus::Set' );

ok( $s->is_empty, 'Initial set is empty' );

$s->push( $b );

is( $s->size, 1, 'Size of set is 1');

isa_ok( $s->[0] , 'OD::Prometheus::Metric' );

my $rs0 = $s->find( 'http_request_duration_microseconds', { plain => 'prometheus' } );
ok( !$rs0->is_empty, 'find test 0' );
my $rs1 = $s->find( 'http_request_duration_microseconds', { plain => 'notthere' } );
ok( $rs1->is_empty, 'find test 1' );
my $rs2 = $s->find( 'http_request_duration_microseconds' );
ok( !$rs2->is_empty, 'find test 2' );
my $rs3 = $s->find( 'http_request_duration_microseconds', { } );
ok( !$rs3->is_empty, 'find test 2' );
my $rs4 = $s->find( 'doesnotexist', { plain => 'prometheus' } );
ok( $rs4->is_empty, 'find test 4' );
my $rs5 = $s->find( 'http_request_duration_microseconds', { plain => 'prometheus', something => 'else' } );
ok( $rs5->is_empty, 'find test 5' );
my $rs6 = $s->find( 'http_request_duration_microseconds', { plain => 'prometheus' }, 'NaN' );
ok( $rs6->is_empty, 'find test 6' );
my $rs7 = $s->find( 'http_request_duration_microseconds', { plain => 'prometheus' }, 7.1 );
ok( !$rs7->is_empty, 'find test 7' );

ok( $rs0->value == 7.1, 'Set value method');

my $count;
$rs0->each( sub {
	isa_ok( $_, 'OD::Prometheus::Metric' );
	$count++
});
ok( $count == 1, 'Each method seems to be working okay' );

done_testing;

# my $c = OD::Prometheus::Client->new(host=>'test.server',port=>9100);
# ok( ref $c->get  eq 'ARRAY', 'get returns an array' );
