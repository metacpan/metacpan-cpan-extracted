# vim: set ft=perl :

use strict;
use lib qw( t/ );
use Test::More tests => 7;
use Log::Log4perl ':easy';

Log::Log4perl->easy_init({ level => $WARN, file => "> spops_tests.log" });

require_ok( 'SPOPS::Initialize' );

my %config = (
	test => {
		class       => 'ArrayTest',
		isa         => [ 'SPOPS::Loopback' ],
		rules_from  => [ 'SPOPSx::Tool::YAML' ],
		field       => [ qw( myid yaml_field ) ],
		id_field    => 'myid',
		yaml_fields => [ qw( yaml_field ) ],
	},
);

my $init_list_yaml = eval { SPOPS::Initialize->process({ config => \%config }) };
ok( ! $@, "Initialize process run $@" );
is( $init_list_yaml->[0], 'ArrayTest',
    'SPOPSx::Tool::YAML array class initialized' );

my $item_yaml = ArrayTest->new({ myid       => 44,
								  yaml_field => [ qw( foo bar baz quux ) ] });
eval { $item_yaml->save };
ok( ! $@, 'Object with YAML array field saved' );
is_deeply( $item_yaml->{yaml_field}, [ qw( foo bar baz quux ) ] );
is( ArrayTest->peek( 44, 'yaml_field' ), "---\n- foo\n- bar\n- baz\n- quux\n",
	'Array YAML field value saved' );

my $new_item_yaml = ArrayTest->fetch( 44 );
is_deeply( $new_item_yaml->{yaml_field}, [ qw( foo bar baz quux ) ],
	'YAML field fetched as array' );
