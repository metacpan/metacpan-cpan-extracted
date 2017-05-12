package PkgForge::Queue;    # -*-perl-*-
use strict;
use warnings;

# $Id: Queue.pm.in 15409 2011-01-12 17:25:17Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 15409 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Queue.pm.in $
# $Date: 2011-01-12 17:25:17 +0000 (Wed, 12 Jan 2011) $

our $VERSION = '1.1.10';

use File::Spec ();
use IO::Dir    ();
use PkgForge::Queue::Entry ();

use Moose;
use PkgForge::Types qw(AbsolutePathDirectory);
use MooseX::Types::Moose qw(Bool Str);

use overload q{""} => sub { shift->stringify };

has 'logger' => (
    is            => 'ro',
    isa           => 'Log::Dispatch::Config',
    predicate     => 'has_logger',
    documentation => 'Optional logging object',
);

has 'directory' => (
    is       => 'ro',
    isa      => AbsolutePathDirectory,
    required => 1,
    default  => sub { File::Spec->curdir() },
    documentation => 'The directory where the queue is stored',
);

has 'allow_symlinks' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    documentation => 'Allow symbolic links within a build queue directory',
);

has 'cruft' => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
    auto_deref => 1,
    handles    => {
        clear_cruft => 'clear',
        add_cruft   => 'push',
        count_cruft => 'count',
    },
    documentation => 'Any cruft found',
);

has 'entries' => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => 'ArrayRef[PkgForge::Queue::Entry]',
    default    => sub { [] },
    auto_deref => 1,
    handles    => {
        clear_entries => 'clear',
        add_entries   => 'push',
        count_entries => 'count',
    },
    documentation => 'The list of entries found',
);

around 'BUILDARGS' => sub {
    my ( $orig, $class, @args ) = @_;

    if ( @args == 1 && !ref $args[0] ) {
        return $class->$orig( directory => $args[0] );
    } else {
        return $class->$orig(@args);
    }
};

no Moose;
__PACKAGE__->meta->make_immutable;

sub stringify {
    my ($self) = @_;
    return $self->directory;
}

sub rescan {
    my ($self) = @_;

    my $dir = $self->directory;

    my $dh = IO::Dir->new($dir)
      or die "Could not open $dir: $!\n";

    my @cruft;
    my @entries;

    while ( defined( my $entry = $dh->read ) ) {
        if ( $entry eq q{.} || $entry eq q{..} ) {
            next;
        }
        my $path = File::Spec->catdir( $dir, $entry );
        if ( !-d $path || ( -l $path && !$self->allow_symlinks ) ) {
            push @cruft, $path;
        } else {
            my $entry = PkgForge::Queue::Entry->new( path => $path );
            push @entries, $entry;
        }
    }

    my @sorted = $self->sorted_entries(@entries);
    $self->cruft( \@cruft );
    $self->entries( \@sorted );

    return;
}

sub erase_cruft {
    my ($self) = @_;

    for my $cruft ( $self->cruft ) {
        if ( $self->has_logger ) {
            $self->logger->notice("Removing $cruft, not a job directory");
        }

        my $ok = unlink $cruft;    # Will not be a directory

        if ( !$ok ) {
            my $msg = "Could not unlink $cruft: $!";
            if ( $self->has_logger ) {
                $self->logger->error($msg);
            } else {
                warn "$msg\n";
            }
        }
    }

    return;
}

sub sorted_entries {
    my ( $self, @entries ) = @_;

    my @sorted = sort { $a->timestamp <=> $b->timestamp } @entries;
    return @sorted;
}

sub BUILD {
    my ($self) = @_;

    $self->rescan();

    return;
}

1;
__END__

=head1 NAME

PkgForge::Queue - Represents a build queue for the LCFG Package Forge

=head1 VERSION

This documentation refers to PkgForge::Queue version 1.1.10

=head1 SYNOPSIS

    use PkgForge::Queue;
    use PkgForge::Job;

    my $queue = PkgForge::Queue->new( directory => "/tmp/incoming" );

    for my $entry ($queue->entries) {
        my $job = PkgForge::Job->new_from_qentry($qentry);

        $job->validate();
    }

=head1 DESCRIPTION

In the LCFG Package Forge a build queue is represented by a
directory. The jobs in a queue are each represented by separate
sub-directories within that build queue directory.

This module is used as a lightweight representation of a queue. It is
basically a means of finding all the build queue entry
sub-directories.

=head1 ATTRIBUTES

These attributes are all only settable when the Queue object is
created. After that point they are all read-only.

=over 4

=item directory

The directory in which the queue is stored.

=item allow_symlinks

This is a boolean value which controls whether or not queue items in
the directory can be symbolic links. By default this option is false.

=item cruft

A list of anything found in the queue directory which is not a valid
queue item. This is anything which is not a directory and, depending
on the setting of the C<allow_symlinks> attribute, might also contain
symbolic links to directories.

=item entries

This is a list of L<PkgForge::Queue::Entry> items representing
the sub-directories found in the queue directory.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item new

This creates a new Queue object. The directory attribute must be specified.

=item rescan

This forces the queue object to rescan the directory and resets the
cruft and entry lists.

=item sorted_entries

Returns the list of entries sorted by the timestamp.

=item clear_entries

Empties the list of entries

=item add_entries

Adds L<Queue::Entry> objects to the entries list.

=item count_entries

Returns the size of the list of entries.

=item clear_cruft

Empties the list of cruft

=item add_cruft

Adds items to the list of cruft.

=item count_cruft

Returns the size of the list of cruft.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Queue::Entry>, L<PkgForge::Utils>

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
