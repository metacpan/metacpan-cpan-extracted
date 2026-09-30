use strict;
use warnings;

use Alien::ngtcp2 0.03 ();
use ExtUtils::MakeMaker;

my $cflags = join ' ', grep { defined && length }
    Alien::ngtcp2->cflags,
    Alien::ngtcp2->crypto_cflags;

sub _makemaker_libs {
    my ($flags) = @_;

    my @out;

    for my $token (split /\s+/, $flags) {
        next if !length $token;

        if ($token =~ m{\A(.+)/([^/]+)\.(a|lib)\z}i) {
            my ($dir, $name) = ($1, $2);

            $name =~ s/\Alib//;

            push @out, "-L$dir", "-l$name";
            next;
        }

        push @out, $token;
    }

    return join ' ', @out;
}

my $libs = _makemaker_libs(
    join ' ', grep { defined && length }
        Alien::ngtcp2->libs,
        Alien::ngtcp2->crypto_libs,
);

WriteMakefile(
    NAME             => 'Net::QUIC',
    VERSION_FROM     => 'lib/Net/QUIC.pm',
    ABSTRACT_FROM    => 'lib/Net/QUIC.pm',
    AUTHOR           => 'Joshua S. Day <haxmeister@hotmail.com>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.020',

    CONFIGURE_REQUIRES => {
        'Alien::ngtcp2'       => '0.03',
        'ExtUtils::MakeMaker' => 0,
    },

    PREREQ_PM => {
        'Alien::ngtcp2'        => '0.03',
        'Carp'                 => 0,
        'Hash::Util::FieldHash' => 0,
        'Scalar::Util'         => 0,
        'XSLoader'             => 0,
    },

    TEST_REQUIRES => {
        'File::Temp'       => 0,
        'FindBin'          => 0,
        'IO::Select'       => 0,
        'IO::Socket::INET' => 0,
        'Socket'           => 0,
        'Test2::V0'        => 0,
        'Time::HiRes'      => 0,
    },

    INC    => $cflags,
    LIBS   => [$libs],

    META_MERGE => {
        'meta-spec' => {
            version => 2,
        },
        provides => {
            'Net::QUIC' => {
                file    => 'lib/Net/QUIC.pm',
                version => MM->parse_version('lib/Net/QUIC.pm'),
            },
            'Net::QUIC::Datagram' => {
                file    => 'lib/Net/QUIC/Datagram.pm',
                version => MM->parse_version('lib/Net/QUIC/Datagram.pm'),
            },
            'Net::QUIC::Connection' => {
                file    => 'lib/Net/QUIC/Connection.pm',
                version => MM->parse_version('lib/Net/QUIC/Connection.pm'),
            },
            'Net::QUIC::Endpoint' => {
                file    => 'lib/Net/QUIC/Endpoint.pm',
                version => MM->parse_version('lib/Net/QUIC/Endpoint.pm'),
            },
            'Net::QUIC::Driver' => {
                file    => 'lib/Net/QUIC/Driver.pm',
                version => MM->parse_version('lib/Net/QUIC/Driver.pm'),
            },
            'Net::QUIC::Stream' => {
                file    => 'lib/Net/QUIC/Stream.pm',
                version => MM->parse_version('lib/Net/QUIC/Stream.pm'),
            },
        },
        resources => {
            homepage => 'https://github.com/haxmeister/perl-Net-QUIC',
            repository => {
                type => 'git',
                url  => 'https://github.com/haxmeister/perl-Net-QUIC.git',
                web  => 'https://github.com/haxmeister/perl-Net-QUIC',
            },
            bugtracker => {
                web => 'https://github.com/haxmeister/perl-Net-QUIC/issues',
            },
        },
    },
);
