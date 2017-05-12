package Net::Fluidinfo::HasPath;
use Moose::Role;

requires 'parent';

has name => (is => 'ro', isa => 'Str', lazy_build => 1);
has path => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_name {
    # TODO: add croaks for dependencies
    my $self = shift;
    my @names = split "/", $self->path;
    $names[-1];
}

sub _build_path {
    # TODO: add croaks for dependencies
    my $self = shift;
    if ($self->parent) {
        $self->parent->path . '/' . $self->name;
    } else {
        $self->name;
    }
}

sub path_of_parent {
   my $self = shift;
   my @names = split "/", $self->path;
   join "/", @names[0 .. $#names-1];
}

# Two paths are equal if their leading segment, the user namespace name,
# are equal case-insensitive, and the rest of segments are eq.
sub equal_paths {
    my ($receiver, $p1, $p2) = @_;

    return 1 if !defined $p1 && !defined $p2;
    return 0 if !defined $p1 || !defined $p2;

    if (index($p1, '/') != -1 && index($p1, '/') != -1) {
        my ($username, $rest) = split '/', $p1, 2;
        # ensure the match is performed in scalar context
        scalar($p2 =~ m{\A (?i: \Q$username\E ) / \Q$rest\E \z}x);
    } else {
        $p1 eq $p2;
    }
}

1;

__END__

=head1 NAME

C<Net::Fluidinfo::HasPath> - Role for resources that have a path

=head1 SYNOPSIS

 $namespace->path;
 $tag->path

=head1 DESCRIPTION

C<Net::Fluidinfo::HasPath> is a role consumed by L<Net::Fluidinfo::Namespace>
and L<Net::Fluidinfo::Tag>. They have in common that they have a path.

Consumers of this role must respond to C<parent>.

=head1 USAGE

=head2 Instance Methods

=over

=item $resource->path

The path of this resource in Fluidinfo. For example "fxn/rating".

This attribute can either be set, or lazily computed from the parent of
the resource and its name.

=item $resource->name

The last segment of the path. A tag with path "fxn/rating" has "rating"
as name.

This attribute can either be set, or lazily computed from the path.

=item $resource->path_of_parent

The path of the parent resource if there's one, an empty string otherwise.

=back

=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
