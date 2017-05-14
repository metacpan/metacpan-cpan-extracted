use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'Ali::OSS',
    VERSION_FROM => 'lib/OSS.pm', # finds $VERSION
    PREREQ_PM => {
	'Encode' =>0,
	'utf8'   =>0,
	'Digest::HMAC_SHA1' => 0,
	'MIME::Base64' =>0,
	'LWP::UserAgent'=>0,
	'POSIX' =>0,
    'Carp' => 0,
    'Http::Date'=>0,
    'HTTP::Headers'=>0,
    'XML::Simple'=>0,
    },
    ($] >= 5.005 ? ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/OSS.pm', # retrieve abstract from module
       AUTHOR => 'Crisewang <crisewng@gmail.com>') : ()),
);
