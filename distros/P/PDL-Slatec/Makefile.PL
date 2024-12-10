use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use version;
use Text::ParseWords qw(shellwords);
use PDL::Core::Dev;
use ExtUtils::F77;

my $f77 = 'ExtUtils::F77';

die "No f77 compiler found. Can't build PDL::Slatec on this system\n"
  if !$f77->testcompiler;

my @pack = (["slatec.pd", qw(Slatec PDL::Slatec), '', 1]);
my @slatecfiles = map {s/\.f$//; $_} glob("slatec/*.f");
my %hash = pdlpp_stdargs(@pack);

my @slatecobj = map "$_\$(OBJ_EXT)", @slatecfiles;
$hash{OBJECT} .= join ' ', '', 'barf$(OBJ_EXT)', @slatecobj;

if($Config{cc} eq 'cl') {
# Link to MinGW's libg2c.a and libgcc.a, if appropriate
  my @f = ();
  my $drive = (split /:/, `gcc -v 2>&1`)[0];
  $drive = substr($drive, -1, 1);
  for(grep /^-L/, shellwords $f77->runtime) {
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
$hash{clean}{FILES} .= join ' ', '', @slatecobj;

$hash{DEFINE} .= qq{ "-DPDL_FORTRAN(x)=x}.($f77->trail_ ? '\#\#_' : '').qq{"};

sub MY::postamble {
        my $mycompiler     = $f77->compiler();
        my $mycflags       = $f77->cflags();
	my $orig = pdlpp_postamble(@pack);
	my $hack_64bit = $Config{archname}=~m/amd64|i686|x86_64/ ?" -fPIC " : "";
	$orig =~ s/:\s*slatec\.pd/: slatec.pd/;
	$orig .= "FFLAGS = $hack_64bit $mycflags \$(OPTIMIZE)\n";
	join "\n", $orig, map "$_\$(OBJ_EXT): $_.f
	$mycompiler -c \$(FFLAGS) -o $_\$(OBJ_EXT) $_.f", @slatecfiles;
}

# Remove i386 option for OS X recent versions for better build, dual arch does not work anyway
if ($Config{osname} =~ /darwin/ && version->parse($Config{osvers}) >= version->parse("14")) { # OS X Mavericks+
       print "Forcing single arch build for SLATEC\n";
       $hash{LDDLFLAGS} = $Config{lddlflags};
       $hash{LDDLFLAGS} =~ s/-arch i386/ /g;
}

my $package_name = $pack[0][2];
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile(
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  MIN_PERL_VERSION => '5.016',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.094',
    'ExtUtils::F77' => '1.26', # eg 1.20 can leave off -lgfortran
  },
  TEST_REQUIRES => {
    'Test::Exception' => 0,
  },
  PREREQ_PM => {
    'PDL' => '2.094',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>"https://github.com/$repo/issues"},
      repository  => {
        url => "git://github.com/$repo.git",
        type => 'git',
        web => "https://github.com/$repo",
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
  clean => { FILES => join ' ', qw(MANIFEST.bak) },
  %hash,
);
