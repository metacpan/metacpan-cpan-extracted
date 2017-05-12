use inc::Module::Install;

name 'Net-Telnet-Gearman';
all_from 'lib/Net/Telnet/Gearman.pm';

requires(
    'Net::Telnet'     => '3.03',
    'Class::Accessor' => '0.34',
    'Scalar::Util'    => undef,
);

test_requires 'Test::More';

perl_version '5.006001';

my @tests = ( 't/*.t' );

if ( -e 'MANIFEST.SKIP' ) {
    system('pod2text lib/Net/Telnet/Gearman.pm > README');
    unshift @tests, 'xt/*.t';
}

tests join ' ', @tests;

auto_install;
WriteAll;
