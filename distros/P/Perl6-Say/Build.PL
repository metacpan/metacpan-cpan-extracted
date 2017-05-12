use strict;
use Module::Build;
#created by eumm-migrate.pl

my $build = Module::Build->new(
  'dist_abstract' => '\'print\' -- but no newline needed',
  'auto_configure_requires' => 0,
  'license' => 'perl',
  'dist_author' => 'Alexandr Ciornii (alexchorny@gmail.com)',
  'module_name' => 'Perl6::Say',
  'requires' => {
    'perl' => '5.008',
    'Scalar::Util' => '1.07',
    'Test::More' => '0.44',
    'IO::Handle' => 0,
    'Carp' => 0
  },
  'meta_merge' => {
    'resources' => {
      'repository' => 'http://github.com/chorny/Perl6-Say'
    }
  },
  'dist_version_from' => 'lib/Perl6/Say.pm'
);

$build->create_build_script();
