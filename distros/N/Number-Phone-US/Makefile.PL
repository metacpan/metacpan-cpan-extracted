# $Id: Makefile.PL,v 1.1.1.1 2000/11/17 22:16:54 kennedyh Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Number::Phone::US',
    'VERSION_FROM' => 'lib/Number/Phone/US.pm', # finds $VERSION
);
