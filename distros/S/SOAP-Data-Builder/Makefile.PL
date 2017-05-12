use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SOAP::Data::Builder',
    VERSION_FROM      => 'lib/SOAP/Data/Builder.pm', # finds $VERSION
    PREREQ_PM         => { SOAP::Lite => 0.65 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (AUTHOR         => 'aaron trevena <teejay@droogs.org>') : ()),
);
