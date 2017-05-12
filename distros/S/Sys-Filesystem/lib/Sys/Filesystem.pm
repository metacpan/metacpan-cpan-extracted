############################################################
#
#   $Id$
#   Sys::Filesystem - Retrieve list of filesystems and their properties
#
#   Copyright 2004,2005,2006 Nicola Worthington
#   Copyright 2008,2009 Jens Rehsack
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Sys::Filesystem;

# vim:ts=4:sw=4:tw=78

use 5.008001;

my @query_order;

use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD $CANONDEV $FSTAB $MTAB);
use Carp qw(croak cluck confess);
use Module::Pluggable
  require => 1,
  only  => [ @query_order = map { __PACKAGE__ . '::' . $_ } ( ucfirst( lc $^O ), $^O =~ m/Win32/i ? 'Win32' : 'Unix', 'Dummy' ) ],
  inner => 0,
  search_path => ['Sys::Filesystem'],
  sub_name    => '_plugins';
use Params::Util qw(_INSTANCE);
use Scalar::Util qw(blessed);
use List::Util qw(first);

use constant DEBUG   => $ENV{SYS_FILESYSTEM_DEBUG} ? 1 : 0;
use constant SPECIAL => ( 'darwin' eq $^O )        ? 0 : undef;

$VERSION = '1.406';

my ( $FsPlugin, $Supported );

BEGIN
{
    Sys::Filesystem->_plugins();

    foreach my $qo (@query_order)
    {
        next unless ( UNIVERSAL::isa( $qo, $qo ) );
        $FsPlugin = $qo;
        last;
    }

    $Supported = $FsPlugin ne 'Sys::Filesystem::Unix' and $FsPlugin ne 'Sys::Filesystem::Dummy';
}

sub new
{
    # Check we're being called correctly with a class name
    ref( my $class = shift ) and croak 'Class name required';

    # Check we've got something sane passed
    croak 'Odd number of elements passed when even number was expected' if ( @_ % 2 );
    my %args = @_;

    exists $args{xtab} and carp("Using xtab is depreciated") and delete $args{xtab};
    defined $FSTAB    and not exists $args{fstab}    and $args{fstab}    = $FSTAB;
    defined $MTAB     and not exists $args{mtab}     and $args{mtab}     = $MTAB;
    defined $CANONDEV and not exists $args{canondev} and $args{canondev} = $CANONDEV;

    # Double check the key pairs for stuff we recognise
    my @sane_keys = qw(aliases canondev fstab mtab);
    my %sane_args;
    @sane_args{@sane_keys} = delete @args{@sane_keys};
    scalar keys %args and croak( "Unrecognised parameter(s) '" . join( "', '", sort keys %args ) . "' passed to module $class" );

    my $self = {%sane_args};

    # Filesystem property aliases - unless caller knows better ...
    defined $self->{aliases}
      or $self->{aliases} = {
        device          => [qw(fs_spec dev)],
        filesystem      => [qw(fs_file mount_point)],
        mount_point     => [qw(fs_file filesystem)],
        type            => [qw(fs_vfstype vfs)],
        format          => [qw(fs_vfstype vfs vfstype)],
        options         => [qw(fs_mntops)],
        check_frequency => [qw(fs_freq)],
        check_order     => [qw(fs_passno)],
        boot_order      => [qw(fs_mntno)],
        volume          => [qw(fs_volume fs_vol vol)],
        label           => [qw(fs_label)],
      };

    # Debug
    DUMP( '$self', $self ) if (DEBUG);

    $self->{filesystems} = $FsPlugin->new(%sane_args);

    # Maybe upchuck a little
    croak "Unable to create object for OS type '$self->{osname}'" unless ( $self->{filesystems} );

    # Bless and return
    bless( $self, $class );
    return $self;
}

sub filesystems
{
    my $self = shift;
    unless ( defined( _INSTANCE( $self, __PACKAGE__ ) ) )
    {
        unshift @_, $self unless ( 0 == ( scalar(@_) % 2 ) );
        $self = __PACKAGE__->new();
    }

    # Check we've got something sane passed
    @_ % 2 and croak 'Odd number of elements passed when even number was expected';

    my $params = {@_};
    for my $param ( keys %{$params} )
    {
        croak "Illegal paramater '$param' passed to filesystems() method"
          unless grep( m/^$param$/, qw(mounted unmounted special device regular) );
    }

    # Invert logic for regular
    if ( exists $params->{regular} )
    {
        delete $params->{regular};
        exists( $params->{special} )
          and carp("Mutual exclusive parameters 'special' and 'regular' specified together");
        $params->{special} = SPECIAL;
    }

    my @filesystems = ();

    # Return list of all filesystems
    keys %{$params} or return sort( keys( %{ $self->{filesystems} } ) );

    for my $fsname ( sort( keys( %{ $self->{filesystems} } ) ) )
    {
        for my $requirement ( keys( %{$params} ) )
        {
            my $fs = $self->{filesystems}->{$fsname};
            my $fsreqname =
              ( !exists $fs->{$requirement} and exists $self->{aliases}->{$requirement} )
              ? first { exists $fs->{$_} } @{ $self->{aliases}->{$requirement} }
              : $requirement;

            defined $params->{$requirement}
              and exists $fs->{$fsreqname}
              and $fs->{$fsreqname} eq $params->{$requirement}
              and push( @filesystems, $fsname )
              and last;
            push( @filesystems, $fsname ) and last
              unless defined( $params->{$requirement} )
              or exists( $fs->{$fsreqname} );
        }
    }

    # Return
    return @filesystems;
}

sub supported
{
    return $Supported;
}

sub mounted_filesystems
{
    return $_[0]->filesystems( mounted => 1 );
}

sub unmounted_filesystems
{
    return $_[0]->filesystems( unmounted => 1 );
}

sub special_filesystems
{
    return $_[0]->filesystems( special => 1 );
}

sub regular_filesystems
{
    return $_[0]->filesystems( special => SPECIAL );
}

sub DESTROY { }

sub AUTOLOAD
{
    my ( $self, $fsname ) = @_;

    croak "$self is not an object" unless ( blessed($self) );
    croak "No filesystem passed where expected" unless ($fsname);

    ( my $name = $AUTOLOAD ) =~ s/.*://;

    # No such filesystem
    exists $self->{filesystems}->{$fsname} or croak "No such filesystem";

    # Found the property
    my $fs = $self->{filesystems}->{$fsname};

    exists $fs->{$name} and return $fs->{$name};

    # Didn't find the property, but check any aliases
    exists $self->{aliases}->{$name}
      and $name = first { exists $fs->{$_} } @{ $self->{aliases}->{$name} }
      and return $fs->{$name};

    return;
}

sub TRACE
{
    return unless DEBUG;
    warn( $_[0] );
}

sub DUMP
{
    return unless DEBUG;
    eval {
        require Data::Dumper;
        warn( shift() . ': ' . Data::Dumper::Dumper( shift() ) );
    };
}

1;

=pod

=head1 NAME

Sys::Filesystem - Retrieve list of filesystems and their properties

=head1 SYNOPSIS

    use strict;
    use Sys::Filesystem ();
    
    # Method 1
    my $fs = Sys::Filesystem->new();
    my @filesystems = $fs->filesystems();
    for (@filesystems)
    {
        printf("%s is a %s filesystem mounted on %s\n",
                          $fs->mount_point($_),
                          $fs->format($_),
                          $fs->device($_)
                   );
    }
    
    # Method 2
    my $weird_fs = Sys::Filesystem->new(
                          fstab => '/etc/weird/vfstab.conf',
                          mtab  => '/etc/active_mounts',
                          xtab  => '/etc/nfs/mounts'
                    );
    my @weird_filesystems = $weird_fs->filesystems();
    
    # Method 3 (nice but naughty)
    my @filesystems = Sys::Filesystem->filesystems();

=head1 DESCRIPTION

Sys::Filesystem is intended to be a portable interface to list and query
filesystem names and their properties. At the time of writing there were only
Solaris and Win32 modules available on CPAN to perform this kind of operation.
This module hopes to provide a consistent API to list all, mounted, unmounted
and special filesystems on a system, and query as many properties as possible
with common aliases wherever possible.

=head1 INHERITANCE

  Sys::Filesystem
  ISA UNIVERSAL

=head1 METHODS

=over 4

=item new

Creates a new Sys::Filesystem object. C<new> accepts following optional key
value pairs to help or force where mount information is gathered from. These
values are not otherwise defaulted by the main Sys::Filesystem object, but
left to the platform specific helper modules to determine as an exercise of
common sense.

=over 4

=item canondev

Specify whether device path's shall be resolved when they're a symbolic
link.

C<$Sys::Filesystem::CANONDEV> is used when no key C<canondev> is passed.

=item fstab

Specify the full path and filename of the filesystem table (or fstab for
short). Not all platforms have such a file and so this option may be
ignored on some systems.

C<$Sys::Filesystem::FSTAB> is used when no key C<fstab> is passed.

=item mtab

Specify the full path and filename of the mounted filesystem table (or mtab
for short). Not all platforms have such a file and so this option may be
ignored on some systems.

C<$Sys::Filesystem::MTAB> is used when no key C<mtab> is passed.

=item xtab

B<DEPRECIATED> Specify the full path and filename of the mounted NFS
filesystem table (or xtab for short). This is usually only pertinant
to Unix bases systems.  Not all helper modules will query NFS mounts
as a separate exercise, and therefore this option may be ignored on
some systems.

B<None> of the OS plugins use that tunable (anymore?), so it now a warning
is raised when it's used. The entire support will be removed not before
2015. Once that happened, using C<xtab> will raise an exception.

=item aliases

Overrides internal aliasing table used to match queries against OS
plugin. This should be used only when dealing with closed source platform
helper module(s).

=back

=item supported

Returns true if the operating system is supported by Sys::Filesystem.
Unsupported operating systems may get less information, e.g. the mount
state couldn't determined or which file system type is special ins't
known.

=back

=head2 Listing Filesystems

=over 4

=item filesystems()

Returns a list of all filesystem. May accept an optional list of key pair
values in order to filter/restrict the results which are returned. The
restrictions are evaluated to match as much as possible, so asking for
regular and special file system (or mounted and special file systems),
you'll get all.

For better understanding, please imagine the parameters like:

  @fslist = $fs->filesystems( mounted => 1, special => 1 );
  # results similar as
  SELECT mountpoint FROM filesystems WHERE mounted = 1 OR special = 1

If you need other selection choices, please take a look at L<DBD::Sys>.

Valid values are as follows:

=over 4

=item device => "string"

Returns only filesystems that are mounted using the device of "string".
For example:

    my $fdd_filesytem = Sys::Filesystem->filesystems(device => "/dev/fd0");

=item mounted => 1

Returns only filesystems which can be confirmed as actively mounted.
(Filesystems which are mounted).

The mounted_filesystems() method is an alias for this syntax.

=item unmounted => 1

Returns only filesystems which cannot be confirmed as actively mounted.
(Filesystems which are not mounted).

The unmounted_filesystems() method is an alias for this syntax.

=item special => 1

Returns only filesystems which are regarded as special in some way. A
filesystem is marked as special by the operating specific helper
module. For example, a tmpfs type filesystem on one operating system
might be regarded as a special filesystem, but not on others. Consult
the documentation of the operating system specific helper module for
further information about your system. (Sys::Filesystem::Linux for Linux
or Sys::Filesystem::Solaris for Solaris etc).

This parameter is mutually exclusive to C<regular>.

The special_filesystems() method is an alias for this syntax.

=item regular => 1

Returns only fileystems which are not regarded as special. (Normal
filesystems).

This parameter is mutually exclusive to C<special>.

The regular_filesystems() method is an alias for this syntax.

=back

=item mounted_filesystems()

Returns a list of all filesystems which can be verified as currently
being mounted.

=item unmounted_filesystems()

Returns a list of all filesystems which cannot be verified as currently
being mounted.

=item special_filesystems()

Returns a list of all fileystems which are considered special. This will
usually contain meta and swap partitions like /proc and /dev/shm on Linux.

=item regular_filesystems()

Returns a list of all filesystems which are not considered to be special.

=back

=head2 Filesystem Properties

Available filesystem properties and their names vary wildly between platforms.
Common aliases have been provided wherever possible. You should check the
documentation of the specific platform helper module to list all of the
properties which are available for that platform. For example, read the
Sys::Filesystem::Linux documentation for a list of all filesystem properties
available to query under Linux.

=over 4

=item mount_point() or filesystem()

Returns the friendly name of the filesystem. This will usually be the same
name as appears in the list returned by the filesystems() method.

=item mounted()

Returns boolean true if the filesystem is mounted.

=item label()

Returns the fileystem label.

This functionality may need to be retrofitted to some original OS specific
helper modules as of Sys::Filesystem 1.12.

=item volume()

Returns the volume that the filesystem belongs to or is mounted on.

This functionality may need to be retrofitted to some original OS specific
helper modules as of Sys::Filesystem 1.12.

=item device()

Returns the physical device that the filesystem is connected to.

=item special()

Returns boolean true if the filesystem type is considered "special".

=item type() or format()

Returns the type of filesystem format. fat32, ntfs, ufs, hpfs, ext3, xfs etc.

=item options()

Returns the options that the filesystem was mounted with. This may commonly
contain information such as read-write, user and group settings and
permissions.

=item mount_order()

Returns the order in which this filesystem should be mounted on boot.

=item check_order()

Returns the order in which this filesystem should be consistency checked
on boot.

=item check_frequency()

Returns how often this filesystem is checked for consistency.

=back

=head1 OS SPECIFIC HELPER MODULES

=head2 Dummy

The Dummy module is there to provide a default failover result to the main
Sys::Filesystem module if no suitable platform specific module can be found
or successfully loaded. This is the last module to be tried, in order of
platform, Unix (if not on Win32), and then Dummy.

=head2 Unix

The Unix module is intended to provide a "best guess" failover result to the
main Sys::Filesystem module if no suitable platform specific module can be
found, and the platform is not 'MSWin32'.

This module requires additional work to improve it's guestimation abilities.

=head2 Darwin

First written by Christian Renz <crenz@web42.com>.

=head2 Win32

Provides C<mount_point> and C<device> of mounted filesystems on Windows.

=head2 AIX

Please be aware that the AIX /etc/filesystems file has both a "type" and
"vfs" field. The "type" field should not be confused with the filesystem
format/type (that is stored in the "vfs" field). You may wish to use the
"format" field when querying for filesystem types, since it is aliased to
be more reliable accross different platforms.

=head2 Other

Linux, Solaris, Cygwin, FreeBSD, NetBSD, HP-UX.

=head2 OS Identifiers

The following list is taken from L<perlport>. Please refer to the original
source for the most up to date version. This information should help anyone
who wishes to write a helper module for a new platform. Modules should have
the same name as ^O in title caps. Thus 'openbsd' becomes 'Openbsd.pm'.

=head1 REQUIREMENTS

Sys::Filesystem requires Perl >= 5.6 to run.

=head1 TODO

Add support for Tru64, MidnightBSD, Haiku, Minix, DragonflyBSD and OpenBSD.
Please contact me if you would like to provide code for these operating
systems.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sys::Filesystem

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sys-Filesystem>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sys-Filesystem>

=item * CPAN Ratings

L<http://cpanratings.perl.org/s/Sys-Filesystem>

=item * Search CPAN

L<http://search.cpan.org/dist/Sys-Filesystem/>

=back

=head1 SEE ALSO

L<perlport>, L<Solaris::DeviceTree>, L<Win32::DriveInfo>

=head1 VERSION

$Id$

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org> - L<http://perlgirl.org.uk>

Jens Rehsack <rehsack@cpan.org> - L<http://www.rehsack.de/>

=head1 ACKNOWLEDGEMENTS

See CREDITS in the distribution tarball.

=head1 COPYRIGHT

Copyright 2004,2005,2006 Nicola Worthington.

Copyright 2008-2014 Jens Rehsack.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

