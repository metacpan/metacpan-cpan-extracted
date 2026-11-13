package Review::Helper::VCS;
use v5.36;

our $VERSION = '0.001';

use Role::Tiny;

requires qw{
    find root user state_dir shared_state_dir is_internal_path
    resolve empty_revision has_revision revision_name revisions parents revision_info change_id
    range_changes range_diff resolution_changes resolution_diff
    file file_id
    pin_name pin pins unpin
};

# Git is the only implementation; another would be tried here in turn.
sub detect($class, $path) {
    require Review::Helper::VCS::Git;
    return Review::Helper::VCS::Git->find($path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::VCS - The version control system a review reads its change from.

=head1 DESCRIPTION

A L<Role::Tiny> role: the one interface the rest of Review::Helper uses to
read a repository, so nothing outside an implementation names a VCS command,
ref or option. L<Review::Helper::VCS::Git> is the only implementation.
C<detect> picks the implementation for a path; it is where another one would
be added.

The terms used below (revision, empty revision, path spec, pin, change id)
are defined in the format specification, F<standards/FORMAT.md> in the share
directory, "Repository conventions", with their git meaning.

A B<change> is a hashref for one file that differs between two revisions:
C<path>, C<old_path> (renames only, else undef), C<status> (C<A>, C<D>, C<M>
or C<R>), C<added>, C<removed>, C<binary> and C<submodule> (1 when either
side is another repository's entry, which has no content here). Binary files
count zero lines.

Paths and text returned are character strings; diffs and file contents are
bytes. Diffs are unified diffs in the fixed form the format specification's
"Diff convention" gives, so line anchors stay stable.

=head1 SYNOPSIS

    use Review::Helper::VCS;

    my $vcs = Review::Helper::VCS->detect($path);

    my $head    = $vcs->resolve('HEAD');
    my $revs    = $vcs->revisions($base, $head);
    my $changes = $vcs->range_changes($base, $head);

=head1 CLASS METHODS

=over 4

=item $vcs = Review::Helper::VCS->detect($path)

The repository holding C<$path>, a file or directory, as an object of the
implementation that manages it. Croaks when none does.

=back

=head1 REQUIRED METHODS

=head2 The repository

=over 4

=item $vcs = $class->find($path)

The repository holding C<$path>, a file or directory. A file need not exist,
but its directory must. Croaks when there is none.

=item $dir = $vcs->root()

Absolute path of the working tree's top directory.

=item $who = $vcs->user()

The user's identity in this repository, C<< Name <email> >>, either part
alone, or undef when none is set.

=item $dir = $vcs->state_dir()

Absolute path of Review::Helper's private directory for this working tree,
outside the tracked files. Review files and the journal go here by default.
It may not exist yet.

=item $dir = $vcs->shared_state_dir()

Absolute path of Review::Helper's private directory shared by every working
tree of the repository; the registry lives here. It may not exist yet.

=item $bool = $vcs->is_internal_path($path)

True when the absolute C<$path> is inside the VCS's own directories, where
nothing is ever tracked.

=back

=head2 Revisions

=over 4

=item $rev = $vcs->resolve($name)

The full id of the revision C<$name> names. Croaks when it names none.

=item $rev = $vcs->empty_revision()

The empty revision's id.

=item $bool = $vcs->has_revision($rev)

True when the revision is in the repository.

=item $name = $vcs->revision_name($rev)

The branch or tag name C<$rev> stands for, or undef when it is not one.

=item $revs = $vcs->revisions($base, $head)

Arrayref of the revisions in C<$head> but not C<$base>, oldest first, each
after its parents, as C<< { revision => $id, parents => [@ids] } >>.

=item $parents = $vcs->parents($rev)

Arrayref of the revision's parents, first parent first.

=item $info = $vcs->revision_info($rev)

Hashref with C<revision> (the full id), C<parent> (first parent, undef for none),
C<subject>, C<message>, C<author> (C<< Name <email> >>) and C<authored>
(epoch seconds).

=item $id = $vcs->change_id($rev)

A stable id of the revision's change: equal for the same change rebased
elsewhere. Undef when the revision changes nothing.

=back

=head2 Changes and diffs

=over 4

=item $changes = $vcs->range_changes($from, $to)

=item $changes = $vcs->range_changes($from, $to, \@path_specs)

Arrayref of the changes (see L</DESCRIPTION>) between C<$from> and C<$to>,
limited to the path specs when given.

=item $bytes = $vcs->range_diff($from, $to, $path)

=item $bytes = $vcs->range_diff($from, $to, $path, $old_path)

The unified diff of one file between two revisions, its path taken
literally. Pass C<$old_path> for a rename so both sides pair up.

=item $changes = $vcs->resolution_changes($rev)

=item $changes = $vcs->resolution_changes($rev, \@path_specs)

=item $bytes = $vcs->resolution_diff($rev, $path)

=item $bytes = $vcs->resolution_diff($rev, $path, $old_path)

A merge's own changes: from what the VCS's merge of its parents would make,
conflicts included, to what was recorded, so the hand-made conflict
resolutions. C<resolution_changes> lists the files (without line counts);
it is empty for a clean merge, a revision that is not a merge, or a VCS
that cannot tell. C<resolution_diff> is one file's diff.

=back

=head2 Files

=over 4

=item $bytes = $vcs->file($rev, $path)

The file's content in that revision, or undef when no file is there (nothing
at that path, a directory, or another repository's entry).

=item $id = $vcs->file_id($rev, $path)

An id of the content at that path in that revision, or undef when nothing is
there. Equal ids mean identical content.

=back

=head2 Pins

=over 4

=item $name = $vcs->pin_name($review_id, $number)

The pin name of iteration C<$number> of a review, as stored in its
C<iteration.pin>.

=item $vcs->pin($name, $rev)

Keep C<$rev> alive under C<$name>, creating or moving the pin.

=item $names = $vcs->pins($review_id)

Arrayref of the names of every pin the review has.

=item $vcs->unpin($name)

Remove a pin.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
