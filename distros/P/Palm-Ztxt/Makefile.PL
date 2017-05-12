use 5.006001;
use ExtUtils::MakeMaker;
use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $ztxt_home = $ENV{ZTXT_HOME};
$ztxt_home ||= 
    prompt('make_ztxt home direcotry [./makeztxt-1.62]:');
$ztxt_home ||= './makeztxt-1.62';

my $use_included = ($ztxt_home eq './makeztxt-1.62');

my $ztxt_lib = $ztxt_home."/libztxt";
WriteMakefile(
    'NAME'		=> 'Palm::Ztxt',
    'VERSION_FROM'	=> 'Ztxt.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::More' => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM	=> 'Ztxt.pm', # retrieve abstract from module
       AUTHOR		=> 'Rudolf Lippan <rlippan@remotelinux.com>') : ()),
    LIBS		=> ["-L$ztxt_lib -lz".(!$use_included ? ' -lztxt' : '')],
    ($use_included ? 
        (MYEXTLIB		=>  "$ztxt_lib/libztxt\$(LIB_EXT)") : () ),
    'DEFINE'		=> '',
    'INC'		=> "-I. -I$ztxt_home -I$ztxt_lib",
    'clean'		=> {FILES => "TestOutput"},
);

sub MY::postamble {
return "" if !$use_included;

    return <<PA;

libztxt.\$(LIB_EXT) : \$(MYEXTLIB)

\$(MYEXTLIB) : $ztxt_home/Makefile
	cd $ztxt_home && \$(MAKE) all

clean :: 
	cd $ztxt_home && \$(MAKE) distclean

PA
}
