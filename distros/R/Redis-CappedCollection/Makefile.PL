use 5.010;
use strict;
use warnings;

use File::Basename;
use ExtUtils::MakeMaker qw( prompt );

my %config = (
    NAME                        => 'Redis::CappedCollection',
    VERSION_FROM                => 'lib/Redis/CappedCollection.pm',
    MIN_PERL_VERSION            => '5.010',
# more to the list $Module::CoreList::version{5.010}
    PREREQ_PM                   => {
        'Const::Fast'           => '0.014',
        'Digest::SHA1'          => '2.13',
        'Mouse'                 => 0,
        'Params::Util'          => '1.07',
        'Redis'                 => '1.976',
        'Try::Tiny'             => '0.18',
        },
    TEST_REQUIRES               => {
        'Data::UUID'            => '1.217',
        'JSON::XS'              => '3.01',
        'Net::EmptyPort'        => '0',
        'Sys::SigAction'        => '0.21',
        'Test::Exception'       => '0.31',
        'Test::NoWarnings'      => '1.04',
        'Test::RedisServer'     => '0.04',
        },
    META_MERGE          => {
        no_index                => {
            directory               => [
#                't',
#                'inc',
                'xt',
            ]
        },
        provides                => {
            'Redis::CappedCollection'   => {
                file                        => 'lib/Redis/CappedCollection.pm',
                version                     => '1.10'
            },
            'Redis::CappedCollection::Util' => {
                file                        => 'lib/Redis/CappedCollection/Util.pm',
                version                     => '1.10'
            },
        },
        'meta-spec'             => { version => 2 },
        resources               => {
            bugtracker              => {
               web                      => 'https://github.com/TrackingSoft/Redis-CappedCollection/issues',
            },
            homepage                => 'https://github.com/TrackingSoft/Redis-CappedCollection',
            repository              => {
                type                    => 'git',
                url                     => 'git://github.com/TrackingSoft/Redis-CappedCollection.git',
                web                     => 'http://github.com/TrackingSoft/Redis-CappedCollection',
            },
        },
    },
    ( $] >= 5.005 ?
        (
        ABSTRACT        => 'Redis::CappedCollection module provides the fixed sized collections that have a auto-FIFO age-out feature.',
        AUTHOR          => 'TrackingSoft LLC <sgladkov@trackingsoft.com>'
        ) : ()
    ),
    dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean       => { FILES => "Debian_CPANTS.txt Redis-*.tar.gz" },
    LICENSE     => 'perl',
#    NO_MYMETA   => 1,
);

my @patterns = qw( t/*.t t/*/*.t );
$config{test} = { TESTS => join ' ', map { glob } @patterns };

if( $ENV{AUTHOR_TESTS} ) {
    @patterns = qw( xt/author/*.t xt/author/*/*.t );
    $config{test}->{TESTS} .= ' '.join ' ', map { glob } @patterns;
}

if( $ENV{RELEASE_TESTS} ) {
    @patterns = qw( xt/release/*.t xt/release/*/*.t );
    $config{test}->{TESTS} .= ' '.join ' ', map { glob } @patterns;
}

mkdir 'inc' unless -d 'inc';

ExtUtils::MakeMaker::WriteMakefile( %config );
