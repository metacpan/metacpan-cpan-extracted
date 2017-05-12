use common::sense;

use Test::More;

use Tapper::Base;
use Tapper::SimNow;
use Test::MockModule;

my $version_string =
'This is AMD SimNow version 4.6.1, an x86 and AMD64 instruction-level platform simulator, supporting version 16384 of the AMD SimNow Device Interface.
AMD SimNow is proprietary AMD software.  For terms of usage, please refer to the license that was shipped with this software.
This internal release is built from revision: 17050 of SVN URL: svn+ssh://svdcsvn1/proj/svn/smn/simnow/trunk
';

my $mock =Test::MockModule->new('Tapper::Base');
$mock->mock('run_one', sub { return 0 });
$mock->mock('log_and_exec', sub { return (0, $version_string) });



my $sim = Tapper::SimNow->new({cfg => {test_run => 1337, hostname => 'localhost'}});
my $retval = $sim->generate_meta_report();
is(ref $retval, 'HASH', 'Metareport is a hash');
{
        no strict;
        is($retval->{headers}->{'Tapper-SimNow-Version'}, '4.6.1', 'SimNow version');
        is($retval->{headers}->{'Tapper-SimNow-SVN-Repository'}, 'svn+ssh://svdcsvn1/proj/svn/smn/simnow/trunk', 'SVN repository');
        is($retval->{headers}->{'Tapper-SimNow-SVN-Version'}, '17050', 'SVN revision');
        is($retval->{headers}->{'Tapper-SimNow-Device-Interface-Version'}, '16384', 'Device interface version');
}

done_testing();

__END__

# prepare for complete test

my $tap_report;
my $mock_net =Test::MockModule->new('Tapper::Remote::Net');
$mock_net->mock('tap_report_away', sub { (undef, $tap_report) = @_; return (0,10) });

my $config = { };
my $mock_conf =Test::MockModule->new('Tapper::Remote::Config');
$mock_conf->mock('get_local_data', sub { return $config });

$retval = $sim->run();
is($retval, 0, 'Running SimNow');
