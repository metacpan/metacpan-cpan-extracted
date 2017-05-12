use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::Server::Mail::ESMTP::AUTH',
    'VERSION_FROM'	=> 'AUTH.pm', # finds $VERSION
    'PREREQ_PM'		=> { Net::Server::Mail => 0.08,
                             MIME::Base64 => 0.0,
                             Net::Server::Mail::ESMTP => 0.0,  }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'AUTH.pm', # retrieve abstract from module
       AUTHOR     => 'Sylvain CRESTO <tost@softhome.net>') : ()),
);
