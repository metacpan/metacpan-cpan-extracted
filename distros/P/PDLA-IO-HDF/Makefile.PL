use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc'; # for Inline::Module
use Inline::Module;

my $thispackage = q(PDLA::IO::HDF);

my %pkghash;
# so can output its deps at least
eval {
  require ExtUtils::Depends;
  my $pkg = ExtUtils::Depends->new($thispackage, qw(PDLA Alien::HDF4));
  $pkg->add_typemaps(PDLA_TYPEMAP());
  %pkghash = $pkg->get_makefile_vars;
};

my @coredep = (
  'PDLA::Core' => '2.019103',
  'Inline::Pdlapp' => '2.019104', # PACKAGE
);

WriteMakefile(
    NAME => $thispackage,
    VERSION_FROM => 'lib/PDLA/IO/HDF.pm',
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
      'Alien::HDF4' => '0.05',
      @coredep,
    },
    'BUILD_REQUIRES' => {
      @coredep,
    },
    'TEST_REQUIRES' => {
      'Test::More' => 0,
    },
    clean => { FILES => '.inline' },
    postamble => {
      inline => {
        module => [ qw(PDLA::IO::HDF::SD PDLA::IO::HDF::VS) ],
        ilsm => 'Inline::Pdlpp',
        bundle => 0,
      },
    },
);
