use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::MySQL',
    'VERSION_FROM'	=> 'MySQL.pm',
    'PREREQ_PM'		=> {
		'IO::Socket'   => 0.0,
        'Digest::SHA1' => 0.0,
	},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'MySQL.pm',
       AUTHOR     => 'Hiroyuki OYAMA <oyama@module.jp>') : ()),
);
