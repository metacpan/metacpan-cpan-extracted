use warnings;
use strict;
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

#p $b;

#say STDERR $b->labels->{ quote };

#say STDERR $b->to_string;

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
