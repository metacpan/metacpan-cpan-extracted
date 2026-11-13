package Review::Helper::Builder;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Cpanel::JSON::XS();
use Cwd qw/abs_path/;
use Encode qw/decode FB_DEFAULT/;
use File::Basename qw/basename dirname/;
use File::Spec();

use Review::Helper::DB;
use Review::Helper::Diff qw/parse_diff count_lines attribute map_lines move_ranges/;
use Review::Helper::Journal;
use Review::Helper::Registry;
use Review::Helper::Split;
use Review::Helper::Util qw/now/;

use Object::HashBase qw{
    <repo
    <db
    <journal
};

# Character-string JSON for TEXT columns; the database handle does the UTF-8.
my $JSON = Cpanel::JSON::XS->new->canonical;

my @FILE_TEXT = qw/what object_system paradigms/;

my $CLOSED_NOTE = '(closed: its commit was rewritten)';

sub init($self) {
    croak "'repo' is a required attribute" unless $self->{+REPO};
    $self->{+JOURNAL} //= Review::Helper::Journal->new(repo => $self->{+REPO});
}

sub build($self, %params) {
    my $squash = $params{squash} ? 1 : 0;
    croak "Missing required parameter 'base'" unless defined($params{base}) || $squash;
    croak "This builder already has a review file" if $self->{+DB};

    my $repo  = $self->{+REPO};
    my %range = (
        base     => defined($params{base}) ? $repo->resolve($params{base}) : $repo->empty_revision,
        head     => $repo->resolve($params{head} // 'HEAD'),
        squashed => $squash,
        paths    => $self->check_paths($params{paths}),
    );
    my $commits = $self->collect_range(\%range);

    my $file = $self->resolve_file($params{file} // $self->default_file($params{head} // 'HEAD', $range{head}));
    $self->check_location($file);
    croak "Review file path '$file' is not valid UTF-8" unless utf8::decode(my $text = $file);

    my $db = $self->{+DB} = Review::Helper::DB->create($file, title => $params{title}, source => $params{source});
    my $ok = eval { $self->store(1, \%range, $commits); 1 };
    unless ($ok) {
        my $err = $@;
        $db->dbh->disconnect;
        unlink($file);
        die $err;
    }

    Review::Helper::Registry->new(repo => $repo)->register($db->review->{id}, $file);
    return $file;
}

sub iterate($self, %params) {
    my $db   = $self->{+DB}          or croak "'db' is required to add an iteration";
    my $prev = $db->latest_iteration or croak "The review has no iteration to follow";

    my $repo  = $self->{+REPO};
    my $base  = $params{base} // $prev->{base};
    my %range = (
        base     => $base eq $repo->empty_revision ? $base : $repo->resolve($base),
        head     => $repo->resolve($params{head} // 'HEAD'),
        squashed => $prev->{squashed},
        paths    => defined($prev->{paths}) ? $JSON->decode($prev->{paths}) : undef,
    );
    my $commits = $self->collect_range(\%range);
    $self->carry_forward($prev, \%range, $commits);

    my $number = $prev->{number} + 1;
    $self->store($number, \%range, $commits);
    return $number;
}

# Path specs as given, or undef for the whole repository.
sub check_paths($self, $paths) {
    return undef                                   unless defined $paths;
    croak "'paths' must be an array of path specs" unless ref($paths) eq 'ARRAY' && !grep { !defined($_) || ref($_) || !length($_) } @$paths;
    return @$paths ? [@$paths] : undef;
}

sub collect_range($self, $range) {
    return $self->collect_squashed(@$range{qw/base head paths/}) if $range->{squashed};
    return $self->collect(@$range{qw/base head paths/});
}

sub collect($self, $base, $head, $paths = undef) {
    my $history = $self->{+REPO}->revisions($base, $head);
    croak "No commits in $base..$head" unless @$history;

    my %parents = map { ($_->{revision} => $_->{parents}) } @$history;
    my @order   = map { $_->{revision} } @$history;
    my $owners  = $self->merge_owners(\%parents, \@order);
    my @commits = map { $self->collect_commit($_, @{$parents{$_}} > 1, $paths) } @order;
    $_->{merge_revision} = $owners->{$_->{revision}} for @commits;
    return \@commits unless $paths;

    my $kept = $self->drop_untouched(\@commits);
    croak "No commits in $base..$head change the given paths" unless @$kept;
    return $kept;
}

# One combined entry for base..head: the head's commit text, with the base
# as its parent (none for the empty revision) and no change id.
sub collect_squashed($self, $base, $head, $paths = undef) {
    my $repo    = $self->{+REPO};
    my $changes = $repo->range_changes($base, $head, $paths);
    croak "No changes in $base..$head" . ($paths ? ' under the given paths' : '') unless @$changes;

    my $info = {%{$repo->revision_info($head)}, parent => $base eq $repo->empty_revision ? undef : $base};
    return [{%$info, change_id => undef, files => [map { $self->collect_file($info, $_) } @$changes]}];
}

# Commits that change none of the paths, and merges whose commits all went.
# A merge's commits come before it, so one pass finds them.
sub drop_untouched($self, $commits) {
    my (%has_commits, @kept);
    for my $commit (@$commits) {
        next unless @{$commit->{files}} || $has_commits{$commit->{revision}};
        push @kept => $commit;
        $has_commits{$commit->{merge_revision}} = 1 if $commit->{merge_revision};
    }

    return \@kept;
}

# Map each commit a merge brought in to that merge: commits reachable from
# the merge's other parents but not its first. Outer merges go first (newest
# first), and a merge takes only commits its own owner holds, so a nested
# merge keeps its commits and a back-merge of the mainline takes none.
sub merge_owners($self, $parents, $order) {
    my (%owner, %mainline);
    my $revision = $order->[-1];
    while (defined($revision) && $parents->{$revision}) {
        $mainline{$revision} = 1;
        $revision = $parents->{$revision}->[0];
    }

    for my $merge (reverse grep { @{$parents->{$_}} > 1 } @$order) {
        my ($first, @others) = @{$parents->{$merge}};
        my $outer   = $owner{$merge} // '';
        my $own     = $self->ancestors($parents, $first);
        my @brought = grep { !$own->{$_} && !$mainline{$_} } keys %{$self->ancestors($parents, @others)};
        $owner{$_} = $merge for grep { ($owner{$_} // '') eq $outer } @brought;
    }

    return \%owner;
}

# The given commits and their ancestors, within the range %$parents covers.
sub ancestors($self, $parents, @start) {
    my %seen;
    my @todo = @start;
    while (@todo) {
        my $revision = shift @todo;
        next if $seen{$revision} || !$parents->{$revision};
        $seen{$revision} = 1;
        push @todo => @{$parents->{$revision}};
    }
    return \%seen;
}

# A merge lists no file changes: the commits it brought in hold them.
sub collect_commit($self, $revision, $merge = 0, $paths = undef) {
    my $repo = $self->{+REPO};
    my $info = $repo->revision_info($revision);

    return {
        %$info,
        change_id => $repo->change_id($revision),
        files     => $merge ? [] : [map { $self->collect_file($info, $_) } @{$repo->range_changes($info->{parent} // $repo->empty_revision, $revision, $paths)}],
    };
}

sub collect_file($self, $info, $change) {
    return $self->submodule_file($change) if $change->{submodule};

    my $texts = $self->file_texts($info->{revision}, $info->{parent}, $change, $change->{binary});

    my $text    = $texts->{after} // $texts->{before};
    my ($first) = defined($text) ? split(/\n/, $text, 2) : ();
    my $kind    = Review::Helper::Split->kind_for($change->{path}, $first);
    $kind = 'binary' if $change->{binary} && $kind ne 'image';
    my $bytes = $kind eq 'image' || $kind eq 'binary';

    return {
        (map { ($_ => $change->{$_}) } qw/path old_path status/),
        kind         => $kind,
        size_unit    => $bytes ? 'bytes' : 'lines',
        size_before  => $self->size($texts, 'before', $bytes),
        size_after   => $self->size($texts, 'after',  $bytes),
        split_source => 'none',
        sections     => [],
        %{count_lines($texts->{hunks})},
    };
}

# A submodule entry has no content in this repository: list it as a binary
# file with no sizes and no sections.
sub submodule_file($self, $change) {
    return {
        (map { ($_ => $change->{$_}) } qw/path old_path status/),
        kind         => 'binary',
        size_unit    => 'bytes',
        size_before  => undef,
        size_after   => undef,
        split_source => 'none',
        sections     => [],
        added        => 0,
        removed      => 0,
        changed      => 0,
    };
}

# Raw and decoded content of both sides of a change, and its parsed diff.
sub file_texts($self, $revision, $parent, $change, $binary) {
    my $repo = $self->{+REPO};
    my %texts;

    # The status says which sides exist.
    $texts{before_raw} = $repo->file($parent,   $change->{old_path} // $change->{path}) if $parent && $change->{status} ne 'A';
    $texts{after_raw}  = $repo->file($revision, $change->{path})                        if $change->{status} ne 'D';

    unless ($binary) {
        $texts{$_} = $self->decode_text($texts{"${_}_raw"}) for qw/before after/;
    }

    my $diff = $repo->range_diff($parent // $repo->empty_revision, $revision, $change->{path}, $change->{old_path});
    $texts{hunks} = parse_diff($self->decode_text($diff))->{hunks};
    return \%texts;
}

sub decode_text($self, $bytes) {
    return undef unless defined $bytes;
    return decode('UTF-8', "$bytes", FB_DEFAULT);
}

sub size($self, $texts, $side, $bytes) {
    my $raw = $texts->{"${side}_raw"};
    return undef unless defined $raw;
    return length($raw) if $bytes;
    return scalar @{Review::Helper::Split->lines($texts->{$side})};
}

# The sections of an agent split of a text change: its units with lines on
# the new side (blank lines in none joined to them), and its units with only
# old_ranges as deleted sections. Line counts come from the diff. Every
# section is kept, touched or not, so a later split can start from the
# whole of this one.
sub split_sections($self, $texts, $units) {
    my @live     = grep { @{$_->{ranges}} } @$units;
    my @deleted  = map  { +{%$_, ranges => [], doc_ranges => [], deleted => 1} } grep { !@{$_->{ranges}} } @$units;
    my $sections = Review::Helper::Split->assemble(\@live, Review::Helper::Split->lines($texts->{after} // ''));

    my @all = ((map { +{old_ranges => [], %$_, deleted => 0} } @$sections), @deleted);
    attribute($texts->{hunks}, \@all);
    delete $_->{touched} for @all;
    return \@all;
}

# A commit carries from the previous iteration's commit with the same change
# id (a commit with none, the same revision). Commits sharing a change id pair
# in order, the first with the first. Two squashed iterations over the same
# base and paths pair their entries by topic instead (the entry with no topic
# pairs with the one with none): files keep their topic, and a topic's own
# text and reading order carry only when it has the same files, its text only
# when each of them also reads the same. The flags of a topic left with no
# file go to the first entry, as when a topics fill removes an entry, so no
# flag and no seen mark is left behind.
sub carry_forward($self, $prev_iteration, $range, $commits) {
    my $dbh  = $self->{+DB}->dbh;
    my $prev = $dbh->selectall_arrayref('SELECT * FROM commit_entry WHERE iteration = ? ORDER BY position', {Slice => {}}, $prev_iteration->{number});
    my (%by_patch, %by_revision);
    push @{$by_patch{$_->{change_id}}} => $_ for grep { defined $_->{change_id} } @$prev;

    # An empty diff (an --allow-empty commit, a merge that changed nothing)
    # has no change id to pair by. Squashed entries have none either, and
    # pair only by topic.
    if (!$prev_iteration->{squashed} && !$range->{squashed}) {
        push @{$by_revision{$_->{revision}}} => $_ for grep { !defined $_->{change_id} } @$prev;
    }
    my %by_topic = map { (($_->{topic} // "\0") => $_) } @$prev;
    my $squash   = $self->same_squash($prev_iteration, $range);
    @$commits = @{$self->topic_entries($prev, $commits->[0])} if $squash;

    for my $commit (@$commits) {
        my $old =
              $squash                       ? $by_topic{$commit->{topic} // "\0"}
            : defined($commit->{change_id}) ? shift(@{$by_patch{$commit->{change_id}} // []})
            :                                 shift(@{$by_revision{$commit->{revision}} // []});
        my (%old_files, $order);
        if ($old) {
            %old_files            = map { ($_->{path} => $_) } @{$self->stored_files($old->{id})};
            $order                = !$squash || join("\0" => sort keys %old_files) eq join("\0" => sort map { $_->{path} } @{$commit->{files}});
            $commit->{$_}         = $old->{$_} for ($squash ? () : qw/what why how/), ($order ? 'order_set' : ());
            $commit->{carry_from} = $old->{id};
        }

        my $same = $order;
        for my $file (@{$commit->{files}}) {
            $same = 0 unless $old_files{$file->{path}} && $self->carry_file($file, $old_files{$file->{path}}, $old, $commit, $squash, $order);
        }
        $commit->{$_} = $old->{$_} for $squash && $same ? qw/what why how/ : ();
    }

    if ($squash && @$commits) {
        my %paired = map { ($_->{carry_from} => 1) } grep { $_->{carry_from} } @$commits;
        $commits->[0]->{carry_also} = [map { $_->{id} } grep { !$paired{$_->{id}} } @$prev];
    }

    return;
}

# A squashed iteration's entry split by the previous iteration's topics:
# each file in the topic that held its path, in the topics' order, and the
# files in none (new ones, or ones not yet in a topic) in one entry with no
# topic, last. A topic left with no file goes. The entry as it is when the
# previous iteration had no topics.
sub topic_entries($self, $prev, $entry) {
    my @topics = grep { defined } map { $_->{topic} } @$prev;
    return [$entry] unless @topics;

    my $sth = $self->{+DB}->dbh->prepare('SELECT path FROM file_change WHERE commit_id = ?');
    my %topic_of;
    for my $old (grep { defined $_->{topic} } @$prev) {
        $topic_of{$_} = $old->{topic} for @{$self->{+DB}->dbh->selectcol_arrayref($sth, undef, $old->{id})};
    }

    my %files;
    push @{$files{$topic_of{$_->{path}} // "\0"}} => $_ for @{$entry->{files}};
    return [map { +{%$entry, topic => $_ eq "\0" ? undef : $_, files => $files{$_}} } grep { $files{$_} } @topics, "\0"];
}

# Whether two iterations (rows, or a range for the new one) are both
# squashed over the same base and the same paths.
sub same_squash($self, $old, $new) {
    return !!0 unless $old->{squashed} && $new->{squashed} && $old->{base} eq $new->{base};
    my ($from, $to) = map { ref($_->{paths}) ? $JSON->encode($_->{paths}) : $_->{paths} // '' } $old, $new;
    return $from eq $to;
}

# A file in a commit with the same change id: same diff, same explanations.
# A file of a paired squashed entry gets its explanations only when it reads
# the same, and its reading position only when $order says the entry's files
# are the same. The agent's split comes along only when the change is the
# same: the file reads the same on both sides, since its ranges are line
# numbers and a rebase can move the same patch to other lines.
sub carry_file($self, $file, $old, $old_commit, $commit, $squash = 0, $order = 1) {
    $file->{read_position} = $old->{read_position} if $order;
    $file->{$_} = $old->{$_} for $squash ? () : @FILE_TEXT;

    my $split = $old->{split_source} ne 'none';
    return !!0 unless $squash || $split;

    my $repo  = $self->{+REPO};
    my $after = $repo->file_id($old_commit->{revision}, $file->{path});
    my $same  = ($after // '') eq ($repo->file_id($commit->{revision}, $file->{path}) // '');
    $file->{$_} = $old->{$_} for $squash && $same ? @FILE_TEXT : ();
    return $same unless $split && defined($after) && $same;

    my $path = $file->{old_path} // $file->{path};
    my ($from, $to) = map { defined($_->{parent}) ? $repo->file_id($_->{parent}, $path) : undef } $old_commit, $commit;
    return $same unless ($from // '') eq ($to // '');

    $file->{split_source} = $old->{split_source};
    $file->{sections}     = $old->{sections};
    return $same;
}

sub stored_files($self, $commit_id) {
    my $dbh   = $self->{+DB}->dbh;
    my $files = $dbh->selectall_arrayref('SELECT * FROM file_change WHERE commit_id = ? ORDER BY id', {Slice => {}}, $commit_id);
    my $sth   = $dbh->prepare('SELECT * FROM section WHERE file_id = ? ORDER BY position');

    for my $file (@$files) {
        $sth->execute($file->{id});
        my $sections = $sth->fetchall_arrayref({});
        for my $section (@$sections) {
            $section->{$_} = $JSON->decode($section->{$_}) for qw/ranges doc_ranges old_ranges/;
            delete @$section{qw/id file_id position/};
        }
        $file->{sections} = $sections;
    }

    return $files;
}

sub store($self, $number, $range, $commits) {
    my $db      = $self->{+DB};
    my $pin     = $self->{+REPO}->pin_name($db->review->{id}, $number);
    my $paths   = $range->{paths} ? $JSON->encode($range->{paths}) : undef;
    my $journal = $self->{+JOURNAL};
    my @entries = $self->journal_entries;

    $db->txn(sub {
        my $dbh = $db->dbh;
        $dbh->do(
            'INSERT INTO iteration (number, base, head, squashed, paths, pin, created) VALUES (?, ?, ?, ?, ?, ?, ?)', undef,
            $number, @$range{qw/base head/}, $range->{squashed} ? 1 : 0, $paths, $pin, now(),
        );

        my ($position, %ids) = (0);
        $ids{$_->{revision}} = $self->store_commit($number, ++$position, $_) for @$commits;
        for my $commit (grep { $_->{merge_revision} } @$commits) {
            $dbh->do('UPDATE commit_entry SET merge_id = ? WHERE id = ?', undef, $ids{$commit->{merge_revision}}, $ids{$commit->{revision}});
        }

        $self->carry_unpaired_flags($number, $commits) if $number > 1 && !$range->{squashed};
        $self->close_orphaned_requests($number)        if $number > 1;
        $self->flags_off_change($number)               if $number > 1;
        $self->flags_to_paths($number)                 if $range->{squashed};
        $self->store_journal($number, \@entries);
    });

    # Only a committed iteration is pinned: a failed commit leaves no pin behind.
    $self->{+REPO}->pin($pin, $range->{head});

    # The iteration is in; a failed removal must not undo or repeat it. An
    # entry left behind is ignored by the next build or iteration.
    eval {
        $journal->remove(map { $_->{id} } @entries) if @entries;
        1;
    } or warn "Could not remove the stored journal entries from the journal: $@";
    return;
}

# The journal's entries: its notes without a flag. One bad entry (a hand
# edit, another tool) is skipped with a warning, as the journal skips a bad
# line, so it blocks no build.
sub journal_entries($self) {
    my $journal = $self->{+JOURNAL};
    my @entries;
    for my $note (grep { !defined $_->{flag} } @{$journal->notes}) {
        my $error = $journal->entry_error($note);
        if ($error) {
            warn "Skipping journal entry $note->{id}: $error\n";
            next;
        }
        push @entries => $note;
    }
    return @entries;
}

# An entry already in the file was taken by an earlier build whose removal
# from the journal failed; it stays where it was.
sub store_journal($self, $number, $entries) {
    my $sth = $self->{+DB}->dbh->prepare('INSERT OR IGNORE INTO journal_entry (id, iteration, kind, path, unit, sentence, detail, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    $sth->execute($_->{id}, $number, @$_{qw/kind path unit sentence detail created/}) for @$entries;
    return;
}

# In a squashed iteration a path names the entry holding it, so a carried
# flag goes to that entry: its file may now be in another one (a file
# renamed waits in the entry with no topic).
sub flags_to_paths($self, $number) {
    $self->{+DB}->dbh->do(<<'    EOT', undef, ($number) x 3);
        UPDATE flag SET commit_id = (
            SELECT f.commit_id FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = ? AND f.path = flag.path)
         WHERE path IS NOT NULL
           AND commit_id IN (SELECT id FROM commit_entry WHERE iteration = ?)
           AND EXISTS (SELECT 1 FROM file_change f JOIN commit_entry c ON c.id = f.commit_id WHERE c.iteration = ? AND f.path = flag.path)
    EOT
    return;
}

# A carried flag on a file that left the change in this iteration (a
# squashed change reverted to the base, say) is pending even when its lines
# read the same: the agent keeps, recolors or retires it. Its marks go, as
# any pending flag's do. Left means no entry of its commit changes its path
# now while one did in the previous iteration, so a kept flag on a file
# already outside the change carries settled. The entries of a squashed
# commit share its revision.
sub flags_off_change($self, $number) {
    my $dbh = $self->{+DB}->dbh;
    my $ids = $dbh->selectcol_arrayref(<<'    EOT', undef, $number);
        SELECT flag.id FROM flag JOIN commit_entry c ON c.id = flag.commit_id
         WHERE c.iteration = ? AND flag.path IS NOT NULL AND flag.pending = 0
           AND NOT EXISTS (SELECT 1 FROM file_change f JOIN commit_entry e ON e.id = f.commit_id
                            WHERE e.iteration = c.iteration AND e.revision = c.revision AND f.path = flag.path)
           AND EXISTS (SELECT 1 FROM flag p JOIN commit_entry pc ON pc.id = p.commit_id
                         JOIN file_change pf ON pf.path = p.path
                         JOIN commit_entry pe ON pe.id = pf.commit_id AND pe.iteration = pc.iteration AND pe.revision = pc.revision
                        WHERE p.note_id = flag.note_id AND pc.iteration = c.iteration - 1)
    EOT
    for my $id (@$ids) {
        $dbh->do('UPDATE flag SET pending = 1 WHERE id = ?', undef, $id);
        $dbh->do('DELETE FROM flag_seen WHERE flag = ?',     undef, $id);
    }
    return;
}

# Split requests on a commit the new iteration no longer has
# are closed with a note saying why.
sub close_orphaned_requests($self, $number) {
    $self->{+DB}->dbh->do(<<'    EOT', undef, $CLOSED_NOTE, $number);
        UPDATE request SET status = 'done', note = COALESCE(note || ' ', '') || ?
         WHERE status = 'open' AND kind = 'split' AND target = 'file'
           AND revision NOT IN (SELECT revision FROM commit_entry WHERE iteration = ?)
    EOT
    return;
}

sub store_commit($self, $number, $position, $commit) {
    my $dbh = $self->{+DB}->dbh;

    my @cols = qw/revision parent subject message author authored change_id topic what why how/;
    $dbh->do(
        'INSERT INTO commit_entry (iteration, position, order_set, ' . join(', ' => @cols) . ') VALUES (?, ?, ?' . (', ?' x @cols) . ')', undef,
        $number, $position, $commit->{order_set} // 0, @$commit{@cols},
    );
    my $id = $dbh->last_insert_id(undef, undef, 'commit_entry', 'id');

    $self->carry_flags($id, $commit, $_) for grep { defined } $commit->{carry_from}, @{$commit->{carry_also} // []};
    $self->store_file($id, $_) for @{$commit->{files}};
    return $id;
}

# Copy the flags of the commit this one carries from (or of $from, another
# stored entry of the same squashed commit). A flag whose code is unchanged
# follows it, to its file's new path when the VCS finds the file renamed, its
# lines moved by the diff between the two versions of its file, with its seen
# marks. One whose code changed is pending, for the agent to keep, recolor or
# retire, with no seen marks, on the span of its lines the diff kept, else on
# the whole file.
sub carry_flags($self, $commit_id, $commit, $from = $commit->{carry_from}) {
    my $dbh   = $self->{+DB}->dbh;
    my $old   = $dbh->selectrow_hashref('SELECT revision, parent FROM commit_entry WHERE id = ?', undef, $from);
    my $flags = $dbh->selectall_arrayref('SELECT * FROM flag WHERE commit_id = ? ORDER BY id', {Slice => {}}, $from);

    my @cols = qw/note_id path line_start line_end color color_reason kind sentence detail created pending/;
    my $sth  = $dbh->prepare('INSERT INTO flag (commit_id, ' . join(', ' => @cols) . ') VALUES (?' . (', ?' x @cols) . ')');
    my $seen = $dbh->prepare('INSERT INTO flag_seen (flag, reviewer, at) SELECT ?, reviewer, at FROM flag_seen WHERE flag = ?');
    my (%moves, %to);
    for my $flag (@$flags) {
        my $path = $flag->{path};
        my $same = 1;
        if (defined $path) {
            $to{$path}    //= $self->renamed_to($old, $commit, $path)             // $path;
            $moves{$path} //= $self->line_moves($old, $commit, $path, $to{$path}) // 0;
            $same = $moves{$path} && !@{$moves{$path}};
            $flag->{path} = $to{$path};
        }
        if (defined($path) && defined($flag->{line_start})) {
            my @lines = $moves{$path} ? map_lines($moves{$path}, @$flag{qw/line_start line_end/}) : ();
            $same                           = !!@lines;
            @lines                          = $self->kept_span($moves{$path}, @$flag{qw/line_start line_end/}) if !$same && $moves{$path};
            @$flag{qw/line_start line_end/} = @lines ? @lines : (undef, undef);
        }
        $flag->{pending} = 1 unless $same;
        $sth->execute($commit_id, @$flag{@cols});
        $seen->execute($dbh->last_insert_id(undef, undef, 'flag', 'id'), $flag->{id}) if $same;
    }

    return;
}

# The flags of a previous commit no new commit pairs with (rewritten, so
# its change id changed, or dropped) are not lost: each goes pending, without
# seen marks, onto the last new commit that changes its path, its lines moved
# through the diff between the two commits where the diff keeps any, else on
# the whole file. With no new commit changing its path, or no path, it goes
# on the iteration's last commit (whole-file), where the sheet reports it as
# having left the change.
sub carry_unpaired_flags($self, $number, $commits) {
    my $dbh    = $self->{+DB}->dbh;
    my %paired = map { ($_->{carry_from} => 1) } grep { $_->{carry_from} } @$commits;
    my $old    = $dbh->selectall_arrayref('SELECT id, revision, parent FROM commit_entry WHERE iteration = ? ORDER BY position', {Slice => {}}, $number - 1);
    my @lost   = grep { !$paired{$_->{id}} } @$old or return;
    my $new    = $dbh->selectall_arrayref('SELECT id, revision, parent FROM commit_entry WHERE iteration = ? ORDER BY position DESC', {Slice => {}}, $number);
    return unless @$new;

    my @cols   = qw/note_id path line_start line_end color color_reason kind sentence detail created/;
    my $insert = $dbh->prepare('INSERT INTO flag (commit_id, pending, ' . join(', ' => @cols) . ') VALUES (?, 1' . (', ?' x @cols) . ')');
    for my $from (@lost) {
        for my $flag (@{$dbh->selectall_arrayref('SELECT * FROM flag WHERE commit_id = ? ORDER BY id', {Slice => {}}, $from->{id})}) {
            my $path = $flag->{path};
            my ($to) = defined($path) ? grep { $dbh->selectrow_array('SELECT 1 FROM file_change WHERE commit_id = ? AND path = ?', undef, $_->{id}, $path) } @$new : ();
            my @lines;
            if ($to && defined $flag->{line_start}) {
                my $moves = $self->line_moves($from, $to, $path);
                @lines = map_lines($moves, @$flag{qw/line_start line_end/})        if $moves;
                @lines = $self->kept_span($moves, @$flag{qw/line_start line_end/}) if $moves && !@lines;
            }
            @$flag{qw/line_start line_end/} = @lines ? @lines : (undef, undef);
            $insert->execute(($to // $new->[0])->{id}, @$flag{@cols});
        }
    }
    return;
}

# From the first to the last of the lines start..end the diff kept, at their
# new numbers; empty when it kept none.
sub kept_span($self, $hunks, $start, $end) {
    my ($moved) = move_ranges($hunks, [[$start, $end // $start]]);
    return @$moved ? ($moved->[0]->[0], $moved->[-1]->[1]) : ();
}

# The path a file at $path in one commit has in another, when the VCS finds
# it renamed between them; undef when it is not, or still has its path.
sub renamed_to($self, $old, $new, $path) {
    my $repo = $self->{+REPO};
    return undef if $old->{revision} eq $new->{revision} || defined($repo->file_id($new->{revision}, $path)) || !defined($repo->file_id($old->{revision}, $path));
    my ($change) = grep { $_->{status} eq 'R' && $_->{old_path} eq $path } @{$repo->range_changes($old->{revision}, $new->{revision})};
    return $change ? $change->{path} : undef;
}

# The diff hunks from a path in one commit to the same path (or $to_path,
# where it was renamed) in another, so line numbers in one can be moved to
# the other; none when they read the same. A file both deleted is compared
# as it was before them. Undef when the path exists on one side only, or is
# a binary file that changed.
sub line_moves($self, $old, $new, $path, $to_path = $path) {
    return [] if $old->{revision} eq $new->{revision};

    my $repo = $self->{+REPO};
    my ($from, $to) = ($old->{revision}, $new->{revision});
    ($from, $to) = ($old->{parent}, $new->{parent}) unless defined($repo->file_id($from, $path)) || defined($repo->file_id($to, $to_path));
    return undef unless defined($from) && defined($to);

    my ($before, $after) = ($repo->file_id($from, $path), $repo->file_id($to, $to_path));
    return undef unless defined($before) && defined($after);
    return [] if $before eq $after;
    my $diff = parse_diff($self->decode_text($repo->range_diff($from, $to, $to_path, $to_path eq $path ? undef : $path)));
    return undef if $diff->{binary};
    return $diff->{hunks};
}

sub store_file($self, $commit_id, $file) {
    my $dbh = $self->{+DB}->dbh;

    my @cols = (qw/path old_path status kind size_unit size_before size_after added removed changed read_position split_source/, @FILE_TEXT);
    $dbh->do('INSERT INTO file_change (commit_id, ' . join(', ' => @cols) . ') VALUES (?' . (', ?' x @cols) . ')', undef, $commit_id, @$file{@cols});
    my $id = $dbh->last_insert_id(undef, undef, 'file_change', 'id');

    $self->store_sections($id, $file->{sections});
    return;
}

sub store_sections($self, $file_id, $sections) {
    my $sth = $self->{+DB}->dbh->prepare(<<'    EOT');
        INSERT INTO section (file_id, position, name, package, ranges, doc_ranges, old_ranges, deleted, added, removed, changed, what)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    EOT

    my $position = 0;
    for my $s (@$sections) {
        $sth->execute(
            $file_id, ++$position, @$s{qw/name package/},
            (map { $JSON->encode($s->{$_} // []) } qw/ranges doc_ranges old_ranges/),
            $s->{deleted} ? 1 : 0, (map { $s->{$_} // 0 } qw/added removed changed/), $s->{what},
        );
    }

    return;
}

sub default_file($self, $rev, $revision) {
    my $dir  = $self->{+REPO}->state_dir;
    my $name = $self->default_name($rev, $revision);

    my ($file, $n) = ("$dir/$name.sqlite", 1);
    $file = "$dir/$name-" . ++$n . '.sqlite' while -e $file;
    return $file;
}

# The head's branch or tag name when it has one, else its short id.
sub default_name($self, $rev, $revision) {
    my $short = substr($revision, 0, 12);
    my $name  = $self->{+REPO}->revision_name($rev);

    return $short unless defined($name) && $name =~ m{\A[\w.\-/]+\z};
    return $short if index($revision, $name) == 0;
    return $name =~ s{/}{-}gr;
}

sub resolve_file($self, $file) {
    $file = File::Spec->rel2abs($file);
    my $dir = dirname($file);
    return -d $dir ? abs_path($dir) . '/' . basename($file) : $file;
}

# Review files belong in the VCS's own directories or the worktree.
sub check_location($self, $file) {
    my $repo = $self->{+REPO};
    return if $repo->is_internal_path($file);

    my $root = $repo->root;
    croak "Review file '$file' is not inside the worktree '$root'" unless index($file, "$root/") == 0;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Builder - Build a review file and add iterations to it.

=head1 DESCRIPTION

Turns a range of commits into review data. For each commit, oldest first, it
records the commit's metadata and change id; for each file the commit changed,
its status, kind, sizes and line counts. It splits no file: a text file
starts with no sections (C<split_source> C<none>) until the agent filling the
review names them through the fill sheet (L<Review::Helper::Sheet>), which
calls C<split_sections>. Diffs and file contents are read from the repository
(L<Review::Helper::VCS>) and never stored.

Binary files are those the VCS reports as binary. Images and binary files are
sized in bytes and have no sections; text files are sized in lines. Text is
decoded as UTF-8, with malformed bytes replaced.

Commits on the mainline, the first-parent chain from the head, have no
merge; every other commit records the merge that brought it in. A merge has
no file changes of its own; the commits it brought in hold them.

A B<squashed> review covers C<base..head> as one combined entry instead of
commit by commit: the head's revision, subject and message, the base as its
parent (none when the base is the empty revision, i.e. the whole codebase), no
change id, and the file changes between base and head. It is for reviewing
or learning a codebase as it finally lands. The agent filling the review
splits that entry into topics through the fill sheet: one entry per topic,
each with the same revision and parent and only its topic's files.

B<Paths> (the VCS's path specs) limit a review to matching files, so a large
codebase can be split into several reviews. Without squashing, commits that
change no matching file are left out, as are merges left with no commits.

Each iteration's head is pinned (L<Review::Helper::VCS/pin>), under the
name stored as its C<pin>, once all database writes of the iteration have
committed in one transaction.

A new iteration copies from the previous one:

=over 4

=item *

for a commit with the same change id: its what, why and how, its reading
order, its flags, and per file the what, object system and paradigms, and the
file's sections (the agent's split, with their explanations) when the file
reads the same on both sides of the commit. A flag's lines move with the diff
between the two versions of its file; when the code under it changed, it is
pending for the agent to decide on.

=item *

for a squashed iteration over the same base and paths: each file stays in
the topic that held its path, and files in none go to an entry with no topic
for the agent to place. A topic's entry pairs with the entry of the same
topic (the one with no topic with the one with none) and takes its flags,
and its reading order when it lists the same paths; its what, why and how
too when, besides, every file reads the same; and each file's explanations
and split when it reads the same.

=back

Any other text file starts unsplit again, and the agent explains its new
sections afresh: explanations are not carried by content.

=head1 SYNOPSIS

    use Review::Helper::Builder;

    my $builder = Review::Helper::Builder->new(repo => $repo);
    my $file    = $builder->build(base => 'main', title => 'Add caching');

    my $db     = Review::Helper::DB->open($file);
    my $number = Review::Helper::Builder->new(repo => $repo, db => $db)->iterate();

=head1 ATTRIBUTES

=over 4

=item $repo = $builder->repo()

The repository holding the commits, a L<Review::Helper::VCS>. Required.

=item $db = $builder->db()

The L<Review::Helper::DB> of the review. Required for C<iterate>; C<build>
sets it.

=item $journal = $builder->journal()

The L<Review::Helper::Journal> whose journal entries (notes without a
C<flag>) each new iteration takes. Defaults to the repository's journal.

=back

=head1 PUBLIC METHODS

=over 4

=item $file = $builder->build(base => $rev, %params)

=item $file = $builder->build(squash => 1, %params)

Create a review of C<base..head> and its iteration 1, pin it, register it, and
return the absolute path of the review file. Optional C<head> (default
C<HEAD>), C<squash> (a true value), C<paths> (arrayref of path specs),
C<title>, C<source> (a pull or merge request URL) and C<file>. C<base> is
required unless C<squash> is set; then it defaults to the empty revision.

The default file is F<E<lt>nameE<gt>.sqlite> in the VCS's state directory
(L<Review::Helper::VCS/state_dir>), named after the head's branch or tag, or
its short id, with a number added when taken. A C<file> outside the VCS's own
directories must be inside the worktree. Croaks when the range has no commits, or nothing under the paths.
On failure the new file is removed.

=item $number = $builder->iterate(%params)

Add the next iteration for C<base..head> and return its number. C<base>
defaults to the previous iteration's base, C<head> to C<HEAD>. The squash
mode and paths are the previous iteration's.

=item $paths = $builder->check_paths($paths)

The path specs as a new arrayref, or undef for none. Croaks unless C<$paths>
is undef or an arrayref of non-empty strings.

=item $commits = $builder->collect_range(\%range)

C<collect> or C<collect_squashed> for a hashref of C<base>, C<head>,
C<squashed> and C<paths>.

=item $commits = $builder->collect($base_sha, $head_sha)

=item $commits = $builder->collect($base_sha, $head_sha, \@paths)

The review data of every commit in the range, oldest first, as stored by
C<store>, each with C<merge_revision> naming the merge that brought it in (undef on
the mainline). With paths, only matching files, and only commits with some.
Croaks when the range is empty.

=item $commits = $builder->collect_squashed($base_sha, $head_sha)

=item $commits = $builder->collect_squashed($base_sha, $head_sha, \@paths)

The one combined entry of a squashed review. Croaks when nothing changed.

=item $kept = $builder->drop_untouched(\@commits)

The commits that have file changes, and the merges that kept a commit.

=item $owners = $builder->merge_owners(\%parents, \@revisions_oldest_first)

Hashref of each revision in the range off the mainline to the revision of the
merge that brought it in. C<%parents> maps
each revision of L<Review::Helper::VCS/revisions> to its parents. A merge brings in the commits reachable
from its second and later parents but not from its first; a nested merge's
commits belong to it, not to the outer merge. No merge takes a mainline
commit, so a branch that merged the mainline in does not take its commits.

=item $set = $builder->ancestors(\%parents, @revisions)

Hashref holding C<@revisions> and their ancestors, limited to the commits in
C<%parents> (revision to parents).

=item $commit = $builder->collect_commit($revision)

=item $commit = $builder->collect_commit($revision, $is_merge)

=item $commit = $builder->collect_commit($revision, $is_merge, \@paths)

=item $file = $builder->collect_file($commit_info, $change)

Review data of one commit, or of one of its changes from
L<Review::Helper::VCS/range_changes>. A merge gets no file changes.

=item $file = $builder->submodule_file($change)

The review data of a submodule entry, which has no content here: kind
C<binary>, sizes in bytes left unknown, no sections and zero line counts.

=item $texts = $builder->file_texts($revision, $parent, $change, $binary)

Hashref of C<before_raw> and C<after_raw> (bytes, missing when the side does
not exist), C<before> and C<after> (decoded, unless C<$binary>), and C<hunks>
(the parsed diff).

=item $text = $builder->decode_text($bytes)

UTF-8 decode with malformed bytes replaced; undef stays undef.

=item $size = $builder->size($texts, $side, $bytes)

Size of one side in bytes or lines; undef when the side does not exist.

=item $sections = $builder->split_sections($texts, \@units)

Every section of an agent split of a text change, with its line counts. C<@units> are hashrefs with C<name>, C<package>,
C<ranges>, C<doc_ranges> and C<old_ranges>, sorted and sharing no line; one
with no C<ranges> is a deleted section, holding only C<old_ranges>. The
live units cover every new-side line that is not blank; blank lines join
them as L<Review::Helper::Split> describes.
A section with no changed line is kept, untouched (all its counts 0).

=item $builder->carry_forward($prev_iteration, \%range, $commits)

Copy explanations, reading order, flags (by C<carry_from>) and splits
from the previous iteration (its row) into collected commits, matching
commits by change id, in order when several share one, and a commit with no
change id (an empty diff) by revision. When C<same_squash>
holds for the previous iteration and C<%range>, the one collected squashed
entry is first split by C<topic_entries>, and entries are matched by topic
instead; an entry's reading order is copied only when both list the same
paths, and its
C<what>/C<why>/C<how> only when, besides, every file reads the same in both.
The first entry also lists, in C<carry_also>, the previous entries no entry
pairs with (a topic left with no file), so their flags are carried to it.

=item $entries = $builder->topic_entries(\@prev_entries, $entry)

A collected squashed entry split by the topics of the previous iteration's
entries (stored rows): one entry per topic, in their order, holding the files
whose path was in it, then one with no C<topic> for the files in none. Topics
left with no file are dropped. C<[$entry]> when no previous entry has a
topic.

=item $bool = $builder->same_squash($old, $new)

True when both iterations (stored rows, or a range with C<paths> as an
arrayref) are squashed with the same C<base> and C<paths>.

=item $builder->carry_file($file, $old_file, $old_commit, $commit, $squash, $order)

Copy one file's reading position (unless C<$order> is false) and
explanations from the same file in C<$old_commit>, and its split (sections
and C<split_source>) when it has one and the file reads the same in both
commits, before and after them. Commits are hashrefs with C<revision> and
C<parent>. With C<$squash>, the explanations too are copied only when the
file reads the same after both. C<$squash> and C<$order> are optional,
defaulting to false and true. The contents are compared only when the answer
is needed. Returns whether the file reads the same after both commits; false
when that was not compared.

=item $files = $builder->stored_files($commit_id)

A stored commit's file rows, each with its decoded C<sections>.

=item $builder->store($number, \%range, $commits)

Write an iteration (C<base>, C<head>, C<squashed> and C<paths> from
C<%range>) and its commits in one transaction, closing orphaned split
requests and making flags off the change pending from iteration 2 on, and
taking the journal's entries (C<store_journal>), then pin its head and
remove those entries from the journal once the transaction has committed.
A failed removal only warns: the iteration stands, and the next build or
iteration ignores the entries it already holds.

=item @entries = $builder->journal_entries()

The journal's notes without a C<flag>, skipping with a warning any note
C<entry_error> in L<Review::Helper::Journal> finds fault with.

=item $builder->store_journal($number, $entries)

Store journal notes without a C<flag> as iteration C<$number>'s journal
entries. One the file already holds keeps its iteration.

=item $builder->close_orphaned_requests($number)

Close each open C<split> request whose commit is not in
iteration C<$number>: its status becomes C<done> and
C<(closed: its commit was rewritten)> is appended to its note.

=item $builder->flags_off_change($number)

Make pending, without seen marks, each flag of iteration C<$number> whose
file left the change in that iteration: no entry with its commit's revision
changes its path, while in the previous iteration an entry with that flag's
commit's revision changed the path the flag had there (a squashed change
reverted to the base, say). The agent decides on it even when its lines
read the same. A flag kept on a file already outside the change carries
settled, with its marks.

=item $builder->carry_unpaired_flags($number, \@commits)

In an iteration that is not squashed, copy the flags of each previous
commit no commit in C<\@commits> carries from (rewritten, so its change id
changed, or dropped), pending and without seen marks: onto the last commit of
iteration C<$number> that changes the flag's path, its lines moved by the
diff between the two commits' files where it keeps any, else on the whole
file; with no commit changing the path, or no path, onto the iteration's
last commit, flagging the whole file.

=item $id = $builder->store_commit($number, $position, $commit)

=item $builder->store_file($commit_id, $file)

=item $builder->store_sections($file_id, $sections)

Insert one commit (with carried flags; returns its id), file, or file's
sections.

=item $builder->carry_flags($commit_id, $commit)

=item $builder->carry_flags($commit_id, $commit, $from)

Copy the flags of the stored commit C<$from> (default
C<< $commit->{carry_from} >>) to the new commit C<$commit_id>, with their
color. C<store_commit> calls it for C<carry_from> and for
each id in C<carry_also>. A flag on a file the VCS finds renamed between the
two commits takes the file's new path. A flag whose code is unchanged (a line
flag whose lines the diff between the two versions of its file only moves, a
whole-file flag whose file reads the same, or a flag with no path) keeps its
moved lines and every reviewer's C<flag_seen> mark, with its time. Any other is
C<pending>, with no seen marks, on the span from the first to the last of
its lines the diff kept, or on the whole file when it kept none or the file
exists in only one of the commits. C<flags_off_change> then makes pending a
flag whose file left the change in the new iteration.

=item ($start, $end) = $builder->kept_span($hunks, $start, $end)

The first and last new line numbers of the lines C<$start> to C<$end> that
C<$hunks> keep; empty when they keep none.

=item $path = $builder->renamed_to(\%old_commit, \%new_commit, $path)

The path C<$path> in the old commit has in the new one when the VCS finds
the file renamed between them; undef when the new commit still
has C<$path>, the old one does not, or no rename is found.

=item $builder->flags_to_paths($number)

In squashed iteration C<$number>, move each flag with a path to the entry
holding that path.

=item $hunks = $builder->line_moves(\%old_commit, \%new_commit, $path)

=item $hunks = $builder->line_moves(\%old_commit, \%new_commit, $path, $to_path)

The parsed diff hunks from C<$path> in one commit to C<$to_path> (default
C<$path>; the file's new path when it was renamed) in the other (each a
hashref with C<revision> and C<parent>): empty when the file reads the same,
undef when it exists in only one. A file deleted in both is compared
before them.

=item $file = $builder->default_file($rev, $revision)

=item $name = $builder->default_name($rev, $revision)

The default review file for a head, and the name it is based on.

=item $path = $builder->resolve_file($file)

Absolute path, with symlinks in an existing directory resolved.

=item $builder->check_location($file)

Croak when C<$file> is outside both the VCS's own directories and the
worktree.

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
