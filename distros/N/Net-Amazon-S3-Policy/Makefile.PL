use strict;
use warnings;
use ExtUtils::MakeMaker 6.48;

WriteMakefile(
   NAME          => 'Net::Amazon::S3::Policy',
   AUTHOR        => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   VERSION_FROM  => 'lib/Net/Amazon/S3/Policy.pm',
   ABSTRACT_FROM => 'lib/Net/Amazon/S3/Policy.pm',
   PL_FILES      => {},
   PREREQ_PM     => {
      'Test::More' => 0,
      'version'    => 0,
      'JSON'       => '2.0',
      'ExtUtils::MakeMaker' => '6.048000',
   },
   MIN_PERL_VERSION => '5.008000',
   dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
   clean => {FILES    => 'Net-Amazon-S3-Policy-*'},
);
