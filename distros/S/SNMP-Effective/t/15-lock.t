use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective;
use Fcntl qw(:flock);

plan tests => 6;
$SIG{'ALRM'} = sub { die "TIMEOUT!" };
my $effective = SNMP::Effective->new;

eval {
    alarm 1;
    is($effective->{'_lock_fh'}, undef, 'lock is not initialized');
    is(ref $effective->_init_lock, 'ARRAY', 'lock is initialized');
    is($effective->_wait_for_lock, 1, 'got lock');
    ok($effective->_wait_for_lock, 'this test should be ok!');
};

alarm 0;
like($@, qr{TIMEOUT!}, 'lock is taken');

eval {
    alarm 1;
    is($effective->_unlock, 1, 'unlock');
    is($effective->_wait_for_lock, 1, 'got lock again');
};

