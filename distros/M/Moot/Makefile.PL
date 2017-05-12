use ExtUtils::MakeMaker;

##----------------------------------------------------------------------
## Configuration
##----------------------------------------------------------------------
use Alien::Moot;
my %prereq = (
	      'ExtUtils::MakeMaker' => 6.52, ##-- for CONFIGURE_REQUIRES
	      'Alien::Moot' => 0.001,
	     );

##-- ensure mininum libmoot version
my $moot_min_version = "2.0.10";
if (Alien::Moot->install_type ne 'system') {
  my $moot_alien_version = Alien::Moot->pkgconfig('moot')->keyword('Version');
  (my $v_alien = $moot_alien_version) =~ s/\-/_/g;
  die("Required library libmoot >= v$moot_min_version not found; we have v$moot_alien_version\n")
    if (version->parse($v_alien) < version->parse($moot_min_version));
}
elsif (system("pkg-config --atleast-version=${moot_min_version} moot") != 0) {
  die("Required library libmoot >= v$moot_min_version not found; we have v", `pkg-config --modversion moot`);
}

##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------
WriteMakefile
  (
   NAME		=> 'Moot',
   #DISTNAME	=> 'moot-perl',
   DISTNAME     => 'Moot',
   AUTHOR       => 'Bryan Jurish <moocow@cpan.org>',
   ABSTRACT	=> 'Perl interface to the libmoot HMM tagger library',
   VERSION_FROM	=> 'Moot.pm',
   LICENSE      => 'perl',

   ##-- prerequisites
   CONFIGURE_REQUIRES => \%prereq,
   PREREQ_PM => \%prereq,

   ##-- user variables
   CC           => 'c++',   ##-- your c++ compiler
   DEFINE       => '-DHAVE_CONFIG_H',     ##-- additional defines
   LIBS         => Alien::Moot->libs,     ##-- additional libraries
   INC          => Alien::Moot->cflags,   ##-- additional includes
   #CCFLAGS      => '',                   ##-- additional(?) flags ... DynaLoader refuses to load on perl v5.14 / 32-bit i686 / debian wheezy if this is set!
   OPTIMIZE    => '-O2 -pipe -Wno-deprecated', ##-- optimization flags
   OBJECT       => 'Moot.o MootPerl.o',

   ##-- install these
   EXE_FILES => [glob("moot*.perl")],

   ##-- DEBUG
   #MAKEAPERL=>1,
   #LINKTYPE=>'static',
   #MAP_TARGET=>'mootperl',
   #CCFLAGS=>'-g',
   ##-- /DEBUG

   ##-- stuff that probably doesn't need to be changed
   XSOPT        => '-C++',
   TYPEMAPS     => ['perlobject.map', 'typemap'],
  );


#-----------------------------------------------------------------------
# Extensions
#-----------------------------------------------------------------------
##...

sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 "\n\n"
		 ##-- included xs dependencies
		 ."Moot.c: "
		 .(''
		   ." Moot.xs"
		   ." Constants.xs"
		   ." Lexfreqs.xs"
		   ." Ngrams.xs"
		   ." HMM.xs"
		   ." DynHMM.xs"
		   ." TokenIO.xs"
		   ." TokenReader.xs"
		   ." TokenWriter.xs"
		   ." Waste.xs"
		  )
		 ."\n\n"
		 ##-- c->o dependencies
		 ."Moot.o: Moot.c MootPerl.h\n"
		 ."\n"
		 ."MootPerl.o: MootPerl.h MootPerl.cc\n"
		 ."\n"
		 ###-- depends -> README.txt
		 ."dist: README.txt\n"
		 ."\n"
		 ."create_distdir: README.txt\n"
		 #."distdir_am: README.txt\n"
		 ."\n"
		 ."distcheck: README.txt\n"
		 ."\n"
		 ."manicheck: README.txt\n"
		 ."\n"
		 ## -- more here
		 ."\n"
		);
  $inherited;
}


##---------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  $inherited .=
"
.SUFFIXES: .pm .pod .rpod .man .txt .html

##-- pod2xxx
.pm.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.pm.txt:
\tpod2text \$< \$@

.pod.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.pod.txt:
\tpod2text \$< \$@

##-- readme
.rpod.html:
\tpod2html --title=\$@ --infile=\$< --outfile=\$@

.rpod.txt:
\tpod2text \$< \$@

readme: README.txt

";
  return $inherited;
}
