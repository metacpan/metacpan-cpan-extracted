use Siebel::COM::App::DataControl;
use Test::Most;
use Cwd;
use File::Spec;

eval "use TryCatch";
plan skip_all => 'TryCatch is required to run this test'
  if $@;

eval "use Config::Tiny";
plan skip_all => 'Config::Tiny is required to run this test'
  if $@;

plan tests => 31;

my $cfg_file = File::Spec->catfile('t', 'data_control.ini');

SKIP: {

    skip 'developer tests that requires a Siebel Enterprise configured', 31
      unless ( -e $cfg_file );

    my $cfg = Config::Tiny->read($cfg_file);

    my $app = Siebel::COM::App::DataControl->new(
        {
            user       => $cfg->{Connection}->{user},
            password   => $cfg->{Connection}->{password},
            host       => $cfg->{Connection}->{host},
            enterprise => $cfg->{Connection}->{enterprise},
            lang       => $cfg->{Connection}->{lang},
            aom        => $cfg->{Connection}->{aom}
        }
    );

    isa_ok( $app, 'Siebel::COM::App::DataControl' );

    try {

        is( $app->login(), 1, 'it is possible to connect to Siebel' );

        my $bo = $app->get_bus_object('Employee');

        ok( $bo, 'get_bus_object method works' );
        isa_ok( $bo, 'Siebel::COM::Business::Object' );

        my $bc = $bo->get_bus_comp('Employee');

        ok( $bc, 'get_bus_comp method works' );
        isa_ok( $bc, 'Siebel::COM::Business::Component' );

        foreach my $field (
            'First Name',
            'Last Name',
            'City',
            'Alias',
            'Nick Name',
            'Login Name'
          )
        {

            ok( $bc->activate_field($field),
                "activate_field method works for $field" );

        }

        ok( $bc->clear_query(),   'clear_query method works' );
        ok( $bc->set_view_mode(), 'set_view_mode method works' );

        ok( $bc->set_search_spec( 'Login Name', "='SADMIN'" ),
            'set_search_spec method works' );
        ok( $bc->query(), 'query method works' );

        my $ret = $bc->first_record();
        is( $ret, 1, 'first_record returns true' );

      SKIP: {

            skip 'Cannot read/write data to/from without finding SADMIN login', 7
              unless $ret;

            is( $bc->get_field_value('First Name'),
                'Siebel', 'first name of SADMIN' );
            is( $bc->get_field_value('Last Name'),
                'Administrator', 'last name of SADMIN' );
            is( $bc->get_field_value('City'), '', 'city of SADMIN' );

            ok(
                $bc->set_field_value( 'Alias', 'root' ),
                'set_field_value works for Alias field'
            );
            ok(
                $bc->set_field_value( 'Nick Name', 'BOFH' ),
                'set_field_value works for Alias field'
            );

            ok( $bc->write_record(), 'it is possible to write records' );

            is( $bc->get_field_value('Alias'),
                'root', 'get_field_value returns "root"' );
            is( $bc->get_field_value('Nick Name'),
                'BOFH', 'get_field_value returns "BOFH"' );

            ok(
                $bc->set_field_value( 'Alias', '' ),
                'set_field_value cleans up Alias field'
            );
            ok(
                $bc->set_field_value( 'Nick Name', '' ),
                'set_field_value cleans up Nick Name field'
            );

            ok( $bc->write_record(), 'second write_record works' );

            dies_ok { $bc->get_field_value('R2D2') }
            'R2D2 field does not exists in a vanilla Siebel Repository';

            is( $bc->next_record(), 0,
                'next_record returns false because SADMIN is a highlander' );

            $bc->get_field_value('R2D2');    #forcing an exception

        }

    }
    catch {

        like( $app->get_last_error(),
            qr/SBL-EXL-00119/, 'got an error for using an inactive field' );

    }

}
