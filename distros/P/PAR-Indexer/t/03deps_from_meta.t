use strict;
use warnings;
use Test::More tests => 11;
BEGIN { use_ok('PAR::Indexer') };
use File::Spec;

my @tests = (
  {
    name => 'all undef',
    meta => undef,
    result => undef,
  },
  {
    name => 'Alien-wxWidgets meta',
    meta => {
          'meta-spec' => {
                           'version' => '1.2',
                           'url' => 'http://module-build.sourceforge.net/META-spec-v1.2.html'
                         },
          'generated_by' => 'Module::Build version 0.3',
          'version' => '0.42',
          'name' => 'Alien-wxWidgets',
          'build_requires' => {
                                'Module::Build' => '0.28',
                                'ExtUtils::CBuilder' => '0.24'
                              },
          'provides' => {
                          'Alien::wxWidgets' => {
                                                  'version' => '0.42',
                                                  'file' => 'lib/Alien/wxWidgets.pm'
                                                },
                          'Alien::wxWidgets::Utility' => {
                                                           'file' => 'lib/Alien/wxWidgets/Utility.pm'
                                                         }
                        },
          'requires' => {
                          'perl' => '5.006',
                          'Module::Pluggable' => '2.6'
                        },
          'configure_requires' => {
                                    'Module::Build' => '0.28'
                                  }
        },
    result => {
      perl => '5.006',
      'Module::Pluggable' => '2.6',
      'Module::Build' => '0.28',
      'ExtUtils::CBuilder' => '0.24',
    },
  },
  {
    name => 'meta with collision req > conf req',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          'requires' => {
                          'AutoXS::Header' => '0.02'
                        },
          'configure_requires' => {
            'AutoXS::Header' => '0.01',
          },
        },
    result => {
      'AutoXS::Header' => '0.02',
    },
  },
  {
    name => 'meta with collision req > build req',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          'requires' => {
                          'AutoXS::Header' => '0.02'
                        },
          'build_requires' => {
            'AutoXS::Header' => '0.01',
          },
        },
    result => {
      'AutoXS::Header' => '0.02',
    },
  },
  {
    name => 'meta with collision build req > conf req',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          'build_requires' => {
                          'AutoXS::Header' => '0.02'
                        },
          'configure_requires' => {
            'AutoXS::Header' => '0.01',
          },
        },
    result => {
      'AutoXS::Header' => '0.02',
    },
  },
  {
    name => 'meta with collision req > build req > conf req',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          'requires' => {
                          'AutoXS::Header' => '0.02'
                        },
          'configure_requires' => {
            'AutoXS::Header' => '0.01',
          },
          'build_requires' => {
            'AutoXS::Header' => '0.01',
          },
        },
    result => {
      'AutoXS::Header' => '0.02',
    },
  },
  {
    name => 'meta without requires',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
        },
    result => undef,
  },
  {
    name => 'meta with empty requires',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          requires => {},
        },
    result => {},
  },
  {
    name => 'meta with empty configure_requires',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          configure_requires => {},
        },
    result => {},
  },
  {
    name => 'meta with empty build_requires',
    meta => {
          'version' => '0.14',
          'name' => 'Class-XSAccessor-Array',
          'license' => 'perl',
          build_requires => {},
        },
    result => {},
  },
);

foreach my $test (@tests) {
  my $name = $test->{name};
  my $meta = $test->{meta};
  my $exp_result = $test->{result};

  my $result;
  my $okay = eval { $result = PAR::Indexer::dependencies_from_meta_yml($meta); 1; };

  if ($test->{exception}) {
    ok(!$okay || $@, "test '$name' threw exception");
  }
  elsif ($@) {
    fail("test '$name' threw unexpected exception");
    diag("Error: $@");
  }
  else {
    is_deeply($result, $exp_result, "test '$name' has expected result");
  }
}

