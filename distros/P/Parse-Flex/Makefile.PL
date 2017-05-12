# Copyright (C) 2003 Ioannis Tambouras <ioannis@earthlink.net> . All rights reserved.
# LICENSE:  Latest version of GPL. Read licensing terms at  http://www.fsf.org .
 

use ExtUtils::MakeMaker;
use ExtUtils::Embed;

my $ccflags = ccflags() .  ' -D_REENTRANT ' ;


grep { -e "$_/flex" }  split /:/, $ENV{PATH}
    or print q(You need flex(1) in your $PATH.)  and exit;



WriteMakefile(
    LICENSE             => 'gpl' ,
    PL_FILES            => { 'src/Makefile.PL' },
    NAME		=> 'Parse::Flex',
    VERSION_FROM	=> 'lib/Parse/Flex.pm', 
    CCFLAGS             =>  $ccflags,
    PREREQ_PM		=> { 'Scalar::Util' => 0,
			      XSLoader      => 0,
			   },
    ABSTRACT_FROM       => 'lib/Parse/Flex.pm', 
    EXE_FILES           =>  [ 'script/makelexer.pl' ],
    AUTHOR              => 'Ioannis Tambouras <ioannis@earthlink.net>',
    NORECURS            =>  0,
);

