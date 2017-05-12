use strict;
use warnings;
use ExtUtils::MakeMaker;

my $thispackage = q(PDLA::IO::HDF::VS);
my $package = [ qw(VS.pd VS), $thispackage ];

my $pdla = eval { require PDLA::Core::Dev };

my %pkghash;
# so can output its deps at least
eval {
  require ExtUtils::Depends;
  my $pkg = ExtUtils::Depends->new($thispackage, qw(Alien::HDF4));
  $pkg->set_inc(PDLA::Core::Dev::PDLA_INCLUDE()) if $pdla;
  $pkg->add_typemaps(PDLA::Core::Dev::PDLA_TYPEMAP()) if $pdla;
  $pkg->add_pm(
      'VS.pm' => '$(INST_LIBDIR)/VS.pm',
  );
  %pkghash = $pkg->get_makefile_vars;
};

undef &MY::postamble; # suppress warning
*MY::postamble = sub { PDLA::Core::Dev::pdlpp_postamble($package); } if $pdla;

WriteMakefile(
    NAME => $thispackage,
    OBJECT => 'VS.o ',
    %pkghash,
    clean => {
        FILES => 'VS.pm VS.xs VS.o VS.c',
    },
    dist => { 
        COMPRESS => 'gzip', 
        SUFFIX => 'gz'
    }, 
    (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
);
