#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::testing;

my $base  = 'Monitoring::Sneck::Checks::base';
my $check = Monitoring::Sneck::Checks::testing->new( args => [], timeout => 30 );

# ranges
is_deeply( $base->parse_range('10'),     { start => 0,     end => 10,    inside => 0 }, 'range 10' );
is_deeply( $base->parse_range('10:'),    { start => 10,    end => undef, inside => 0 }, 'range 10:' );
is_deeply( $base->parse_range('~:10'),   { start => undef, end => 10,    inside => 0 }, 'range ~:10' );
is_deeply( $base->parse_range('-5:0.5'), { start => -5,    end => 0.5,   inside => 0 }, 'range -5:0.5' );
is_deeply( $base->parse_range('@10:20'), { start => 10,    end => 20,    inside => 1 }, 'range @10:20' );
foreach my $bad ( '', 'ten', '20:10', '1:2:3', '@', ':' ) {
	ok( !eval { $base->parse_range($bad); 1 }, '"' . $bad . '" is not a range' );
}
my %alerts = (
	'10'     => { -1    => 1, 0  => 0, 10   => 0, 11 => 1 },
	'10:'    => { 9     => 1, 10 => 0, 1000 => 0 },
	'~:10'   => { -1000 => 0, 10 => 0, 10.5 => 1 },
	'10:20'  => { 9     => 1, 15 => 0, 21   => 1 },
	'@10:20' => { 9     => 0, 10 => 1, 20   => 1, 21 => 0 },
);
foreach my $range ( sort( keys(%alerts) ) ) {
	foreach my $value ( sort( keys( %{ $alerts{$range} } ) ) ) {
		is( $base->in_alert( $value, $range ), $alerts{$range}{$value}, $value . ' for ' . $range );
	}
}
is( $base->threshold_status( 5,  10,    20 ),    0, 'OK' );
is( $base->threshold_status( 15, 10,    20 ),    1, 'WARNING' );
is( $base->threshold_status( 25, 10,    20 ),    2, 'CRITICAL' );
is( $base->threshold_status( 25, undef, undef ), 0, 'no ranges, OK' );

# worst and names
is( $base->worst( 0, 3, 1 ),                   1,          'WARNING over UNKNOWN' );
is( $base->worst( 3, 0 ),                      3,          'UNKNOWN over OK' );
is( $base->worst( 1, 2, 3 ),                   2,          'CRITICAL over all' );
is( $base->worst(),                            0,          'nothing is OK' );
is( $base->status_name(2),                     'CRITICAL', 'status name' );
is( $base->label,                              'BASE',     'label' );
is( Monitoring::Sneck::Checks::testing->label, 'TESTING',  'label of a check' );

# perfdata and finish
is( $check->perfdata( label => 'time', value => '0.120', uom => 's', warning => 1, critical => 2, min => 0 ),
	'time=0.120s;1;2;0', 'perfdata' );
is( $check->perfdata( label => 'size', value => 10 ),                 'size=10',                'trailing ; dropped' );
is( $check->perfdata( label => "it's / here", value => 1, max => 5 ), q{'it''s / here'=1;;;;5}, 'quoted label' );
is( $check->finish( 1, 'slow', 'a detail' ),                          1, 'finish returns the code' );
is(
	$check->{stdout},
	q{TESTING WARNING - slow | time=0.120s;1;2;0 size=10 'it''s / here'=1;;;;5} . "\na detail\n",
	'status line, perfdata, and details'
);
$check->err("oops\n");
is( $check->{combined}, $check->{stdout} . "oops\n", 'combined in order' );

# timeout
is( Monitoring::Sneck::Checks::testing->new( timeout => 30 )->timeout,              29,  'a second under' );
is( Monitoring::Sneck::Checks::testing->new( timeout => 0.5 )->timeout,             1,   'at least one' );
is( Monitoring::Sneck::Checks::testing->new( args    => [ '-t', '2.5' ] )->timeout, 2.5, '-t' );
ok( !eval { Monitoring::Sneck::Checks::testing->new( args => [ '-t', 0 ] ) }, '-t 0 is bad' );

# quotes
foreach my $balanced ( '', '-H x', q{-s 'a b'}, q{-s "it's"}, q{-s 'it\'s'}, q{-s "a \" b"}, q{a\'b} ) {
	is( $base->quotes_balanced($balanced), 1, 'balanced: ' . $balanced );
}
foreach my $unbalanced ( q{-s 'a b}, q{-s "a}, q{-s "a \"}, q{a\\} ) {
	is( $base->quotes_balanced($unbalanced), 0, 'unbalanced: ' . $unbalanced );
}

# hosts
ok( $base->is_host('www.example.org'), 'hostname' );
ok( $base->is_host('2001:db8::1'),     'IPv6' );
ok( !$base->is_host('not a host'),     'not a host' );

# certificates
SKIP: {
	skip( 'no IO::Socket::SSL::Utils', 8 ) if !eval { require IO::Socket::SSL::Utils; 1 };
	my $make = sub {
		my (%over) = @_;
		my ($cert) = IO::Socket::SSL::Utils::CERT_create(
			CA      => 1,
			subject => { commonName => 'www.example.org' },
			%over
		);
		return $cert;
	};
	my $cert    = $make->( not_after => time + 86400 * 20 + 60, subjectAltNames => [ [ DNS => 'www.example.org' ] ] );
	my $details = $base->cert_details($cert);
	is( $details->{subject},   'www.example.org', 'subject' );
	is( $details->{days_left}, 20,                'days left' );
	is_deeply( $details->{names}, ['DNS:www.example.org'], 'names' );
	my ( $code, $message ) = $base->cert_status( $details, 30, 14 );
	is( $code, 1, '20 days is WARNING' );
	like( $message, qr/\A"www.example.org" expires in 20 days, \d{4}-\d\d-\d\d \d\d:\d\d:\d\d UTC\z/, 'message' );
	is( ( $base->cert_status( $details, 10, 5 ) )[0], 0, 'OK' );
	is(
		( $base->cert_status( $base->cert_details( $make->( not_after => time - 10 ) ), 30, 14 ) )[1] =~ /expired/
		? 1
		: 0,
		1, 'expired'
	);
	is(
		(
			$base->cert_status(
				$base->cert_details( $make->( not_before => time + 3600, not_after => time + 86400 * 90 ) ),
				30, 14
			)
		)[0],
		2,
		'not good yet is CRITICAL'
	);
} ## end SKIP:

done_testing();
