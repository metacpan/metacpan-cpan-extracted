package PkgForge::PidFile; # -*- perl -*-
use strict;
use warnings;

# $Id: PidFile.pm.in 15149 2010-12-17 09:00:50Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15149 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/PidFile.pm.in $
# $Date: 2010-12-17 09:00:50 +0000 (Fri, 17 Dec 2010) $

our $VERSION = '1.1.10';

use English qw( -no_match_vars );
use Fcntl qw(:flock O_WRONLY O_EXCL O_CREAT);
use File::Spec ();
use IO::File ();

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Getopt::OptionTypeMap;
use MooseX::Types::Moose qw(Int Str);

coerce 'PkgForge::PidFile',
    from Str,
    via { PkgForge::PidFile->new( file => $_ ) };

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    'PkgForge::PidFile' => '=s',
);

has 'file' => (
    is        => 'rw',
    isa       => Str,
    lazy      => 1,
    predicate => 'has_pidfile',
    builder   => 'init_pidfile',
);

has 'pid' => (
    is        => 'rw',
    isa       => Int,
    lazy      => 1,
    predicate => 'has_pid',
    clearer   => 'clear_pid',
    builder   => 'init_pid',
);

has 'progname' => (
    is      => 'rw',
    isa     => Str,
    default => sub { return (File::Spec->splitpath( $PROGRAM_NAME ) )[-1] },
);

has 'basedir' => (
    is      => 'rw',
    isa     => Str,
    default => sub { File::Spec->tmpdir },
);

has 'mode' => (
    is      => 'rw',
    isa     => Int,
    default => sub { oct '0644' },
);

sub init_pid {
    my ($self) = @_;

    my $pid;
    if ( $self->does_file_exist ) {
        my $file = $self->file;

        my $fh = IO::File->new( $file, 'r' )
            or die "Could not open PID file $file: $OS_ERROR\n";
        chomp( my $contents = $fh->getline );
        $fh->close;

        if ( $contents =~ m/^(\d+)/ ) {
            $pid = $1;
        }
        else {
            die "Failed to parse contents of PID file $file\n";
        }
    }

    $pid = $PROCESS_ID if !defined $pid; # Default

    return $pid;
}

sub init_pidfile {
    my ($self) = @_;

    my $file = $self->progname . '.pid';
    return File::Spec->catfile( $self->basedir, $file );
}

sub store {
    my ($self) = @_;

    my $file = $self->file;

    my $pid = $self->pid;

    my $fh = IO::File->new( $file, O_WRONLY|O_EXCL|O_CREAT, $self->mode )
        or die "Could not open PID file $file: $OS_ERROR\n";
    flock( $fh, LOCK_EX|LOCK_NB ) or die "Could not lock: $OS_ERROR\n";
    $fh->print($pid . "\n");
    $fh->close or die "Could not close PID file: $OS_ERROR\n";

    return 1;
}

sub does_file_exist {
    my ($self) = @_;

    # Done this way to avoid it returning an undef
    return ( -f $self->file || 0 );
}

sub is_running {
    my ($self) = @_;

    my $pid = $self->pid;

    if ( -d "/proc/$pid" ) {
        return 1;
    } else {
        return kill 0, $pid;
    }

}

sub remove {
    my ($self) = @_;

    if ( $self->does_file_exist ) {
        return unlink $self->file;
    }
    else {
        return 1;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

PkgForge::PidFile - A class to provide simple PID file handling

=head1 VERSION

This documentation refers to PkgForge::PidFile version 1.1.10

=head1 SYNOPSIS

     use PkgForge::PidFile;

     my $pidfile = PkgForge::PidFile->new();

     if ( $pidfile->is_running ) {
        my $pid = $pidfile->pid;
        die "daemon process ($pid) already running\n";
      }
      elsif ( $pidfile->does_file_exist ) {
        $self->pidfile->remove;
      }

      $pidfile->pid($PROCESS_ID);
      $pidfile->store;

=head1 DESCRIPTION


=head1 ATTRIBUTES

=over

=item file

A string representing the full path to the file in which the PID is stored.

=item pid

An integer PID.

=item progname

The name of the program being run. The default is based on the
contents of the C<$0> variable.

=item basedir

This is the directory into which the PID file will be stored. The
default value is that returned by C<File::Spec> C<tmpdir> method. This
will only be used when you have not specified a full path for the
C<file> attribute.

=item mode

This is the mode with which a new PID file will be created. The
default is C<0644>.

=back

=head1 SUBROUTINES/METHODS

=over

=item init_pid

If the PID file already exists then the value stored in the file will
be returned. Otherwise the value in the C<$$> variable will be
returned.

=item clear_pid

This can be used to clear the value set for the C<pid> attribute. This
will force the PID file to be read again, or, if it does not exist,
the value to be reset to that in the C<$$> variable.

=item init_pidfile

This returns the full path to the default location for the PID
file. The filename is based on the C<progname> resource with a C<.pid>
suffix. It will be in the directory specified in the C<basedir>
attribute.

=item store

This will write the value specified in the C<pid> attribute into the
file specified in the C<file> attribute. You can control the mode of
the file created via the C<mode> attribute. If another process using
this module already has the PID file open for writing then this method
will fail immediately.

=item does_file_exist

Returns true/false to to show whether the file specified in the
C<file> attribute actually exists.

=item is_running

If the PID file exists then this will check if there is a process with
this PID actually running and return true/false. The function first
looks in the C</proc> directory, if that is not present then it will
use the C<kill> function with a signal of zero. If the PID file does
not exist then this method returns undef.

=item remove

If the PID file exists then this will attempt to unlink it and return
true/false to indicate success. If the file already does not exist the
method just returns true.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. It also requires L<MooseX::Getopt>
and L< MooseX::Types>.

=head1 SEE ALSO

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 201O University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
