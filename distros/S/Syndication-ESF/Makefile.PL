use inc::Module::Install 0.91;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Syndication/ESF.pm > README' );
}

perl_version '5.006';

name 'Syndication-ESF';
all_from 'lib/Syndication/ESF.pm';

test_requires 'Test::More';

repository "http://github.com/bricas/syndication-esf/tree/master";

WriteAll;
