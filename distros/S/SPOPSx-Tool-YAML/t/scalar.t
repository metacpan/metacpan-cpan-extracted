# vim: set ft=perl :

use strict;
use lib qw( t/ );
use Test::More tests => 7;
use Log::Log4perl ':easy';

Log::Log4perl->easy_init({ level => $WARN, file => "> spops_tests.log" });

require_ok( 'SPOPS::Initialize' );

my %config = (
	test => {
		class       => 'ScalarTest',
		isa         => [ 'SPOPS::Loopback' ],
		rules_from  => [ 'SPOPSx::Tool::YAML' ],
		field       => [ qw( myid yaml_field ) ],
		id_field    => 'myid',
		yaml_fields => [ qw( yaml_field ) ],
	},
);

my $init_list_yaml = eval { SPOPS::Initialize->process({ config => \%config }) };
ok( ! $@, "Initialize process run $@" );
is( $init_list_yaml->[0], 'ScalarTest',
    'SPOPSx::Tool::YAML scalar class initialized' );

my $item_yaml = ScalarTest->new({ myid       => 88,
								  yaml_field => 'foo' });
eval { $item_yaml->save };
ok( ! $@, 'Object with YAML scalar field saved' );
is( $item_yaml->{yaml_field}, 'foo' );
is( ScalarTest->peek( 88, 'yaml_field' ), "--- foo\n",
	'Scalar YAML field value saved' );

my $new_item_yaml = ScalarTest->fetch( 88 );
is( $new_item_yaml->{yaml_field}, 'foo',
	'YAML field fetched as scalar' );
