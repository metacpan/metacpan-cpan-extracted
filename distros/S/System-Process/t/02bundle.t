use strict;
use warnings;
use System::Process qw/:test/;

use Test::More tests => 1;

my $worker_process_name = 'blahblahblah';
my $processes_count = 3;


my $bundle = System::Process::pidinfo pattern => $worker_process_name;

my $i = 0;

for my $object (@$bundle) {
    if ($object->command() eq $worker_process_name) {
        $i++;
    }
}

ok $i eq $processes_count, 'Bundled processes';

done_testing();
