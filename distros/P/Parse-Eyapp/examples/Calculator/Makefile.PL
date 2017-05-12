use warnings;
use strict;

use ExtUtils::MakeMaker;

my $PUBLIC_PLACE = $ENV{PUBLIC_PLACE}   || "/home/$ENV{USER}/public_html/perlexamples/";
my $MACHINES     = $ENV{REMOTEMACHINES} || 'localhost';

WriteMakefile(
    NAME              => 'Math::Calc',
    VERSION_FROM      => 'lib/Math/Calc.eyp',
    PREREQ_PM         => { 
                               'Parse::Eyapp' => '1.124', 
                             # 'Devel::Cover' => '0.64',   # Only for the DEVELOPER
                             # 'GRID::Machine' => '0.101', # Only for the DEVELOPER
                         }, 
    EXE_FILES         => [ 'scripts/calc.pl' ],
    ABSTRACT_FROM     => 'lib/Math/Calc.pod', 
    AUTHOR            => 'Casiano Rodriguez-Leon <casiano@ull.es>',
);

sub MY::postamble {

  return '' unless $ENV{DEVELOPER};

  $_ = targets();

  s/<<PUBLIC_PLACE>>/$PUBLIC_PLACE/ge;

  s/<<MACHINES>>/$MACHINES/ge;

  return $_;
}

sub targets {

  return <<'EOM';
EYAPP=eyapp
# Set EYAPPENV environment variable to '-s' if you want a standalone
# parser
EYAPPFLAGS=-m Math::Calc ${EYAPPENV}
PLTAGS=/usr/share/vim/vim71/tools/pltags.pl

%.pm:%.eyp 
	${EYAPP}  ${EYAPPFLAGS} -o $@ $*
	${PERL} -Ilib -c $@

calc: lib/Math/Calc.pm 

scripts/c.pl: lib/Math/Calc.eyp
	${EYAPP}  ${EYAPPFLAGS} -b '' -o $@ lib/Math/Calc.eyp

lib/Math/Calc.pm: lib/Math/Calc.eyp lib/Math/Tail.pm

myclean: veryclean rmcalc
	rm -f Math-Calc-*.tar.gz
	cover -delete

rmcalc: 
	rm -f lib/Math/Calc.pm scripts/c.pl

mytest: calc test
	
remotetest: calc dist
	remotetest.pl ${DISTVNAME}.tar.gz <<MACHINES>>

coverage: calc
	cover -delete
	make HARNESS_PERL_SWITCHES=-MDevel::Cover test
	cover

public: calc dist
	cp ${DISTVNAME}.tar.gz <<PUBLIC_PLACE>>

.PHONY: tags

tags:
	${PLTAGS} scripts/*.pl lib/Math/Tail.pm lib/Math/*.eyp Makefile.PL 
	ctags -a 

google:
	svn commit -m ${M}
EOM
}

