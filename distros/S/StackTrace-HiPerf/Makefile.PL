use inc::Module::Install;

all_from 'lib/StackTrace/HiPerf.pm';

perl_version '5.008';

recursive_author_tests( 'xt' );

requires 'XSLoader';

WriteAll;
