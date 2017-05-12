use Test::Most;

use Server::Module::Comparison;
ok my $comparer = Server::Module::Comparison->new({ 
        modules => []
    });
eq_or_diff [$comparer->identify_resource('server.mc.local')],   ['ssh', 'server.mc.local'];
eq_or_diff [$comparer->identify_resource('ssh://server.mc.local')],   ['ssh', 'server.mc.local'];
eq_or_diff [$comparer->identify_resource('quay.io/test')],   ['docker', 'quay.io/test'];
eq_or_diff [$comparer->identify_resource('docker://myimage:v3')],   ['docker', 'myimage:v3'];

done_testing;
