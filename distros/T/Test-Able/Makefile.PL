use inc::Module::Install;

all_from 'lib/Test/Able.pm';

requires 'Moose' => '0.94';

recursive_author_tests( 'xt' );

WriteAll;
