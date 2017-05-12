package Test::Siebel::Srvrmgr::Daemon::Action::CheckComps;

use parent qw(Test::Siebel::Srvrmgr::Daemon::Action);
use Test::Most;
use Siebel::Srvrmgr::ListParser;
use Siebel::Srvrmgr::Daemon::Action::CheckComps;
use Siebel::Srvrmgr::ListParser::Output::ListComp::Server;
use Test::Siebel::Srvrmgr::Daemon::Action::Check::Server;
use Test::Siebel::Srvrmgr::Daemon::Action::Check::Component;

sub set_action2 {
    my $test = shift;
    $test->{action2} = shift;
}

sub get_action2 {
    my $test = shift;
    return $test->{action2};
}

# must override parent method because CheckComps has different arguments for new
sub before : Test(setup) {
    my $test = shift;
    $ENV{SIEBEL_TZ} = 'America/Sao_Paulo';

    # applying roles as expected by Siebel::Srvrmgr::Daemon::Action::CheckComps
    my $comp1 = Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
        {
            alias          => 'SRBroker',
            description    => 'foobar',
            componentGroup => 'foobar',
            OKStatus       => 'Running',
            criticality    => 5,
            taskOKStatus   => 'Running'
        }
    );
    my $comp2 = Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
        {
            alias          => 'SRProc',
            description    => 'foobar',
            componentGroup => 'foobar',
            OKStatus       => 'Running',
            criticality    => 5,
            taskOKStatus   => 'Running'
        }
    );

    $test->SUPER::before(
        [
            Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
                { name => 'siebel1', components => [ $comp1, $comp2 ] }
            )
        ]
    );

    $test->set_action2(
        $test->class()->new(
            {
                parser => $test->{parser},
                params => [
                    Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
                        { name => 'foobar', components => [ $comp1, $comp2 ] }
                    )
                ]
            }
        )
    );

}

sub clean_up : Test(shutdown) {
    delete $ENV{SIEBEL_TZ};
}

sub constructor : Tests(+2) {
    my $test = shift;
    ok( $test->{action2}, 'the other constructor should succeed' );
    isa_ok( $test->get_action2(), $test->class() );
}

sub class_methods : Tests(+2) {
    my $test = shift;
    note($ENV{SIEBEL_TZ});
    $test->SUPER::class_methods();
    my $stash = Siebel::Srvrmgr::Daemon::ActionStash->instance();

    # data expected to be returned from the stash
    is_deeply(
        $stash->shift_stash(),
        {
            'siebel1' => {
                'SRBroker' => 1,
                'SRProc'   => 1
            }
        },
        'data returned by the stash is the expected one'
    );

    dies_ok(
        sub { $test->get_action2->do( $test->get_my_data() ) },
        'do method must die because the expected server will not be available'
    );

}

1;

