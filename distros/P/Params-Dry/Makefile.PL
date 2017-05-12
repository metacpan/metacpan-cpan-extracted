use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Params::Dry',
    AUTHOR           => q{Pawel Guspiel <neo@cpan.org>},
    VERSION_FROM     => 'lib/Params/Dry.pm',
    ABSTRACT_FROM    => 'lib/Params/Dry.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Most' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Exporter' => 0,
        'Scalar::Util' => 0,
    },
    META_MERGE        => {
        "provides" => {
            "Params::Dry" => {
                "file" => "lib/Params/Dry.pm",
                "version" => "1.2003"
            },
            "Params::Dry::Types" => {
                "file" => "lib/Params/Dry/Types.pm",
                "version" => "1.2003"
            },
            "Params::Dry::Types::DateTime" => {
                "file" => "lib/Params/Dry/Types/DateTime.pm",
                "version" => "1.2003"
            },
            "Params::Dry::Types::Number" => {
                "file" => "lib/Params/Dry/Types/Number.pm",
                "version" => "1.2003"
            },
            "Params::Dry::Types::Object" => {
                "file" => "lib/Params/Dry/Types/Object.pm",
                "version" => "1.2003"
            },
            "Params::Dry::Types::Ref" => {
                "file" => "lib/Params/Dry/Types/Ref.pm",
                "version" => "1.2003"
            },
            "Params::Dry::Types::String" => {
                "file" => "lib/Params/Dry/Types/String.pm",
                "version" => "1.2003"
            }
        },
        "release_status" => "stable",
 
        "meta-spec" => { version => 2 },
        
        resources => {
            "license" => [
                "http://opensource.org/licenses/artistic-license-2.0.php"
            ],
        
            repository => {
                type => 'git',
                web => "https://github.com/neo77/Params-Dry",
                git => "git://github.com/neo77/Params-Dry.git",
            },
        
        },
        
    },
    
    
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Params-*' },

);
