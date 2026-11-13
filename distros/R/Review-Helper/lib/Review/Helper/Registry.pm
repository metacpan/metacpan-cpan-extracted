package Review::Helper::Registry;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Encode qw/decode encode FB_CROAK LEAVE_SRC/;
use Fcntl qw/:flock O_RDWR O_CREAT/;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;
use File::Spec();

use Review::Helper::Util qw/json_encode json_decode/;

use Object::HashBase qw{
    <repo
    <path
};

sub init($self) {
    croak "'repo' is a required attribute" unless $self->{+REPO};
    $self->{+PATH} //= $self->{+REPO}->shared_state_dir . '/registry.json';
}

sub close_review($self, $db, $path) {
    $db->set_state('closed');
    $self->register($db->review->{id}, $path, 'closed');
    return;
}

sub register($self, $id, $path, $state = 'open') {
    croak "Invalid review id '$id'"                 unless $self->_valid_id($id);
    croak "Review state must be 'open' or 'closed'" unless $state eq 'open' || $state eq 'closed';
    my $abs = $self->_path_text(File::Spec->rel2abs($self->_path_bytes($path)));
    $self->_update(sub ($reviews) {
        $reviews->{$id} = {path => $abs, state => $state};
    });
    return;
}

sub set_state($self, $id, $state) {
    croak "Review state must be 'open' or 'closed'" unless $state eq 'open' || $state eq 'closed';
    $self->_update(sub ($reviews) {
        croak "Review '$id' is not registered" unless $reviews->{$id};
        $reviews->{$id}{state} = $state;
    });
    return;
}

sub reviews($self) {
    my $reviews = $self->_stored;
    return {map { ($_ => {%{$reviews->{$_}}, path => $self->_stored_path($reviews->{$_})}) } keys %$reviews};
}

sub prune($self, %params) {
    my $repo = $self->{+REPO};
    my @removed;

    my $scan = sub ($reviews) {
        for my $id (sort keys %$reviews) {
            # An entry no review can have names no pins to delete; it goes.
            unless ($self->_valid_id($id)) {
                delete $reviews->{$id} unless $params{dry_run};
                next;
            }

            my $review = $reviews->{$id};
            next if $review->{state} eq 'open' && -e $self->_stored_path($review);

            for my $pin (@{$repo->pins($id)}) {
                $repo->unpin($pin) unless $params{dry_run};
                push @removed => $pin;
            }
            delete $reviews->{$id} unless $params{dry_run};
        }
    };

    $params{dry_run} ? $scan->($self->_stored) : $self->_update($scan);

    return \@removed;
}

sub _valid_id($self, $id) { defined($id) && $id =~ m/\A[0-9A-Za-z][0-9A-Za-z_-]*\z/ }

# The file holds paths as text; file operations need the bytes.
sub _stored_path($self, $review) { defined($review->{path}) ? encode('UTF-8', $review->{path}) : undef }

# The bytes Perl's file operations use for $path: a character string is
# used as its UTF-8 encoding.
sub _path_bytes($self, $path) { utf8::is_utf8($path) ? encode('UTF-8', $path) : $path }

sub _path_text($self, $bytes) {
    my $text;
    my $ok = eval { $text = decode('UTF-8', $bytes, FB_CROAK | LEAVE_SRC); 1 };
    croak "Review file paths must be valid UTF-8: $bytes" unless $ok;
    return $text;
}

sub _stored($self) {
    my $path = $self->{+PATH};
    return {} unless -e $path;

    open(my $fh, '<', $path) or die "Cannot open '$path': $!";
    flock($fh, LOCK_SH)      or die "Cannot lock '$path': $!";
    return $self->_decode($fh)->{reviews};
}

sub _decode($self, $fh) {
    my $raw = join('' => <$fh>);
    return {reviews => {}} unless $raw =~ m/\S/;
    my $data = eval { json_decode($raw) };
    return $data if ref($data) eq 'HASH' && ref($data->{reviews}) eq 'HASH';
    die "Registry '$self->{+PATH}' is not a review registry: expected a JSON object with a 'reviews' object\n";
}

# Read-modify-write under an exclusive lock held for the whole update.
sub _update($self, $code) {
    my $path = $self->{+PATH};
    make_path(dirname($path));

    sysopen(my $fh, $path, O_RDWR | O_CREAT) or die "Cannot open '$path': $!";
    flock($fh, LOCK_EX)                      or die "Cannot lock '$path': $!";

    my $data = $self->_decode($fh);
    $code->($data->{reviews});

    seek($fh, 0, 0)  or die "Cannot seek '$path': $!";
    truncate($fh, 0) or die "Cannot truncate '$path': $!";
    print $fh json_encode($data), "\n";
    close($fh) or die "Cannot write '$path': $!";

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Registry - The reviews registered in a repository.

=head1 DESCRIPTION

The registry maps each review id to its file path and state (C<open> or
C<closed>). One registry serves every worktree of a repository; it lives at
F<registry.json> in the VCS's shared state directory
(L<Review::Helper::VCS/shared_state_dir>). It exists so
C<prune> can find reviews that are closed or whose file is gone without
searching every worktree.

The file is JSON: C<< { "reviews": { "<id>": { "path": ..., "state": ... } } } >>.
Paths are stored as text, so the file holds each path's UTF-8 encoding once;
methods take and return paths as bytes.
Every change holds an exclusive C<flock> on it while reading and rewriting.
A file of any other shape is refused with an error naming it, and left as
it is.

=head1 SYNOPSIS

    use Review::Helper::Registry;

    my $registry = Review::Helper::Registry->new(repo => $repo);

    $registry->register($id, $file);
    $registry->set_state($id, 'closed');

    my $reviews = $registry->reviews;
    my $removed = $registry->prune(dry_run => 1);

=head1 ATTRIBUTES

=over 4

=item $repo = $registry->repo()

The repository the registry belongs to, a L<Review::Helper::VCS>. Required.

=item $path = $registry->path()

The registry file. Defaults to the repository's shared registry location.

=back

=head1 PUBLIC METHODS

=over 4

=item $registry->close_review($db, $path)

Mark the review open in C<$db> (a L<Review::Helper::DB>) closed, in the file
and in the registry. C<$path> is the review file's path.

=item $registry->register($id, $path)

=item $registry->register($id, $path, $state)

Record a review, replacing any earlier entry for C<$id>. C<$path> is stored
as an absolute path; C<$state> defaults to C<open>. Croaks when the path is
not valid UTF-8. Review ids may contain
only letters, digits, C<-> and C<_>, so they are safe inside a pin name.

=item $registry->set_state($id, $state)

Set a registered review's state. Croaks when C<$id> is not registered.

=item $reviews = $registry->reviews()

Hashref of id to C<< { path => ..., state => ... } >>, with each path as
bytes ready for file operations. Empty when there is no registry file.

=item $pins = $registry->prune(dry_run => $bool)

For every review that is closed or whose file no longer exists, remove its
pins (L<Review::Helper::VCS/pins>) and drop its entry. An entry whose id is
not a valid review id is dropped too, removing no pins. Returns the names of
the pins removed. With C<dry_run>, changes nothing and returns the pins it
would remove; the invalid entries it would drop are not listed, since they
name no pins. Review files are never deleted.

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
