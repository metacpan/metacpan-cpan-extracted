use Test::More;

use Proc::PidFile::Info;

my $pfinfo;

my %service_info = (
    service => 123,
    bar => 456,
    foo => 789,
    whitespace => 144,
);

$info = new_ok("Proc::PidFile::Info", [ autoscan => 0 ]);
is_deeply( scalar $info->locations,  [ '/var/run' ], 'default location');
is($info->info_level, 0, 'default info level');
is_deeply(scalar $info->pidfiles, [], 'no automatic scan');

$info = new_ok("Proc::PidFile::Info", [locations => ['t/run', 't/service.pid'], info_level => 1 ]);
is_deeply(scalar $info->locations, ['t/run', 't/service.pid'], 'custom location');
is($info->info_level, 1, 'custom info level');

check_pids( $info->pidfiles() );

system( "echo 42 >> t/run/baz.pid" );
$service_info{baz} = 42;
ok($info->scan(), 'rescan PID file directory');

check_pids( $info->pidfiles() );

unlink('t/run/baz.pid');

done_testing;

sub check_pids {
    my @services = @_;

    foreach my $svc (@services) {
        is($svc->{pid}, $service_info{$svc->{name}}, "$svc->{name} service PID");
    }
}
