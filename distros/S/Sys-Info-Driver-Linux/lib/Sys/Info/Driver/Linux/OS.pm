package Sys::Info::Driver::Linux::OS;
$Sys::Info::Driver::Linux::OS::VERSION = '0.7905';
use strict;
use warnings;
use base qw( Sys::Info::Base );
use POSIX ();
use Cwd;
use Carp qw( croak );
use Sys::Info::Driver::Linux;
use Sys::Info::Driver::Linux::Constants qw( :all );
use constant FSTAB_LENGTH => 6;

##no critic (InputOutput::ProhibitBacktickOperators)

sub init {
    my $self = shift;
    $self->{OSVERSION}  = undef; # see _populate_osversion
    $self->{FILESYSTEM} = undef; # see _populate_fs
    return;
}

# unimplemented
sub logon_server {}

sub edition {
    return shift->_populate_osversion->{OSVERSION}{RAW}{EDITION};
}

sub tz {
    my $self = shift;
    return if ! -e proc->{timezone};
    chomp( my $rv = $self->slurp( proc->{timezone} ) );
    return $rv;
}

sub meta {
    my $self = shift->_populate_osversion;

    require POSIX;
    require Sys::Info::Device;

    my $cpu   = Sys::Info::Device->new('CPU');
    my $arch  = ($cpu->identify)[0]->{architecture};
    my %mem   = $self->_parse_meminfo;
    my @swaps = $self->_parse_swap;
    my %info;

    $info{manufacturer}              = $self->{OSVERSION}{MANUFACTURER};
    $info{build_type}                = undef;
    $info{owner}                     = undef;
    $info{organization}              = undef;
    $info{product_id}                = undef;
    $info{install_date}              = $self->{OSVERSION}{RAW}{BUILD_DATE};
    $info{boot_device}               = undef;

    $info{physical_memory_total}     = $mem{MemTotal};
    $info{physical_memory_available} = $mem{MemFree};
    $info{page_file_total}           = $mem{SwapTotal};
    $info{page_file_available}       = $mem{SwapFree};

    # windows specific
    $info{windows_dir}               = undef;
    $info{system_dir}                = undef;

    $info{system_manufacturer}       = undef;
    $info{system_model}              = undef;
    $info{system_type}               = sprintf '%s based Computer', $arch;

    $info{page_file_path}            = join ', ', map { $_->{Filename} } @swaps;

    return %info;
}

sub tick_count {
    my $self = shift;
    my $uptime = $self->slurp( proc->{uptime} ) || return 0;
    my @uptime = split /\s+/xms, $uptime;
    # this file has two entries. uptime is the first one. second: idle time
    return $uptime[UP_TIME];
}

sub name {
    my($self, @args) = @_;
    $self->_populate_osversion;
    my %opt  = @args % 2  ? ()         : @args;
    my $id   = $opt{long} ? 'LONGNAME' : 'NAME';
    return $self->{OSVERSION}{ $opt{edition} ? $id . '_EDITION' : $id };
}

sub version   { return shift->_populate_osversion->{OSVERSION}{VERSION}         }
sub build     { return shift->_populate_osversion->{OSVERSION}{RAW}{BUILD_DATE} }
sub uptime    { return time - shift->tick_count }

# user methods
sub is_root {
    return 0 if defined &Sys::Info::EMULATE;
    my $name = login_name();
    my $id   = POSIX::geteuid();
    my $gid  = POSIX::getegid();
    return 0 if $@;
    return 0 if ! defined $id || ! defined $gid;
    return $id == 0 && $gid == 0 && $name eq 'root';
}

sub login_name {
    my($self, @args) = @_;
    my %opt   = @args % 2 ? () : @args;
    my $login = POSIX::getlogin() || return;
    my $rv    = eval { $opt{real} ? (getpwnam $login)[REAL_NAME_FIELD] : $login };
    $rv =~ s{ [,]{3,} \z }{}xms if $opt{real};
    return $rv;
}

sub node_name { return shift->uname->{nodename} }

sub domain_name {
    my $self = shift;
    # hmmmm...
    foreach my $line ( $self->read_file( proc->{resolv} ) ) {
        chomp $line;
        if ( $line =~ m{\A domain \s+ (.*) \z}xmso ) {
            return $1;
        }
    }
    my $sys = qx{dnsdomainname 2> /dev/null};
    return $sys;
}

sub fs {
    my $self = shift;
    $self->{current_dir} = Cwd::getcwd();

    my(@fstab, @junk, $re);
    foreach my $line( $self->read_file( proc->{fstab} ) ) {
        chomp $line;
        next if $line =~ m{ \A \# }xms;
        @junk = split /\s+/xms, $line;
        next if ! @junk || @junk != FSTAB_LENGTH;
        next if lc($junk[FS_TYPE]) eq 'swap'; # ignore swaps
        $re = $junk[MOUNT_POINT];
        next if $self->{current_dir} !~ m{\Q$re\E}xmsi;
        push @fstab, [ $re, $junk[FS_TYPE] ];
    }

    @fstab  = reverse sort { $a->[0] cmp $b->[0] } @fstab if @fstab > 1;
    my $fstype = $fstab[0]->[1];
    my $attr   = $self->_fs_attributes( $fstype );
    return
        filesystem => $fstype,
        ($attr ? %{$attr} : ())
    ;
}

sub bitness { return shift->uname->{machine} =~ m{64}xms ? '64' : '32' }

# ------------------------[ P R I V A T E ]------------------------ #

sub _parse_meminfo {
    my $self = shift;
    my %mem;
    foreach my $line ( split /\n/xms, $self->slurp( proc->{meminfo} ) ) {
        chomp $line;
        my($k, $v) = split /:/xms, $line;
        # units in KB
        $mem{ $k } = (split /\s+/xms, $self->trim( $v ) )[0];
    }
    return %mem;
}

sub _parse_swap {
    my $self = shift;
    my @swaps      = split /\n/xms, $self->slurp( proc->{swaps} );
    my @swap_title = split /\s+/xms, shift @swaps;
    my @swap_list;
    foreach my $line ( @swaps ) {
        chomp $line;
        my @data = split /\s+/xms, $line;
        push @swap_list,
            {
                map { $swap_title[$_] => $data[$_] } 0..$#swap_title
            };
    }
    return @swap_list;
}

sub _ip {
    my $self = shift;
    my $cmd  = q{/sbin/ifconfig};
    return if ! -e $cmd || ! -x _;
    my $raw = qx($cmd);
    return if not $raw;
    my @raw = split /inet addr/xms, $raw;
    return if ! @raw || @raw < 2 || ! $raw[1];
    if ( $raw[1] =~ m{(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})}xms ) {
        return $1;
    }
    return;
}

sub _populate_osversion {
    my $self = shift;
    return $self if $self->{OSVERSION};
    require Sys::Info::Driver::Linux::OS::Distribution;
    my $distro       = Sys::Info::Driver::Linux::OS::Distribution->new;
    my $osname       = $distro->name;
    my $V            = $distro->version;
    my $edition      = $distro->edition;
    my $kernel       = $distro->kernel;
    my $build        = $distro->build;
    my $build_date   = $distro->build_date;
    my $manufacturer = $distro->manufacturer || q{};

    $self->{OSVERSION} = {
        NAME             => $osname,
        NAME_EDITION     => $edition ? "$osname ($edition)" : $osname,
        LONGNAME         => q{}, # will be set below
        LONGNAME_EDITION => q{}, # will be set below
        VERSION          => $V,
        KERNEL           => $kernel,
        MANUFACTURER     => $manufacturer,
        RAW              => {
            BUILD      => defined $build      ? $build      : 0,
            BUILD_DATE => defined $build_date ? $build_date : 0,
            EDITION    => $edition,
        },
    };

    my $o = $self->{OSVERSION};
    my $t = '%s %s (kernel: %s)';
    $o->{LONGNAME}         = sprintf $t, $o->{NAME},         $o->{VERSION}, $kernel;
    $o->{LONGNAME_EDITION} = sprintf $t, $o->{NAME_EDITION}, $o->{VERSION}, $kernel;
    return $self;
}

sub _fs_attributes {
    my $self = shift;
    my $fs   = shift;

    return {
        ext3 => {
                case_sensitive     => 1, #'supports case-sensitive filenames',
                preserve_case      => 1, #'preserves the case of filenames',
                unicode            => 1, #'supports Unicode in filenames',
                #acl                => '', #'preserves and enforces ACLs',
                #file_compression   => '', #'supports file-based compression',
                #disk_quotas        => '', #'supports disk quotas',
                #sparse             => '', #'supports sparse files',
                #reparse            => '', #'supports reparse points',
                #remote_storage     => '', #'supports remote storage',
                #compressed_volume  => '', #'is a compressed volume (e.g. DoubleSpace)',
                #object_identifiers => '', #'supports object identifiers',
                efs                => '1', #'supports the Encrypted File System (EFS)',
                #max_file_length    => '';
        },
    }->{$fs};
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::Driver::Linux::OS

=head1 VERSION

version 0.7905

=head1 SYNOPSIS

-

=head1 DESCRIPTION

-

=head1 NAME

Sys::Info::Driver::Linux::OS - Linux backend

=head1 METHODS

Please see L<Sys::Info::OS> for definitions of these methods and more.

=head2 build

=head2 domain_name

=head2 edition

=head2 fs

=head2 init

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

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

sub _fetch_user_info {
    my %user;
    $user{NAME}               = POSIX::getlogin();
    $user{REAL_USER_ID}       = POSIX::getuid();  # $< uid
    $user{EFFECTIVE_USER_ID}  = POSIX::geteuid(); # $> effective uid
    $user{REAL_GROUP_ID}      = POSIX::getgid();  # $( guid
    $user{EFFECTIVE_GROUP_ID} = POSIX::getegid(); # $) effective guid
    my %junk;
    # quota, comment & expire are unreliable
    @junk{qw(name  passwd  uid  gid
             quota comment gcos dir shell expire)} = getpwnam($user{NAME});
    $user{REAL_NAME} = defined $junk{gcos}    ? $junk{gcos}    : '';
    $user{COMMENT}   = defined $junk{comment} ? $junk{comment} : '';
    return %user;
}

