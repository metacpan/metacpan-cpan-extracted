package Test::Siebel::Srvrmgr::Daemon::ActionFactory;

use Test::Most;
use Siebel::Srvrmgr::ListParser;
use base 'Test::Siebel::Srvrmgr';

sub my_interface : Test(+1) {

    my $test = shift;

    can_ok( $test->class(), qw(create) );

}

sub create_instances : Tests(+9) {

    my $test = shift;

    my @available = (
        'Dummy',         'Dumper',     'ListCompDef',     'ListComps',
        'ListCompTypes', 'ListParams', 'LoadPreferences'
    );

    foreach my $class (@available) {

        my $full_name = 'Siebel::Srvrmgr::Daemon::Action::' . $class;

        isa_ok(
            $test->class()->create(
                $class,
                {
                    parser => Siebel::Srvrmgr::ListParser->new(),
                    params => ['somefile']
                }
            ),
            $full_name,
"create method returns an $full_name instance with the '$class' string as parameter"
        );

    }

    dies_ok( sub { $test->class()->create('CheckComps') },
        'expected to die since CheckComps required additional parameters with Roles applied' );

    dies_ok(
        sub { $test->class()->create('FooBar') },
'create method raises an exception trying to instantiate an object from a invalid class'
    );

}

1;
