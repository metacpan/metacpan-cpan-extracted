use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require 5.005;

WriteMakefile(
    'NAME'		      => 'Regexp::Extended',
    'VERSION_FROM'  => 'Extended.pm', # finds $VERSION
    'AUTHOR'        => 'Daniel Shane <lachinois@hotmail.com>',
		'ABSTRACT_FROM' => 'Extended.pm', # retrieve abstract from module
);
