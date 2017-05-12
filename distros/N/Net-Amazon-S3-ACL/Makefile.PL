use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Net::Amazon::S3::ACL',
   AUTHOR        => 'Flavio Poletti <flavio [at] polettix [dot] it>',
   VERSION_FROM  => 'lib/Net/Amazon/S3/ACL.pm',
   ABSTRACT_FROM => 'lib/Net/Amazon/S3/ACL.pm',
   PL_FILES      => {},
   PREREQ_PM     => {
      'Test::More'                => 0,
      'version'                   => 0,
      'Class::Accessor::Fast'     => 0,
      'XML::LibXML'               => 0,
      'XML::LibXML::XPathContext' => 0,
   },
   dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
   clean => {FILES    => 'Net-Amazon-S3-ACL-*'},
);
