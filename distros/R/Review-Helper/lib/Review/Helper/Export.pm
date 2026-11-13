package Review::Helper::Export;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Cpanel::JSON::XS();

use Review::Helper();
use Review::Helper::Builder;
use Review::Helper::DB;
use Review::Helper::Registry;

use Object::HashBase qw{
    <db
    <repo
};

use constant FORMAT         => 'review-export';
use constant FORMAT_VERSION => 1;

# Each reviewer keeps their own feedback, requests and seen marks.
my %EXCLUDED = (feedback => 1, request => 1, flag_seen => 1);

my $OTHER_VERSION = 'This review export was built by a different version of review-helper; export it again with this version, or import it with the version that built it';

my $JSON = Cpanel::JSON::XS->new->canonical->utf8;

sub export($self) {
    my $db  = $self->{+DB} or croak "'db' is required to export";
    my $dbh = $db->dbh;

    return {
        format         => FORMAT,
        format_version => FORMAT_VERSION,
        generator      => "Review::Helper $Review::Helper::VERSION",
        tables         => {map { ($_ => $self->export_table($dbh, $_)) } grep { !$EXCLUDED{$_} } Review::Helper::DB->schema_tables},
    };
}

# Rows in primary key order, or rowid order for a table without one.
# Extension (x_) columns stay behind, like extension tables.
sub export_table($self, $dbh, $name) {
    my $info = $dbh->selectall_arrayref('PRAGMA table_info(' . $dbh->quote_identifier($name) . ')', {Slice => {}});
    my @cols = grep { !m/^x_/ } map     { $_->{name} } @$info;
    my @pk   = map  { $_->{name} } sort { $a->{pk} <=> $b->{pk} } grep { $_->{pk} } @$info;

    my $select = join ', ' => map { $dbh->quote_identifier($_) } @cols;
    my $order  = @pk ? join(', ' => map { $dbh->quote_identifier($_) } @pk) : 'rowid';
    return {
        columns => \@cols,
        rows    => $dbh->selectall_arrayref("SELECT $select FROM " . $dbh->quote_identifier($name) . " ORDER BY $order"),
    };
}

# Canonical JSON with one table row per line, so exports diff well.
sub encode($self, $export) {
    my @tables;
    for my $name (sort keys %{$export->{tables}}) {
        my $table = $export->{tables}{$name};
        my @rows  = map { '        ' . $JSON->encode($_) } @{$table->{rows}};

        my @fields = ('      "columns": ' . $JSON->encode($table->{columns}));
        push @fields => '      "rows": ' . (@rows ? "[\n" . join(",\n" => @rows) . "\n      ]" : '[]');

        push @tables => '    ' . $JSON->encode($name) . ": {\n" . join(",\n" => @fields) . "\n    }";
    }

    my @top = map { qq{  "$_": } . $JSON->encode($export->{$_}) } qw/format format_version generator/;
    push @top => '  "tables": ' . (@tables ? "{\n" . join(",\n" => @tables) . "\n  }" : '{}');
    return "{\n" . join(",\n" => @top) . "\n}\n";
}

sub restore($self, $export, %params) {
    my $repo = $self->{+REPO} or croak "'repo' is required to import";
    my $id   = $self->check_export($export);

    my $registry = Review::Helper::Registry->new(repo => $repo);
    my $builder  = Review::Helper::Builder->new(repo => $repo);
    my $file     = $self->target_file($builder, $registry->reviews->{$id}, $id, $export, %params);

    # A file already holding this review takes the export in. Registering is
    # the transaction's last step, so a failure to register rolls the merge
    # back instead of leaving it in a file not registered as open.
    my $new = !-e $file;
    my $db  = $new ? Review::Helper::DB->create($file) : $self->open_same($file, $id);
    my $ok  = eval {
        $self->load($db, $export->{tables}, sub { $registry->register($id, $file, 'open') });
        1;
    };
    unless ($ok) {
        my $err = $@;
        if ($new) {
            $db->dbh->disconnect;
            unlink($file);
        }
        die $err;
    }

    return {file => $file, missing => $self->pin($db)};
}

# The registered file when it exists, else the asked-for or default file.
sub target_file($self, $builder, $known, $id, $export, %params) {
    if ($known && -e $known->{path}) {
        croak "Review $id is already in this repository: $known->{path}"
            if defined($params{file}) && $builder->resolve_file($params{file}) ne $builder->resolve_file($known->{path});
        return $known->{path};
    }

    my $file = $builder->resolve_file($params{file} // $self->default_file($params{name}, $export));
    $builder->check_location($file);
    return $file;
}

# Another format version's review file is refused as opening it is.
sub open_same($self, $file, $id) {
    my $db = Review::Helper::DB->is_review_file($file) ? Review::Helper::DB->open($file) : undef;
    croak "Review file '$file' already exists and does not hold review $id" unless $db && $db->review->{id} eq $id;
    return $db;
}

sub check_export($self, $export) {
    croak "Not a review export" unless ref($export) eq 'HASH' && ($export->{format} // '') eq FORMAT;

    my $version = $export->{format_version} // '';
    croak "Unsupported review export format version '$version'" unless $version eq FORMAT_VERSION;

    my $tables = $export->{tables};
    croak "The export has no 'tables' object" unless ref($tables) eq 'HASH';

    my @excluded = grep { $tables->{$_} } sort keys %EXCLUDED;
    croak "An export must not include these tables: @excluded" if @excluded;

    my $review = $tables->{review};
    my $rows   = ref($review) eq 'HASH' && ref($review->{columns}) eq 'ARRAY' && ref($review->{rows}) eq 'ARRAY' ? $review->{rows} : [];
    croak "The export must hold exactly one review row" unless @$rows == 1 && ref($rows->[0]) eq 'ARRAY';

    my %row = map { ($review->{columns}[$_] => $rows->[0][$_]) } 0 .. $#{$review->{columns}};
    croak "The export's review has no id" unless defined $row{id} && !ref $row{id};
    return $row{id};
}

sub default_file($self, $name, $export) {
    unless (defined $name) {
        my $review = $export->{tables}{review};
        my %row    = map { ($review->{columns}[$_] => $review->{rows}[0][$_]) } 0 .. $#{$review->{columns}};
        $name = $row{title} // $row{id};
    }

    $name =~ s/[^\w.\-]+/-/g;
    $name =~ s/\A[-.]+|-+\z//g;
    $name = 'review' unless length $name;

    return $self->{+REPO}->state_dir . "/$name.sqlite";
}

# Core tables load first, in schema order, so their rows replace the ones
# create() wrote; foreign keys are checked at commit, after every row is in.
# Into an existing file, the export replaces the review row and each
# iteration it holds, with everything agent-written under them; other
# iterations, feedback and requests stay. Flag ids are per file, so a replaced
# flag's marks move to the flag with its note in that iteration, if it still
# covers the same commit, path and lines. The review is then open: state is
# each reviewer's own.
sub load($self, $db, $tables, $then = undef) {
    my $dbh = $db->dbh;

    $db->txn(sub {
        $dbh->do('PRAGMA defer_foreign_keys = ON');
        $dbh->do('DELETE FROM review');
        my $numbers = $self->exported_iterations($tables);
        $self->save_marks($dbh, $numbers);
        $self->clear_iterations($dbh, $numbers);
        $self->load_table($dbh, $_, $tables->{$_}) for grep { !$EXCLUDED{$_} } Review::Helper::DB->schema_tables;
        $self->restore_marks($dbh);
        $db->set_state('open');
        $self->check_pins($db);
        $self->check_references($dbh);
        $then->() if $then;
    });

    return;
}

sub exported_iterations($self, $tables) {
    my $table = $tables->{iteration};
    my $cols  = ref($table) eq 'HASH' && ref($table->{columns}) eq 'ARRAY' && ref($table->{rows}) eq 'ARRAY' ? $table->{columns} : [];
    my ($at)  = grep { $cols->[$_] eq 'number' } 0 .. $#$cols;
    return [] unless defined $at;
    return [map { ref($_) eq 'ARRAY' ? $_->[$at] : () } @{$table->{rows}}];
}

# Marks on the flags of the iterations about to be replaced, by note and what
# the flag covers, with the flag's color: a flag the export has turned from
# yellow to red is unseen by everyone, as the recolor made it.
sub save_marks($self, $dbh, $numbers) {
    my $in = '(' . join(', ' => ('?') x @$numbers) . ')';
    $dbh->do('DROP TABLE IF EXISTS temp.saved_marks');
    $dbh->do(<<~"EOT", undef, @$numbers);
        CREATE TEMP TABLE saved_marks AS
        SELECT flag.note_id, commit_entry.iteration, commit_entry.revision, flag.path, flag.line_start, flag.line_end,
               flag.color, flag_seen.reviewer, flag_seen.at
          FROM flag_seen
          JOIN flag ON flag.id = flag_seen.flag
          JOIN commit_entry ON commit_entry.id = flag.commit_id
         WHERE commit_entry.iteration IN $in
        EOT
    return;
}

sub restore_marks($self, $dbh) {
    $dbh->do('DELETE FROM flag_seen WHERE flag NOT IN (SELECT id FROM flag)');
    $dbh->do(<<~'EOT');
        INSERT OR IGNORE INTO flag_seen (flag, reviewer, at)
        SELECT flag.id, saved_marks.reviewer, saved_marks.at
          FROM temp.saved_marks AS saved_marks
          JOIN flag ON flag.note_id = saved_marks.note_id
               AND flag.path IS saved_marks.path
               AND flag.line_start IS saved_marks.line_start
               AND flag.line_end IS saved_marks.line_end
               AND NOT (saved_marks.color = 'yellow' AND flag.color = 'red')
          JOIN commit_entry ON commit_entry.id = flag.commit_id
               AND commit_entry.iteration = saved_marks.iteration
               AND commit_entry.revision = saved_marks.revision
        EOT
    $dbh->do('DROP TABLE temp.saved_marks');
    return;
}

# Child rows first, so a deleted row never leaves one pointing at it.
sub clear_iterations($self, $dbh, $numbers) {
    return unless @$numbers;
    my $in      = '(' . join(', ' => ('?') x @$numbers) . ')';
    my $commits = "SELECT id FROM commit_entry WHERE iteration IN $in";
    my $files   = "SELECT id FROM file_change WHERE commit_id IN ($commits)";
    $dbh->do($_, undef, @$numbers)
        for (
        "DELETE FROM guide_step WHERE iteration IN $in",
        "DELETE FROM journal_entry WHERE iteration IN $in",
        "DELETE FROM flag_seen WHERE flag IN (SELECT id FROM flag WHERE commit_id IN ($commits))",
        "DELETE FROM flag WHERE commit_id IN ($commits)",
        "DELETE FROM section WHERE file_id IN ($files)",
        "DELETE FROM file_change WHERE commit_id IN ($commits)",
        "DELETE FROM commit_entry WHERE iteration IN $in",
        "DELETE FROM iteration WHERE number IN $in",
        );
    return;
}

# A column the export lacks would load as null or its default without a
# word, so that is refused; a column this version lacks fails the insert.
sub load_table($self, $dbh, $name, $table) {
    croak "$OTHER_VERSION (it has no table '$name')" unless $table;
    my ($cols, $rows) = ref($table) eq 'HASH' ? @$table{qw/columns rows/} : ();
    croak "Table '$name' needs 'columns' and 'rows' arrays" unless ref($cols) eq 'ARRAY' && @$cols && ref($rows) eq 'ARRAY';

    my @keep  = grep { $cols->[$_] !~ m/^x_/ } 0 .. $#$cols;
    my @use   = @{$cols}[@keep];
    my %has   = map  { ($_ => 1) } @use;
    my @lacks = grep { !$has{$_} && !m/^x_/ } @{$dbh->selectcol_arrayref('SELECT name FROM pragma_table_info(?)', undef, $name)};
    croak "$OTHER_VERSION (table '$name' lacks columns: @lacks)" if @lacks;

    # create() wrote this tool's own meta rows; they win.
    my $insert = $name eq 'meta' ? 'INSERT OR IGNORE' : 'INSERT';
    my $sth    = $dbh->prepare(
        "$insert INTO " . $dbh->quote_identifier($name) . ' (' . join(', ' => map { $dbh->quote_identifier($_) } @use) . ') VALUES (' . join(', ' => ('?') x @use) . ')',
    );

    for my $row (@$rows) {
        croak "Table '$name' has a row that does not match its columns" unless ref($row) eq 'ARRAY' && @$row == @$cols;
        croak "Table '$name' has a value that is not a string, number or null" if grep { ref } @$row;
        $sth->execute(@{$row}[@keep]);
    }

    return;
}

# Foreign keys are deferred to the commit; check them first, so that a step
# run before the commit (registering) is not undone by a bad reference.
sub check_references($self, $dbh) {
    my $bad = $dbh->selectrow_hashref('PRAGMA foreign_key_check') or return;
    croak "Table '$bad->{table}' has a row that refers to a missing '$bad->{parent}' row";
}

# Iterations are pinned by name, so the names must be this review's.
sub check_pins($self, $db) {
    my $id = $db->review->{id};
    for my $iteration (@{$db->iterations}) {
        my $want = $self->{+REPO}->pin_name($id, $iteration->{number});
        croak "Iteration $iteration->{number} must have pin '$want'" unless $iteration->{pin} eq $want;
    }
    return;
}

sub pin($self, $db) {
    my $repo = $self->{+REPO};
    my @missing;
    for my $iteration (@{$db->iterations}) {
        if ($repo->has_revision($iteration->{head})) {
            $repo->pin($iteration->{pin}, $iteration->{head});
        }
        else {
            push @missing => {iteration => $iteration->{number}, head => $iteration->{head}};
        }
    }
    return \@missing;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Export - A review file as shareable JSON, and back.

=head1 DESCRIPTION

The export is the text form of a review file, for sharing a review with
other reviewers: every table the schema defines except C<feedback>,
C<request> and C<flag_seen>, since each reviewer keeps their own. Tables are
written generically, with their columns and their rows in primary key order,
so new columns need no code here.

Extension tables and columns (named C<x_...>) are not carried in this format
version. Importing ignores any it finds.

Importing creates a review file in the current repository, or merges an
export of a review already here into the file holding it, registers it as
open, and pins each iteration whose head commit is present.

=head1 SYNOPSIS

    use Review::Helper::Export;

    my $exporter = Review::Helper::Export->new(db => $db);
    print $exporter->encode($exporter->export);

    my $importer = Review::Helper::Export->new(repo => $repo);
    my $result   = $importer->restore($export, name => 'add-caching');
    say $result->{file};
    say "fetch $_->{head}" for @{$result->{missing}};

=head1 ATTRIBUTES

=over 4

=item $db = $export->db()

The L<Review::Helper::DB> to export. Required by C<export>.

=item $repo = $export->repo()

The repository to import into, a L<Review::Helper::VCS>. Required by
C<restore>.

=back

=head1 PUBLIC METHODS

=over 4

=item $export = $exporter->export()

The review as a hashref: C<format> (C<review-export>), C<format_version>
(1), C<generator>, and C<tables>, which maps each table name to
C<< { columns => [...], rows => [[...], ...] } >>.

=item $table = $exporter->export_table($dbh, $name)

One table as C<< { columns => [...], rows => [[...], ...] } >>: rows in
primary key order, or rowid order for a table without one, leaving out
C<x_> extension columns.

=item $text = $exporter->encode($export)

The export as UTF-8 JSON text with sorted keys and one table row per line.

=item $result = $importer->restore($export, %params)

Import a decoded export and return
C<< { file => $path, missing => [{ iteration => $n, head => $revision }, ...] } >>.
The review is open and registered as open, whatever state the export
records. C<missing> lists iterations whose head commit is not in the
repository; they are not pinned. C<%params> may hold C<file> (default:
F<NAME.sqlite> in the VCS's state directory) and C<name>
(default: the review's title, else its id).

When the review is already registered here with a file that exists, or the
target file already holds it, the export is merged into that file: see
C<load>; registering is the last step of its transaction. Croaks, leaving
no new file behind and an existing file unchanged, when registering fails,
when the export is invalid or lacks a table or column this version has
(another version built it), when the target file exists and holds another
review or has another format version, or when C<file> names a path other
than the review's registered file.

=item $id = $importer->check_export($export)

Croak unless C<$export> has this format and version, a C<tables> object, no
feedback, requests or seen marks, and exactly one review row. Returns the review id.

=item $path = $importer->target_file($builder, $known, $id, $export, %params)

The file to import into: the registered file C<$known> when it exists,
else C<file> or the default file, checked for location.

=item $db = $importer->open_same($file, $id)

Open an existing C<$file>, croaking unless it is a review file holding
review C<$id>. A file of another format version is refused as
L<Review::Helper::DB/open> refuses it.

=item $path = $importer->default_file($name, $export)

The default file for an import, named after C<$name> or the export's review.

=item $importer->load($db, $tables)

=item $importer->load($db, $tables, $then)

Write the exported tables into the review file in one transaction. C<$then>,
when given, runs last inside it, after every check: when it dies, nothing is
written. The
export's review row replaces the file's; each exported iteration replaces
the file's iteration of that number with all its commits, files, sections,
flags, journal entries and guide steps. Iterations the export lacks, the C<meta> rows, and
all feedback and requests stay. A replaced flag's marks move to the flag
with the same C<note_id> in that iteration when it covers the same commit,
path and lines, unless the export turned it from yellow to red, and are
dropped otherwise. The review's state is then C<open>.

=item $importer->save_marks($dbh, $numbers)

=item $importer->restore_marks($dbh)

C<save_marks> keeps the seen marks of iterations C<$numbers> in a temporary
table before C<load> replaces them; C<restore_marks> puts each back on the
new flag with the same C<note_id>, iteration, commit, path and lines, unless
that flag is red and was yellow, drops the rest, and removes the temporary
table.

=item $numbers = $importer->exported_iterations($tables)

The iteration numbers the exported C<iteration> table holds.

=item $importer->clear_iterations($dbh, $numbers)

Delete those iterations and every row under them.

=item $importer->load_table($dbh, $name, $table)

Insert one exported table's rows, skipping C<x_> columns. Croaks when the
export has no such table or lacks a column the file's table has (other than
an C<x_> one), which would otherwise load as null without a word: a
different version of review-helper built the export. A column the file's
table lacks fails the insert.

=item $importer->check_references($dbh)

Croak when a row refers to a row that is not there. C<load> defers foreign
keys to the commit and checks them with this before C<$then>, so nothing
it runs is followed by a failed commit for want of a row.

=item $importer->check_pins($db)

Croak unless each iteration's pin is the name the VCS gives it
(L<Review::Helper::VCS/pin_name>).

=item $missing = $importer->pin($db)

Pin each iteration of the file whose head is present, including ones pinned
before or fetched since, and return the others.

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
