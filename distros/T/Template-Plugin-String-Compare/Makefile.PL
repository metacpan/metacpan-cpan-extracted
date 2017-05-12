use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Template::Plugin::String::Compare',
    VERSION_FROM      => 'lib/Template/Plugin/String/Compare.pm',
    PREREQ_PM         => {
        'Template'                 => 0,
        'Template::Plugin::String' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Template/Plugin/String/Compare.pm',
       AUTHOR         => 'Satoshi Tanimoto <tanimoto@cpan.org>') : ()),
);
