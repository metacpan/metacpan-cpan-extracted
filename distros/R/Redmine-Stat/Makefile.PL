use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Redmine::Stat',
    VERSION_FROM      => 'lib/Redmine/Stat.pm', # finds $VERSION
    PREREQ_PM         => {
        'LWP::UserAgent'	=> 0,
	'XML::LibXML'		=> 0,
	'IO::Socket::SSL'	=> 0,
	'Crypt::SSLeay'		=> 0,
	'File::Slurp'		=> 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Redmine/Stat.pm', # retrieve abstract from module
       AUTHOR         => 'Fedor A Borshev <fedor@shogo.ru>') : ()),
);
