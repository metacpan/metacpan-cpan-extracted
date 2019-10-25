use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;

use constant LIBRDKAFKA_MIN_VERSION => "1.0.0";

# If you have a local librdkafka installation and you want to use that instead
# of the system-wide, do something like:
# PKG_CONFIG_PATH=/usr/local/lib/pkgconfig perl Makefile.PL
# or whatever is the actual installation path
my %rdkafka = ExtUtils::PkgConfig->find( 'rdkafka' );

warn sprintf(
    "WARNING: Installed librdkafka version %s is lower than tested %s",
    $rdkafka{modversion},
    LIBRDKAFKA_MIN_VERSION
) if $rdkafka{modversion} lt LIBRDKAFKA_MIN_VERSION;

print "Compiling Net::Kafka with librdkafka $rdkafka{modversion}\n\n";

my $preop = 'perl -MPod::Markdown -e \'Pod::Markdown->new->filter(@ARGV)\' $(VERSION_FROM) | tee $(DISTVNAME)/README.md > README.md;' .
            'pod2readme $(VERSION_FROM) $(DISTVNAME)/README';

WriteMakefile(
    NAME          => 'Net::Kafka',
    DISTNAME      => 'Net-Kafka',
    AUTHOR        => [
        'Rajesh Amradi <rajesh.amradi@booking.com>',
        'Michael Austin <michael.austin@booking.com>',
        'Ankit Bhatnagar <ankit.bhatnagar@booking.com>',
        'Jaap Eldering <jaap.eldering@booking.com>',
        'Osama Elsayed <osama.elsayed@booking.com>',
        'Eduardo Dalla Favera <eduardo.dallafavera@booking.com>',
        'Pavel Gurkov <pavel.gurkov@booking.com>',
        'Przemysław Iskra <sparky@pld-linux.org>',
        'Alex Mironov <alex.mironov@booking.com>',
        'Pavel Shaydo <zwon@cpan.org>',
    ],
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Net/Kafka.pm',
    ABSTRACT_FROM => 'lib/Net/Kafka.pm',
    LIBS          => [ "-lrdkafka -lpthread" ],
    OBJECT        => '$(O_FILES)',
    TYPEMAPS      => ['typemap'],
    PREREQ_PM           => {
        'AnyEvent'               => 0,
        'Test::More'             => 0,
        'AnyEvent::XSPromises'   => 0,
    },
    dist          => {
        PREOP => $preop,
    },
    META_MERGE    => {
        "meta-spec" => { version => 2 },
        resources => {
            homepage    => 'https://github.com/bookingcom/perl-Net-Kafka',
            bugtracker  => {
                web => 'https://github.com/bookingcom/perl-Net-Kafka/issues'
            },
            repository => {
                type    => 'git',
                url     => 'https://github.com/bookingcom/perl-Net-Kafka.git',
                web     => 'https://github.com/bookingcom/perl-Net-Kafka',
            },
        },
    },
    CONFIGURE_REQUIRES  => {
        'ExtUtils::MakeMaker' => 0,
        'ExtUtils::PkgConfig' => 0,
    },
);
