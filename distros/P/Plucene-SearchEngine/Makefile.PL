use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
NAME => "Plucene::SearchEngine", 
    VERSION_FROM      => 'lib/Plucene/SearchEngine/Index.pm', # finds $VERSION
    PREREQ_PM         => {
Date::Parse => 0,
File::Basename => 0,
File::MMagic => 0,
HTML::TreeBuilder => 0,
LWP => 0,
Lucene::QueryParser => 0,
Module::Pluggable => 0,
Plucene => 1.17,
Time::Piece => 0,
UNIVERSAL::moniker => 0,
UNIVERSAL::require => 0,
Text::Context =>0,
    }, # e.g., Module::Name => 1.1
    );
