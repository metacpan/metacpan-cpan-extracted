use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'Net::Starnet::DataAccounting',
    VERSION_FROM	=> 'lib/Net/Starnet/DataAccounting.pm',
    PREREQ_PM => {
		'Carp' => 0,
		'Pod::Coverage' => 0.09,
		'Module::Info' => 0.12,
		'Test::More' => 0.41,
		'constant' => 1.02,
		'Getopt::Std' => 1.02,
		'IO::Socket' => 1.26,
		'Socket' => 1.72,
		'Data::Dumper' => 2.102,
	    },
        EXE_FILES => [
	        'bin/str',
	    ],
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Net/Starnet/DataAccounting.pm', # retrieve abstract from module
      AUTHOR     => 'Iain Truskett <spoon@cpan.org>') : ()),
);


