use Test::Most;

BEGIN {
    unless ($ENV{LIVE_TEST} )
    {
        plan skip_all => 'This checks the local machine.  Set LIVE_TEST=1 if you have /opt/perl5/bin/mversion installed.';
    }
}
use Server::Module::Comparison;

ok my $comparer = Server::Module::Comparison->new({ 
        perl_path => '/opt/perl5/bin',
        modules => [qw/OpusVL::CMS OpusVL::FB11X::CMSView OpusVL::FB11X::CMS/] 
    });
ok my $versions = $comparer->check_local;
explain $versions;

done_testing;


