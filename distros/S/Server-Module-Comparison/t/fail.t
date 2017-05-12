use Test::Most;
use Server::Module::Comparison;

ok my $comparer = Server::Module::Comparison->new({ 
        perl_path => 'fail',
        modules => [] 
    });
throws_ok(sub { $comparer->check_local }, 'failure::module::comparison');

done_testing;

