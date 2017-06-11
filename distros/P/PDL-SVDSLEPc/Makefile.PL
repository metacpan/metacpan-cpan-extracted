use PDL::Core::Dev;
use ExtUtils::MakeMaker;

##-- read in user variables
do "Config.PL";
die "$0: reading 'Config.PL' failed: $@" if ($@);

##-- pdlmaker stuff
PDL::Core::Dev->import();
require "./pdlmaker.plm";

$package = ["svdslepc.pd",SVDSLEPc,PDL::SVDSLEPc];
%hash = pdlmaker_init($package);

##----------------------------------------------------------------------
## ExtUtils::MakeMaker hash
$hash{AUTHOR} = 'Bryan Jurish';
$hash{ABSTRACT} = 'PDL interface to SLEPc sparse singular value decomposition';
$hash{PREREQ_PM} = {
		    'PDL'=>$cconfig{MIN_PDL_VERSION},
		   };
$hash{CONFIGURE_REQUIRES} = {
			     'PDL'=>$cconfig{MIN_PDL_VERSION},
			     'ExtUtils::MakeMaker'=>0,
			     'Devel::CheckLib'=>0,
			     'Data::Dumper'=>0,
			    };
$hash{BUILD_REQUIRES}{'Test::More'} = 0;

#push(@{$hash{TYPEMAPS}}, 'typemap');

$hash{DIR} = [];
$hash{VERSION_FROM} = 'svdslepc.pd';
$hash{LICENSE} = 'perl';
$hash{realclean}{FILES} .= '*~ *.tmp README.txt Config.cache';

##-- include $Config{ccflags} explicitly to avoid errors like:
## t/00_basic.t .. Not a CODE reference at /usr/lib/perl/5.14/DynaLoader.pm line 207.
use Config;
$hash{CCFLAGS}  .= " $Config{ccflags} ";

WriteMakefile(%hash);

##----------------------------------------------------------------------
sub MY::cflags {
  package MY;
  return shift->SUPER::cflags(@_) . <<EOF;

##-- cache some important variables petsc/slepc might clobber
## + slepc/petsc set GZIP=/bin/gzip, but that breaks EU::MM 'make dist' ("gzip.gz: permission denied")
## + DESTDIR is used by EU::MM
DESTDIR_SAVE := \${DESTDIR}
GZIP_SAVE := \${GZIP}

SLEPC_DIR = $::cconfig{SLEPC_DIR}
PETSC_DIR = $::cconfig{PETSC_DIR}

SVDSLEPC_CPPFLAGS = $::cconfig{SVDSLEPC_CPPFLAGS}
SVDSLEPC_CCFLAGS = $::cconfig{SVDSLEPC_CCFLAGS}
SVDSLEPC_LDFLAGS  = $::cconfig{SVDSLEPC_LDFLAGS}

#CCFLAGS_perl := \${CCFLAGS}
include \$(SLEPC_DIR)/conf/slepc_variables

##-- restore cached variables
GZIP := \${GZIP_SAVE}
DESTDIR := \${DESTDIR_SAVE}

#CC = \$(PCC)
LD = \$(CLINKER)
INC += \$(SVDSLEPC_CPPFLAGS) \$(CCPPFLAGS)
CCFLAGS += \$(SVDSLEPC_CCFLAGS) \$(CCFLAGS_perl) -Wno-write-strings
LDFLAGS += \$(SVDSLEPC_LDFLAGS) \$(SLEPC_LIB)
LDDLFLAGS += \$(SVDSLEPC_LDFLAGS) \$(SLEPC_LIB)
#OPTIMIZE +=


EOF
}

##----------------------------------------------------------------------
sub MY::depend {
  package MY;
  my $inherited = shift->SUPER::depend(@_);
  $inherited .= (
		 "\n\n"
		 ##--
		 #."SVDLIBC.o: svdutil.h svdlib.h\n\n"
		);
}

##----------------------------------------------------------------------
sub MY::special_targets {
  package MY;
  my $inherited = shift->SUPER::special_targets(@_);
  #$inherited =~ s/^(\.SUFFIXES\s*:.*)$/$1 .pod .rpod .pm .man .txt .html;/
  $inherited .= <<EOF

##-- readme
readme: README.txt

EOF
}

##----------------------------------------------------------------------
## avoid applying 'processPL' rules to 'Config.PL'
sub MY::processPL { return ''; }
