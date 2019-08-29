package Sys::HostIP;
$Sys::HostIP::VERSION = '2.120';
# ABSTRACT: Try extra hard to get IP address related info

use strict;
use warnings;

use Carp;
use Exporter;
use File::Basename 'dirname';
use parent 'Exporter';

our @EXPORT_OK = qw( ip ips interfaces ifconfig );

our $IS_WIN = $^O =~ qr/(MSWin32|cygwin)/xms; ## no critic qw(Variables::ProhibitPunctuationVars)

sub new { ## no critic qw(Subroutines::RequireArgUnpacking)
    my $class = shift
        or croak 'Cannot create new method in a functional way';

    my %opts = @_;
    my $self = bless {%opts}, $class;

    # only get ifconfig binary if it's not a windows
    $self->{'ifconfig'} ||= $IS_WIN ? '' : $self->_get_ifconfig_binary;
    $self->{'if_info'}  ||= $self->_get_interface_info;

    return $self;
}

sub ifconfig {
    my $self = shift;
    my $path = shift;

    if ( !ref $self ) {
        return $self->_get_ifconfig_binary;
    }

    # set path
    $path and $self->{'ifconfig'} = $path;

    return $self->{'ifconfig'};
}

sub ip {
    my $self = shift || 'Sys::HostIP';
    my $if_info;

    if ( !ref $self ) {
        $if_info = $self->_get_interface_info;
    } else {
        $if_info = $self->if_info;
    }

    if ($IS_WIN) {
        my @if_keys = sort keys %{$if_info};
        return scalar @if_keys != 0 ? ( $if_info->{ $if_keys[0] } ) : '';
    } else {
        my $lo_found;

        foreach my $key ( sort keys %{$if_info} ) {

            # we don't want the loopback
            if ( $if_info->{$key} eq '127.0.0.1' ) {
                $lo_found++;
                next;
            }

            # now we return the first one that comes up
            return ( $if_info->{$key} );
        }

        # we get here if loopback is the only active device
        $lo_found and return '127.0.0.1';

        return '';
    }
}

sub ips {
    my $self = shift || 'Sys::HostIP';

    if ( !ref $self ) {
        return [ values %{ $self->_get_interface_info } ];
    }

    return [ values %{ $self->if_info } ];
}

sub interfaces {
    my $self = shift || 'Sys::HostIP';

    if ( !ref $self ) {
        return $self->_get_interface_info;
    }

    return $self->if_info;
}

sub if_info {
    my $self = shift;

    return $self->{'if_info'};
}

sub _get_ifconfig_binary {
    my $self     = shift;
    my $ifconfig = '/sbin/ifconfig -a';

    ## no critic qw(Variables::ProhibitPunctuationVars)
    if ( $^O =~ /(?: linux|openbsd|freebsd|netbsd|solaris|darwin )/xmsi ) {
        $ifconfig = -f '/sbin/ifconfig' ? '/sbin/ifconfig -a' : '/sbin/ip address';
    } elsif ( $^O eq 'aix' ) {
        $ifconfig = '/usr/sbin/ifconfig -a';
    } elsif ( $^O eq 'irix' ) {
        $ifconfig = '/usr/etc/ifconfig';
    } elsif ( $^O eq 'dec_osf' ) {
        $ifconfig = '/sbin/ifconfig';
    } else {
        carp "Unknown system ($^O), guessing ifconfig is in /sbin/ifconfig "
            . "(email xsawyerx\@cpan.org with the location of your ifconfig)\n";
    }

    return $ifconfig;
}

sub _get_interface_info {
    my $self = shift;

    my $interface_info = $IS_WIN
        ? $self->_get_win32_interface_info()
        : $self->_get_unix_interface_info();

    my $warning_msg = "Unable to detect interface information!\n"
        . "Please open an issue on https://github.com/xsawyerx/sys-hostip/issues with your 'ipconfig' or 'ifconfig' output";
    warn $warning_msg if values %$interface_info == 0;

    return $interface_info;
}

sub _clean_ifconfig_env {
    my $self = shift;

    # this is an attempt to fix tainting problems

    # removing $BASH_ENV, which exists if /bin/sh is your bash
    delete $ENV{'BASH_ENV'};

    # now we set the local $ENV{'PATH'} to be only the path to ifconfig
    # We have localized %ENV in the call to this, so we disable critic warning
    ## no critic qw(Variables::RequireLocalizedPunctuationVars)
    my $ifconfig = $self->ifconfig;
    $ENV{'PATH'} = dirname $ifconfig;

    return $ifconfig;
}

sub _get_unix_interface_info {
    my $self = shift;

    # localize the environment
    local %ENV;

    # make sure nothing else has touched $/
    local $/ = "\n";

    my ( $ip, $interface, %if_info );

    # clean environment for taint mode
    my $ifconfig_bin = $self->_clean_ifconfig_env();
    my @ifconfig     = `$ifconfig_bin`;

    foreach my $line (@ifconfig) {

        # TODO: refactor this into tests
        # output from 'ifconfig -a' looks something like this on every *nix i
        # could get my hand on except linux (this one's actually from OpenBSD):
        #
        # gershiwin:~# /sbin/ifconfig -a
        # lo0: flags=8009<UP,LOOPBACK,MULTICAST>
        #         inet 127.0.0.1 netmask 0xff000000
        # lo1: flags=8008<LOOPBACK,MULTICAST>
        # xl0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST>
        #         media: Ethernet autoselect (100baseTX full-duplex)
        #         status: active
        #         inet 10.0.0.2 netmask 0xfffffff0 broadcast 10.0.0.255
        # sl0: flags=c010<POINTOPOINT,LINK2,MULTICAST>
        # sl1: flags=c010<POINTOPOINT,LINK2,MULTICAST>
        #
        # in linux it's a little bit different:
        #
        # [jschatz@nooky Sys-IP]$ /sbin/ifconfig
        #  eth0      Link encap:Ethernet  HWaddr 00:C0:4F:60:6F:C2
        #           inet addr:10.0.3.82  Bcast:10.0.255.255  Mask:255.255.0.0
        #           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
        #           Interrupt:19 Base address:0xec00
        #  lo        Link encap:Local Loopback
        #           inet addr:127.0.0.1  Mask:255.0.0.0
        #           UP LOOPBACK RUNNING  MTU:3924  Metric:1
        #
        # In linux, using /sbin/ip it looks like:
        # [goldenboy:~] adamb $ ip address
        # 1: lo:   <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default
        #     link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
        #     inet 127.0.0.1/8 scope host lo
        #        valid_lft forever preferred_lft forever
        #     inet6 ::1/128 scope host
        #        valid_lft forever preferred_lft forever
        # 2: eth0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc pfifo_fast state DOWN group default qlen 1000
        #     link/ether 9c:b6:54:a5:64:60 brd ff:ff:ff:ff:ff:ff
        #
        # so the regexen involved here have to deal with the following: 1)
        # there's no ':' after an interface's name in linux 2) in linux, it's
        # "inet addr:127.0.0.1" instead of "inet 127.0.0.1" hence the somewhat
        # hairy regexen /(^\w+(?:\d)?(?:\:\d)?)/ (which also handles aliased ip
        # addresses , ie eth0:1) and /inet(?:addr\:)?(\d+\.\d+\.\d+\.\d+)/
        #
        # so we parse through the list returned. if the line starts with some
        # letters followed (possibly) by an number and a colon, then we've got an
        # interface. if the line starts with a space, then it's the info from the
        # interface that we just found, and we stick the contents into %if_info
        if ( ( $line =~ /^\s+/x ) && ($interface) ) {
            $if_info{$interface} .= $line;
        }

        # FIXME: refactor this regex
        elsif ( ($interface) = ( $line =~ /^(?:\d+\:\s){0,1}(\w+(?:\d)?(?:\.\d+)?(?:\:\d+)?)/x ))
        {
            $line =~ s/\w+\d(\:)?\s+//x;
            $if_info{$interface} = $line;
        }
    }

    foreach my $key ( keys %if_info ) {

        # now we want to get rid of all the other crap in the ifconfig
        # output. we just want the ip address. perhaps a future version can
        # return even more useful results (netmask, etc).....
        if ( my ($ip)
            = ( $if_info{$key} =~ /inet\s(?:addr\:)?(\d+(?:\.\d+){3})/x ) )
        {
            $if_info{$key} = $ip;
        } else {

            # ok, no ip address here, which means this interface isn't
            # active. some os's (openbsd for instance) spit out ifconfig info for
            # inactive devices. this is pretty much worthless for us, so we
            # delete it from the hash
            delete $if_info{$key};
        }
    }

    # now we do some cleanup by deleting keys that have no associated info
    # (some os's like openbsd list inactive interfaces when 'ifconfig -a' is
    # used, and we don't care about those
    return \%if_info;
}

sub _run_ipconfig {
    return `ipconfig`;
}

sub _get_win32_interface_info {
    my $self    = shift;
    my %regexes = (
        address => qr/
            \s+
            IP(?:v4)? .*? :
            \s+
            (\d+ (?: \. \d+ ){3} )
        /x,

        adapter => qr/
            ^
            (?:
                Ethernet(?:\s?|-)\w+
                |
                .*?\s+Ethernet
            )
            \s+
            (.*) :
        /x,
    );

    my @ipconfig = $self->_run_ipconfig();
    my ( $interface, %if_info );

    foreach my $line (@ipconfig) {
        chomp($line);

        if ( $line =~ /Windows/xms ) {

            # ignore the header
            next;
        } elsif ( $line =~ /^\s$/xms ) {
            next;
        } elsif ( ( $line =~ $regexes{'address'} ) and defined $interface ) {
            $if_info{$interface} = $1;
            $interface = undef;
        } elsif ( $line =~ $regexes{'adapter'} ) {
            $interface = $1;
            chomp $interface;
            $interface =~ s/\s+$//gxms; # remove trailing whitespace, if any
        }
    }

    return \%if_info;
}

1;

__END__

=head1 NAME

Sys::HostIP - Try extra hard to get IP address related info

=head1 SYNOPSIS

    use Sys::HostIP;

    my $hostip     = Sys::HostIP->new;
    my $ips        = $hostip->ips;
    my $interfaces = $hostip->interfaces;

=head1 DESCRIPTION

Sys::HostIP does what it can to determine the ip address of your
machine. All 3 methods work fine on every system that I've been able to test
on. (Irix, OpenBSD, FreeBSD, NetBSD, Solaris, Linux, OSX, Win32, Cygwin). It
does this by parsing ifconfig(8) (ipconfig on Win32/Cygwin) output.

It has an object oriented interface and a functional one for compatibility
with older versions.

=head1 ATTRIBUTES

=head2 ifconfig

    my $hostip = Sys::HostIP->new( ifconfig => '/path/to/your/ifconfig' );

You can set the location of ifconfig with this attribute if the code doesn't
know where your ifconfig lives.

If you use the object oriented interface, this value is cached.

=head2 if_info

The interface information. This is either created on new, or you can create
it yourself at initialize.

    # get the cached if_info
    my $if_info = $hostip->if_info;

    # create custom one at initialize
    my $hostip = Sys::HostIP->new( if_info => {...} );

=head1 METHODS

=head2 ip

    my $ip = $hostip->ip;

Returns a scalar containing a best guess of your host machine's IP address. On
*nix (Unix, BSD, GNU/Linux, OSX, etc.) systems, it will return the loopback
interface (127.0.0.1) if it can't find anything else.

=head2 ips

    my $all_ips = $hostip->ips;
    foreach my $ip ( @{$all_ips} ) {
        print "IP: $ip\n";
    }

Returns an array ref containing all the IP addresses of your machine.

=head2 interfaces

    my $interfaces = $hostip->interfaces;

    foreach my $interface ( keys %{$interfaces} ) {
        my $ip = $interfaces->{$interface};
        print "$interface => $ip\n";
    }

Returns a hash ref containing all pairs of interfaces and their corresponding
IP addresses Sys::HostIP could find on your machine.

=head2 EXPORT

Nothing by default!

To export something explicitly, use the syntax:
Nothing.

    use HostIP qw/ip ips interfaces/;
    # that will get you those three subroutines, for example

All of these subroutines will match the object oriented interface methods.

=over 4

=item * ip

    my $ip = ip();

=item * ips

    my $ips = ips();

=item * interfaces

    my $interfaces = interfaces();

=back

=head1 HISTORY

Originally written by Jonathan Schatz <bluelines@divisionbyzero.com>.

Currently maintained by Paul Cochrane <paul@liekut.de> and Sawyer X
<xsawyerx@cpan.org>.

=head1 TODO

I haven't tested the win32 code with dialup or wireless connections.

Machines with output in some languages other than English fail.
Neverthless, the code has been shown to work in German, Swedish, French,
Italian, and Finnish locales.

=head1 COPYRIGHT AND LICENSE

Copyright (C) prior to 2010, Jonathan Schatz <bluelines@divisionbyzero.com>.

Copyright (C) 2010-2019, Sawyer X <xsawyerx@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * ifconfig(8)

=item * ipconfig

=back

