use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use Devel::CheckLib qw(check_lib);

# Makefile has targets 'cleanall' and 'distcleanall'.
# These do clean and distclean in both module distribution
# toplevel and in $matio_top_level.

my ($matio_top_level, $inc, $libs, %object) = ('./matio-1.5.0', '', '');

if (check_lib(lib => 'hdf5')) {
  $libs .= ' -lhdf5';
  $inc .= ' -DHAVE_HDF5=1';
} else {
  my $this_inc = (
    eval {require PkgConfig; join ' ', PkgConfig->find('hdf5')->get_cflags} ||
    eval {require ExtUtils::PkgConfig; ExtUtils::PkgConfig->cflags('hdf5')} ||
    `pkg-config hdf5 --cflags` ||
    ''
  );
  $inc .= ' '.$this_inc.' -DHAVE_HDF5=1' if $this_inc;
  $libs .= ' '.(
    eval {require PkgConfig; join ' ', PkgConfig->find('hdf5')->get_ldflags} ||
    eval {require ExtUtils::PkgConfig; ExtUtils::PkgConfig->libs('hdf5')} ||
    `pkg-config hdf5 --libs` ||
    '-lhdf5'
  );
}

if (check_lib(lib => 'matio')) {
  $libs .= ' -lmatio';
} else {
  %object = (OBJECT  =>  ' Matlab$(OBJ_EXT) matio_obj$(OBJ_EXT) ');
  if ( not -e "$matio_top_level/src/matio_pubconf.h" ) {
    print "Makefile.PL: running configure in $matio_top_level\n";
    system "cd $matio_top_level; ./configure";
  }
}

my $matlab_package = ['matlab.pd', 'Matlab', 'PDL::IO::Matlab'];
my %hash = pdlpp_stdargs($matlab_package);

my %more_items = (
    AUTHOR              => q{John Lapeyre <jlapeyre@cpan.org>},
    ABSTRACT_FROM       => 'matlab.pd',
    %object,
    LIBS => [ '-lz' ],
    CONFIGURE_REQUIRES => {
        'Devel::CheckLib' => '1.14',
        'ExtUtils::MakeMaker' => '6.64', # TEST_REQUIRES
        'PDL' => '2.043',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88', # done_testing
    },
    PREREQ_PM => {
        'PDL' => '2.043',
    },
    # note the file below that matio Makefile fails to clean.
    clean               => { FILES => ' PDL-IO-Matlab-* Matlab.* tst.mat testf.mat ' . 
                                 $matio_top_level . '/test/atconfig' },
);
%hash = (%hash, %more_items);
$hash{INC} .= $inc;
$hash{LIBS}[0] .= $libs;

sub MY::postamble {   qq{

matio_obj\$(OBJ_EXT):
	cd $matio_top_level; cd src; \$(MAKE)
	ld -r -o matio_obj\$(OBJ_EXT) $matio_top_level/src/.libs/*\$(OBJ_EXT)

cleanall: clean
	cd $matio_top_level; \$(MAKE) clean

distcleanall: distclean
	cd $matio_top_level; \$(MAKE) distclean

}  . pdlpp_postamble($matlab_package)};


WriteMakefile( %hash );


if(exists $ARGV[0] && $ARGV[0] eq 'README.pod')
{
  print STDERR "Writing README.pod\n";
  open README, '>README.pod'  or die "Couldn't open README.pod";
#  print README $POD_header;

  foreach my $mod  ('Matlab.pm') {
      open MOD, $mod or die "Couldn't open main module";
      while (<MOD>)
      {
          if (/^=/../^=cut/)
          { print README; }
      }
      close(MOD);
  }
  close(README);
}
