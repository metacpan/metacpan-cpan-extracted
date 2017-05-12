use strict;
use warnings;

use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }

use Config;

BEGIN {eval "require Errno;"; };

use Test::More tests => 5;

my %copy = %Config::Config;
untie(%Config::Config);
$copy{version} = '5.8.7';
$copy{archname} = 'my_arch';
tie %Config::Config => 'Config', \%copy;

use_ok('PAR::Repository::Client');

my @tests = (
    'Math::Symbolic' => {
        'Math-Symbolic-0.502-my_arch-5.8.6.par' => '0.502',
        'Math-Symbolic-0.500-my_arch-5.8.7.par' => '0.500',
        'Math-Symbolic-0.501-my_arch-5.8.7.par' => '0.501',
        'Math-Symbolic-0.501-any_arch-5.8.7.par' => '0.501',
    },
    'Math-Symbolic-0.501-my_arch-5.8.7.par',

    'Math::Symbolic' => {
        'Math-Symbolic-0.502-any_arch-5.8.7.par' => '0.502',
        'Math-Symbolic-0.502-any_arch-any_version.par' => '0.502',
        'Math-Symbolic-0.500-my_arch-5.8.7.par' => '0.500',
        'Math-Symbolic-0.501-my_arch-5.8.7.par' => '0.501',
        'Math-Symbolic-0.501-any_arch-5.8.7.par' => '0.501',
    },
    'Math-Symbolic-0.502-any_arch-5.8.7.par',
);

my $obj = bless {
  perl_version => $Config::Config{version},
  architecture => $Config::Config{archname},
} => 'PAR::Repository::Client';

my @tests_copy = @tests;
while (@tests_copy) {
    my $ns = shift @tests_copy;
    my $h  = shift @tests_copy;
    my $expect = shift @tests_copy;
    my $res = $obj->prefered_distribution($ns, $h);
    is($res, $expect);
}

$copy{version} = '5.8.9';
$copy{archname} = 'unknown_arch';
$obj->architecture('my_arch');
$obj->perl_version('5.8.7');

while (@tests) {
    my $ns = shift @tests;
    my $h  = shift @tests;
    my $expect = shift @tests;
    my $res = $obj->prefered_distribution($ns, $h);
    is($res, $expect);
}

