############################################################
#
#   $Id$
#   Sys::Filesystem - Retrieve list of filesystems and their properties
#
#   Copyright 2004,2005,2006 Nicola Worthington
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

package Sys::Filesystem::Mswin32;

# vim:ts=4:sw=4:tw=78

use 5.008001;

use strict;
use warnings;
use vars qw($VERSION);

use Params::Util qw(_STRING);
use Win32::DriveInfo;
use Carp qw(croak);

$VERSION = '1.406';

sub version()
{
    return $VERSION;
}

my @volInfoAttrs = ( 'n/a', 'preserve case', 'case sensitive', 'unicode', 'acl', 'file compression', 'compressed volume' );
my @typeExplain = ( 'unable to determine', 'no root directory', 'removeable', 'fixed', 'network', 'cdrom', 'ram disk' );

sub new
{
    ref( my $class = shift ) && croak 'Class name required';
    my %args = @_;
    my $self = {};

    my @drives = Win32::DriveInfo::DrivesInUse();

    for my $drvletter (@drives)
    {
        my $type = Win32::DriveInfo::DriveType($drvletter);
        my ( $VolumeName, $VolumeSerialNumber, $MaximumComponentLength, $FileSystemName, @attr ) =
          Win32::DriveInfo::VolumeInfo($drvletter);

        my $drvRoot = $drvletter . ":/";
        defined( _STRING($VolumeName) ) and $VolumeName =~ s/\\/\//g;
        defined( _STRING($VolumeName) ) or $VolumeName = $drvRoot;
        $VolumeName = ucfirst($VolumeName);

        $FileSystemName ||= 'CDFS' if ( $type == 5 );

        # XXX Win32::DriveInfo gives no details here ...
        $self->{$drvRoot}->{mount_point} = $drvRoot;
        $self->{$drvRoot}->{device}      = $VolumeName;
        # XXX Win32::DriveInfo gives sometime wrong information here
        $self->{$drvRoot}->{format} = $FileSystemName;
        $self->{$drvRoot}->{options} = join( ',', map { $volInfoAttrs[$_] } @attr );
        my $mntstate = ( ( defined $FileSystemName ) and $type > 1 );
        $mntstate
          and 2 == $type
          and $mntstate = Win32::DriveInfo::IsReady($drvletter);
        $mntstate = $mntstate ? "mounted" : "unmounted";
        $self->{$drvRoot}->{$mntstate} = 1;
        $type > 0 and $self->{$drvRoot}->{type} = $typeExplain[$type];
    }

    bless( $self, $class );
    return $self;
}

1;

=pod

=head1 NAME

Sys::Filesystem::Mswin32 - Return Win32 filesystem information to Sys::Filesystem

=head1 SYNOPSIS

See L<Sys::Filesystem>.

=head1 INHERITANCE

  Sys::Filesystem::Mswin32
  ISA UNIVERSAL

=head1 METHODS

=over 4

=item version ()

Return the version of the (sub)module.

=back

=head1 ATTRIBUTES

=over 4

=item mount_point

Mount point.

=item device

Device of the file system.

=item mounted

True when mounted.

=back

=head1 VERSION

$Id$

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org> - L<http://perlgirl.org.uk>

Jens Rehsack <rehsack@cpan.org> - L<http://www.rehsack.de/>

=head1 BUGS AND LIMITATIONS

As long no better data source as Win32::DriveInfo is available, only mounted
drives are recognized, no UNC names neither file systems mounted to a path.

=head1 COPYRIGHT

Copyright 2004,2005,2006 Nicola Worthington.

Copyright 2009-2014 Jens Rehsack.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut

