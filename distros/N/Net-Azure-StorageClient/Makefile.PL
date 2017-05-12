use 5.008009;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::Azure::StorageClient',
    VERSION_FROM      => 'lib/Net/Azure/StorageClient.pm', # finds $VERSION
    PREREQ_PM         => { 'LWP::UserAgent' => 0,
                           'HTTP::Date' => 0,
                           'URI::QueryParam' => 0,
                           'Digest::SHA' => 0,
                           'Test::More' => 0,
                           'XML::Simple' => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/Azure/StorageClient.pm', # retrieve abstract from module
       AUTHOR         => 'Junnama Noda <junnama@alfasado.jp>') : ()),
);
