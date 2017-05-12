use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Spread::Message',
    'VERSION_FROM'	=> 'Message.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'Spread'       => 0,
						 'Data::Dumper' => 0,
						 'Carp'         => 0,
						 'Sys::Hostname'         => 0,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Message.pm', # retrieve abstract from module
       AUTHOR     => 'Mark Pfeiffer <markpf@mlp-consulting.com.au>') : ()),
);
