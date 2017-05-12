use Test::Most;

BEGIN {
    unless ($ENV{LDAP_TEST} )
    {
        plan skip_all => 'This is an interactive LDAP test.  Set LDAP_TEST if your environment is configured.'; 
    }
}

use FindBin;
use lib "$FindBin::Bin/lib";
use Term::ReadKey;
use Scope::Guard;
use OpusVL::AppKit::LDAPAuth;


diag('Enter username');
my $user = ReadLine(0);
chomp $user;
diag('Enter password');
my $password = get_password();

my $test = OpusVL::AppKit::LDAPAuth->new();
ok $test->check_password($user, $password);

done_testing;

sub get_password
{ 
    my $cleanup = Scope::Guard->new(sub { 
        ReadMode('restore');
    });
    ReadMode('noecho');
    my $pass = ReadLine(0);
    chomp $pass;
    print "\n";
    return $pass;
}
