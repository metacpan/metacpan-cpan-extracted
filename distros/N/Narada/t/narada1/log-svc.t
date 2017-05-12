use t::narada1::share; guard my $guard;


plan skip_all => 'runit not installed'      if !grep {-x "$_/runsv"} split /:/, $ENV{PATH};
plan skip_all => 'socklog not installed'    if !grep {-x "$_/socklog"} split /:/, $ENV{PATH};


ok !-e 'var/log/current', 'log file not exists';
system('runsv ./service/log/ >/dev/null 2>&1 & sleep 1');
ok -e 'var/log/current', 'log file exists';
our $LOGSOCK;
eval 'use Narada::Log qw( $LOGSOCK )';

ok ref $LOGSOCK, 'log object imported';

$LOGSOCK->level('INFO');
$LOGSOCK->DEBUG('debug');
$LOGSOCK->INFO('info');
ok 256 == system('grep debug var/log/current >/dev/null 2>&1'), 'log file not contain "debug"';
ok 0   == system('grep info  var/log/current >/dev/null 2>&1'), 'log file contain "info"';

system('sv force-stop ./service/log/ &>/dev/null');


done_testing();
