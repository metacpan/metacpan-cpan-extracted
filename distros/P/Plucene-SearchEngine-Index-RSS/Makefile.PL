use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Plucene::SearchEngine::Index::RSS',
    VERSION_FROM      => 'lib/Plucene/SearchEngine/Index/RSS.pm', # finds $VERSION
    PREREQ_PM         => {
        Plucene::SearchEngine::Index => 1.1,
        XML::RSS => 0,
    }, # e.g., Module::Name => 1.1
);
