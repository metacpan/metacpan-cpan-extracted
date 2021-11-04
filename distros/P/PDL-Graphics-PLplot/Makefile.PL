use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use Data::Dumper;

use PDL::Core::Dev;
use Devel::CheckLib;
use Alien::PLplot;

my $PL_MAJOR = 5; # minimum required
my $PL_MINOR = 13;

unlink ("OPTIONS!"); # remove file used to communicate with plplot.pd

my $plplot_lib_path;
my $plplot_include_path;
my $libs;
my $header;

sub _probe_msg_failure {
  my ($msg) = @_;
  die "$msg\n" . <<'EOF';

Please either:
- Install PLplot using your package manager then reinstall Alien::PLplot or
- Reinstall Alien::PLplot from CPAN with environment variable
  ALIEN_INSTALL_TYPE=share.
EOF
}

sub probe {
  $header = (Alien::PLplot->inline_auto_include)->[0];
  $plplot_include_path = Alien::PLplot->cflags;
  $libs = Alien::PLplot->libs;
}

probe;

# Test that PLplot was compiled --with-double (IE, a PLFLT is a double)
my $size = compileAndRun( <<'EOC' );
printf  ("%d", sizeof (PLFLT));
EOC

unless ($size == 8) {
  _probe_msg_failure <<'EOF';
Sizeof(PLFLT) must be 8.
PLplot must be compiled --with-double (IE ./configure --with-double).
EOF
}

my $plgver = compileAndRun (<<'EOC');
char ver[80];
c_plgver(ver);
fputs(ver, stdout);
EOC

my @plver = split /\./, $plgver;
unless ($plver[0] > $PL_MAJOR or ($plver[0] == $PL_MAJOR and $plver[1] >= $PL_MINOR)) {
  _probe_msg_failure "Insufficient plplot version '$plgver'; need at least $PL_MAJOR.$PL_MINOR";
}

my %plversion = ();
$plversion{'C_COMPILE'}   = "$Config{cc} $Config{ccflags} $plplot_include_path";
$plversion{'C_COMPILE_SUFFIX'} = $libs;
$plversion{'PLPLOT_LIB'}  = $plplot_lib_path;
# Write these options to a file--used during the test step
open my $fh, '>', 'OPTIONS!' or die "Cannot write to OPTIONS! file";
print  {$fh} Dumper(\%plversion);
close   $fh;

my @pack = ([qw(plplot.pd PLplot PDL::Graphics::PLplot), undef, 1]);

my %hash = pdlpp_stdargs(@pack);
$hash{'PREREQ_PM'} = { PDL => 0 };
$hash{CONFIGURE_REQUIRES} = {
  'PDL::Core::Dev' => 0,
  'Devel::CheckLib' => 0,
  'Alien::PLplot' => 0,
};
# $hash{'OPTIMIZE'}  = '-g'; # If you want to debug, uncomment this.
$hash{TEST_REQUIRES} = {
  'Test::More' => '0.88', # done_testing
};
$hash{'VERSION_FROM'}   = 'plplot.pd';
$hash{OBJECT} .= ' callback$(OBJ_EXT)';
$hash{'LIBS'}      = [$libs];
$hash{'INC'}      .= " $plplot_include_path";
$hash{clean}{FILES} .= ' *svg.* *.xfig temp* OPTIONS!';
$hash{META_MERGE} = {
  "meta-spec" => { version => 2 },
  resources => {
    bugtracker  => {web=>'https://github.com/PDLPorters/pdl-graphics-plplot/issues'},
    repository  => {
       url => 'git://github.com/PDLPorters/pdl-graphics-plplot.git',
       type => 'git',
       web => 'https://github.com/PDLPorters/pdl-graphics-plplot',
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
};

my $postamble = pdlpp_postamble(@pack);

WriteMakefile(%hash);

# Add genpp rule
sub MY::postamble { $postamble };

sub compileAndRun {
  my ($code) = @_;
  my $result;

  check_lib(
    ccflags  => "$plplot_include_path",
    ldflags  => "$libs",
    INC      => "$plplot_include_path",
    LIBS     => "$libs",
    header   => [ 'stdio.h', $header ],
    function => $code,
    analyze_binary => sub {
      my ($l, $bin) = @_;
      my $path_to_bin = File::Spec->catfile('.', $bin);
      $result = `$path_to_bin`;
    },
    not_execute => 1,
  );
  return $result;
}
