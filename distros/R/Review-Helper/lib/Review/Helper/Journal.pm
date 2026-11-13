package Review::Helper::Journal;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Fcntl qw/:flock O_RDWR O_CREAT/;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;

use Review::Helper::Util qw/json_encode json_decode gen_uuid now/;

use Object::HashBase qw{
    <repo
    <path
};

my @KINDS    = qw/deviation assumption self-review test-revealed note other/;
my @COLORS   = qw/yellow red/;
my @REQUIRED = qw/kind path sentence/;
my @OPTIONAL = qw/flag unit snippet detail/;

sub init($self) {
    return if $self->{+PATH};
    croak "Either 'repo' or 'path' is required" unless $self->{+REPO};
    $self->{+PATH} = $self->{+REPO}->state_dir . '/journal.jsonl';
}

sub add($self, %note) {
    $note{kind} //= 'other';
    $self->_validate(\%note);

    my $id   = gen_uuid();
    my $line = json_encode({
        id      => $id,
        created => now(),
        (map { $_ => $note{$_} } @REQUIRED, @OPTIONAL),
    });

    my $path = $self->{+PATH};
    make_path(dirname($path));
    open(my $fh, '+>>', $path) or die "Cannot open '$path': $!";
    flock($fh, LOCK_EX)        or die "Cannot lock '$path': $!";

    # A write cut short leaves a last line with no newline; appending to it
    # would make the new note part of that bad line.
    my $last = '';
    if (-s $fh) {
        seek($fh, -1, 2)             or die "Cannot seek '$path': $!";
        defined(read($fh, $last, 1)) or die "Cannot read '$path': $!";
    }
    my $start = length($last) && $last ne "\n" ? "\n" : '';
    print $fh "$start$line\n";
    close($fh) or die "Cannot write '$path': $!";

    return $id;
}

sub notes($self) {
    my $path = $self->{+PATH};
    return [] unless -e $path;

    open(my $fh, '<', $path) or die "Cannot open '$path': $!";
    flock($fh, LOCK_SH)      or die "Cannot lock '$path': $!";
    my @lines = <$fh>;
    return [grep { defined } map { $self->_decode($lines[$_], $_ + 1) } 0 .. $#lines];
}

sub remove($self, @ids) {
    my $path = $self->{+PATH};
    return unless -e $path;

    my %drop = map { $_ => 1 } @ids;
    sysopen(my $fh, $path, O_RDWR) or die "Cannot open '$path': $!";
    flock($fh, LOCK_EX)            or die "Cannot lock '$path': $!";
    my @lines = <$fh>;
    my @keep;
    for my $i (0 .. $#lines) {
        next unless $lines[$i] =~ m/\S/;
        my $note = $self->_decode($lines[$i], $i + 1);
        push @keep => $lines[$i] unless $note && $drop{$note->{id}};
    }

    seek($fh, 0, 0)  or die "Cannot seek '$path': $!";
    truncate($fh, 0) or die "Cannot truncate '$path': $!";
    print $fh @keep;
    close($fh) or die "Cannot write '$path': $!";

    return;
}

# A note the journal could not have written: a field missing or invalid.
sub entry_error($self, $note) {
    my $id = $note->{id};
    return "'id' must be a non-empty string"           unless defined($id) && !ref($id) && length($id);
    return "'created' must be a time in epoch seconds" unless ($note->{created} // '') =~ m/\A\d+\z/;
    my %fields = map { ($_ => $note->{$_}) } grep { exists $note->{$_} } qw/flag kind path unit snippet sentence detail/;
    return undef if eval { $self->_validate(\%fields); 1 };
    my $error = $@;
    $error =~ s/ at \S+ line \d+\.?\n\z//;
    return $error;
}

# One bad line (a crash mid-write, a hand edit) must not block the rest of
# the journal, so it is skipped with a warning and never removed.
sub _decode($self, $line, $number) {
    return undef unless $line =~ m/\S/;
    my $note = eval { json_decode($line) };
    return $note if ref($note) eq 'HASH' && defined $note->{id};
    warn "Skipping line $number of journal '$self->{+PATH}': not a note\n";
    return undef;
}

sub _validate($self, $note) {
    my %known   = map { $_ => 1 } @REQUIRED, @OPTIONAL;
    my @unknown = sort grep { !$known{$_} } keys %$note;
    croak "Unknown note fields: @unknown" if @unknown;

    for my $field (@REQUIRED, @OPTIONAL) {
        my $val = $note->{$field};
        croak "Note field '$field' must be a string"  if ref $val;
        next                                          if defined($val) && length($val);
        croak "Note field '$field' is required"       if grep { $_ eq $field } @REQUIRED;
        croak "Note field '$field' must not be empty" if defined $val;
    }

    croak "Note flag must be one of: @COLORS" if defined($note->{flag}) && !grep { $_ eq $note->{flag} } @COLORS;
    croak "Note kind must be one of: @KINDS" unless grep                         { $_ eq $note->{kind} } @KINDS;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Journal - Notes an agent records while it works.

=head1 DESCRIPTION

The journal is a JSON Lines file, one note per line, kept per worktree as
F<journal.jsonl> in the VCS's state directory
(L<Review::Helper::VCS/state_dir>). A note with a C<flag> is a flag to be;
it waits there until it is placed into a review, which removes it. A note
without one is a journal entry: the next build or iteration of a review
takes it into that iteration's journal and removes it.

Every write holds an exclusive C<flock> on the file, so concurrent agents in
one worktree do not lose notes.

A note has C<id> (UUID v7), C<created> (epoch seconds), C<kind>
(C<deviation>, C<assumption>, C<self-review>, C<test-revealed>, C<note> or
C<other>, the default), C<path>, C<sentence>, and the optional C<flag> (the
flag's color: C<yellow>, a reviewer may object, or C<red>, probably a
problem), C<unit>, C<snippet> and C<detail>, which are null when not
given.

=head1 SYNOPSIS

    use Review::Helper::Journal;

    my $journal = Review::Helper::Journal->new(repo => $repo);

    my $id = $journal->add(
        flag     => 'yellow',
        kind     => 'deviation',
        path     => 'lib/Foo.pm',
        unit     => 'bar',
        sentence => 'Skips expiry when TTL is zero.',
    );

    my $notes = $journal->notes;
    $journal->remove($id);

=head1 ATTRIBUTES

=over 4

=item $repo = $journal->repo()

The repository whose journal this is, a L<Review::Helper::VCS>.

=item $path = $journal->path()

The journal file. Defaults to the repository's journal location; pass it
instead of C<repo> to use another file.

=back

=head1 PUBLIC METHODS

=over 4

=item $id = $journal->add(%note)

Validate the note fields, append the note, and return its new id. Field
values are character strings, not encoded bytes; the journal stores them as
UTF-8. A missing C<kind> is C<other>. Croaks on unknown fields, missing
required fields, empty strings, a C<flag> other than C<yellow> or C<red>,
or an unknown kind. Creates the file and its directory when
needed.

=item $notes = $journal->notes()

Arrayref of every note in the journal, oldest first. Empty when there is no
journal file. A line that is not a note is skipped with a warning naming it.

=item $error = $journal->entry_error($note)

Why a note read from the journal is not one C<add> could have written (a
field missing, empty or invalid, an C<id> that is not a non-empty string, or
C<created> not epoch seconds), or undef
when it is. Fields other than the note's own are ignored.

=item $journal->remove(@ids)

Remove the notes with these ids. Ids not in the journal are ignored. A line
that is not a note is kept as it is, with a warning.

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
