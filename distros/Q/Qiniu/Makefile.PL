use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Qiniu',
  VERSION_FROM => 'lib/Qiniu.pm',
  ABSTRACT     => 'Perl 版七牛云存储 API',
  AUTHOR       => 'fukai (扶凯) <iakuf@163.com>',
  LICENSE      => 'perl',
  DISTNAME     => 'Qiniu',
  META_MERGE   => {
    requires  => {perl => '5.010001'},
    resources => {
      bugtracker => 'https://github.com/iakuf/Qiniu/issues',
      repository => 'https://github.com/iakuf/Qiniu.git',
    },
    no_index => {directory => ['t']},
  },
  dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean               => { FILES => 'Qiniu-*' },
  PREREQ_PM => {
    'Mojolicious' => '0',
    'Moo' => '0',
	'Digest::SHA' => 0,
	'MIME::Base64' => 0,
  },
);
