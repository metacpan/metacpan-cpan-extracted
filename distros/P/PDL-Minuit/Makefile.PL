use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::F77;
use Config;
use PDL::Core::Dev;
use version;
use Text::ParseWords qw(shellwords);

my $f77 = 'ExtUtils::F77';
my @minuitfiles = ("futils", "minuit", "intracfalse");
my @pack = (["minuit.pd", qw(Minuit PDL::Minuit)]);
my %hash = pdlpp_stdargs(@pack);

$hash{OBJECT} .= join ' ', '', 'FCN$(OBJ_EXT)', map "minuitlib/${_}\$(OBJ_EXT)", @minuitfiles;

if($Config{cc} eq 'cl') {
# Link to MinGW's libg2c.a and libgcc.a, if appropriate
  my @f = ();
  my $drive = (split /:/, `gcc -v 2>&1`)[0];
  $drive = substr($drive, -1, 1);
  for(grep /^-L/, shellwords $77->runtime) {
     $_ =~ s#^-L##;
     unless($_ =~ /:/) {$_ = $drive . ':' . $_}
     if(-e $_ . '/libg2c.a') {push @f, $_ . '/libg2c.a'}
     if(-e $_ . '/libgcc.a') {push @f, $_ . '/libgcc.a'}
  }
  $hash{LDFROM} = join ' ', $hash{OBJECT}, @f;
}

my $fortran_libs = $f77->runtime;
if ($fortran_libs =~ /quadmath.*gfortran/) { # wrong order, thanks EUMM
  my @words = shellwords $fortran_libs;
  my @other = grep !/quadmath/, @words;
  my @quadmath = grep /quadmath/, @words;
  $fortran_libs = join ' ', map /\s/ ? qq{"$_"} : $_, @other, @quadmath;
}
$hash{LIBS}[0] .= $fortran_libs;
$hash{clean}{FILES} .= join '', map {" minuitlib/$_\$(OBJ_EXT) "} @minuitfiles;

# Handle multiple compilers

my $f2cbased = ($f77->runtime =~ /-lf2c/);
my $g2cbased = ($f77->runtime =~ /-lg2c/) unless $f2cbased;

$hash{DEFINE} .= " -DPDL_USCORE=" . ($f77->trail_ ? "_" : "");

undef &MY::postamble; # suppress warning
*MY::postamble = sub {
        my $mycompiler     = $f77->compiler();
        my $mycflags       = $f77->cflags();
	my $orig = pdlpp_postamble(@pack);
	my $hack_64bit = ($Config{archname}=~m/amd64|i686|x86_64/ ?" -fPIC " : "");
	$orig =~ s/:\s*minuit\.pd/: minuit.pd/;
	$orig .= "FFLAGS = $hack_64bit $mycflags \$(OPTIMIZE)\n";
	$orig .= join "\n",map {
	    ("minuitlib/$_\$(OBJ_EXT): minuitlib/$_.f
	$mycompiler -c \$(FFLAGS) -o minuitlib/$_\$(OBJ_EXT) minuitlib/$_.f
" )} @minuitfiles;
	return $orig;
};

# Remove i386 option for OS X recent versions for better build, dual arch does not work anyway. KG 25/Oct/2015
my %items;
if ($Config{osname} =~ /darwin/ && version->parse($Config{osvers}) >=version->parse("14")) { # OS X Mavericks+
       print "Forcing single arch build for MINUIT\n";
       $items{LDDLFLAGS} = $Config{lddlflags};
       $items{LDDLFLAGS} =~ s/-arch i386/ /g;
}

WriteMakefile(
  %hash,
  %items,
  'ABSTRACT' => 'Minuit 1 optimization routines for PDL',
  'LICENSE' => 'perl',
  'CONFIGURE_REQUIRES' =>  { "PDL" => '2.093', "ExtUtils::F77" => '1.26' },
  'PREREQ_PM' => {
    'PDL' => '2.093',
  },
  TEST_REQUIRES => { "Test::More" => '0.88' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-Minuit.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-Minuit',
      },
      bugtracker => {web=>'https://github.com/PDLPorters/PDL-Minuit/issues'},
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
);
