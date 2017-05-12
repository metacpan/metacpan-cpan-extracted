use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::HighlightPerl',
    VERSION_FROM      => 'lib/Template/Plugin/HighlightPerl.pm', # finds $VERSION
    PREREQ_PM         => {
    'Syntax::Highlight::Perl' => 1.00,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/HighlightPerl.pm', # retrieve abstract from module
       AUTHOR         => 'Stephen A Sykes <stephen@stephensykes.us>') : ()),
);
