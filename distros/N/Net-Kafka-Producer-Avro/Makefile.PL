#!/usr/bin/env perl

use strict;
use warnings;
use 5.010;

use ExtUtils::MakeMaker;

if ( $^O eq 'MSWin32' || $^O eq 'solaris' ||  $^O eq 'cygwin' ) {
    print STDERR "OS unsupported: $^O\n";
    exit( 255 );
}

my $package = 'Net::Kafka::Producer::Avro';
my $path_to_package = 'lib/Net/Kafka/Producer/Avro.pm';

`perldoc -uT $path_to_package | pod2text - README`;
`perldoc -uT $path_to_package | pod2markdown - README.md`; # useful for GitHub repo home

my %config = (
    NAME                => $package,
    VERSION_FROM        => $path_to_package,  # finds $VERSION
    MIN_PERL_VERSION    => '5.010',
    PREREQ_PM           => {            # more to the list $Module::CoreList::version{5.010}
		'JSON::XS'					=> 'v4.30.0',
		'Net::Kafka::Producer'		=> '0',
		'Avro::BinaryEncoder'		=> 'v1.12.1',
		'Avro::Schema'				=> 'v1.12.1',
		'Confluent::SchemaRegistry'	=> 'v1.0.0',
        'Memoize'                   => '0',
        'Try::Tiny'                 => '0',
    },
    TEST_REQUIRES       => {            # more to the list $Module::CoreList::version{5.010}
		'Math::BigInt'				=> '1.89',
		'Test::Exception'			=> '0.43',
        'Time::HiRes'               => '0'
    },
    META_MERGE          => {
        no_index                => {
            directory               => [
                't',
                'inc',
            ]
        },
        'meta-spec'             => { version => 2 },
        resources               => {
            bugtracker              => {
               web                      => 'https://github.com/alivraghi/Net-Kafka-Producer-Avro/issues',
            },
            homepage                => 'https://github.com/alivraghi/Net-Kafka-Producer-Avro',
            repository              => {
                type                    => 'git',
                url                     => 'git@github.com/Net-Kafka-Producer-Avro.git',
                web                     => 'https://github.com/alivraghi/Net-Kafka-Producer-Avro.git',
            },
        },
    },
    ( $] >= 5.005 ?                             ## Add these new keywords supported since 5.005
        (
            ABSTRACT            => 'Apache Kafka message producer based on librdkafka, Avro serialization and Confluent Schema Registry validation.',
            AUTHOR              => 'Alvaro Livraghi',
        ) : ()
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    realclean           => { FILES => "inc Net-Kafka-Producer-Avro-*.tar.gz" },
    LICENSE             => 'perl',
#    NO_MYMETA           => 1,
);

ExtUtils::MakeMaker::WriteMakefile( %config );
