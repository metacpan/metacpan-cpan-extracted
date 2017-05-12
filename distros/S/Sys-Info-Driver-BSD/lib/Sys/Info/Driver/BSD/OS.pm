package Sys::Info::Driver::BSD::OS;
use strict;
use warnings;
use vars qw( $VERSION );
use base qw( Sys::Info::Base );
use POSIX ();
use Cwd;
use Carp qw( croak );
use Sys::Info::Constants qw( USER_REAL_NAME_FIELD );
use Sys::Info::Driver::BSD;

$VERSION = '0.7801';

my %OSVERSION;

my $MANUFACTURER = {
    # taken from Wikipedia
    freebsd => 'The FreeBSD Project',
    openbsd => 'The OpenBSD Project',
    netbsd  => 'The NetBSD Foundation',
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
    $self->_populate_osversion();

    require POSIX;
    require Sys::Info::Device;

    my $cpu       = Sys::Info::Device->new('CPU');
    my $arch      = ($cpu->identify)[0]->{architecture};
    my $physmem   = fsysctl('hw.physmem');
    my $usermem   = fsysctl('hw.usermem');
    my $swap_call = $^O eq 'openbsd' ? '/sbin/swapctl -l' : '/usr/sbin/swapinfo';
    my $swap_buf  = qx($swap_call 2>&1);
    my %swap;
    if ( $swap_buf ) {
        foreach my $line ( split m{\n}xms, $swap_buf ) {
            chomp $line;
            next if $line =~ m{ \A Device }xms;
            @swap{ qw/ path size used / } = split m{\s+}xms, $line;
            last;
        }
    }

    my %info;

    $info{manufacturer}              = $MANUFACTURER->{ $^O };
    $info{build_type}                = undef;
    $info{owner}                     = undef;
    $info{organization}              = undef;
    $info{product_id}                = undef;
    $info{install_date}              = undef;
    $info{boot_device}               = undef;

    $info{physical_memory_total}     = $physmem;
    $info{physical_memory_available} = $physmem - $usermem;
    $info{page_file_total}           = $swap{size};
    $info{page_file_available}       = $swap{size} - $swap{used};

    # windows specific
    $info{windows_dir}               = undef;
    $info{system_dir}                = undef;

    $info{system_manufacturer}       = undef;
    $info{system_model}              = undef;
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
sub build     { shift->_populate_osversion(); return $OSVERSION{RAW}->{BUILD_DATE} }
sub uptime    {                               return fsysctl 'kern.boottime' }

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
    my $self = shift;
    return unimplemented => 1;
}

sub bitness {
    my $self = shift;
    return;
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _file_has_substr {
    my $self = shift;
    my $file = shift;
    my $str  = shift;
    return if ! -e $file || ! -f _;
    my $raw = $self->slurp( $file ) =~ m{$str}xms;
    return $raw;
}

sub _probe_edition {
    my $self = shift;
    my $name = shift;

    # Check DesktopBSD
    # /etc/motd
    # /var/db/pkg/desktopbsd-tools-1.1_2/
    return if $name ne 'FreeBSD';
    my $dbsd = quotemeta '# $DesktopBSD$';

    return 'DesktopBSD' if
        $self->_file_has_substr('/etc/motd'           , qr{Welcome \s to \s DesktopBSD}xms ) ||
        $self->_file_has_substr('/etc/devd.conf'      , qr{\A $dbsd}xms ) ||
        $self->_file_has_substr('/etc/rc.d/clearmedia', qr{\A $dbsd}xms );
    return; # fail!
}

sub _populate_osversion {
    return if %OSVERSION;
    my $self    = shift;
    require POSIX;
    my($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

    my(undef, $raw)  = split m{\#}xms, $version;
    my($date, undef) = split m{ \s+ \S+ \z }xms, $raw;
    my $build_date = $date ? $self->date2time( $date ) : undef;
    my $build      = $date;
    my $edition    = $self->_probe_edition( $sysname );

    my $kernel = '???';

    %OSVERSION = (
        NAME             => $sysname,
        NAME_EDITION     => $edition ? "$sysname ($edition)" : $sysname,
        LONGNAME         => q{}, # will be set below
        LONGNAME_EDITION => q{}, # will be set below
        VERSION  => $release,
        KERNEL   => undef,
        RAW      => {
                        BUILD      => defined $build      ? $build      : 0,
                        BUILD_DATE => defined $build_date ? $build_date : 0,
                        EDITION    => $edition,
                    },
    );

    $OSVERSION{LONGNAME}         = sprintf '%s %s (kernel: %s)',
                                   @OSVERSION{ qw/ NAME         VERSION / },
                                   $kernel;
    $OSVERSION{LONGNAME_EDITION} = sprintf '%s %s (kernel: %s)',
                                   @OSVERSION{ qw/ NAME_EDITION VERSION / },
                                   $kernel;
    return;
}

1;

__END__

=head1 NAME

Sys::Info::Driver::BSD::OS - BSD backend

=head1 SYNOPSIS

-

=head1 DESCRIPTION

This document describes version C<0.7801> of C<Sys::Info::Driver::BSD::OS>
released on C<12 September 2011>.

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
The C</proc> virtual filesystem:
L<http://www.redhat.com/docs/manuals/linux/RHL-9-Manual/ref-guide/s1-proc-topfiles.html>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2009 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
