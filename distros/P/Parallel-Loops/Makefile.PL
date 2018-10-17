use inc::Module::Install;

name           'Parallel-Loops';
repository     'https://github.com/pmorch/perl-Parallel-Loops';
all_from       'lib/Parallel/Loops.pm';

requires       'Parallel::ForkManager' => '1.15';
test_requires  'Test::More' => '0.84';

WriteAll;
