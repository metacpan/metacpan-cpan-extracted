package Sys::FS;
{
  $Sys::FS::VERSION = '0.11';
}
BEGIN {
  $Sys::FS::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: filesystem interaction tools

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Carp;
use File::Spec;
use File::Copy qw();

use Sys::Run;

with 'Log::Tree::RequiredLogger';

has 'sys' => (
    'is'      => 'ro',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( { 'logger' => $self->logger(), } );

    return $Sys;
}

############################################
# Usage      : Create an absolute filename
sub filename {
    my ( $self, @dirs ) = @_;

    if ( !@dirs ) {
        my $msg = 'Missing option in Sys::FS::filename. Need at least one directory. Caller: ' . ( caller(1) )[3];
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }

    my $filename = File::Spec->catfile(@dirs);
    return $filename;
}

sub switch {
    my $self       = shift;
    my $sourcefile = shift;
    my $destfile   = shift;

    if($sourcefile && ref($sourcefile)) {
        $self->logger()->log( message => 'Refusing to switch multiple source files to one destination. Check your configuration.', level => 'error', );
        return;
    }

    if($destfile && ref($destfile)) {
        $self->logger()->log( message => 'Refusing to switch one source file to multiple destinations. Check your configuration.', level => 'error', );
        return;
    }

    my @cmds = ();

    # unlink old backup, if it doesn't exist do nothing
    if ( -e $destfile . '.bak' ) {
        if ( unlink( $destfile . '.bak' ) ) {
            $self->logger()->log( message => 'source: '.$sourcefile.' - dest: '.$destfile.' - Removed old backup.', level => 'debug', );
        }
        else {
            $self->logger()->log( message => 'source: '.$sourcefile.' - dest: '.$destfile.' - Could not remove old backup: ' . $!, level => 'error', );
            return;
        }
    }

    # prepare new config for switch
    if ( File::Copy::copy( $sourcefile, $destfile . '.new' ) ) {
        $self->logger()->log( message => "source: $sourcefile - dest: $destfile - Successfully copied to .new file.", level => 'debug', );
    }
    else {
        $self->logger()->log( message => "source: $sourcefile - dest: $destfile - Failed to copy $sourcefile to $destfile.new", level => 'error', );
        return;
    }

    # create backup of old config
    if ( -e $destfile ) {
        if ( File::Copy::copy( $destfile, $destfile . '.bak' ) ) {
            $self->logger()->log( message => "source: $sourcefile - dest: $destfile - Successfully created backup.", level => 'debug', );
        }
        else {
            $self->logger()->log( message => "source: $sourcefile - dest: $destfile - Failed to copy $destfile to $destfile.bak", level => 'error' );
            return;
        }
    }

    # perform the final switch (atomic? should be ...)
    if ( rename( $destfile . '.new', $destfile ) ) {
        $self->logger()->log( message => "source: $sourcefile - dest: $destfile - Successfully switched files.", level => 'debug', );
        return 1;
    }
    else {
        $self->logger()->log( message => "source: $sourcefile - dest: $destfile - Failed to copy $destfile.new to $destfile", level => 'error', );
        return;
    }
}

############################################
# Usage      : Create a directory stucture and return the created directory
sub makedir {
    my $self     = shift;
    my $filename = shift;
    my $opts     = shift || {};

    if ( !$filename ) {
        my $msg = 'No filename given in Sys::FS::makedir! Caller: ' . ( caller(1) )[3];
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }

    my $mode = $opts->{'Mode'} || oct(777);

    my @dirs   = File::Spec::->splitdir($filename);
    my $dir    = q{};
    my $mkdirs = 0;
    foreach my $i ( 0 .. $#dirs ) {
        $dir = File::Spec::->catdir( @dirs[ 0 .. $i ] );
        if ( !-d $dir ) {
            my $msg = "Filename: $filename - mkdir $dir, $mode";
            if ( mkdir( $dir, $mode ) ) {
                $self->logger()->log( message => $msg, level => 'debug', );
                $mkdirs++;
            }
            else {
                $self->logger()->log( message => $msg . ' FAILED!', level => 'debug', );
            }
            if ( $opts->{'Uid'} && $opts->{'Gid'} ) {
                chown $opts->{'Uid'}, $opts->{'Gid'} => $dir;
            }
        }
    }
    my $msg = "Filename: $filename - created $mkdirs dirs for $dir";
    $self->logger()->log( message => $msg, level => 'debug', );
    return $dir;
}

sub spaceleft {
    my $self = shift;
    my $dir  = shift;
    my $host = shift || 'localhost';
    my $opts = shift || {};

    # check free space on destination
    local $opts->{CaptureOutput} = 1;
    local $opts->{Chomp}         = 1;
    my $cmd = 'LANG=C /bin/df -P ' . $dir . ' | /usr/bin/tail -1';
    my $out = $self->sys()->run( $host, $cmd, $opts );

    my ( $dev, $onekblocks, $used, $avail, $pcfree, $mount_point ) = split /\s+/, $out;
    $avail      = 0 unless $avail      =~ m/^\d+$/;
    $onekblocks = 0 unless $onekblocks =~ m/^\d+$/;
    my $gbfree  = int( $avail /      ( 1024 * 1024 ) );
    my $gbtotal = int( $onekblocks / ( 1024 * 1024 ) );
    $pcfree =~ s/%$//;

    return wantarray ? ( $gbfree, $pcfree, $gbtotal ) : $gbfree;
}

sub fsck {
    my $self    = shift;
    my $device  = shift;
    my $fs_type = shift;
    my $opts    = shift || {};
    if ( $fs_type && -x '/sbin/fsck.'.$fs_type ) {
        $self->sys()->run_cmd('/sbin/fsck.'.$fs_type.' -y -p '.$device);
        return 1;
    }
    else {
        my $msg = "fsck($device,$fs_type) - dunno how to check $fs_type!";
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }
}

# used by get_mounted_device
sub mounts {
    my $self = shift;
    my $opts = shift || {};

    my $mounts_file = '/proc/mounts';
    if ( open( my $FH, '<', $mounts_file ) ) {
        my @lines = <$FH>;
        # DGR: just reading
        ## no critic (RequireCheckedClose)
        close($FH);
        ## use critic
        my %mounts = ();
        foreach my $line (@lines) {
            my ( $dev, $mount_point, $fs_type, $options, $dump, $pass ) = split( /\s/, $line );
            my $key;
            if ( $opts->{DevAsKey} ) {
                $key = $dev;
                $mounts{$key}{'mount_point'} = $mount_point;
            }
            else {    # MountPointAsKey
                $key = $mount_point;
                $mounts{$key}{'dev'} = $dev;
            }
            $mounts{$key}{'fs_type'} = $fs_type;
            $mounts{$key}{'options'} = $options;
            $mounts{$key}{'dump'}    = $dump;
            $mounts{$key}{'pass'}    = $pass;
        }
        return \%mounts;
    }
    else {
        my $msg = "Could not open $mounts_file: $!";
        $self->logger()->log( message => $msg, level => 'error', );
        return {};
    }
}

sub is_mounted {
    my $self   = shift;
    my $device = shift;
    my $opts   = shift || {};

    # check if given device is mounted
    local $opts->{DevAsKey} = 1;
    my $mounts = $self->mounts($opts);
    foreach my $dev ( keys %{$mounts} ) {
        if ( $device =~ m/^$dev/ ) {
            return 1;
        }
    }
    return;
}

sub get_mounted_device {
    my $self = shift;
    my $path = shift;
    my $opts = shift || {};

    $self->logger()->log( message => "$path", level => 'debug', );

    # get mounts indexed by mount point as key, so we
    # can traverse over the mounts to find the longest matching one
    my $mounts      = $self->mounts( { DevAsKey => 0, } );
    my $device      = undef;
    my $mount_point = undef;

    # sort the keys be length, the shortest (the root fs at /) first
    # and use the longest still-matching one as the mounted device
    # for the given path
    foreach my $key ( sort { length($a) <=> length($b) } keys %{$mounts} ) {
        if ( $path =~ m/^$key/ ) {
            $device      = $mounts->{$key}{'dev'};
            $mount_point = $key;
        }
    }

    if ( !$mount_point ) {
        my $msg = "get_mounted_device($path) - no matching mount point found!";
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }

    $self->logger()->log(
        message => 'Path: '.$path.' - returning '.$device.', ' . $mounts->{$mount_point}{'fs_type'} . ', ' . $mounts->{$mount_point}{'options'} . ', '.$mount_point,
        level   => 'debug',
    );

    return wantarray ? ( $device, $mounts->{$mount_point}{'fs_type'}, $mounts->{$mount_point}{'options'}, $mount_point ) : $device;
}

sub mount {
    my $self        = shift;
    my $device      = shift;
    my $mount_point = shift;
    my $fs_type     = shift;
    my $fs_opts     = shift;
    my $opts        = shift || {};

    if ( $fs_type eq 'xfs' && $fs_opts !~ m/nouuid/i ) {
        $fs_opts .= ',nouuid';
    }

    # device must be a block device
    if ( !-b $device ) {
        my $msg = "mount($device,$mount_point,$fs_type,$fs_opts) - $device is no block-device!";
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }

    # mp must be a dir
    if ( !-d $mount_point ) {
        my $msg = "mount($device,$mount_point,$fs_type,$fs_opts) - $mount_point is no directory!";
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }

    my $cmd = "/bin/mount -t $fs_type -o $fs_opts $device $mount_point";
    local $opts->{Timeout} = 1200;
    return $self->sys()->run_cmd( $cmd, $opts );
}

sub umount {
    my $self   = shift;
    my $device = shift;
    my $opts   = shift || {};

    # device must be a block device
    if ( !-b $device ) {
        my $msg = "umount($device) - $device is no block-device!";
        $self->logger()->log( message => $msg, level => 'error', );
        return;
    }

    my $cmd = "/bin/umount $device >/dev/null 2>&1";
    return $self->sys()->run_cmd( $cmd, $opts );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::FS - filesystem interaction tools

=head1 SYNOPSIS

    use Sys::FS;
    use Log::Tree;
    my $FS = Sys::FS::->new({
    	'logger'	=> Log::Tree::->new();
    });
    my $filename = $FS->filename('/tmp', qw(a list of subdirs));
    $FS->makedir($filename);
    my ($gb, $percent) = $FS->spaceleft($filename);

=head1 ATTRIBUTES

=head2 sys

An instance of Linux::System

=head1 METHODS

=head2 filename

Construct a filename out of an array of directories.

=head2 fsck

Run fsck on the given device.

=head2 get_mounted_device

Find the device mounted on the given directory.

=head2 is_mounted

Tests if a given device is currently mounted.

=head2 makedir

Create a directory stucture and return the created directory

=head2 mount

Mount a device on a mount point.

=head2 mounts

Return a hashref containing all mounted devices.

=head2 spaceleft

Return the amount of free space on the given device in GB.

=head2 switch

Reliably switch two files.

=head2 umount

Unmount a given device.

=head1 NAME

Sys::FS - Misc. Filesystem interaction methods

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
