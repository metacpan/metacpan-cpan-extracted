use strict;
use warnings;
use ExtUtils::MakeMaker;

my $thispackage = q(PDLA::IO::HDF);

my %pkghash;
# so can output its deps at least
eval {
  require ExtUtils::Depends;
  my $pkg = ExtUtils::Depends->new($thispackage, qw(Alien::HDF4));
  $pkg->set_inc(PDLA_INCLUDE());
  $pkg->add_typemaps(PDLA_TYPEMAP());
  $pkg->add_pm(
      'HDF.pm' => '$(INST_LIBDIR)/HDF.pm',
  );
  %pkghash = $pkg->get_makefile_vars;
};

my @coredep = ('PDLA::Core' => '2.019100');

WriteMakefile(
    NAME => $thispackage,
    VERSION_FROM => 'HDF.pm',
    %pkghash,
    'META_MERGE' => {
        "meta-spec" => { version => 2 },
        resources => {
            homepage => 'http://pdlporters.github.io',
            bugtracker  => {web=>'https://github.com/PDLPorters/pdla-io-hdf/issues'},
            repository  => {
                url => 'git://github.com/PDLPorters/pdla-io-hdf',
                type => 'git',
                web => 'https://github.com/PDLPorters/pdla-io-hdf',
            },
        },
    },
    'CONFIGURE_REQUIRES' => {
      'ExtUtils::MakeMaker' => 0,
      'ExtUtils::Depends' => '0.402',
      'Alien::HDF4' => 0,
      @coredep,
    },
    'BUILD_REQUIRES' => {
      @coredep,
    },
    'TEST_REQUIRES' => {
      'Test::More' => 0,
    },
);
