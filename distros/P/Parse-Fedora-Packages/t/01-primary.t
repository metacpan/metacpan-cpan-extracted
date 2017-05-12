#!/usr/bin/perl
use strict;
use warnings;


use Data::Dumper qw(Dumper);
use Test::More;
use Test::NoWarnings;

my $tests;
plan tests => $tests+1;

use_ok('Parse::Fedora::Packages');

my $p = Parse::Fedora::Packages->new;
isa_ok($p, 'Parse::Fedora::Packages');
BEGIN { $tests += 2; }

$p->parse_primary('t/files/primary.xml');
diag $p->count_packages;
is($p->reported_count_packages, 4, "number of packages is correct");
is($p->count_packages, 4, "number of packages is correct");
BEGIN { $tests += 2; }

{
    my @all = $p->list_packages();
    my $expected = [
          {
            'summary' => 'Enterprise Security Client Smart Card Client',
            'version' => '1.0.0',
            'url' => 'http://directory.fedora.redhat.com/wiki/CoolKey',
            'name' => 'esc',
            'description' => 'Enterprise Security Client allows the user to enroll and manage their cryptographic smartcards.'
          },
          {
            'summary' => 'Development tools for programs which will use the netpbm libraries.',
            'version' => '10.35',
            'url' => 'http://netpbm.sourceforge.net/',
            'name' => 'netpbm-devel',
            'description' => 'The netpbm-devel package contains the header files and static libraries, etc., for developing programs which can handle the various graphics file formats supported by the netpbm libraries.  Install netpbm-devel if you want to develop programs for handling the graphics file formats supported by the netpbm libraries.  You\'ll also need to have the netpbm package installed.'
          },
          {
            'summary' => 'Perl Object interface for AF_INET|AF_INET6 domain sockets',
            'version' => '2.51',
            'url' => 'http://search.cpan.org/~mondejar/IO-Socket-INET6/',
            'name' => 'perl-IO-Socket-INET6',
            'description' => 'Perl Object interface for AF_INET|AF_INET6 domain sockets'
          },
          {
            'summary' => 'K Desktop Environment - Utilities',
            'version' => '3.5.4',
            'url' => 'http://www.kde.org',
            'name' => 'kdeutils',
            'description' => 'Utilities for the K Desktop Environment. Includes: ark (tar/gzip archive manager); kcalc (scientific calculator); kcharselect (character selector); kdepasswd (change password); kdessh (ssh front end); kdf (view disk usage); kedit (simple text editor); kfloppy (floppy formatting tool); khexedit (hex editor); kjots (note taker); klaptopdaemon (battery monitoring and management for laptops); ksim (system information monitor); ktimer (task scheduler); kwikdisk (removable media utility)'
          }
        ];

    is_deeply(\@all, $expected);
    BEGIN { $tests += 1; }
}

{
    my @all = $p->list_packages(name => 'perl');
    my $expected = [
          {
            'summary' => 'Perl Object interface for AF_INET|AF_INET6 domain sockets',
            'version' => '2.51',
            'url' => 'http://search.cpan.org/~mondejar/IO-Socket-INET6/',
            'name' => 'perl-IO-Socket-INET6',
            'description' => 'Perl Object interface for AF_INET|AF_INET6 domain sockets'
          }
        ];
    is_deeply(\@all, $expected);
    BEGIN { $tests += 1; }
}




