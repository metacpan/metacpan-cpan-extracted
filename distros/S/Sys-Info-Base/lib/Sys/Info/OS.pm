package Sys::Info::OS;
$Sys::Info::OS::VERSION = '0.7807';
use strict;
use warnings;
use subs qw( LC_TYPE  );
use base                 qw( Sys::Info::Base );
use Carp                 qw( croak );
use Sys::Info::Constants qw( OSID  );

use constant TARGET_CLASS => __PACKAGE__->load_subclass('Sys::Info::Driver::%s::OS');
use base TARGET_CLASS;

my $POSIX;

BEGIN {
    # this check is for the Unknown driver
    local $@;
    my $eok = eval {
        require POSIX;
        POSIX->import( qw(locale_h) );
        $POSIX = 1;
        1;
    };
    *LC_CTYPE = sub () {} if $@ || ! $eok;
}

BEGIN {
    CREATE_SYNONYMS_AND_UTILITY_METHODS: {
        ## no critic (TestingAndDebugging::ProhibitProlongedStrictureOverride)
        no strict qw(refs);
        *is_admin   = *is_admin_user
                    = *is_adminuser
                    = *is_root_user
                    = *is_rootuser
                    = *is_super_user
                    = *is_superuser
                    = *is_su
                    = *{ TARGET_CLASS.'::is_root' }
                    ;
        *is_win32   = *is_windows
                    = *is_win
                    = sub () { OSID eq 'Windows' }
                    ;
        *is_linux   = *is_lin
                    = sub () { OSID eq 'Linux'   }
                    ;
        *is_bsd     = sub () { OSID eq 'BSD'     };
        *is_unknown = sub () { OSID eq 'Unknown' };
        *workgroup  = *{ TARGET_CLASS . '::domain_name' };
        *host_name  = *{ TARGET_CLASS . '::node_name'   };
        *time_zone  = *{ TARGET_CLASS . '::tz'          };
        ## use critic
    }

    CREATE_FAKES: {
        # driver specific methods
        my @fakes = qw(
            is_winnt
            is_win95
            is_win9x
            product_type
            cdkey
        );

        no strict qw(refs);
        foreach my $meth ( @fakes ) {
            next if __PACKAGE__->can( $meth );
            *{ $meth } = sub {};
        }
    }

}

sub new {
    my($class, @args) = @_;
    my $self = { @args % 2 ? () : @args };
    bless $self, $class;
    $self->init if $self->can('init');
    return $self;
}

sub meta {
    my $self = shift;
    my $id   = shift;
    my %info = $self->SUPER::meta( $id );

    return %info if ! $id;

    my $lcid = lc $id;
    croak "$id meta value is not supported" if ! exists $info{ $lcid };

    return $info{ $lcid };
}

sub ip {
    my $self = shift;
    require Socket;
    require Sys::Hostname;
    my $host = gethostbyname Sys::Hostname::hostname() || return;
    my $ip   = Socket::inet_ntoa($host);
    $ip = $self->SUPER::_ip()
        if $ip && $ip =~ m{ \A 127 }xms && $self->SUPER::can('_ip');
    return $ip;
}

sub locale {
    return if ! $POSIX;
    my $self = shift;
    return setlocale( LC_CTYPE() );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Sys::Info::OS

=head1 VERSION

version 0.7807

=head1 SYNOPSIS

   use Sys::Info;
   my $info = Sys::Info->new;
   my $os   = $info->os(%options);

or

   use Sys::Info::OS;
   my $os = Sys::Info::OS->new(%options);

Example:

   use Data::Dumper;
   
   warn "Collected information can be incomplete\n" if $os->is_unknown;
   
   my %fs = $os->fs;
   print Data::Dumper->Dump([\%fs], ['*FILE_SYSTEM']);
   
   print "B1ll G4teZ rull4z!\n" if $os->is_windows;
   print "Pinguin detected!\n"  if $os->is_linux;
   if ( $os->is_windows ) {
      printf "This is a %s based system\n", $os->is_winnt ? 'NT' : '9.x';
   }
   printf "Operating System: %s\n", $os->name( long => 1 );
   
   my $user = $os->login_name( real => 1 ) || $os->login_name || 'User';
   print "$user, You've Got The P.O.W.E.R.!\n" if $os->is_root;
   
   if ( my $up = $os->uptime ) {
      my $tick = $os->tick_count;
      printf "Running since %s\n"   , scalar localtime $up;
      printf "Uptime: %.2f hours\n" , $tick / (60*60      ); # probably windows
      printf "Uptime: %.2f days\n"  , $tick / (60*60*24   ); # might be windows
      printf "Uptime: %.2f months\n", $tick / (60*60*24*30); # hmm... smells like tux
   }

=head1 DESCRIPTION

Supplies detailed operating system information.

=head1 NAME

Sys::Info::OS - Detailed os information.

=head1 METHODS

=head2 new

Object constructor.

=head2 name

Returns the OS name. Supports these named parameters: C<edition>, C<long>:

   # also include the edition info if present
   $os->name( edition => 1 );

This will return the long OS name (with build number, etc.):

   # also include the edition info if present
   $os->name( long => 1, edition => 1 );

=head2 version

Returns the OS version.

=head2 build

Returns the OS build number or build date, depending on
the system.

=head2 uptime

Returns the uptime as a unix timestamp.

=head2 tick_count

Returns the uptime in seconds since the machine booted.

=head2 node_name

Machine name

=head2 domain_name

Returns the network domain name.

Synonyms:

=over 4

=item workgroup

=back

=head2 login_name

Returns the name of the effective user. Supports parameters in
C<< name => value >> format. Accepted parameters: C<real>:

    my $user = $os->login_name( real => 1 ) || $os->login_name;

=head2 ip

Returns the IP number.

=head2 fs

Returns an info hash about the filesystem. The contents of the hash can
vary among different systems.

=head2 host_name

=head2 time_zone

=head2 product_type

=head2 bitness

If successful, returns the bitness ( C<32> or C<64> ) of the OS. Returns
false otherwise.

=head2 meta

Returns a hash containing various informations about the OS.

=head2 cdkey

=head2 locale

=head1 UTILITY METHODS

These are some useful utility methods.

=head2 is_windows

Returns true if the os is windows.
Synonyms:

=over 4

=item is_win32

=item is_win

=back

=head2 is_winnt

Returns true if the OS is a NT based system (NT/2000/XP/2003).

Always returns false if you are not under windows or you are
not under a NT based system.

=head2 is_win95

Returns true if the OS is a 9x based system (95/98/Me).

Always returns false if you are not under Windows or
Windows9x.

Synonyms:

=over 4

=item is_win9x

=back

=head2 is_linux

Returns true if the os is linux.
Synonyms:

=over 4

=item is_lin

=back

=head2 is_bsd

Returns true if the os is (free|open|net)bsd.

=head2 is_unknown

Returns true if this module does not support the OS directly.

=head2 is_root

Returns true if the current user has admin rights.
Synonyms:

=over 4

=item is_admin

=item is_admin_user

=item is_adminuser

=item is_root_user

=item is_rootuser

=item is_super_user

=item is_superuser

=item is_su

=back

=head1 CAVEATS

=over 4

=item *

I don't have access to all operating systems in the world, so this module
(currently) only supports Windows, Linux and (Free)BSD. Windows support is better.
If you want support for some other OS, you'll need to write the driver
yourself. Anything other than natively supported systems will fall-back
to the generic C<Unknown> driver which has I<very> limited capabilities.

=item *

Win32::IsAdminUser() implemented in 5.8.4 (However, it is possible to
manually upgrade the C<Win32> module). If your ActivePerl
is older than this, C<is_admin> method will always returns false.
(There I<may> be a workaround for that).

=item *

Contents of the filesystem hash may change in further releases.

=item *

Filesystem [Windows]

File system information can not be extracted under restricted
environments. If this is the case, we'll get an
I<access is denied> error.

=item *

Bitness has some problems [Linux, BSD], especially on the os side.

=back

=head1 SEE ALSO

L<Win32>, L<POSIX>, 
L<Sys::Info>,
L<Sys::Info::Device>,
L<http://msdn.microsoft.com/library/en-us/sysinfo/base/osversioninfoex_str.asp>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


use Socket;
sub network_name {
   my $self  = shift;
   my $ip    = shift;
   my $iaddr = inet_aton($ip);
   my $name  = gethostbyaddr($iaddr, AF_INET);
   return $name || $ip;
}

#<TODO>
sub disk_quota {}
#</TODO>
