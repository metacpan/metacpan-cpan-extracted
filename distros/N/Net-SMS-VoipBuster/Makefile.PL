use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::SMS::VoipBuster',
    VERSION_FROM      => 'lib/Net/SMS/VoipBuster.pm', # finds $VERSION
    PREREQ_PM         => { LWP::UserAgent => 0, XML::XPath => 1.13 , XML::XPath::XMLParser => 0 , Carp => 0, XML::Parser => 0 , Crypt::SSLeay => 0, IO::Socket::SSL =>0 }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/SMS/VoipBuster.pm', # retrieve abstract from module
       AUTHOR         => 'Filipe Dutra <mopy@cpan.org>') : ()),
);
