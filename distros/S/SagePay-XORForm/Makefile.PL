use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SagePay::XORForm',
    VERSION_FROM      => 'lib/SagePay/XORForm.pm', # finds $VERSION
    PREREQ_PM         => {'MIME::Base64'        => 0,}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SagePay/XORForm.pm', # retrieve abstract from module
       AUTHOR         => 'Cris Pini <cris@perlconsulting.co.uk>') : ()),
);
