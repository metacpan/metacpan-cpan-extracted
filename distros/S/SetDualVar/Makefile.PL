#BEGIN {@INC=("/home/kjahds/perl5/perl5.000/lib/auto","/home/kjahds/perl5/perl5.000/lib");}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'SetDualVar',
    'VERSION'	=> '1.0',
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
