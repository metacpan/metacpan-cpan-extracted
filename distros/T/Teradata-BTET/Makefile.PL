use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Teradata::BTET',
    'VERSION_FROM'	=> 'BTET.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'BTET.pm', # retrieve abstract from module
       AUTHOR     => 'Geoffrey Rommel <GROMMEL@cpan.org>') : ()),
    'C'			=> ['BTET.c', 'tdbtet.c'] ,
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I/usr/include/other'
    'OBJECT'		=> '$(O_FILES) tdbtet.o',
    'LDFROM'		=> '$(O_FILES) /usr/lib/ppruntim.a',
    'LIBS'		=> ["-ltdusr -lcliv2 -lppc -lnsl -lsocket"],
    'clean'		=> {FILES => " tdbtet.c"},
);

sub MY::depend {
# my $TDLOGON = $ENV{'TDLOGON'};
# die ">>>> Please specify TDLOGON\n" unless $TDLOGON;

 return <<ZZ
tdbtet.c : tdbtet.pc tdbtet.h
	-/usr/bin/ppcmain "SQLCHECK(NOSYNTAX)" \\
   "DATE(I)" "INPUT(tdbtet.pc)" "PUNCH(tdbtet.c)" \\
   "CURPREFIX(TDB)" "TRANSACT(BTET)" "MARGINS(1,200)"

ZZ
}
