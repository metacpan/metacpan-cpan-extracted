use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::UKDomain::Nominet::Automaton',
    'VERSION_FROM'	=> 'Automaton.pm', # finds $VERSION
    'PREREQ_PM'		=> { 	'Crypt::OpenPGP' => 1.01,
				'LWP::UserAgent' => 2.001,
				'Net::XWhois' => 0.82,
				'Net::SMTP' => 2.29,
				}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Automaton.pm', # retrieve abstract from module
       AUTHOR     => 'Jason Clifford <jason@ukpost.com>') : ()),
);
