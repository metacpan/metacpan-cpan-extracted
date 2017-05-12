use Test::Most;

BEGIN {
    unless ($ENV{SSH_SERVER} )
    {
        plan skip_all => 'This requires access an SSH server to test. Set SSH_SERVER=servername if you have the necessary setup.';
    }
}

use Server::Module::Comparison;

ok my $comparer = Server::Module::Comparison->new({ 
        perl_path => '/opt/perl5/bin',
        modules => [qw/OpusVL::CMS OpusVL::FB11X::CMSView OpusVL::FB11X::CMS/] 
    });
ok my $versions = $comparer->check_ssh_server($ENV{SSH_SERVER});
explain $versions;

done_testing;

