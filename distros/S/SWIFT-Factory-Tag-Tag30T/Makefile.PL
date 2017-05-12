use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'SWIFT::Factory::Tag::Tag30T',
    'VERSION_FROM'	=> 'Tag30T.pm', # finds $VERSION
    'PREREQ_PM'		=> {
       'SWIFT::Factory::Tag::Tag30' => '0.01'
    },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Tag30T.pm', # retrieve abstract from module
       AUTHOR     => 'Gustav Schaffter, <schaffter_cpan@hotmail.com>') : ()),
);

