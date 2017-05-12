# vim: set ft=perl :

use strict;
use lib qw( t/ );
use Test::More tests => 7;
use Log::Log4perl ':easy';

SKIP: {
	eval "require DateTime::Format::Strptime";
	if ($@) {
		skip "DateTime::Format::Strptime not installed.", 7;
	}

	Log::Log4perl->easy_init({ level => $WARN, file => "> spops_tests.log" });

	require_ok( 'SPOPS::Initialize' );

	my $strptime = DateTime::Format::Strptime->new(pattern => '%D %T');
	my %config = (
		test => {
			class           => 'StrptimeTest',
			isa             => [ 'SPOPS::Loopback' ],
			rules_from      => [ 'SPOPSx::Tool::DateTime' ],
			field           => [ qw( myid datetime_field ) ],
			id_field        => 'myid',
			datetime_format => {
				datetime_field => $strptime,
			},
		},
	);

	my $init_list_dt = eval { SPOPS::Initialize->process({ config => \%config }) };
	ok( ! $@, "Initialize process run $@" );
	is( $init_list_dt->[0], 'StrptimeTest',
		'SPOPSx::Tool::DateTime strptime class initialized' );

	my $now = DateTime->now;
	my $item_dt = StrptimeTest->new({ myid           => 88,
                                      datetime_field => $now });
	eval { $item_dt->save };
	ok( ! $@, 'Object with DateTime strptime field saved' );
	isa_ok( $item_dt->{datetime_field}, 'DateTime' );
	is( StrptimeTest->peek( 88, 'datetime_field' ), $strptime->format_datetime($now),
		'DateTime strptime field value saved' );

	my $new_item_dt = StrptimeTest->fetch( 88 );
	isa_ok( $new_item_dt->{datetime_field}, 'DateTime',
		'YAML field fetched as scalar' );
}
