require 5.00561;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$rxperl = '../../RxPerl';


unlink "RxPerl", "rxperl";
print "Where will the RxPerl source directory be constructed? ";
print "[$rxperl] ";
chomp($resp = <STDIN>) if -t STDIN;
$rxperl = $resp if $resp ne '';
symlink $rxperl, "RxPerl" or die "Couldn't make RxPerl symlink: $!";
symlink "RxPerl/perl", "rxperl" or die "Couldn't make rxperl symlink: $!";


WriteMakefile(
    'NAME'	=> 'Rx',
    'CCFLAGS'    => '-DREG_COMP_C -DDEBUGGING',
    'VERSION_FROM' => 'Rx.pm', # finds $VERSION
    'LIBS'	=> [],     # e.g., '-lm' 
    'DEFINE'	=> '', # '-DMJD_DB',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-IRxPerl',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => 'Rx.o Dump.o',
#     'FULLPERL'  => 'perl561',
#     'PERL'      => 'perl561',
    'depend'    => { 'Dump.o' => 'Dump.c regname.h regarglen.h Dump.h',
#                     'Undump.o' => 'Undump.c Dump.h',
#		     'regargprint.o' => 'regargprint.c',
#		     'mjddump.a' => 'Dump.o',
                   },
);


sub MY::postamble {
  'bytecode: bydecode.c
'}

#   '
# mjddump.a: Dump.o
# 	ar cr mjddump.a Dump.o
# ';
# }
