## File: PDL-SVDLIBC/Config.PL
## Description: user variables for PDL::SVDLIBC package

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
## Sources

## $SVD_SRCDIR : location of SVDLIBC sources
#my $SVD_SRC0 = (grep {-d $_} qw(./SVDLIBC ../SVDLIBC))[0] // "http://tedlab.mit.edu/~dr/SVDLIBC/svdlibc.tgz";
##  + packed into PDL-SVDLIBC source distribution for PDL-SVDLIBC >= v0.15
$cconfig{SVD_SRCDIR} = './SVDLIBC';

##-- sanity check
if (! -d $cconfig{SVD_SRCDIR}) {
  warn("Warning: source directory SVD_SRCDIR=$SVD_SRCDIR does not exist!");
  return;
}


##--------------------------------------------------------------
## Flags

## $SVD_INC : include flags for SVDLIBC
#cprompt('SVD_INC', "include flags for SVDLIBC", '-I/usr/local/include/svdlibc');
#cprompt('SVD_INC', "Additional include flags for SVDLIBC", "-I$cconfig{SVD_SRCDIR}");
#$cconfig{SVD_INC} = "-I$cconfig{SVD_SRCDIR}";
$cconfig{SVD_INC} = "-I.";

## $SVD_DEFS : additional defines for SVDLIBC
cprompt("ENABLE_PDL_INDX", "Enable 64-bit PDL_Indx support if available (requires PDL >= v2.007)", "y");
$cconfig{ENABLE_PDL_INDX} = ($cconfig{ENABLE_PDL_INDX} && $cconfig{ENABLE_PDL_INDX} !~ /^[n0]/ ? 1 : 0);

require PDL::Core;
my ($LONG,$LONGLONG) = $cconfig{ENABLE_PDL_INDX} && defined(&PDL::indx) ? ('PDL_Indx','PDL_Indx') : ('PDL_Long','PDL_LongLong');
cprompt('SVD_LONG',     "SVDLIBC long integer datatype", "$LONG");
cprompt('SVD_LONGLONG', "SVDLIBC long long integer datatype", "$LONGLONG");
cprompt('SVD_DEFS', "Additional defines for SVDLIBC", "-D__SVDLIBC_LONG=$cconfig{SVD_LONG} -D__SVDLIBC_LONG_LONG=$cconfig{SVD_LONGLONG}");

## $SVD_CFLAGS : additional compiler flags for SVDLIBC
# + do *NOT* use -ffast-math !
#my $SVD_CFLAGS = $ENV{CFLAGS};
#my $SVD_CFLAGS = "-O2 -pipe";
#my $SVD_CFLAGS = "-O3 -pipe -march=native -mtune=native -mfpmath=sse";
#cprompt('SVD_CFLAGS', "SVDLIBC compiler flags", $SVD_CFLAGS);

## $SVD_LDFLAGS : linker flags for SVDLIBC
#cprompt('SVD_LDFLAGS', "SVDLIBC linker flags", '-L/usr/local/lib');

## $SVD_LIBS : libs to link
#cprompt('SVD_LIBS', "SVDLIBC libraries", '');

## $SVD_OBJ : additional object files and/or static libs to link
#my $SVD_OBJ = '/usr/local/lib/libsvd.a';
#my $SVD_OBJ = join(' ', qw(las2.o svdlib.o svdutil.o);
#cprompt('SVD_OBJ', "SVDLIBC objects", $SVD_OBJ);

##--------------------------------------------------------------
## remove auto-generated sources if present
foreach (qw(las2.c svdlib.c svdlib.h svdutil.c svdutil.h)) {
  !-e $_
    or unlink($_)
    or die("Config.PL: failed to unlink intermediate source file '$_': $!");
}

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

