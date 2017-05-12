package PkgForge::Queue::Entry; # -*-perl-*-
use strict;
use warnings;

# $Id: Entry.pm.in 14566 2010-11-23 14:53:41Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 14566 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Queue/Entry.pm.in $
# $Date: 2010-11-23 14:53:41 +0000 (Tue, 23 Nov 2010) $

our $VERSION = '1.1.10';

use File::Spec ();
use File::stat ();
use PkgForge::Utils ();

use overload q{""} => sub { shift->stringify };

use Moose;
use PkgForge::Types qw(AbsolutePathDirectory);
use MooseX::Types::Moose qw(Int Str);

has 'path' => (
    is       => 'ro',
    isa      => AbsolutePathDirectory,
    required => 1,
);

has 'id' => (
    is  => 'ro',
    isa => Str,
);

has 'owner' => (
    is  => 'ro',
    isa => Int,
);

has 'timestamp' => (
    is  => 'ro',
    isa => Int,
);

sub stringify {
    my ($self) = @_;
    return $self->path;
}

sub scrub {
    my ( $self, $options ) = @_;

    PkgForge::Utils::remove_tree( $self->path, $options );

    undef $self;

    return;
}

sub pretty_timestamp {
    my ($self) = @_;

    return scalar localtime($self->timestamp)
}

sub overdue {
    my ( $self, $timeout ) = @_;

    my $now = time;
    return ( ($now - $timeout) > $self->timestamp );
}

around 'BUILDARGS' => sub {
    my ( $orig, $class, @args ) = @_;

    my %args;
    if ( scalar @args == 1 ) {
        if ( defined $args[0] && ref $args[0] eq 'HASH' ) {
            %args = %{$args[0]};
        }
        elsif ( defined $args[0] && !ref $args[0] ) {
            $args{path} = $args[0];
        }
        else {
            $class->throw_error( "Single parameters to new() must be a directory path or a HASH ref", data => $_[0] );
        }
    }
    else {
        %args = @args;
    }

    my $path = $args{path};
    if ( defined $path && -e $path ) {
        $args{id} = (File::Spec->splitdir($path))[-1];

        my $info = File::stat::stat($path);
        $args{owner} = $info->uid;
        $args{timestamp}  = $info->ctime;
    }

    return $class->$orig(%args);
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

PkgForge::Queue::Entry - Represents an entry in a build queue for the LCFG Package Forge

=head1 VERSION

This documentation refers to PkgForge::Queue::Entry version 1.1.10

=head1 SYNOPSIS

     use PkgForge::Queue::Entry;
     use PkgForge::Job;

     my $qentry = PkgForge::Queue::Entry->new($dir);

     print "Queue entry: " . $qentry->id .
           " submitted at: " . $qentry->pretty_timestamp . "\n";

     my $job = PkgForge::Job->new_from_qentry($qentry);
 
=head1 DESCRIPTION

In the LCFG Package Forge a build queue is represented by a
directory. The jobs in a queue are each represented by separate
sub-directories within that build queue directory.

This module is used as a lightweight representation of an entry within
a queue. It is basically a means of querying useful meta-data
associated with a physical directory.

=head1 ATTRIBUTES

These attributes are all only settable when the Queue::Entry object is
created. After that point they are all read-only.

=over 4

=item path

This is the path to a directory which represents an entry in a build
queue. It must exist.

=item id

This is the identifier for the build queue entry, it is the name of
the specific sub-directory within the queue directory, (i.e. the
final, deepest level of the directory tree only).

=item owner

This is the UID of the owner of the queue entry directory.

=item timestamp

This is the ctime of the queue entry directory.

=back

=head1 SUBROUTINES/METHODS

=over 4

=item new($path)

Takes the path to the individual directory which represents a job in
the build queue and returns a Queue::Entry object.

=item overdue($timeout)

This takes a timeout, in seconds, and returns a boolean value which
signifies whether or not the build queue entry is more than that many
seconds old.

=item scrub

This method will erase the directory associated with this build queue
entry. Note that it also blows away the object since it no longer has
any physical meaning once the directory is gone. Internally this uses
the C<remove_tree> subroutine provided by L<PkgForge::Utils>. It is
possible, optionally, to pass in a reference to a hash of options to
control how the C<remove_tree> subroutine functions.

=item pretty_timestamp

This method returns a nicely formatted string form of the C<timestamp>
attribute. This uses the C<localtime> function and is provided mainly
for prettier logging.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Queue>, L<PkgForge::Utils>

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
