use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Net::LPR',
    'VERSION_FROM'	=> 'LPR.pm',
    'PREREQ_PM'		=> { IO::Socket::INET => 1, IO::Socket => 1, Socket => 1, Carp => 0, Sys::Hostname => 1 },
    ($] >= 5.005 ?
      (ABSTRACT   => 'Module for connecting to an RFC1179 line printer daemon',
       AUTHOR     => 'David M. Lloyd <dmlloyd@cpan.org>') : ()),
);
