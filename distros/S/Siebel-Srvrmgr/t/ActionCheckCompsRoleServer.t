use lib 't';
use Test::Siebel::Srvrmgr::Daemon::Action::Check::Server;
use Test::Siebel::Srvrmgr::Daemon::Action::Check::Component;
use Test::Most tests => 6;
use Test::Moose;

my $comp = Test::Siebel::Srvrmgr::Daemon::Action::Check::Component->new(
    {
        alias          => 'SynchMgr',
        description    => 'foobar',
        componentGroup => 'foobar',
        OKStatus       => 'Running',
        taskOKStatus   => 'Running',
        criticality    => 5
    }
);

my $server = Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
    { name => 'foo', components => [$comp] } );

does_ok( $server, 'Siebel::Srvrmgr::Daemon::Action::Check::Server' );

foreach (qw(name components)) {

    has_attribute_ok( $server, $_, "$server has the attribute $_" );

}

dies_ok(
    sub {
        my $other_server =
          Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new();
    },
    'constructor cannot accept missing attributes declaration'
);

dies_ok(
    sub {
        my $other_server =
          Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
            {
                name       => '',
                components => [$comp]
            }
          );
    },
    'constructor cannot accept string based attributes without value'
);

dies_ok(
    sub {
        my $other_server =
          Test::Siebel::Srvrmgr::Daemon::Action::Check::Server->new(
            {
                name       => 'foobar',
                components => ['an string']
            }
          );
    },
'constructor cannot accept anything but Component objects as items of an array reference'
);
