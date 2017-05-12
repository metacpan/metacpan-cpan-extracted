package Sys::Info::Driver::OSX::OS;
use strict;
use warnings;

our $VERSION = '0.7958';

use base qw( Sys::Info::Base );
use Carp qw( croak );
use Cwd;
use POSIX ();
use Sys::Info::Constants qw( USER_REAL_NAME_FIELD );
use Sys::Info::Driver::OSX;

use constant RE_DATE_STAMP => qr{
    \A
     [a-z]{3}  \s                       # Thu
    ([a-z]{3}) \s                       # May
    ([0-9]{2}) \s                       # 12
    ([0-9]{2} : [0-9]{2} : [0-9]{2}) \s # 00:51:29
    ([0-9]{4})                          # 2011
    \z
}xmsi;

my %MONTH_TO_ID = do {
    my $c = 0;
    map { $_ => $c++ }
        qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
};

my %UNIT_TO_BYTES = (
    G => 1024**3,
    M => 1024**2,
    K => 1024,
);

my %OSVERSION;

my %FILE = (
    install_history => '/Library/Receipts/InstallHistory.plist',
    server_version  => '/System/Library/CoreServices/ServerVersion.plist',
    cdis            => '/var/log/CDIS.custom',
);

my $EDITION = {
    # taken from Wikipedia
    0 => 'Cheetah',
    1 => 'Puma',
    2 => 'Jaguar',
    3 => 'Panther',
    4 => 'Tiger',
    5 => 'Leopard',
    6 => 'Snow Leopard',
    7 => 'Lion',
    8 => 'Mountain Lion',
    9 => 'Mavericks',
};

# unimplemented
sub logon_server {}

sub edition {
    my $self = shift->_populate_osversion;
    return $OSVERSION{RAW}->{EDITION};
}

sub tz {
    my $self = shift;
    return POSIX::strftime('%Z', localtime);
}

sub meta {
    my $self = shift;
    $self->_populate_osversion;

    require POSIX;
    require Sys::Info::Device;

    my $cpu       = Sys::Info::Device->new('CPU');
    my $arch      = ($cpu->identify)[0]->{architecture};
    my %swap      = $self->_probe_swap;
    my %vm_stat   = vm_stat();
    my %info;

    # http://jaharmi.com/2007/05/11/read_the_mac_os_x_edition_and_version_from_prope
    # desktop: /System/Library/CoreServices/SystemVersion.plist
    my $has_server = -e $FILE{server_version};

    $info{manufacturer}              = 'Apple Inc.';
    $info{build_type}                = $has_server ? 'Server' : 'Desktop';
    $info{owner}                     = undef;
    $info{organization}              = undef;
    $info{product_id}                = undef;
    $info{install_date}              = $self->_install_date;
    $info{boot_device}               = undef;

    $info{physical_memory_total}     = fsysctl('hw.memsize');
    $info{physical_memory_available} = $vm_stat{memory_free};
    $info{page_file_total}           = $swap{total};
    $info{page_file_available}       = $swap{free};

    # windows specific
    $info{windows_dir}               = undef;
    $info{system_dir}                = undef;

    $info{system_manufacturer}       = 'Apple Inc.';
    $info{system_model}              = undef; # iMac/MacBook ???
    $info{system_type}               = sprintf '%s based Computer', $arch;

    $info{page_file_path}            = $swap{path};

    return %info;
}

sub tick_count {
    my $self = shift;
    return time - $self->uptime;
}

sub name {
    my($self, @args) = @_;
    $self->_populate_osversion;
    my %opt  = @args % 2 ? () : @args;
    my $id   = $opt{long} ? ($opt{edition} ? 'LONGNAME_EDITION' : 'LONGNAME')
             :              ($opt{edition} ? 'NAME_EDITION'     : 'NAME'    )
             ;
    return $OSVERSION{ $id };
}


sub version   { shift->_populate_osversion(); return $OSVERSION{VERSION}      }
sub build     { shift->_populate_osversion(); return $OSVERSION{RAW}->{BUILD} }

sub uptime {
    my $key   = 'kern.boottime';
    my $value = fsysctl $key;
    my $sec   = _parse_uptime( $value, $key );
    croak "Bogus data returned from $key: $value" if ! $sec;
    return $sec;
}

sub _parse_uptime {
    my($value, $key, $use_gmtime) = @_;

    if ( my @m = $value =~ m<\A[{](.+?)[}]\s+?(.+?)\z>xms ) {
        my($data, $stamp) = @m;
        my %data = map {
                        map {
                            __PACKAGE__->trim($_)
                        } split m{=}xms
                    } split m{[,]}xms, $data;
        croak "sec key does not exist in $key" if ! exists $data{sec};
        return $data{sec};
    }

    if ( my @m = $value =~ RE_DATE_STAMP ) {
        my($mon_name, $mday, $hms, $year) = @m;
        my $mon = $MONTH_TO_ID{ $mon_name }
                    || croak "Unable to gather month from $mon_name";
        my($hour, $min, $sec) = split m{:}xms, $hms;

        require Time::Local;
        my $converter = $use_gmtime ? \&Time::Local::timegm
                                    : \&Time::Local::timelocal;
        return $converter->( $sec, $min, $hour, $mday, $mon, $year );
    }

    return;
}

# user methods
sub is_root {
    my $name = login_name();
    my $id   = POSIX::geteuid();
    my $gid  = POSIX::getegid();
    return 0 if $@;
    return 0 if ! defined $id || ! defined $gid;
    return $id == 0 && $gid == 0; # && $name eq 'root'; # $name is never root!
}

sub login_name {
    my($self, @args) = @_;
    my %opt   = @args % 2 ? () : @args;
    my $login = POSIX::getlogin() || return;
    my $rv    = eval { $opt{real} ? (getpwnam $login)[USER_REAL_NAME_FIELD] : $login };
    $rv =~ s{ [,]{3,} \z }{}xms if $opt{real};
    return $rv;
}

sub node_name { return shift->uname->{nodename} }

sub domain_name { }

sub fs {
    # TODO
    my $self = shift;
    return unimplemented => 1;
}

sub bitness {
    my $self = shift;
    my $v    = $self->uname->{version} || q{};
    return $v =~ m{ [/]RELEASE_X86_64 \z }xms ? 64
        :  $v =~ m{ [/]RELEASE_I386      }xms ? 32
        : do {
            my($sw) = system_profiler( 'SPSoftwareDataType' );
            return if ref $sw ne 'HASH';
            return if ! exists $sw->{'64bit_kernel_and_kexts'};
            my $type = $sw->{'64bit_kernel_and_kexts'} || q{};
            return $type eq 'yes' ? 64 : 32;
    }
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _probe_swap {
    my($self) = @_;
    # `vm_stat` ?
    my $swapusage = fsysctl 'vm.swapusage';
    my @sparts    = split m<\s{2,}>xms, $swapusage;
    my $swap_enc  = $sparts[-1] =~ m{encrypted}xms ? pop @sparts : undef;
    my %sw        = map { split m{ \s+ = \s+ }xms, $_ } @sparts;
    my $size      = sub {
        my($unit, $orig) = @_;
        return $UNIT_TO_BYTES{ $unit }
                || croak "Unable to determine bytes from $unit unit ($orig)"
    };

    foreach my $prop ( qw( free used total ) ) {
        my $value = $sw{ $prop } || next;
        my $unit  = chop $value;
        $value += 0;
        $sw{ $prop } = $value ? $value * $size->( $unit, $sw{ $prop } ) : 0;
    }

    return
        %sw,
        encrypted => $swap_enc ? 1 : 0,
        path      => -d '/private/var/vm' ? '/private/var/vm' : undef,
    ;
}

sub _install_date {
    my $self = shift;
    # I have no /var/log/OSInstall.custom on my system, so I believe that
    # file is no longer reliable
    my @idate;
    push @idate, -e $FILE{cdis} ? ( stat $FILE{cdis} )[10] : ();

    if ( -e $FILE{install_history} ) {
        my $rec  = plist( $FILE{install_history} );
        push @idate, $rec ? do {
            # poor mans date parser
            my $d = $rec->[0]{date} || q();
            my($y,$h) = split m{T}xms, $d, 2;
            if ( $y && $h ) {
                chop $h;
                my($year, $mon, $mday) = split m{\-}xms, $y;
                my($hour, $min, $sec)  = split m{:}xms, $h;
                require Time::Local;
                Time::Local::timelocal(
                    $sec, $min, $hour, $mday, $mon - 1, $year
                );
            }
            else {
                ()
            }
        } : ();
    }

   return @idate ? (sort { $a <=> $b } @idate)[0] : undef;
}

sub _file_has_substr {
    my $self = shift;
    my $file = shift;
    my $str  = shift;
    return if ! -e $file || ! -f _;
    my $raw = $self->slurp( $file ) =~ m{$str}xms;
    return $raw;
}

sub _probe_edition {
    my($self, $v) = @_;
    my($major, $minor, $patch) = split m{[.]}xms, $v;
    return $EDITION->{ $minor };
}

sub _populate_osversion {
    return if %OSVERSION;
    my $self    = shift;
    my $uname   = $self->uname;

    # 'Darwin Kernel Version 10.5.0: Fri Nov  5 23:20:39 PDT 2010; root:xnu-1504.9.17~1/RELEASE_I386',
    my($stuff, $root) = split m{;}xms, $uname->{version}, 2;
    my($name, $stamp) = split m{:}xms, $stuff, 2;
    $_ = __PACKAGE__->trim( $_ ) for $stuff, $root, $name, $stamp;

    my %sw_vers    = sw_vers();
    my $build_date = $stamp ? $self->date2time( $stamp ) : undef;
    my $build      = $sw_vers{BuildVersion} || $stamp;
    my $edition    = $self->_probe_edition(
                        $sw_vers{ProductVersion} || $uname->{release}
                    );

    my $sysname = $uname->{sysname} eq 'Darwin' ? 'Mac OSX' : $uname->{sysname};

    %OSVERSION = (
        NAME             => $sysname,
        NAME_EDITION     => $edition ? "$sysname ($edition)" : $sysname,
        LONGNAME         => q{}, # will be set below
        LONGNAME_EDITION => q{}, # will be set below
        VERSION  => $sw_vers{ProductVersion} || $uname->{release},
        KERNEL   => undef,
        RAW      => {
                        BUILD      => defined $build      ? $build      : 0,
                        BUILD_DATE => defined $build_date ? $build_date : 0,
                        EDITION    => $edition,
                    },
    );

    $OSVERSION{LONGNAME}         = sprintf '%s %s',
                                   @OSVERSION{ qw/ NAME         VERSION / };
    $OSVERSION{LONGNAME_EDITION} = sprintf '%s %s',
                                   @OSVERSION{ qw/ NAME_EDITION VERSION / };
    return;
}

1;

__END__

=head1 NAME

Sys::Info::Driver::OSX::OS - OSX backend

=head1 SYNOPSIS

-

=head1 DESCRIPTION

This document describes version C<0.7958> of C<Sys::Info::Driver::OSX::OS>
released on C<23 October 2013>.

-

=head1 METHODS

Please see L<Sys::Info::OS> for definitions of these methods and more.

=head2 build

=head2 domain_name

=head2 edition

=head2 fs

=head2 is_root

=head2 login_name

=head2 logon_server

=head2 meta

=head2 name

=head2 node_name

=head2 tick_count

=head2 tz

=head2 uptime

=head2 version

=head2 bitness

=head1 SEE ALSO

L<Sys::Info>, L<Sys::Info::OS>,
L<http://en.wikipedia.org/wiki/Mac_OS_X>,
L<http://stackoverflow.com/questions/3610424/determine-kernel-bitness-in-mac-os-x-10-6>,
L<http://osxdaily.com/2010/10/08/mac-virtual-memory-swap/>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2010 - 2013 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.
=cut
