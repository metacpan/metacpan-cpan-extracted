# vim: set ft=perl :

use strict;
use lib qw( t/ );
use Test::More tests => 7;
use Log::Log4perl ':easy';

Log::Log4perl->easy_init({ level => $WARN, file => "> spops_tests.log" });

require_ok( 'SPOPS::Initialize' );

my %config = (
	test => {
		class       => 'HashTest',
		isa         => [ 'SPOPS::Loopback' ],
		rules_from  => [ 'SPOPSx::Tool::YAML' ],
		field       => [ qw( myid yaml_field ) ],
		id_field    => 'myid',
		yaml_fields => [ qw( yaml_field ) ],
	},
);

my $init_list_yaml = eval { SPOPS::Initialize->process({ config => \%config }) };
ok( ! $@, "Initialize process run $@" );
is( $init_list_yaml->[0], 'HashTest',
    'SPOPSx::Tool::YAML hash class initialized' );

my $item_yaml = HashTest->new({ myid       => 22,
                                yaml_field => { foo=>1, bar=>2, baz=>3, quux=>4 } });
eval { $item_yaml->save };
ok( ! $@, 'Object with YAML hash field saved' );
is_deeply( $item_yaml->{yaml_field}, { foo=>1, bar=>2, baz=>3, quux=>4 } );
is( HashTest->peek( 22, 'yaml_field' ), "---\nbar: 2\nbaz: 3\nfoo: 1\nquux: 4\n",
	'Hash YAML field value saved' );

my $new_item_yaml = HashTest->fetch( 22 );
is_deeply( $new_item_yaml->{yaml_field}, { foo=>1, bar=>2, baz=>3, quux=>4 },
	'YAML field fetched as hash' );
