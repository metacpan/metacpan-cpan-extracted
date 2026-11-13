package Review::Helper::DB;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use DBI();
use DBD::SQLite::Constants qw/DBD_SQLITE_STRING_MODE_UNICODE_STRICT/;
use File::Basename qw/dirname/;
use File::Path qw/make_path/;
use File::Spec();

use Review::Helper();
use Review::Helper::Util qw/gen_uuid now share_dir/;

use Object::HashBase qw{
    <path
    <dbh
};

use constant FORMAT         => 'review-file';
use constant FORMAT_VERSION => '1';

my $SCHEMA;

# The schema ships as standards/review.sql in the share directory; the format
# specification names that file as the schema.
sub schema($class) {
    return $SCHEMA //= do {
        my $file = File::Spec->catfile(share_dir(), 'standards', 'review.sql');
        open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open $file: $!";
        local $/;
        <$fh>;
    };
}

sub init($self) {
    croak "'path' is a required attribute" unless $self->{+PATH};
    croak "Review file paths may not contain ';': $self->{+PATH}" if $self->{+PATH} =~ m/;/;
    $self->{+DBH} //= $self->_connect($self->{+PATH});
}

sub create($class, $path, %review) {
    croak "Review file '$path' already exists"           if -e $path;
    croak "Review file paths may not contain ';': $path" if $path =~ m/;/;
    my @unknown = sort grep { !/^(?:id|title|source|created)$/ } keys %review;
    croak "Unknown review fields: @unknown" if @unknown;

    make_path(dirname($path));
    my $self = $class->new(path => $path);

    my $ok = eval {
        $self->txn(sub {
            my $dbh = $self->{+DBH};
            local $dbh->{sqlite_allow_multiple_statements} = 1;
            $dbh->do($class->schema);
            my $meta = $dbh->prepare('INSERT INTO meta (key, value) VALUES (?, ?)');
            $meta->execute(format         => FORMAT);
            $meta->execute(format_version => FORMAT_VERSION);
            $meta->execute(generator      => "Review::Helper $Review::Helper::VERSION");
            $dbh->do(
                'INSERT INTO review (id, title, source, created, state) VALUES (?, ?, ?, ?, ?)', undef,
                $review{id} // gen_uuid(), $review{title}, $review{source}, $review{created} // now(), 'open',
            );
        });
        1;
    };
    unless ($ok) {
        my $err = $@;
        $self->{+DBH}->disconnect;
        unlink($path);
        die $err;
    }

    return $self;
}

sub open($class, $path) {
    croak "No such review file: $path" unless -f $path;
    my $self = $class->new(path => $path);
    croak "Not a review file: $path" unless $class->is_review_file($path);

    my ($version) = $self->{+DBH}->selectrow_array(q{SELECT value FROM meta WHERE key = 'format_version'});
    $version //= '';
    croak "Unsupported review file format version '$version': $path" unless $version eq FORMAT_VERSION;

    return $self;
}

# Whether the file is an SQLite file whose meta says it is a review file,
# whatever its format version. Anything else, such as a file that is not
# SQLite at all, is not.
sub is_review_file($class, $path) {
    return 0 unless -f $path;
    my $format = eval { $class->new(path => $path)->dbh->selectrow_array(q{SELECT value FROM meta WHERE key = 'format'}) };
    return ($format // '') eq FORMAT ? 1 : 0;
}

# The schema's table names in schema order.
sub schema_tables($class) {
    return $class->schema =~ m/^CREATE TABLE (\w+) \(/mg;
}

sub txn($self, $code) {
    my $dbh = $self->{+DBH};
    $dbh->begin_work;

    my @out;
    my $ok  = eval { @out = $code->(); 1 };
    my $err = $@;
    if ($ok) {
        $dbh->commit;
        return wantarray ? @out : $out[0];
    }

    $dbh->rollback;
    die $err;
}

sub review($self) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM review');
}

sub set_state($self, $state) {
    croak "Review state must be 'open' or 'closed'" unless $state eq 'open' || $state eq 'closed';
    $self->{+DBH}->do('UPDATE review SET state = ?', undef, $state);
    return;
}

sub set_published($self, $id) {
    my $rows = $self->{+DBH}->do('UPDATE feedback SET published = ? WHERE id = ?', undef, now(), $id);
    croak "No such feedback item: $id" unless $rows > 0;
    return;
}

sub iterations($self) {
    return $self->{+DBH}->selectall_arrayref('SELECT * FROM iteration ORDER BY number', {Slice => {}});
}

sub latest_iteration($self) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM iteration ORDER BY number DESC LIMIT 1');
}

# Queries for the web server.

sub iteration($self, $number) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM iteration WHERE number = ?', undef, $number);
}

sub commits($self, $iteration) {
    return $self->_rows('SELECT * FROM commit_entry WHERE iteration = ? ORDER BY position', $iteration);
}

sub commits_by_revision($self, $iteration, $revision) {
    return $self->_rows('SELECT * FROM commit_entry WHERE iteration = ? AND revision = ? ORDER BY position', $iteration, $revision);
}

sub files($self, $commit_id) {
    return $self->_rows('SELECT * FROM file_change WHERE commit_id = ? ORDER BY id', $commit_id);
}

sub file_change($self, $id) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM file_change WHERE id = ?', undef, $id);
}

sub file_by_path($self, $commit_id, $path) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM file_change WHERE commit_id = ? AND path = ?', undef, $commit_id, $path);
}

sub commit_entry($self, $id) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM commit_entry WHERE id = ?', undef, $id);
}

sub sections($self, $file_id) {
    return $self->_rows('SELECT * FROM section WHERE file_id = ? ORDER BY position', $file_id);
}

# Whether the commit changed a line of a section: only those are explained
# (the fill sheet) and shown (the page).
sub section_touched($self, $section) { $section->{deleted} || $section->{added} || $section->{removed} || $section->{changed} ? 1 : 0 }

sub flags($self, $iteration) {
    return $self->_rows(<<~'EOT', $iteration);
        SELECT flag.*, commit_entry.revision
          FROM flag JOIN commit_entry ON commit_entry.id = flag.commit_id
         WHERE commit_entry.iteration = ?
         ORDER BY commit_entry.position, flag.path, flag.line_start, flag.id
        EOT
}

sub journal_entries($self, $iteration) {
    return $self->_rows('SELECT * FROM journal_entry WHERE iteration = ? ORDER BY created, id', $iteration);
}

sub flag($self, $id) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM flag WHERE id = ?', undef, $id);
}

# The iteration's flag with a note id, with its entry's revision and topic; undef
# when none.
sub flag_by_note($self, $iteration, $note_id) {
    return $self->{+DBH}->selectrow_hashref(<<~'EOT', undef, $iteration, $note_id);
        SELECT flag.*, commit_entry.revision, commit_entry.topic AS topic
          FROM flag JOIN commit_entry ON commit_entry.id = flag.commit_id
         WHERE commit_entry.iteration = ? AND flag.note_id = ?
        EOT
}

sub flag_seen($self, $iteration) {
    return $self->_rows(<<~'EOT', $iteration);
        SELECT flag_seen.*
          FROM flag_seen
          JOIN flag ON flag.id = flag_seen.flag
          JOIN commit_entry ON commit_entry.id = flag.commit_id
         WHERE commit_entry.iteration = ?
         ORDER BY flag_seen.at, flag_seen.reviewer
        EOT
}

sub set_flag_seen($self, $flag, $reviewer, $seen) {
    my $dbh = $self->{+DBH};
    if ($seen) {
        $dbh->do('INSERT OR IGNORE INTO flag_seen (flag, reviewer, at) VALUES (?, ?, ?)', undef, $flag, $reviewer, now());
    }
    else {
        $dbh->do('DELETE FROM flag_seen WHERE flag = ? AND reviewer = ?', undef, $flag, $reviewer);
    }
    return;
}

sub guide_steps($self, $iteration) {
    return $self->_rows('SELECT * FROM guide_step WHERE iteration = ? ORDER BY position', $iteration);
}

sub add_feedback($self, %fields) {
    my $now = now();
    $self->{+DBH}->do(<<~'EOT', undef, @fields{qw/iteration target revision path section_name section_package topic flag flag_sentence line side body reviewer/}, $now, $now);
        INSERT INTO feedback (iteration, target, revision, path, section_name, section_package, topic, flag, flag_sentence, line, side, body, reviewer, created, updated, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open')
        EOT
    return $self->{+DBH}->sqlite_last_insert_rowid;
}

sub feedback($self, $id) {
    return $self->{+DBH}->selectrow_hashref('SELECT * FROM feedback WHERE id = ?', undef, $id);
}

sub update_feedback($self, $id, %fields) {
    my @cols = grep { exists $fields{$_} } qw/body status/;
    croak "Nothing to update" unless @cols;
    my $set = join ', ' => map { "$_ = ?" } @cols, 'updated';
    return $self->{+DBH}->do("UPDATE feedback SET $set WHERE id = ?", undef, @fields{@cols}, now(), $id) > 0;
}

sub add_request($self, %fields) {
    $self->{+DBH}->do(<<~'EOT', undef, @fields{qw/iteration kind target revision path section_name section_package topic note reviewer/}, now());
        INSERT INTO request (iteration, kind, target, revision, path, section_name, section_package, topic, note, reviewer, created, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'open')
        EOT
    return $self->{+DBH}->sqlite_last_insert_rowid;
}

sub _rows($self, $sql, @bind) {
    return $self->{+DBH}->selectall_arrayref($sql, {Slice => {}}, @bind);
}

sub _connect($self, $path) {
    my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$path", '', '',
        {
            RaiseError         => 1,
            PrintError         => 0,
            AutoCommit         => 1,
            sqlite_string_mode => DBD_SQLITE_STRING_MODE_UNICODE_STRICT,
        },
    );
    $dbh->do('PRAGMA foreign_keys = ON');
    return $dbh;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::DB - The SQLite review file.

=head1 DESCRIPTION

Creates and opens review files: one SQLite database per review, holding only
review data. Content such as diffs and file text comes from the repository
(L<Review::Helper::VCS>), never from here.

Text goes in and comes out as Perl character strings; the file stores UTF-8.
Foreign keys are enforced.

=head1 SYNOPSIS

    use Review::Helper::DB;

    my $db = Review::Helper::DB->create($path, title => 'Add caching');
    my $db = Review::Helper::DB->open($path);

    $db->txn(sub {
        $db->dbh->do('UPDATE iteration SET note = ? WHERE number = ?', undef, $note, 2);
    });

    my $review = $db->review;
    my $latest = $db->latest_iteration;

=head1 ATTRIBUTES

=over 4

=item $path = $db->path()

The review file. Required. It may not contain C<;>, which the SQLite driver
would read as the end of the file name.

=item $dbh = $db->dbh()

The L<DBI> handle. C<RaiseError> is on.

=back

=head1 PUBLIC METHODS

=over 4

=item $db = Review::Helper::DB->create($path, %review)

Create a new review file with the full schema, its C<meta> rows, and the
single C<review> row in state C<open>. C<%review> may hold C<id> (default: a
new UUID v7), C<title>, C<source> (the URL of the pull or merge request under
review) and C<created> (default: now). Creates missing parent directories.
Croaks when the file already exists; on failure the partial file is removed.

=item $db = Review::Helper::DB->open($path)

Open an existing review file. Croaks when the file is missing, is not a review
file, or has a format version this code does not support. The schema is not
checked: a file an earlier build of the same format version wrote may fail
later with SQLite errors, and is rebuilt. Files are never upgraded. A file
that cannot be written opens for reading.

=item $bool = Review::Helper::DB->is_review_file($path)

True when C<$path> is an SQLite file whose C<meta> names it a review file,
whatever its format version; false for a missing file, any other SQLite
file, or a file that is not SQLite. C<open> refuses such a file as "Not a
review file"; L<Review::Helper::Export> asks it before opening a file it
would merge into.

=item $sql = Review::Helper::DB->schema()

The schema's DDL, read once from F<standards/review.sql> in the share directory
(L<Review::Helper::Util/share_dir>). C<create> runs it as is.

=item @names = Review::Helper::DB->schema_tables()

The names of the tables the schema defines, in schema order (a table before
the tables that refer to it). A file may hold other tables too.

=item @result = $db->txn(sub { ... })

Run the code in a transaction and return its result. Commits when it returns,
rolls back and rethrows when it dies. Transactions do not nest.

=item $review = $db->review()

Hashref of the review row.

=item $db->set_state($state)

Set the review's state to C<open> or C<closed>.

=item $db->set_published($id)

Record feedback item C<$id> as posted to the pull or merge request, now.
Croaks when there is no such item.

=item $iterations = $db->iterations()

Arrayref of iteration rows as hashrefs, oldest first.

=item $iteration = $db->latest_iteration()

Hashref of the newest iteration row, or undef when there is none.

=back

=head2 Queries for the web server

Rows come back as hashrefs of their columns; lists are arrayrefs. Range
columns stay JSON text.

=over 4

=item $iteration = $db->iteration($number)

The iteration row, or undef.

=item $commits = $db->commits($iteration)

The iteration's commit rows, first commit first.

=item $commits = $db->commits_by_revision($iteration, $revision)

The iteration's commit rows for C<$revision>, first first: one, or none; in a
squashed iteration split into topics, one per topic, all with the head's revision.

=item $commit = $db->commit_entry($id)

The commit row with that id, or undef.

=item $files = $db->files($commit_id)

The commit's file change rows, in insertion order.

=item $file = $db->file_change($id)

The file change row with that id, or undef.

=item $file = $db->file_by_path($commit_id, $path)

The commit's file change row for C<$path>, or undef.

=item $sections = $db->sections($file_id)

The file change's section rows, in file order.

=item $bool = $db->section_touched($section)

True for a section row the commit changed: deleted, or with a line added,
removed or changed. Only those are explained in the fill sheet and shown in
the page; a split stores the untouched sections too.

=item $entries = $db->journal_entries($iteration)

The iteration's journal entries, oldest first.

=item $flags = $db->flags($iteration)

The flag rows of the iteration's commits, each with C<revision> added.

=item $flag = $db->flag($id)

The flag row with that id, or undef.

=item $flag = $db->flag_by_note($iteration, $note_id)

The iteration's flag row with that note id, with C<revision> and C<topic>
(its entry's) added, or undef.

=item $marks = $db->flag_seen($iteration)

The C<flag_seen> rows of the iteration's flags, oldest mark first.

=item $db->set_flag_seen($flag_id, $reviewer, $seen)

Mark the flag seen by C<$reviewer> now when C<$seen> is true, keeping the
time of an earlier mark; remove that reviewer's mark when it is false.

=item $steps = $db->guide_steps($iteration)

The iteration's guide steps, in order.

=item $id = $db->add_feedback(%fields)

Insert open feedback and return its id. C<%fields>: C<iteration>,
C<target>, C<revision>, C<path>, C<section_name>, C<section_package>,
C<topic>, C<flag>, C<flag_sentence>, C<line>, C<side>, C<body>, C<reviewer>. The caller validates them.

=item $row = $db->feedback($id)

The feedback row with that id, or undef.

=item $bool = $db->update_feedback($id, %fields)

Set C<body> and/or C<status> of a feedback row and bump C<updated>. Returns
false when there is no such row. Croaks when neither field is given.

=item $id = $db->add_request(%fields)

Insert an open request and return its id. C<%fields>: C<iteration>, C<kind>,
C<target>, C<revision>, C<path>, C<section_name>, C<section_package>,
C<topic>, C<note>, C<reviewer>.

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
