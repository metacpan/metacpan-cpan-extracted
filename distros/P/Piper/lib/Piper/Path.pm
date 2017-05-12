#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Simple path object for labeling locations in Piper pipelines
#####################################################################

package Piper::Path;

use v5.10;
use strict;
use warnings;

use Types::Standard qw(ArrayRef Str);

use Moo;
use namespace::clean;

use overload (
    q{""} => sub { $_[0]->stringify },
    fallback => 1,
);

our $VERSION = '0.04'; # from Piper-0.04.tar.gz

#pod =head1 SYNOPSIS
#pod
#pod     use Piper::Path;
#pod
#pod     # grandparent/parent/child
#pod     my $path = Piper::Path->new(qw(
#pod         grandparent parent child
#pod     ));
#pod
#pod     # grandparent/parent/child/grandchild
#pod     $path->child('grandchild');
#pod
#pod     # (qw(grandparent parent child))
#pod     $path->split;
#pod
#pod     # child
#pod     $path->name;
#pod
#pod     # 'grandparent/parent/child'
#pod     $path->stringify;
#pod     "$path";
#pod
#pod =head1 DESCRIPTION
#pod
#pod Simple filesystem-like representation of a pipeline segment's placement in the pipeline, relative to containing segments.
#pod
#pod =head1 CONSTRUCTOR
#pod
#pod =head2 new(@path_segments)
#pod
#pod Creates a L<Piper::Path> object from the given path segments.
#pod
#pod Segments may be single path elements (similar to a file name), joined path elements S<(with C</>)>, or L<Piper::Path> objects.
#pod
#pod The following examples create equivalent objects:
#pod
#pod     Piper::Path->new(qw(grandparent parent child));
#pod     Piper::Path->new(qw(grandparent/parent child));
#pod     Piper::Path->new(
#pod         Piper::Path->new(qw(grandparent parent)),
#pod         qw(child)
#pod     );
#pod
#pod =cut

has path => (
    is => 'ro',
    isa => ArrayRef[Str],
);

around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;
    
    my @pieces;
    for my $part (@args) {
        if (eval { $part->isa('Piper::Path') }) {
            push @pieces, $part->split;
        }
        elsif (ref $part eq 'ARRAY') {
            push @pieces, map { split('/', $_) } @$part;
        }
        else {
            push @pieces, split('/', $part);
        }
    }
    return $self->$orig(
        path => \@pieces,
    );
};

#pod =head1 METHODS
#pod
#pod =head2 child(@segments)
#pod
#pod Returns a new L<Piper::Path> object representing the appropriate child of L<$self>.
#pod
#pod     $path                     # grampa/parent
#pod     $path->child(qw(child))   # grampa/parent/child
#pod
#pod =cut

sub child {
    my $self = shift;
    return $self->new($self, @_);
}

#pod =head2 name
#pod
#pod Returns the last segment of the path, similar to the C<basename> of a filesystem path.
#pod
#pod     $path         # foo/bar/baz
#pod     $path->name   # baz
#pod
#pod =cut

sub name {
    my ($self) = @_;
    return $self->path->[-1];
}

#pod =head2 split
#pod
#pod Returns an array of the path segments.
#pod
#pod     $path          # foo/bar/baz
#pod     $path->split   # qw(foo bar baz)
#pod
#pod =cut

sub split {
    my ($self) = @_;
    return @{$self->path};
}

#pod =head2 stringify
#pod
#pod Returns a string representation of the path, which is simply a join of the path segments with C</>.
#pod
#pod String context is overloaded to call this method.  The following are equivalent:
#pod
#pod     $path->stringify
#pod     "$path"
#pod
#pod =cut

sub stringify {
    my ($self) = @_;
    return join('/', @{$self->path});
}

1;

__END__

=pod

=for :stopwords Mary Ehlers Heaney Tim

=head1 NAME

Piper::Path - Simple path object for labeling locations in Piper pipelines

=head1 SYNOPSIS

    use Piper::Path;

    # grandparent/parent/child
    my $path = Piper::Path->new(qw(
        grandparent parent child
    ));

    # grandparent/parent/child/grandchild
    $path->child('grandchild');

    # (qw(grandparent parent child))
    $path->split;

    # child
    $path->name;

    # 'grandparent/parent/child'
    $path->stringify;
    "$path";

=head1 DESCRIPTION

Simple filesystem-like representation of a pipeline segment's placement in the pipeline, relative to containing segments.

=head1 CONSTRUCTOR

=head2 new(@path_segments)

Creates a L<Piper::Path> object from the given path segments.

Segments may be single path elements (similar to a file name), joined path elements S<(with C</>)>, or L<Piper::Path> objects.

The following examples create equivalent objects:

    Piper::Path->new(qw(grandparent parent child));
    Piper::Path->new(qw(grandparent/parent child));
    Piper::Path->new(
        Piper::Path->new(qw(grandparent parent)),
        qw(child)
    );

=head1 METHODS

=head2 child(@segments)

Returns a new L<Piper::Path> object representing the appropriate child of L<$self>.

    $path                     # grampa/parent
    $path->child(qw(child))   # grampa/parent/child

=head2 name

Returns the last segment of the path, similar to the C<basename> of a filesystem path.

    $path         # foo/bar/baz
    $path->name   # baz

=head2 split

Returns an array of the path segments.

    $path          # foo/bar/baz
    $path->split   # qw(foo bar baz)

=head2 stringify

Returns a string representation of the path, which is simply a join of the path segments with C</>.

String context is overloaded to call this method.  The following are equivalent:

    $path->stringify
    "$path"

=head1 SEE ALSO

=over

=item L<Piper>

=back

=head1 VERSION

version 0.04

=head1 AUTHOR

Mary Ehlers <ehlers@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mary Ehlers.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
