use ExtUtils::MakeMaker;
use strict;
use warnings;

my %runtime_reqs = (
  'perl' => '5.016',
  'parent' => 0,
  'FFI::Platypus' => 0,
  'FFI::CheckLib' => 0.06,
  'Sub::Util' => 0,
);

WriteMakefile(
  NAME => 'NativeCall',
  VERSION_FROM => 'lib/NativeCall.pm',
  ABSTRACT_FROM => 'lib/NativeCall.pm',
  AUTHOR => 'Ed J <etj@cpan.org>',
  LICENSE => 'perl',
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/mohawk2/nativecall',
        web => 'https://github.com/mohawk2/nativecall',
      },
    },
  },
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0 },
  TEST_REQUIRES => {
    'Test::More' => 0,
    %runtime_reqs,
  },
  PREREQ_PM => \%runtime_reqs,
);
