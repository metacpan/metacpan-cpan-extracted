package Sys::Info::Driver::Linux::OS::Distribution::Conf;
$Sys::Info::Driver::Linux::OS::Distribution::Conf::VERSION = '0.7905';
use strict;
use warnings;
use base qw( Exporter );
use Config::General ();

our @EXPORT  = qw( %CONF );

our %CONF = Config::General::ParseConfig( -String => <<'RAW' );
# Some parts of this data set was initially taken from Wikipedia

<adamantix>
    release_derived = adamantix_version
</adamantix>

<arch>
    release = arch-release
</arch>

<centos>
    manufacturer  = Lance Davis
    release       = redhat-release
    version_match = CentOS(?: Linux)? release (.*) \(
</centos>

<conectiva>
    release_derived = conectiva-release
</conectiva>

<debian>
    manufacturer  = Debian Project
    version_match = (.+)
    release = debian_version
    release = debian_release
    <edition>
           1.1  = buzz
           1.2  = rex
           1.3  = bo
           2.0  = hamm
           2.1  = slink
           2.2  = potato
           3.0  = woody
           3.1  = sarge
           4.0  = etch
           5.0  = lenny
           6.0  = squeeze
           7.0  = wheezy
    </edition>
    # we get the version as "lenny/sid" for example
    <vfix>
        buzz    = 1.1
        rex     = 1.2
        bo      = 1.3
        hamm    = 2.0
        slink   = 2.1
        potato  = 2.2
        woody   = 3.0
        sarge   = 3.1
        etch    = 4.0
        lenny   = 5.0
        squeeze = 6.0
        wheezy  = 7.0
    </vfix>
</debian>

<fedora>
    manufacturer    = Fedora Project
    version_match   = Fedora (?:Core )?release (\d+) \(
    release_derived = fedora-release
    <edition>
           1    = Yarrow
           2    = Tettnang
           3    = Heidelberg
           4    = Stentz
           5    = Bordeaux
           6    = Zod
           7    = Moonshine
           8    = Werewolf
           9    = Sulphur
          10    = Cambridge
          11    = Leonidas
          12    = Constantine
          13    = Goddard
          14    = Laughlin
          15    = Lovelock
          16    = Verne
          17    = Beefy Miracle
    </edition>
</fedora>

<gentoo>
    manufacturer  = Gentoo Foundation
    version_match = Gentoo Base System version (.*)
    release       = gentoo-release
</gentoo>

<immunix>
    release_derived = immunix-release
</immunix>

<knoppix>
    manufacturer  = Klaus Knopper
    release_derived = knoppix-version
</knoppix>

<libranet>
    release_derived = libranet_version
</libranet>

<mandrake>
    release = mandrake-release
    release = mandrakelinux-release
</mandrake>

<mandriva>
    manufacturer  = Mandriva
    <edition>
           5.1  = Venice
           5.2  = Leeloo
           5.3  = Festen
           6.0  = Venus
           6.1  = Helios
           7.0  = Air
           7.1  = Helium
           7.2  = Odyssey
           8.0  = Traktopel
           8.1  = Vitamin
           8.2  = Bluebird
           9.0  = Dolphin
           9.1  = Bamboo
           9.2  = FiveStar
          10.0  = Community
          10.1  = Community
          10.2  = Limited Edition 2005
        2006.0  = 2006
        2007    = 2007
        2007.1  = 2007 Spring
        2008.0  = 2008
        2008.1  = 2008 Spring
        2009.0  = 2009
        2009.1  = 2009 Spring
        2010.0  = 2010
        2010.1  = 2010 Spring
        2010.2  = 2010.2
        2011.0  = Hydrogen
    </edition>
</mandriva>

<redflag>
    version_match = Red Flag (?:Desktop|Linux) (?:release |\()(.*?)(?: \(.+)?\)
    release_derived = redflag-release
</redflag>

<redhat>
    manufacturer  = Red Hat, Inc.
    version_match = Red Hat (?:Enterprise )?Linux (?:Server )release (.*) \(
    release = redhat-release
    release = redhat_version
    use_codename_for_edition = 1
</redhat>

<pardus>
    version_match = \APardus (.+)\z
    release_derived = pardus-release
</pardus>

<slackware>
    manufacturer  = Patrick Volkerding
    version_match = \ASlackware (.+)\z
    release = slackware-version
    release = slackware-release
</slackware>

<suse>
    name          = SUSE
    manufacturer  = Novell
    version_match = VERSION = (.*)
    release       = SuSE-release
</suse>

<tinysofa>
    release_derived = tinysofa-release
</tinysofa>

<trustix>
    release_derived = trustix-release
</trustix>

<turbolinux>
    release_derived = turbolinux-release
</turbolinux>

<ubuntu>
    manufacturer  = Canonical Ltd. / Ubuntu Foundation
    <edition>
           4.10 = Warty Warthog
           5.04 = Hoary Hedgehog
           5.10 = Breezy Badger
           6.06 = Dapper Drake
           6.10 = Edgy Eft
           7.04 = Feisty Fawn
           7.10 = Gutsy Gibbon
           8.04 = Hardy Heron
           8.10 = Intrepid Ibex
           9.04 = Jaunty Jackalope
           9.10 = Karmic Koala
          10.04 = Lucid Lynx
          10.10 = Maverick Meerkat
          11.04 = Natty Narwhal
          11.10 = Oneiric Ocelot
          12.04 = Precise Pangolin
          12.10 = Quantal Quetzal
          13.04 = Raring Ringtail
          13.10 = Saucy Salamander
          14.04 = Trusty Tahr
          14.10 = Utopic Unicorn
          15.04 = Vivid Vervet
          15.10 = Wily Werewolf
          16.04 = Xenial Xerus
          16.10 = Yakkety Yak
          17.04 = Zesty Zapus
          17.10 = Artful Aardvark
          18.04 = Bionic Beaver
          18.10 = Cosmic Cuttlefish
          19.04 = Disco Dingo
    </edition>
</ubuntu>

<va-linux>
    release_derived = va-release
</va-linux>

<yellowdog>
    release_derived = yellowdog-release
</yellowdog>

<yoper>
    release_derived = yoper-release
</yoper>

RAW

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Driver::Linux::OS::Distribution::Conf

=head1 VERSION

version 0.7905

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 NAME

Sys::Info::Driver::Linux::OS::Distribution::Conf - Distro configuration

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
