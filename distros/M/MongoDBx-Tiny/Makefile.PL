use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MongoDBx::Tiny',
    AUTHOR              => q{Naoto ISHIKAWA <toona at seesaa.co.jp>},
    VERSION_FROM        => 'lib/MongoDBx/Tiny.pm',
    ABSTRACT_FROM       => 'lib/MongoDBx/Tiny.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	"Carp" => 0,
	"Class::Trigger" => 0,
	"Data::Dumper" => 0,
	"Digest::SHA" => 0,
	"IO::File" => 0,
	"MongoDB" => 0,
	"Params::Validate" => 0,
	"Scalar::Util"  => 0,
	"Tie::IxHash" => 0,
        "Test::More" => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MongoDBx-Tiny-*' },
);
