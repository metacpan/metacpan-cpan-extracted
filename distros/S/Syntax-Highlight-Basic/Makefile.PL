use ExtUtils::MakeMaker;
use File::ShareDir::Install;
install_share 'share';

WriteMakefile(
    NAME             => 'Syntax::Highlight::Basic',
    VERSION_FROM     => 'lib/Syntax/Highlight/Basic.pm',
    ABSTRACT_FROM    => 'lib/Syntax/Highlight/Basic.pm',
    AUTHOR           => 'Sandor Patocs',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.016',
    EXE_FILES        => ['script/vim-syntax-to-shb', 'script/syntax-highlight-basic'],
    TEST_REQUIRES    => { 'Test::More' => '0' },
    PREREQ_PM        => { 'File::ShareDir' => '0', 'File::Find' => '0' },
);

package MY;
use File::ShareDir::Install qw(postamble);
