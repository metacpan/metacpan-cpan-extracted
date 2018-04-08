use lib 't'; use share; guard my $guard;
use Narada::Config qw( set_config );


plan skip_all => 'runit not installed'      if !grep {-x "$_/runsv"} split /:/, $ENV{PATH};
plan skip_all => 'socklog not installed'    if !grep {-x "$_/socklog"} split /:/, $ENV{PATH};


our $LOGSOCK;
my $logfile = path('var/log/current');


is system('narada-shutdown-services'), 0, 'no services';

is system('narada-install 0.2.0 >/dev/null 2>&1'), 0, 'narada-install 0.2.0';
ok !$logfile->exists, 'service not running';

system('narada-start-services &');
sleep 2;
ok $logfile->exists, 'service running';
eval 'use Narada::Log qw( $LOGSOCK )';

lives_ok { $LOGSOCK->INFO('msg1') } 'service available';

is system('narada-shutdown-services'), 0, 'shutdown services';
throws_ok { $LOGSOCK->INFO('msg2') } qr/connect/, 'service not available';

is system('narada-shutdown-services'), 0, 'no services running';

set_config('service/type', 'nosuch');
isnt system('narada-shutdown-services 2>/dev/null'), 0, 'unknown service type';

set_config('service/type', q{});
is system('narada-shutdown-services'), 0, 'no service type';


done_testing();
