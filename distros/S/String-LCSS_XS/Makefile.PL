use 5.006_001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'String::LCSS_XS',
    VERSION_FROM      => 'lib/String/LCSS_XS.pm', 
    MIN_PERL_VERSION  => '5.008000',  # Unicode support
    PREREQ_PM         => {
        'XSLoader'   => 0,
        'Exporter'   => 0,
        'Test::More' => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/String/LCSS_XS.pm', # retrieve abstract from module
       AUTHOR         => 'Markus Riester <limaone@cpan.org>') : ()),
    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
            ('LICENSE'  => 'perl')         : ()),
    LIBS              => [''], 
    DEFINE            => '-I ../..', 
    INC               => '-I.', 
    #CCFLAGS            => ' -lgcov -static-libgcc -fprofile-arcs -ftest-coverage',
    OBJECT            => '$(O_FILES)', 
    clean             =>  { FILES => 'String-LCSS_XS-*' },
    #dynamic_lib      => { OTHERLDFLAGS => ' -lgcov'},
);

1;

package MY;

sub postamble
{
    join "\n" =>
    'cover test_cover:',
    "\tcover -delete",
    "\tmake",
    "\t" .'HARNESS_PERL_SWITCHES=-MDevel::Cover $(MAKE) test',
    "\t" .'gcov LCSS_XS.c 2>/dev/null',
    "\t" .'gcov lcss.c 2>/dev/null',
    "\t" .'find * -name \*.gcov -exec gcov2perl {} \;',
    "\t" .'cover',
    '',
    '';
    } # postamble
