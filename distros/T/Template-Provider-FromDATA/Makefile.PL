use inc::Module::Install 1.05;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Template/Provider/FromDATA.pm > README' );
}

perl_version '5.008';

name 'Template-Provider-FromDATA';
all_from 'lib/Template/Provider/FromDATA.pm';

requires 'Template' => '2.15';
requires 'Class::Accessor';

test_requires 'Test::More';
extra_tests;

repository "http://github.com/bricas/template-provider-fromdata";

WriteAll;
