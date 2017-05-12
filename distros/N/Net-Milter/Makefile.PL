use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Milter',
    'VERSION_FROM'	=> 'Milter.pm', # finds $VERSION
    'PREREQ_PM'		=> {IO::Socket, IO::Select}, 
    'AUTHOR'            => 'Martin Lee <mlee@messagelabs.com>',
    'ABSTRACT'          => 'Pure Perl implementation the Sendmail end of the milter API',

);
