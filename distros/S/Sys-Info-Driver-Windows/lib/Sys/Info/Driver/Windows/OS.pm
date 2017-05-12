package Sys::Info::Driver::Windows::OS;
use strict;
use warnings;

our $VERSION = '0.78';

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
## no critic (ValuesAndExpressions::RequireNumberSeparators)

use constant LAST_ELEMENT => -1;
use constant MILISECOND   => 1000;
use base qw( Sys::Info::Driver::Windows::OS::Editions );
use Win32;
use Win32::OLE                 qw( in    );
use Carp                       qw( croak );
use Sys::Info::Driver::Windows qw( :all  );
use Sys::Info::Driver::Windows::OS::Net;

use Sys::Info::Constants qw( :windows_reg :windows_wmi NEW_PERL );

# first row -> All; second row -> NT 4 SP6 and later
my @OSV_NAMES = qw/
    STRING  MAJOR   MINOR     BUILD       ID
    SPMAJOR SPMINOR SUITEMASK PRODUCTTYPE
/;

BEGIN {
    *is_win9x = *is_win95 = sub{ Win32::IsWin95() } if ! defined &is_win9x;
    *is_winnt             = sub{ Win32::IsWinNT() } if ! defined &is_winnt;
}

sub init {
    my $self = shift;
    $self->{OSVERSION}  = undef; # see _populate_osversion
    $self->{FILESYSTEM} = undef; # see _populate_fs
    return;
}

sub is_root {
    # Win32::IsAdminUser(): Perl 5.8.3 Build 809 Monday, Feb 2, 2004
    return defined &Win32::IsAdminUser ? Win32::IsAdminUser()
         : Win32::IsWin95()            ? 1
         :                               0
         ;
}

sub node_name { return Win32::NodeName() }

sub edition {
    return shift->_populate_osversion->{OSVERSION}{RAW}{EDITION};
}

sub product_type {
    my($self, @args) = @_;
    $self->_populate_osversion;
    my %opt  = @args % 2 ? () : @args;
    my $raw  = $self->{OSVERSION}{RAW}{PRODUCTTYPE};
    return $opt{raw} ? $raw : $self->_product_type( $raw );
}

sub name {
    my($self, @args) = @_;
    $self->_populate_osversion;
    my %opt  = @args % 2  ? ()         : @args;
    my $id   = $opt{long} ? 'LONGNAME' : 'NAME';
    return $self->{OSVERSION}{ $opt{edition} ? $id . '_EDITION' : $id };
}

sub version {
    my($self, @args) = @_;
    my %opt     = @args % 2 ? () : @args;
    my $version = $self->_populate_osversion->{OSVERSION}{VERSION};

    if ( $opt{short} ) {
        my @v = split m{[.]}xms, $version;
        shift @v;
        return join q{.}, @v ;
    }

    return $version;
}

sub build {
    return shift->_populate_osversion->{OSVERSION}{RAW}{BUILD} || 0;
}

sub uptime {
    my $self = shift;
    return time - $self->tick_count;
}

sub domain_name {
    my $self = shift;
    return $self->is_win95() ? q{} : Win32::DomainName()
}

sub tick_count {
    my $self = shift;
    my $tick = Win32::GetTickCount();
    return $tick ? $tick / MILISECOND : 0; # in miliseconds
}

sub login_name {
    my($self, @args) = @_;
    $self->_populate_osversion;
    my %opt   = @args % 2 ? () : @args;
    my $login = Win32::LoginName();
    return $opt{real} && $login
           ? Sys::Info::Driver::Windows::OS::Net->user_fullname( $login )
           : $login
           ;
}

sub logon_server {
    my $self = shift;
    my $name = $self->login_name || return q{};
    return Sys::Info::Driver::Windows::OS::Net->user_logon_server( $name );
}

sub fs {
    my $self = shift;
    return %{ $self->_populate_fs->{FILESYSTEM} };
}

sub tz {
    my $self = shift;
    my $tz;
    foreach my $object ( in WMI_FOR('Win32_TimeZone') ) {
        $tz = $object->Caption;
        last;
    }
    if ( NEW_PERL ) {
        require Encode;
        my $locale = $self->locale;
        my $cp     = (split m{[.]}xms, $locale)[LAST_ELEMENT] + 0; # vugly hack
        $tz = Encode::decode( "cp$cp", $tz ) if $cp;
    }
    return $tz;
}

sub meta {
    my $self  = shift;
    my $id    = shift;
    my $os    = ( in WMI_FOR('Win32_OperatingSystem' ) )[0];
    my $cs    = ( in WMI_FOR('Win32_ComputerSystem'  ) )[0];
    my $pf    = ( in WMI_FOR('Win32_PageFileUsage'   ) )[0];
    my $idate = $self->_wmidate_to_unix( $os->InstallDate );
    my %info;

    $info{manufacturer}              = $os->Manufacturer;
    $info{build_type}                = $os->BuildType;
    $info{owner}                     = $os->RegisteredUser;
    $info{organization}              = $os->Organization;
    $info{product_id}                = $os->SerialNumber;
    $info{install_date}              = $idate;
    $info{boot_device}               = $os->BootDevice;
    $info{physical_memory_total}     = $os->TotalVisibleMemorySize;
    $info{physical_memory_available} = $os->FreePhysicalMemory;
    $info{page_file_total}           = $os->TotalVirtualMemorySize;
    $info{page_file_available}       = $os->FreeVirtualMemory;
    # windows specific
    $info{windows_dir}               = $os->WindowsDirectory;
    $info{system_dir}                = $os->SystemDirectory;
    $info{system_manufacturer}       = $cs->Manufacturer;
    $info{system_model}              = $cs->Model;
    $info{system_type}               = $cs->SystemType;
    $info{page_file_path}            = $pf ? $pf->Name : undef;

    return %info;
}

sub cdkey {
    my($self, @args) = @_;
    return if Win32::IsWin95(); # not supported
    my %opt = @args % 2 ? () : @args;

    if ( $opt{office} ) {
        my $base = registry()->{ +WIN_REG_OCDKEY };
        my @versions;
        foreach my $e ( keys %{ $base } ) {
            next if $e =~ m{[^0-9\./]}xms; # only get versioned keys
            $e =~ s{ / \z }{}xms;
            # check all installed office versions
            push @versions, $e if $base->{ $e . '/Registration' };
        }

        my @list;
        foreach my $v ( reverse sort { $a <=> $b } @versions ) {
            my $key = $base->{ $v . '/Registration' };
            my $id  = ( keys %{ $key } )[0];
            my $val = $key->{ $id . 'DigitalProductId' } || next;
            push @list, decode_serial_key( $val );
        }
        return @list; #return all available keys
    }

    my $val = registry()->{ +WIN_REG_CDKEY } || return;
    return decode_serial_key( $val );
}

sub bitness {
    my $self = shift;
    my %i    = GetSystemInfo();
    return $i{wProcessBitness};
}

# ------------------------[ P R I V A T E ]------------------------ #

sub _wmidate_to_unix {
    my $self  = shift;
    my $thing = shift || return;
    my($date, $junk) = split m/[.]/xms, $thing;
    my($year, $mon, $mday, $hour, $min, $sec) = unpack WIN_WMI_DATE_TMPL, $date;
    require Time::Local;
    return Time::Local::timelocal( $sec, $min, $hour, $mday, $mon-1, $year );
}

sub _populate_fs {
    my $self  = shift;
    return $self if $self->{FILESYSTEM};
    my($FSTYPE, $FLAGS, $MAXCOMPLEN) = Win32::FsType();
    if ( !$FSTYPE && Win32::GetLastError() ) {
        warn "Can not fetch file system information: $^E\n";
        return;
    }
    my %flag = (
        case_sensitive     => 0x00000001, #supports case-sensitive filenames
        preserve_case      => 0x00000002, #preserves the case of filenames
        unicode            => 0x00000004, #supports Unicode in filenames
        acl                => 0x00000008, #preserves and enforces ACLs
        file_compression   => 0x00000010, #supports file-based compression
        disk_quotas        => 0x00000020, #supports disk quotas
        sparse             => 0x00000040, #supports sparse files
        reparse            => 0x00000080, #supports reparse points
        remote_storage     => 0x00000100, #supports remote storage
        compressed_volume  => 0x00008000, #is a compressed volume (e.g. DoubleSpace)
        object_identifiers => 0x00010000, #supports object identifiers
        efs                => 0x00020000, #supports the Encrypted File System (EFS)
    );
    my @fl;
    if ( $FLAGS ) {
        foreach my $f (keys %flag) {
            push @fl, $f => $flag{$f} & $FLAGS ? 1 : 0;
        }
    }

    push @fl, max_file_length => $MAXCOMPLEN if $MAXCOMPLEN;
    push @fl, filesystem      => $FSTYPE     if $FSTYPE; # NTFS/FAT/FAT32

    $self->{FILESYSTEM} = { @fl };
    return $self;
}

sub _osversion_table {
    my $self    = shift;
    my $OSV     = shift;

    my $t       = sub { $OSV->{MAJOR} == $_[0] && $OSV->{MINOR} == $_[1] };
    my $version = join q{.}, $OSV->{ID}, $OSV->{MAJOR}, $OSV->{MINOR};
    my $ID      = $OSV->{ID};
    my($os,$edition);

       if ( $ID == 0 ) { $os = 'Win32s' }
    elsif ( $ID == 1 ) {
        $os = $t->(4,0 ) ? 'Windows 95'
            : $t->(4,10) ? 'Windows 98'
            : $t->(4,90) ? 'Windows Me'
            :              "Windows 9x $version"
            ;
    }
    elsif ( $ID == 2 ) {
          $t->(3,51) ? do { $os = 'Windows NT 3.51' }
        : $t->(4,0 ) ? do { $os = 'Windows NT 4'    }
        : do {
            # damn editions!
              $t->(5,0) ? $self->_2k_03_xp(    \$edition, \$os, $OSV )
            : $t->(5,1) ? $self->_xp_editions( \$edition, \$os, $OSV )
            : $t->(5,2) ? $self->_xp_or_03(    \$edition, \$os, $OSV )
            : $t->(6,0) ? $self->_vista_or_08( \$edition, \$os       )
            : $t->(6,1) ? $self->_win7(        \$edition, \$os       )
            :             do { $os = "Windows NT $version" }
        }
    }
    else {
        $os = "Windows $version";
    }

    return $os, $version, $edition;
}

sub _populate_osversion { # returns the object
    my $self = shift;
    return $self if $self->{OSVERSION};
    # Win32::GetOSName() is not reliable.
    # Since, an older release will not have any idea about XP or Vista
    # Server 2008 is tricky since it has the same version number as Vista
    my %OSV;
    @OSV{ @OSV_NAMES } = Win32::GetOSVersion();

    $OSV{MAJOR} ||= 0;
    $OSV{MINOR} ||= 0;

    my($osname, $version, $edition) = $self->_osversion_table( \%OSV );

    $self->{OSVERSION} = {
        NAME             => $osname,
        NAME_EDITION     => $edition ? "$osname $edition" : $osname,
        LONGNAME         => q{}, # will be set below
        LONGNAME_EDITION => q{}, # will be set below
        VERSION          => $version,
        RAW              => {
            STRING      => $OSV{STRING},
            MAJOR       => $OSV{MAJOR},
            MINOR       => $OSV{MINOR},
            BUILD       => $OSV{BUILD},
            ID          => $OSV{ID},
            SPMAJOR     => $OSV{SPMAJOR},
            SPMINOR     => $OSV{SPMINOR},
            PRODUCTTYPE => $OSV{PRODUCTTYPE},
            EDITION     => $edition,
            SUITEMASK   => $OSV{SUITEMASK},
        },
    };

    my $o      = $self->{OSVERSION};
    my $build  = $o->{RAW}{BUILD} ? 'build ' . $o->{RAW}{BUILD} : q{};
    my $string = $o->{RAW}{STRING};

    $o->{LONGNAME}         = join q{ }, $o->{NAME},         $string, $build;
    $o->{LONGNAME_EDITION} = join q{ }, $o->{NAME_EDITION}, $string, $build;

    return $self;
}

sub _product_type {
    my $self = shift;
    my $pt   = shift || return;
    my %type = (
        1 => 'Workstation', # (NT 4, 2000 Pro, XP Home, XP Pro)
        2 => 'Domain Controller',
        3 => 'Server',
    );
    return $type{ $pt };
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Windows::OS - Windows backend for Sys::Info::OS

=head1 SYNOPSIS

This is a private sub-class.

=head1 DESCRIPTION

This document describes version C<0.78> of C<Sys::Info::Driver::Windows::OS>
released on C<17 April 2011>.

This document only discusses the driver specific parts.

=head1 METHODS

=head2 build

=head2 cdkey

=head2 domain_name

=head2 node_name

=head2 edition

=head2 fs

=head2 init

=head2 is_win95

=head2 is_win9x

=head2 is_winnt

=head2 is_root

=head2 login_name

=head2 logon_server

=head2 meta

=head2 name

=head2 product_type

=head2 tick_count

=head2 tz

=head2 uptime

=head2 bitness

Please see L<Sys::Info::OS> for definitions of these methods and more.

=head2 version

Version method returns the Windows version in C<%d.%d.%d> format. Possible
version values and corresponding names are:

   Version   Windows
   -------   -------
   0.0.0     Win32s
   1.4.0     Windows 95
   1.4.10    Windows 98
   1.4.90    Windows Me
   2.3.51    Windows NT 3.51
   2.4.0     Windows NT 4
   2.5.0     Windows 2000
   2.5.1     Windows XP
   2.5.2     Windows Server 2003
   2.6.0     Windows Vista
   2.6.0     Windows Server 2008(*)
   2.6.1     Windows 7(**)

It is also possible to get the short version (C<5.1> instead of C<2.5.1> for XP)
if you pass the C<short> parameter with a true value:

    my $v = $os->version( short => 1 );

(*) Unfortunately Windows Server 2008 has the same version number as Vista.
One needs to check the L<name> method to differentiate:

    if ( $os->version eq '2.6.0' ) {
        if ( $os->name eq 'Windows Server 2008' ) {
            print "We have the server version, all right";
        }
        else {
            print "Vista";
        }
    }
    else {
        print "Old Technology";
    }

(**) Yes, that is correct. "Windows 7" is B<not> Windows version 7. It's the
marketing name.

=head1 SEE ALSO

L<Win32>, L<Sys::Info>, L<Sys::Info::OS>,
L<http://www.codeguru.com/cpp/w-p/system/systeminformation/article.php/c8973>,
L<http://msdn.microsoft.com/en-us/library/cc216469.aspx>,
L<http://msdn.microsoft.com/en-us/library/ms724358(VS.85).aspx>
.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2006 - 2011 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.12.2 or, 
at your option, any later version of Perl 5 you may have available.

=cut
