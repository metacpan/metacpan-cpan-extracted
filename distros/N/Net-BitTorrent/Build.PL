#!/usr/bin/perl -w
use strict;
use warnings;
use File::Find;
use Module::Build;
use Config;
$|++;
my $automated_testing = $ENV{q[AUTOMATED_TESTING]}
    || $ENV{q[PERL_MM_USE_DEFAULT]};
my $is_developer = ((-d q[.git]) ? 1 : 0) or ($ENV{RELEASE_TESTING} ? 1 : 0);
my $okay_tcp     = okay_tcp();
my $okay_udp     = okay_udp();
my @tests;
find \&find_cb, qw[t/000_miniswarm/ t/700_classes/];
@tests = reverse sort @tests;
printf $okay_tcp || $okay_udp
    ? <<'FTW': <<'FAIL', map { $_ ? 'En' : 'Dis' } ($okay_tcp, $okay_udp);
 ****************************************************************************
   During the test phase, we will be opening ports, contacting a tiny local
   tracker, and trading data to simulate actual swarms.  By design, the
   tests transfer only to the local system.

     - TCP tests are %sabled.
     - UDP tests are %sabled.

   NOTE: These tests may fail due to restrictive firewalling, solar flare
   activity, or other connectivity problems.
 ****************************************************************************
FTW
 ****************************************************************************
   Hrm... Your system seems to be misconfigured; an attempt to create a
   loopback has failed.  We'll work around this by skipping most of the
   socket-related tests.

     - TCP tests are %sabled.
     - UDP tests are %sabled.

   NOTE: Skipping these tests greatly reduces the usefullness of the
   Net::BitTorrent test suite and makes life (in general) difficult.
 ****************************************************************************
FAIL
use lib 'inc';
my $class
    = $is_developer ? 'MBX::Net::BitTorrent::Developer' : 'Module::Build';

if (!eval "require $class") {
    printf 'Failed to load %s: %s This ain\'t good, so... bye!', $class, $@;
    exit 0;
}
my $mb = $class->new(
    module_name       => q[Net::BitTorrent],
    license           => q[artistic_2],
    dist_author       => q[Sanko Robinson <sanko@cpan.org>],
    dist_abstract     => q[BitTorrent peer-to-peer protocol],
    dist_version_from => q[lib/Net/BitTorrent/Version.pm],
    requires          => {
                 q[Cwd]           => 0,
                 q[Data::Dumper]  => 0,
                 q[Digest::SHA]   => 5.45,
                 q[Errno]         => 0,
                 q[Exporter]      => 0,
                 q[Fcntl]         => 0,
                 q[File::Path]    => 0,
                 q[File::Spec]    => 0,
                 q[Math::BigInt]  => 1.78,
                 q[Module::Build] => 0.30,
                 q[perl]          => q[5.8.8],
                 q[Scalar::Util]  => 1.19,
                 q[Socket]        => 1.77,
                 q[Test::More]    => 0.80,
                 q[Time::HiRes]   => 0,
                 q[version]       => 0.74
    },
    build_requires => {q[Module::Build] => 0.30,
                       q[Test::More]    => 0.80
    },
    recommends => {q[Data::Dump]         => 0,
                   q[perl]               => q[5.10.0],
                   q[Math::Pari]         => 0,
                   q[Math::BigInt::Pari] => 0
    },
    auto_features => {
                 win32_utf8_support => {
                          description => q[Unicode filename support on Win32],
                          requires    => {
                                       q[Encode]         => 0,
                                       q[utf8]           => 0,
                                       q[Win32]          => 0,
                                       q[Win32API::File] => 0.10
                          }
                 },
                 improved_message_stream_encryption_speed => {
                     description =>
                         q[MSE-related calculations are significantly faster],
                     requires => {q[Math::Pari]         => 0,
                                  q[Math::BigInt::Pari] => 0
                     }
                 }
    },
    script_files => qw[scripts/net-bittorrent.pl],
    test_files   => \@tests,
    meta_merge   => {
        generated_by => q[Conversion, software version 7.0],
        keywords     => [
            qw[BitTorrent client peer p2p torrent socket
                DHT Kademlia exhange kad Mainline
                MSE stream encryption cryptography PHE PE
                DH D-H Diffie-Hellman key exchange
                RC4 ARC4 Alleged ARCFOUR
                ]
        ],
        no_index => {

            #directory => [qw[tatoeba]],
            file => [qw[scripts/net-bittorrent.pl]]
        },
        resources => {
             bugtracker => q[http://github.com/sanko/net-bittorrent/issues],
             ChangeLog =>
                 q[http://github.com/sanko/net-bittorrent/commits/master],
             homepage => q[http://sankorobinson.com/net-bittorrent/],
             license => q[http://www.perlfoundation.org/artistic_license_2_0],
             MailingList => q[http://groups.google.com/group/net-bittorrent],
             repository  => q[http://github.com/sanko/net-bittorrent/]
        }
    },
);
$mb->notes(okay_tcp          => $okay_tcp);
$mb->notes(okay_udp          => $okay_udp);
$mb->notes(automated_testing => $automated_testing ? 1 : 0);
$mb->notes(release_testing   => $is_developer);
$mb->notes(test_suite        => \@tests);
$mb->notes(gmtime            => gmtime);
$mb->notes(verbose => scalar grep {m[^v$]} keys %{$mb->args()});
$mb->notes(threads => $Config::Config{q[useithreads]} ? 1 : 0);
$mb->create_build_script;
exit 0;

sub okay_tcp {
    return 0 if not -f q[t/900_data/910_scripts/TCP-talk-to-ourself.pl];
    system(qq["$^X" t/900_data/910_scripts/TCP-talk-to-ourself.pl]);
    return $? ? 0 : 1;
}

sub okay_udp {
    return 0 if not -f q[t/900_data/910_scripts/UDP-talk-to-ourself.pl];
    system(qq["$^X" t/900_data/910_scripts/UDP-talk-to-ourself.pl]);
    return $? ? 0 : 1;
}

sub find_cb {
    return if -d $_ or -l $_;
    return unless -T $_;
    return unless $_ =~ m[.+\.t$];
    return push @tests, $File::Find::name;
}

BEGIN {    # Tired of getting FAIL-mail from outdated build environments
    if ($] < 5.008008) {    # already 3+ years old...
        warn sprintf
            q[Perl v5.8.8 required--this is only v%vd, stopped],
            $^V;
        exit 0;
    }
    if ($Module::Build::VERSION < 0.3) {
        warn sprintf
            q[Module::Build version 0.3 required--this is only version %s],
            $Module::Build::VERSION;
        exit 0;
    }
}
__END__
Copyright (C) 2008-2009 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it
under the terms of The Artistic License 2.0.  See the LICENSE file
included with this distribution or
http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by
the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

$Id: Build.PL 626ea33 2009-09-07 03:13:59Z sanko@cpan.org $
