use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Pod::WikiText',
    VERSION_FROM      => 'lib/Pod/WikiText.pm', # finds $VERSION
    PREREQ_PM         => { 'English' => 0,
                           'File::Spec' => 0,
                           'Text::Wrap' => 0,
                           'Text::Tiki' => 0,
                           'Syntax::Highlight::Engine::Kate' => 0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Pod/WikiText.pm', # retrieve abstract from module
       AUTHOR         => 'Brad Adkins <dbijcl@gmail.com>') : ()),
);
