use strict;
use warnings;
use Test::More tests => 3;
BEGIN { use_ok('Net::Z3950::FOLIO') };

my $pid = fork();
exit 'Uh-oh! $!' if $pid < 0;

if ($pid == 0) {
    # Child
    sleep 1; # Allow time for server to start up
    exec 'zoomsh -e "open @:9996/dummy" "find water" "set preferredRecordSyntax usmarc" "show 1" quit';
}

$ENV{OKAPI_PASSWORD} = 'fameflowerID052020';
my $service = new Net::Z3950::FOLIO('etc/config');
ok(defined $service, 'created service');
$service->launch_server('z2folio', '-1', '@:9996');
ok(1, 'served a session');
