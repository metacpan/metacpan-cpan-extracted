use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Plucene::SearchEngine::Index::Image',
    VERSION_FROM      => 'lib/Plucene/SearchEngine/Index/Image.pm', # finds $VERSION
    PREREQ_PM         => {
        Plucene::SearchEngine::Index => 0,
        Image::Info => 0
    }, # e.g., Module::Name => 1.1
);
