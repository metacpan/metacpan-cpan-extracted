use Test::More 0.98;

use_ok( 'Net::MAC::Vendor' );

my @Good = (
	[ qw( 00:0d:93:84:49:ee 00-0D-93 ) ],
	[ qw( 00:0d:93:29:f6:c2 00-0D-93 ) ],
	[ qw( 00-0d-93-84-49-ee 00-0D-93 ) ],
	[ qw( 00-0d-93          00-0D-93 ) ],
	[ qw( :d:93             00-0D-93 ) ],
	[ qw( 00:d:9            00-0D-09 ) ],
	);

foreach my $elem ( @Good ) {
	my $normalized = Net::MAC::Vendor::normalize_mac( $elem->[0] );
	is( $normalized, $elem->[1], "MAC $$elem[0] is $$elem[1]" );
	}

SKIP: {
    skip 'NetAddr::MAC required for this test' if not eval { +require NetAddr::MAC };
    is( '00-16-3E-01-01-01', Net::MAC::Vendor::normalize_mac( NetAddr::MAC->new('00:16:3e:01:01:01') ),
        'NetAddr::MAC objects work ok as argument to normalize_mac()');
}

{
no warnings 'uninitialized';

local *STDERR;
open STDERR, ">", \my $warnings;

foreach my $elem ( undef, '', 0, -1, "Foo" ) {
	my $rc = Net::MAC::Vendor::normalize_mac( $elem );
	is( $rc, undef, "Bad MAC [$elem] returns undef" );
	}
}

done_testing();
