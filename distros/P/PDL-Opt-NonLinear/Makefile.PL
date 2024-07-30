use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use ExtUtils::F77;
use utf8; # to get author name right
my $f77 = 'ExtUtils::F77';
die "No fortran compiler found. Will not build PDL::Opt::NonLinear on this system\n" if !$f77->testcompiler;

my @pack = (qw(nonlinear.pd NonLinear PDL::Opt::NonLinear), undef, 1);
my @ffiles = map {s/\.f$//; $_} glob("*.f");
my $fobj = join ' ', map {"$_\$(OBJ_EXT)"} @ffiles;
my @cfiles = qw(hooke asa asa_usr dhc de36 select);
my $cobj = join ' ', map "$_\$(OBJ_EXT)", @cfiles;

my %hash = pdlpp_stdargs(\@pack);
$hash{INC} .= " -I.";  # uncomment as required
$hash{OBJECT} .= " $cobj $fobj";
$hash{LIBS}[0] .= $f77->runtime . ' -L/usr/local/lib -lport -lblas' ;
$hash{clean}{FILES} .= " $fobj";

WriteMakefile(
  %hash,
  'ABSTRACT' => 'Non linear optimization routines for PDL',
  'AUTHOR' => [ 'Grégory Vanuxem <g.vanuxem@gmail.com>' ],
  'LICENSE' => 'artistic_2',
  'CONFIGURE_REQUIRES' =>  { "PDL" => '2.088', "ExtUtils::F77" => 0 },
  'PREREQ_PM' => {
    'PDL' => '2.088', # =CALC
    'PDL::LinearAlgebra' => 0,
  },
  TEST_REQUIRES => { "Test::More" => '0.88' },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      repository  => {
        url => 'git://github.com/PDLPorters/PDL-Opt-NonLinear.git',
        type => 'git',
        web => 'https://github.com/PDLPorters/PDL-Opt-NonLinear',
      },
      bugtracker => {web=>'https://github.com/PDLPorters/PDL-Opt-NonLinear/issues'},
    },
    x_IRC => 'irc://irc.perl.org/#pdl',
  },
);

sub MY::postamble {
        my $mycompiler     = $f77->compiler;
        my $mycflags       = $f77->cflags;
	my $orig = pdlpp_postamble(\@pack);
	$orig =~ s/:\s*nonlinear\.pd/: nonlinear.pd/;
	$orig .= <<EOF;

FC = $mycompiler
FFLAGS = $mycflags -O3 -fPIC

EOF

	$orig .join "\n",map {
("
$_\$(OBJ_EXT): $_.f
	\$(FC) -c -o \$@ \$(FFLAGS) \$<
" )} @ffiles;
}
