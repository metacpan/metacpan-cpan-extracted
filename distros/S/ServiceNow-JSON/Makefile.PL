use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'ServiceNow::JSON',
    VERSION_FROM      => 'lib/ServiceNow/JSON.pm', # finds $VERSION
    PREREQ_PM         => { 
                            Moose => 0.01,
                            'REST::Client' => 0.01,
                            'MIME::Base64' => 0.01,
                            'JSON' => 0.01 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/ServiceNow/JSON.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin L. Kane <kkane@cpan.org>') : ()),
);
