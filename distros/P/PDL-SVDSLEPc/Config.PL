## File: PDL-SVDSLEPc/Config.PL
## Description: user variables for PDL::SVDSLEPc package

##-- load cache (disabling to see if this fixes cpantesters failures (v0.14, Tue, 17 Nov 2015 14:56:15 +0100)
if (0 && -e "./Config.cache") {
  do "./Config.cache";
  if ($@) {
    warn("$0: could not load cache data from 'Config.cache': $@");
  }
}

##--
## $val = cprompt($key, $message)
## $val = cprompt($key, $message, $default)
##   + prompt for and sets configuration value $cconfig{$key}
##   + uses ExtUtils::MakeMaker::prompt() for cpan smoker-friendliness
sub cprompt {
  my ($key, $msg, $default)=@_;
  return $cconfig{$key} if (defined($cconfig{$key}));
  $default = '' if (!defined($default)); 
  my $answer = ExtUtils::MakeMaker::prompt("<Config.PL> $msg [$default] ?");
  chomp($answer);
  return $cconfig{$key} = ($answer eq '' ? $default : $answer);
}

##--------------------------------------------------------------
## Sources: slepc

## $SLEPC_DIR : root directory of SLEPc installation
my @SLEPC_DIRS = (
		  $cconfig{SLEPC_DIR}, ##-- cached
		  $ENV{SLEPC_DIR},     ##-- SLEPc environment variable
		  glob("slepc-*"),
		  "/usr/local/lib/slepc",
		  "/usr/lib/slepc",
		 );
my $SLEPC_DIR;
foreach my $d (@SLEPC_DIRS) {
  if (-d $d && -r "$d/conf/slepc_variables") {
    $SLEPC_DIR = $d;
    last;
  }
}

##-- prompt and check
cprompt("SLEPC_DIR", "SLEPc root directory", $SLEPC_DIR);
if (!$cconfig{SLEPC_DIR} || !-d $cconfig{SLEPC_DIR} || !-r "$cconfig{SLEPC_DIR}/conf/slepc_variables") {
  warn("Warning: could not find SLEPc sources in SLEPC_DIR=".($cconfig{SLEPC_DIR}||''));
  exit 0; ##-- cpantesters -> NA
}

##--------------------------------------------------------------
## Sources: petsc

## $PETSC_DIR : root directory of PETSc installation
my @PETSC_DIRS = (
		  $cconfig{PETSC_DIR}, ##-- cached
		  $ENV{PETSC_DIR},     ##-- SLEPc environment variable
		  glob("petsc-*"),
		  "/usr/local/lib/petsc",
		  "/usr/lib/petsc",
		 );
my $PETSC_DIR;
foreach my $d (@PETSC_DIRS) {
  if (-d $d && -r "$d/conf/petscvariables") {
    $PETSC_DIR = $d;
    last;
  }
}

##-- prompt and check
cprompt("PETSC_DIR", "PETSc root directory", $PETSC_DIR);
if (!$cconfig{PETSC_DIR} || !-d $cconfig{PETSC_DIR} || !-r "$cconfig{PETSC_DIR}/conf/petscvariables") {
  warn("Warning: could not find PETSc sources in PETSC_DIR=".($cconfig{PETSC_DIR}||''));
  exit 0; ##-- cpantesters -> NA
}

##--------------------------------------------------------------
## 64-bit index support?

my $PETSC_USE_64BIT_INDICES = 0;
if (-r "$cconfig{PETSC_DIR}/petscconf.h") {
  open(my $fh,"$cconfig{PETSC_DIR}/petscconf.h");
  while (defined($_=<>)) {
    if (/^\s*#define\s*PETSC_USE_64BIT_INDICES\s*([0-9]+)/) {
      $PETSC_USE_64BIT_INDICES = $1+0;
    }
  }
  close($fh);
}
$cconfig{PETSC_USE_64BIT_INDICES} = $PETSC_USE_64BIT_INDICES;
$cconfig{MIN_PDL_VERSION} = $PETSC_USE_64BIT_INDICES ? '2.007' : '0';
#cprompt("PETSC_USE_64BIT_INDICES", "Use 64-bit indices (requires 64-bit index support in PETSc and PDL >= v2.007)", "y");


##--------------------------------------------------------------
## extra compile flags

cprompt("SVDSLEPC_CPPFLAGS", "Additional preprocessor flags for SVDSLEPc", $ENV{SVDSLEPC_CPPFLAGS});
cprompt("SVDSLEPC_CCFLAGS", "Additional compiler flags for SVDSLEPc", $ENV{SVDSLEPC_CCFLAGS});
cprompt("SVDSLEPC_LDFLAGS", "Additional linker flags for SVDSLEPc", $ENV{SVDSLEPC_LDFLAGS});

##--------------------------------------------------------------
## check for slepc c library
use Devel::CheckLib;
check_lib_or_exit(lib => 'slepc',
		  LIBS => $cconfig{SVDSLEPC_LDFLAGS},
		 );

##--------------------------------------------------------------
## save cache file
use Data::Dumper;
open(CACHE,">Config.cache")
  or die("$0: open failed for Config.cache: $!");
print CACHE
  ("## Automatically generated, remove to re-configure!\n",
   Data::Dumper->Dump([\%cconfig],['*cconfig']),
   "1; ##-- be happy\n",
  );
close CACHE;

1; ##-- return nicely

