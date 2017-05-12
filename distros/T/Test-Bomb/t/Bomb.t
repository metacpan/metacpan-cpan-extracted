
use Test::Tester;
use Test::More;

# required to config file testing
BEGIN {
    $Test::Bomb::cf = '/tmp/testTimeBomb';
    $ENV{TESTBOMBCONFIG} = $Test::Bomb::cf;
    use_ok 'Test::Bomb';
}

my $configFile = $Test::Bomb::cf;

my $earlyTime = localtime( time - 5000 );
my $lateTime = localtime(time + 5000 );

=head NOTE

any flag in the 'releasing' function needs to be undone here
otherwise all the tests will fail.

=cut

delete $ENV{DZIL_RELEASING};

=head test checkDate function

=cut

check_test(
    sub { Test::Bomb::checkDate($earlyTime) },
     { depth => 0, ok => 0, name => 'deadline passed', diag => '' },
     'test expired',
);

check_test(
    sub { Test::Bomb::checkDate($lateTime) },
     { depth => 0, ok => 1, name => 'bomb after ' . $lateTime, diag => '' },
     'test waiting',
);

=head test valid with failure

=cut

check_test(
    sub { bomb -after => $earlyTime },
     { ok => 0, name => 'deadline passed', diag => '' },
     'valid w/ fail',
);

=head test valid with success

=cut

check_test(
    sub { bomb -after => $lateTime },
    { ok => 1, name => 'bomb after ' . $lateTime, diag => '' },
    'valid w/ success',
);

=head test invalid parameter

=cut

check_test(
    sub { bomb -bob => $lateTime },
    { ok => 0, name => 'invalid parameter: \'-bob\'', diag => '' },
    'invalid param',
);

=head test invalid date

=cut

check_test(
    sub { bomb -after => 'bob' },
    { ok => 0, name => 'invalid date: \'bob\'', diag => '' },
    'invalid date',
);

=head1 test config file

=over

=item test config file missing

use env var to identify config file ( set above, before module is 'used' )

=cut

check_test(
    sub { Test::Bomb::readConfig('bob') eq 'configFail' },
    { depth => 0, ok => 0, name => 'failed to open config file', diag => '' },
    'readConfig: config file missing',
);

check_test(
    sub { bomb -with => 'bob' },
    { ok => 0, name => 'failed to open config file', diag => '' },
    'config file missing',
);

=item test config file exists; group missing

=cut

open CF, '>', $configFile
     or ok 0, 'failed to open config file for writing '.$configFile;
print CF 'nothing much here';
close CF;

check_test(
    sub { bomb -with => 'bob' },
    { ok => 0, name => 'bomb group is not defined: bob', diag => '' },
    'bomb group missing',
);

=item test config file exists; group exists; bomb waiting

=cut

open CF, '>', $configFile
     or ok 0, 'failed to open config file for writing '.$configFile;
print CF " a comment \n   bob  =  '$lateTime'\n";
close CF;

check_test(
    sub { bomb -with => 'bob' },
    { ok => 1, name => 'bomb after ' . $lateTime, diag => '' },
    'bomb group waiting',
);

=item test config file exists; group exists; bomb expired

=cut

open CF, '>', $configFile
     or ok 0, 'failed to open config file for writing '.$configFile;
print CF " a comment \n   bob  =  '$earlyTime'\n";
close CF;

check_test(
    sub { bomb -with => 'bob' },
     { ok => 0, name => 'deadline passed', diag => '' },
    'bomb group expired',
);

=item test config hash; bomb waiting

=cut

unlink $ENV{TESTBOMBCONFIG};
$Test::Bomb::groups{tom} = $lateTime;

check_test(
    sub { bomb -with => 'tom' },
    { ok => 1, name => 'bomb after ' . $lateTime, diag => '' },
    'hash:bomb group waiting',
);

=item test config hash; bomb expired

=cut

$Test::Bomb::groups{tom} = $earlyTime;

check_test(
    sub { bomb -with => 'tom' },
     { ok => 0, name => 'deadline passed', diag => '' },
    'hash:bomb group expired',
);

=back

=head1 test for release failure flag

=cut

ok ! Test::Bomb::releasing(), 'releasing() returns false';

$ENV{DZIL_RELEASING} = 1;

ok Test::Bomb::releasing(), 'releasing() returns true';

check_test(
    sub { bomb -with => 'tom' },
     { ok => 0, name => 'Don\'t send me out there! I can\'t take the preasure!',
                diag => '' },
    'distribution flag set',
);

done_testing;

