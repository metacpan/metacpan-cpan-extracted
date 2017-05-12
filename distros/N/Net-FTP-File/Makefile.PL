use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::FTP::File',
    VERSION_FROM      => 'File.pm', 
    PREREQ_PM         => {
        Net::FTP => 0
    },
    ($] >= 5.005 ? 
      (ABSTRACT_FROM  => 'File.pm',
       AUTHOR         => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>') : ()),
);
