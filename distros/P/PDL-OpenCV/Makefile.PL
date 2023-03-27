use strict;
use warnings;
use PDL::Core::Dev;            # Pick up development utilities
use ExtUtils::MakeMaker;
use File::Spec::Functions qw(catfile curdir updir);
use Alien::Base::Wrapper ();

require ''. catfile curdir, 'submodmf.pl';
my %alien_cv = Alien::Base::Wrapper->new('Alien::OpenCV')->mm_args;
our $libs = $alien_cv{LIBS}[0];
our $inc = $alien_cv{INC};

my $package = ["opencv.pd",'OpenCV','PDL::OpenCV'];
my %hash = pdlpp_stdargs($package);
$hash{clean}{FILES} .= join ' ', '', map "$_.h $_.cpp", qw(opencv_wrapper wraplocal);
$hash{LIBS}[0] .= $libs;
$hash{INC} .= " $inc";
$hash{OBJECT} .= join ' ', '', map $_.'$(OBJ_EXT)', qw(wraplocal);
$hash{PM}{'Demo.m'} = '$(INST_LIB)/PDL/Demos/OpenCV.pm';

use ExtUtils::CppGuess;
my $guess = ExtUtils::CppGuess->new;
our %cpp_opts = $guess->makemaker_options;
$cpp_opts{CCFLAGS} .= ' ' . $guess->cpp_standard_flag('C++11');
$hash{dynamic_lib} = $cpp_opts{dynamic_lib};
our ($cppg_cc, $cppg_cflags) = @cpp_opts{qw(CC CCFLAGS)};

our @cw_objs = map $_.'$(OBJ_EXT)', qw(opencv_wrapper);

%hash = (%hash,
    NAME                => 'PDL::OpenCV',
    AUTHOR              => 'Ingo Schmid',
    LICENSE => 'perl',
    CONFIGURE_REQUIRES => {
        'ExtUtils::CppGuess' => '0.22',
        'ExtUtils::MakeMaker' => '6.3002',
        'PDL' => '2.082', # pp_add_typemaps
        'Alien::OpenCV' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
    },
    PREREQ_PM => {
        'PDL'        => '2.079',
    },
    MYEXTLIB => join(' ', @cw_objs),
    depend => {
      '$(OBJECT)'=>'opencv_wrapper.h wraplocal.h',
      'opencv_wrapper$(OBJ_EXT)'=>'opencv_wrapper.h',
      'opencv_wrapper.h wraplocal.h OpenCV.pm'=>'funclist.pl genpp.pl constlist.txt classes.pl', # .pm because that deps on .pd
      'OpenCV.pm OpenCV.c'=>'typemap',
      '$(FIRST_MAKEFILE)'=>'submodmf.pl',
    },
);
WriteMakefile(%hash);

sub cxx_cmd {
  my ($self, $cppg_cc, $cppg_cflags) = @_;
  my $cccmd = $self->const_cccmd;
  $cccmd =~ s/CCCMD/CXXCMD/;
  $cccmd =~ s/\$\(CC\)/$cppg_cc/;
  $cccmd =~ s/(\$\(OPTIMIZE\)).*/$cppg_cflags $1\n/s;
  $cccmd;
}
sub cpp_comp {
  join "\n", map "$_\$(OBJ_EXT) : $_.cpp\n\t\$(CXXCMD) \$(CCCDLFLAGS) $_.cpp\n", @_;
}
sub genwrap_from {
  my ($genwhatstem, $updir, @params) = @_;
  my $plfile = $updir ? catfile(updir, 'genwrap.pl') : 'genwrap.pl';
  <<EOF;
$genwhatstem.cpp : $genwhatstem.h # impose sequence so only run once
$genwhatstem.h : $plfile
	\$(PERLRUN) $plfile $genwhatstem @params
EOF
}
sub cpp_build {
  my ($self, @bases) = @_;
  (cxx_cmd($self, $cppg_cc, $cppg_cflags), cpp_comp(@bases));
}
sub MY::postamble {
  my ($self) = @_;
  my $const = -f 'constlist.txt' ? 'wraplocal.h : constlist.txt' : '';
  join "\n", pdlpp_postamble($package),
    genwrap_from('opencv_wrapper', 0, ','),
    genwrap_from('wraplocal', 0, ',', 'nocons'),
    $const,
    cpp_build($self, qw(opencv_wrapper wraplocal));
}
