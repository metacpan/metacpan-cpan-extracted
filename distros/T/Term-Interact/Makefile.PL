use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'      => 'Term::Interact',
    'VERSION_FROM'  => 'Interact.pm', # finds $VERSION
    'PREREQ_PM'     => {
                         Text::Autoformat => '0.00',
                         Term::ReadKey    => '0.00',
                         Date::Manip      => '0.00',
                         File::Spec       => '0.00',
                       },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Interact.pm', # retrieve abstract from module
       AUTHOR     => 'Phil R Lawrence') : ()),
);
