use 5.014;
use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN {
    eval "use File::ShareDir::Install;";
    $@ and return 0;
}

use File::ShareDir::Install;
install_share dist => "share";

WriteMakefile(
    NAME               => 'Quant::Framework',
    AUTHOR             => q{Binary.com <support@binary.com>},
    VERSION_FROM       => 'lib/Quant/Framework.pm',
    ABSTRACT_FROM      => 'lib/Quant/Framework.pm',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES => {
        'Moose'                     => 0,
        'YAML::XS'                  => 0,
        'File::ShareDir'            => 0,
        'Test::More'                => 0,
        'Test::CheckManifest'       => 1.29,
        'Test::Exception'           => 0,
        'Test::MockModule'          => 0,
        'Test::MockObject::Extends' => 0,
        'Test::NoWarnings'          => 0,
        'Date::Utility'             => 0,
        'Data::Chronicle::Writer'   => 0,
        'Data::Chronicle::Reader'   => 0,
        'Data::Chronicle::Mock'     => 0,
        'Format::Util::Numbers'     => 0,
    },
    PREREQ_PM => {
        'Moose'                         => 0,
        'Test::Syntax::Aggregate'       => 0,
        'YAML::XS'                      => 0,
        'File::Find::Rule'              => 0,
        'Test::Strict'                  => 0,
        'File::ShareDir'                => 0,
        'Math::Function::Interpolator', => 0,
        'Date::Utility'                 => 0,
        'Data::Chronicle::Writer'       => 0,
        'Data::Chronicle::Reader'       => 0,
        'Time::Duration::Concise'       => 0,
        'Memoize'                       => 0,
        'Memoize::HashKey::Ignore'      => 0,
        'List::Util'                    => 0,
        'List::MoreUtils'               => 0,
        'Try::Tiny'                     => 0,
        'Storable'                      => 0,
        'Number::Closest::XS'           => 0,
        'Scalar::Util'                  => 0,
        'Text::SimpleTable'             => 0,
        'Text::CSV'                     => 0,
        'Scalar::Util::Numeric'         => 0,
        'Math::Business::BlackScholes::Binaries' => 0,
        'Carp'                          => 0,
        'Digest::MD5'                   => 0,
        'VolSurface::Utils'             => 0,
        'Clone'                         => 0,
        'MooseX::StrictConstructor'     => 0,
        'Cache::RedisDB'                => 0,
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'Quant-Framework-*'},
    test => { 
      RECURSIVE_TEST_FILES => 1,
    },
);

{
    package MY;
    use File::ShareDir::Install qw(postamble);
}
