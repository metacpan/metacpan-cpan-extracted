package Test::Siebel::Srvrmgr::ListParser::OutputFactory;

use Test::Most;
use parent 'Test::Siebel::Srvrmgr';

sub static_methods : Tests(16) {

    my $test  = shift;
    my $class = $test->class;

    can_ok( $class, qw(create can_create get_mapping) );

    dies_ok {
        my $output =
          $class->create( 'foobar',
            { data_type => 'foobar', raw_data => [], cmd_line => '' } );
    }
    'the create method fail with an invalid class';

    foreach my $type (
        qw(list_servers list_comp list_params list_comp_def greetings list_comp_types load_preferences)
      )
    {

        ok( $class->can_create($type), "$type is a valid type" );

    }

    my $table;

    ok( $table = $class->get_mapping(), 'get_mapping returns something' );

    is( ref($table), 'HASH', 'get_mapping returns an hash ref' );

    my $total_maps = scalar( keys( %{ $class->get_mapping() } ) );

    ok( delete( $table->{list_comp} ),
        'it is ok to remove keys from the hash ref' );

    is(
        $total_maps,
        scalar( keys( %{ $class->get_mapping() } ) ),
        'original mapping stays untouched'
    );

    $table = $class->get_mapping();

    note(
'Validating that "list comps" does not matches other similar commands by mistake'
    );
    foreach my $cmd ( ( 'list comp types', 'list comp defs' ) ) {
        unlike( $cmd, $table->{list_comp}->[1], "list_comp cannot match $cmd" );
    }
    note('But matches components with wildcards');
    like(
        'list comp EAI%',
        $table->{list_comp}->[1],
        'list_comp matches "list comp EAI%'
    ) or diag(explain($table->{list_comp}));

}

1;
