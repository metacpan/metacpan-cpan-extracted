use 5.030000;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'Netkit',
    VERSION_FROM      => 'lib/Netkit.pm',
    PREREQ_PM         => {
    	'strict' => 0,
    	'warnings' => 0,
    	'List::Util' => 1.33,
    	'File::Copy::Recursive' => 0.01,
    },
    ABSTRACT_FROM     => 'lib/Netkit.pm', # retrieve abstract from module
    AUTHOR            => 'Rhys Adams <rhys@therhys.co.uk>',
    LICENSE           => 'perl',
);
