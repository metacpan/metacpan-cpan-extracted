package Review::Helper::Sheet;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Cpanel::JSON::XS();
use Digest::SHA qw/sha256_hex/;

use Review::Helper::Builder;
use Review::Helper::Feedback;
use Review::Helper::Journal;
use Review::Helper::Split;
use Review::Helper::Util qw/json_encode now/;

use Object::HashBase qw{
    <repo
    <db
    <journal
};

use constant FORMAT         => 'review-sheet';
use constant FORMAT_VERSION => 1;

# Character-string JSON for TEXT columns; the database handle does the UTF-8.
my $JSON = Cpanel::JSON::XS->new->canonical;

my %TEXT_FIELDS = (
    summary => [qw/what why how/],
    commit  => [qw/what why how/],
    file    => [qw/what object_system paradigms/],
    section => [qw/what/],
    debate  => [qw/case_for case_against/],
);

# Validation order: topics first, so items they would change can be refused;
# then splits and note placements, so sections and guide steps can see what
# they create; the guide last.
my %CHECK_ORDER = (topics => -1, split => 0, note => 0, guide => 2);

# Items naming a commit entry, which a topics fill in the same sheet would
# move or remove.
my %NAMES_ENTRY = map { ($_ => 1) } qw/commit order note guide/;

my %TARGET_KEYS = (
    summary => [],
    commit  => [qw/commit topic/],
    file    => [qw/commit path/],
    section => [qw/commit path section/],
    flag    => [qw/flag/],
    diff    => [qw/commit topic path section/],
    view    => [qw/commit path lines/],
);

sub init($self) {
    croak "'repo' is a required attribute" unless $self->{+REPO};
    croak "'db' is a required attribute"   unless $self->{+DB};
    $self->{+JOURNAL} //= Review::Helper::Journal->new(repo => $self->{+REPO});
}

# With 'all', done items are listed too, so text already written can be
# replaced; their revs guard against overwriting a concurrent change.
sub sheet($self, %params) {
    my $ctx = $self->context;

    my @items;
    for my $item (grep { $params{all} || !$_->{done} } @{$self->items($ctx)}) {
        push @items => {
            (map { ($_ => $item->{$_}) } qw/id type rev about fields/),
            ($item->{optional} ? (optional => Cpanel::JSON::XS::true()) : ()),
        };
    }

    return {
        format         => FORMAT,
        format_version => FORMAT_VERSION,
        review         => $ctx->{review}->{id},
        iteration      => $ctx->{iteration}->{number},
        items          => \@items,
    };
}

sub fill($self, $data) {
    my $ctx = $self->context;
    my ($plan, $errors) = $self->validate($ctx, $data);
    die join("\n" => 'The sheet was rejected:', @$errors) . "\n" if @$errors;

    $self->{+DB}->txn(sub {
        for my $entry (@{$plan->{writes}}) {
            my ($item, $fields) = @$entry;
            my $method = "write_$item->{type}";
            $self->$method($ctx, $item, $fields, $plan);
        }
    });

    # Notes placed now, and any an earlier fill placed but failed to remove.
    my @placed = (keys(%{$plan->{notes}}), map { $_->{id} } grep { $ctx->{flags}->{$_->{id}} } @{$ctx->{notes}});
    $self->{+JOURNAL}->remove(@placed) if @placed;

    my $remaining = grep { !$_->{done} && !$_->{optional} } @{$self->items($self->context)};
    return {filled => scalar(@{$plan->{writes}}), remaining => $remaining};
}

# {{{ Loading the iteration

sub context($self) {
    my $dbh       = $self->{+DB}->dbh;
    my $iteration = $self->{+DB}->latest_iteration or croak "The review has no iteration";

    my %ctx = (
        review    => $self->{+DB}->review,
        iteration => $iteration,
        commits   => $dbh->selectall_arrayref('SELECT * FROM commit_entry WHERE iteration = ? ORDER BY position', {Slice => {}}, $iteration->{number}),
        feedback  => $dbh->selectall_arrayref(q{SELECT * FROM feedback WHERE status = 'open' ORDER BY id}, {Slice => {}}),
        requests  => $dbh->selectall_arrayref('SELECT * FROM request ORDER BY id',                         {Slice => {}}),
        steps     => $dbh->selectall_arrayref('SELECT * FROM guide_step WHERE iteration = ? ORDER BY position', {Slice => {}}, $iteration->{number}),
        notes     => [grep { defined $_->{flag} } @{$self->{+JOURNAL}->notes}],
    );

    my $files    = $dbh->prepare('SELECT * FROM file_change WHERE commit_id = ? ORDER BY path');
    my $sections = $dbh->prepare('SELECT * FROM section WHERE file_id = ? ORDER BY position');
    for my $commit (@{$ctx{commits}}) {
        $files->execute($commit->{id});
        $commit->{files}   = $files->fetchall_arrayref({});
        $commit->{by_path} = {map { ($_->{path} => $_) } @{$commit->{files}}};
        for my $file (@{$commit->{files}}) {
            $sections->execute($file->{id});
            $file->{sections} = $sections->fetchall_arrayref({});
            for my $section (@{$file->{sections}}) {
                $section->{$_} = $JSON->decode($section->{$_}) for qw/ranges doc_ranges old_ranges/;
            }
        }
    }

    my $commit_ids = join(', ' => map { $_->{id} } @{$ctx{commits}}) || 'NULL';
    $ctx{flags}     = {map { ($_->[0] => $_->[1]) } @{$dbh->selectall_arrayref("SELECT note_id, commit_id FROM flag WHERE commit_id IN ($commit_ids)")}};
    $ctx{flag_rows} = $dbh->selectall_arrayref("SELECT flag.*, commit_entry.revision, commit_entry.topic AS topic FROM flag JOIN commit_entry ON commit_entry.id = flag.commit_id WHERE flag.commit_id IN ($commit_ids) ORDER BY flag.id", {Slice => {}});

    return \%ctx;
}

# }}} Loading the iteration

# {{{ Items

sub rev($self, $item) { sha256_hex(json_encode([$item->{about}, $item->{fields}])) }

sub items($self, $ctx) {
    my @items    = ($self->summary_item($ctx));
    my $squashed = $ctx->{iteration}->{squashed};
    push @items => $self->topics_item($ctx) if $squashed;

    for my $commit (@{$ctx->{commits}}) {
        push @items => $self->text_item($ctx, commit => "commit:$commit->{id}", $commit, $self->commit_about($ctx, $commit));
        if (@{$commit->{files}}) {
            my $order = $self->order_item($commit);
            $order->{optional} = 1 if $squashed;
            push @items => $order;
        }

        for my $file (@{$commit->{files}}) {
            push @items => $self->text_item($ctx, file => "file:$file->{id}", $file, $self->file_about($commit, $file));
            push @items => $self->split_item($ctx, $commit, $file);
            for my $section (grep { $self->{+DB}->section_touched($_) } @{$file->{sections}}) {
                my $item = $self->text_item($ctx, section => "section:$section->{id}", $section, $self->section_about($commit, $file, $section));
                $item->{optional} = 1 if $squashed;
                push @items => $item;
            }
        }
    }

    push @items => map { $self->note_item($_) } grep { !$ctx->{flags}->{$_->{id}} } @{$ctx->{notes}};
    push @items => map { $self->flag_item($ctx, $_) } @{$ctx->{flag_rows}};
    push @items => map { $self->feedback_item($ctx, $_) } @{$ctx->{feedback}};
    push @items => map { $self->debate_item($_) } grep { $_->{kind} eq 'debate' } @{$ctx->{requests}};
    push @items => $self->guide_item($ctx);

    $_->{rev} = $self->rev($_) for @items;
    return \@items;
}

# From iteration 2 the summary also takes a note on what the iteration
# changed. It is optional: the summary is done once what, why and how are.
sub summary_item($self, $ctx) {
    my $iteration = $ctx->{iteration};
    my %about     = (
        (map { ($_ => $iteration->{$_}) } qw/base head/),
        title    => $ctx->{review}->{title},
        squashed => $iteration->{squashed}       ? Cpanel::JSON::XS::true()           : Cpanel::JSON::XS::false(),
        paths    => defined($iteration->{paths}) ? $JSON->decode($iteration->{paths}) : undef,
    );

    my $item = $self->text_item($ctx, summary => "summary:$iteration->{number}", $iteration, \%about);
    $item->{fields}->{note} = $iteration->{note} if $iteration->{number} > 1;
    return $item;
}

# A squashed iteration's files grouped into named topics, each an entry of
# its own. Done once every file is in a topic; until then the files in none
# share one entry with no topic (all of them, before the first fill).
sub topics_item($self, $ctx) {
    my $paths  = sub ($entry) { [sort map { $_->{path} } @{$entry->{files}}] };
    my @named  = grep { defined $_->{topic} } @{$ctx->{commits}};
    my ($none) = grep { !defined $_->{topic} } @{$ctx->{commits}};

    return {
        id    => "topics:$ctx->{iteration}->{number}",
        type  => 'topics',
        about => {
            paths      => [sort map { $_->{path} } map { @{$_->{files}} } @{$ctx->{commits}}],
            unassigned => $none ? $paths->($none) : [],
        },
        fields => {topics => @named ? [map { {name => $_->{topic}, paths => $paths->($_)} } @named] : undef},
        done   => $none ? 0 : 1,
    };
}

sub text_item($self, $ctx, $type, $id, $row, $about) {
    my $names  = $TEXT_FIELDS{$type};
    my %fields = map                                                                    { ($_ => $row->{$_}) } @$names;
    my $done   = $type eq 'file' || $type eq 'section' ? defined($fields{what}) : !grep { !defined } values %fields;
    return {id => $id, type => $type, about => $about, fields => \%fields, names => $names, done => $done, row => $row};
}

sub order_item($self, $commit) {
    my @files = @{$commit->{files}};
    my $order = $commit->{order_set} ? [map { $_->{path} } sort { ($a->{read_position} // 0) <=> ($b->{read_position} // 0) } @files] : undef;

    return {
        id     => "order:$commit->{id}",
        type   => 'order',
        about  => {commit => $commit->{revision}, paths => [map { $_->{path} } @files]},
        fields => {paths  => $order},
        done   => $commit->{order_set} ? 1 : 0,
        row    => $commit,
    };
}

sub commit_about($self, $ctx, $commit) {
    my ($merge) = grep { $_->{id} == ($commit->{merge_id} // 0) } @{$ctx->{commits}};
    return {revision => $commit->{revision}, subject => $commit->{subject}, position => $commit->{position}, merge => $merge ? $merge->{revision} : undef, topic => $commit->{topic}};
}

sub file_about($self, $commit, $file) {
    return {
        commit => $commit->{revision},
        map { ($_ => $file->{$_}) } qw/path old_path status kind size_unit size_before size_after added removed changed split_source/,
    };
}

sub section_about($self, $commit, $file, $section) {
    return {
        commit => $commit->{revision},
        path   => $file->{path},
        map { ($_ => $section->{$_}) } qw/name package ranges doc_ranges old_ranges deleted added removed changed/,
    };
}

# Every text file its commit adds, or changes a line of without deleting it,
# has one, even when empty: a rename or mode change alone has nothing to
# split. Required while the file has no split yet (optional in a squashed
# iteration) and while a split request on it is open.
sub split_item($self, $ctx, $commit, $file) {
    return () unless $file->{size_unit} eq 'lines' && $file->{status} ne 'D';
    return () unless $file->{status} eq 'A' || $file->{added} || $file->{removed} || $file->{changed};
    my ($request) = grep { $_->{status} eq 'open' && $self->is_split_request($_, $commit, $file) } @{$ctx->{requests}};
    my $pending = $file->{split_source} eq 'none';

    return {
        id    => "split:$file->{id}",
        type  => 'split',
        about => {
            commit      => $commit->{revision},
            path        => $file->{path},
            old_path    => $file->{old_path},
            status      => $file->{status},
            kind        => $file->{kind},
            size_before => $file->{size_before},
            size_after  => $file->{size_after},
            request     => $request ? {id => $request->{id}, note => $request->{note}} : undef,
            sections    => [map { $self->split_entry($_) } @{$file->{sections}}],
            previous    => $pending ? $self->previous_split($ctx, $commit, $file) : undef,
        },
        fields   => {sections => undef},
        optional => !$request && $ctx->{iteration}->{squashed} ? 1 : 0,
        done     => !$request && !$pending,
        row      => $file,
        request  => $request,
        commit   => $commit,
    };
}

# A stored unit as the split field gives it.
sub split_entry($self, $section) {
    return {
        name    => $section->{name},
        package => $section->{package},
        ($section->{deleted}       ? ()                                    : (lines => $section->{ranges}, doc_lines => $section->{doc_ranges})),
        (@{$section->{old_ranges}} ? (old_lines => $section->{old_ranges}) : ()),
    };
}

# Both sides of a change, decoded, and its diff; read once per context.
sub file_texts($self, $ctx, $commit, $file) {
    my $builder = Review::Helper::Builder->new(repo => $self->{+REPO}, db => $self->{+DB});
    return $ctx->{texts}->{$file->{id}} //= $builder->file_texts($commit->{revision}, $commit->{parent}, $file, 0);
}

# The newest split an earlier iteration stored for this file (its path, or
# its old path when renamed), preferring the commit with the same change id,
# as stored: each live section's lines are at that commit, not moved.
sub previous_split($self, $ctx, $commit, $file) {
    my $dbh   = $self->{+DB}->dbh;
    my @paths = ($file->{path}, $file->{old_path} // $file->{path});
    my $old   = $dbh->selectrow_hashref(<<'    EOT', undef, @paths, $ctx->{iteration}->{number}, $commit->{change_id}) or return undef;
        SELECT f.id, f.path, c.revision, c.iteration FROM file_change f JOIN commit_entry c ON c.id = f.commit_id
         WHERE f.path IN (?, ?) AND c.iteration < ? AND f.split_source != 'none'
         ORDER BY c.iteration DESC, c.change_id IS ? DESC, c.position DESC
         LIMIT 1
    EOT

    my $rows     = $dbh->selectall_arrayref(q{SELECT name, package, ranges, doc_ranges FROM section WHERE file_id = ? AND deleted = 0 ORDER BY position}, {Slice => {}}, $old->{id});
    my @sections = map { {name => $_->{name}, package => $_->{package}, lines => $JSON->decode($_->{ranges}), doc_lines => $JSON->decode($_->{doc_ranges})} } @$rows;

    return {commit => $old->{revision}, iteration => $old->{iteration}, path => $old->{path}, sections => \@sections};
}

sub is_split_request($self, $request, $commit, $file) {
    return 0 unless $request->{kind} eq 'split';
    return 0 unless $request->{target} eq 'file';
    return ($request->{revision} // '') eq $commit->{revision} && ($request->{path} // '') eq $file->{path};
}

sub note_item($self, $note) {
    my %about = map { ($_ => $note->{$_}) } qw/flag kind path unit snippet sentence detail/;
    return {id => "note:$note->{id}", type => 'note', about => \%about, fields => {commit => undef, topic => undef, path => undef, lines => undef}, optional => 1, done => 0, row => $note};
}

# A flag's decision is needed only while it is pending: made pending by the
# carry-forward. Its fields are actions, so they always start null.
sub flag_item($self, $ctx, $flag) {
    my $lines = sub ($row) {
        defined($row->{line_start}) ? [map { $_ + 0 } @$row{qw/line_start line_end/}] : undef;
    };
    my ($previous, $rewritten);
    if ($flag->{pending}) {
        my $old = $self->{+DB}->flag_by_note($ctx->{iteration}->{number} - 1, $flag->{note_id});
        $previous = $old ? {commit => $old->{revision}, path => $old->{path}, lines => $lines->($old)} : undef;

        # Commits of a history review pair by change id, or by revision when
        # they have none; a flag on a commit that does not pair with its
        # previous one came off a rewritten or dropped commit.
        if ($old && !$ctx->{iteration}->{squashed}) {
            my $dbh = $self->{+DB}->dbh;
            my ($was, $is) = map { scalar $dbh->selectrow_array('SELECT change_id FROM commit_entry WHERE id = ?', undef, $_) } $old->{commit_id}, $flag->{commit_id};
            $rewritten = defined($was) ? !(defined($is) && $was eq $is) : defined($is) || $old->{revision} ne $flag->{revision};
        }
    }
    my $bool = sub ($val) { $val ? Cpanel::JSON::XS::true() : Cpanel::JSON::XS::false() };
    my $path = $flag->{path};
    my $left = defined($path) && !grep { $_->{revision} eq $flag->{revision} && $_->{by_path}->{$path} } @{$ctx->{commits}};

    return {
        id    => "flag:$flag->{id}",
        type  => 'flag',
        about => {
            note        => $flag->{note_id},
            commit      => $flag->{revision},
            lines       => $lines->($flag),
            pending     => $bool->($flag->{pending}),
            previous    => $previous,
            left_change => $bool->($left),
            rewritten   => $bool->($rewritten),
            map { ($_ => $flag->{$_}) } qw/topic path color color_reason kind sentence detail/,
        },
        fields => {decision => undef, color => undef, reason => undef},
        done   => $flag->{pending} ? 0 : 1,
        row    => $flag,
    };
}

sub feedback_item($self, $ctx, $feedback) {
    return {
        id     => "feedback:$feedback->{id}",
        type   => 'feedback',
        about  => {%{Review::Helper::Feedback->anchor($feedback)}, flag => ($ctx->{flag_of} //= Review::Helper::Feedback->new(db => $self->{+DB}))->flag_of($feedback), map { ($_ => $feedback->{$_}) } qw/iteration line side body/},
        fields => {status => undef, response => $feedback->{response}},
        done   => 0,
        row    => $feedback,
    };
}

sub debate_item($self, $request) {
    return {
        id     => "request:$request->{id}",
        type   => 'debate',
        about  => {%{Review::Helper::Feedback->anchor($request)}, map { ($_ => $request->{$_}) } qw/iteration note/},
        fields => {case_for => $request->{case_for}, case_against => $request->{case_against}},
        done   => $request->{status} eq 'done' ? 1 : 0,
        row    => $request,
    };
}

# A guide is asked for again when a later re-split left one of its steps
# naming a section the page no longer shows, or a retire one naming a flag
# the iteration no longer has.
sub guide_item($self, $ctx) {
    my $steps = $ctx->{steps};
    my $value = @$steps ? [map { {target => $JSON->decode($_->{target}), highlight => $JSON->decode($_->{highlight}), commentary => $_->{commentary}} } @$steps] : undef;
    my $stale = grep { $self->is_stale_step($ctx, $_->{target}) } @{$value // []};

    return {
        id    => "guide:$ctx->{iteration}->{number}",
        type  => 'guide',
        about => {
            commits => [
                do {
                    my %seen;
                    grep { !$seen{$_}++ } map { $_->{revision} } @{$ctx->{commits}};
                }
            ]
        },
        fields => {steps => $value},
        done   => @$steps && !$stale ? 1 : 0,
    };
}

# A step is stale too when its commit no longer names one entry or its path
# is no longer in that entry: a topics fill since moved or renamed it.
sub is_stale_step($self, $ctx, $target) {
    return $ctx->{flags}->{$target->{flag}} ? 0 : 1 if $target->{type} eq 'flag';
    return 0 unless defined $target->{commit};
    my ($commit, $error) = $self->find_commit($ctx, map { $target->{$_} } qw/commit topic path/);
    return 1 if $error;
    return 0 if !defined($target->{path}) || $target->{type} eq 'view';

    my $file = $self->find_file($commit, $target->{path}) or return 1;
    return 0 unless defined $target->{section};
    return $self->check_section_target({}, $file, $target->{section}) ? 1 : 0;
}

# }}} Items

# {{{ Validation

sub is_text($self, $val)                              { defined($val) && !ref($val) && length($val) ? 1 : 0 }
sub check_summary($self, $ctx, $item, $fields, $plan) { $self->check_text($item, $fields, sort keys %{$item->{fields}}) }
sub check_commit($self, $ctx, $item, $fields, $plan)  { $self->check_text($item, $fields, @{$TEXT_FIELDS{commit}}) }
sub check_debate($self, $ctx, $item, $fields, $plan)  { $self->check_text($item, $fields, @{$TEXT_FIELDS{debate}}) }
sub find_file($self, $commit, $path)                  { $commit->{by_path}->{$path} }
sub trim($self, $val)                                 { defined($val) && !ref($val) ? $val =~ s/\A\s+|\s+\z//gr : $val }
sub is_line($self, $val)                              { defined($val) && !ref($val) && $val =~ m/\A[1-9][0-9]*\z/ ? 1 : 0 }
sub sorted($self, $ranges)                            { [sort { $a->[0] <=> $b->[0] } map { [$_->[0] + 0, $_->[1] + 0] } @$ranges] }

sub validate($self, $ctx, $data) {
    my @errors;
    return (undef, ['The sheet must be a JSON object']) unless ref($data) eq 'HASH';
    push @errors => "'format' must be '" . FORMAT . "'"                                      unless ($data->{format}         // '') eq FORMAT;
    push @errors => "'format_version' must be " . FORMAT_VERSION                             unless ($data->{format_version} // '') eq FORMAT_VERSION;
    push @errors => "The sheet is for another review"                                        unless ($data->{review}         // '') eq $ctx->{review}->{id};
    push @errors => "The sheet is not for the latest iteration, $ctx->{iteration}->{number}" unless ($data->{iteration}      // '') eq $ctx->{iteration}->{number};
    push @errors => "'items' must be an array"                                               unless ref($data->{items}) eq 'ARRAY';
    return (undef, \@errors) if @errors;

    my %items = map { ($_->{id} => $_) } @{$self->items($ctx)};
    my %plan  = (writes => [], splits => {}, notes => {});
    my %seen;

    my @todo;
    for my $n (0 .. $#{$data->{items}}) {
        my $in = $data->{items}->[$n];
        my ($item, $fields, @errs) = $self->check_item($in, \%items, $n);
        push @errors => @errs;
        next unless $item;
        push @errors => "$item->{id}: listed more than once" if $seen{$item->{id}}++;
        push @todo   => [$item, $fields];
    }

    for my $entry (sort { ($CHECK_ORDER{$a->[0]->{type}} // 1) <=> ($CHECK_ORDER{$b->[0]->{type}} // 1) } @todo) {
        my ($item, $fields) = @$entry;
        my $method = "check_$item->{type}";
        my @errs   = $plan{topics} && $NAMES_ENTRY{$item->{type}} ? ('the topics change in this sheet; fill this item from the next sheet') : $self->$method($ctx, $item, $fields, \%plan);
        push @errors => map { "$item->{id}: $_" } @errs;

        # A file item is done once it has 'what': a valid one without it, given
        # or stored, is skipped, so it stays to do and does not count as filled.
        next if !@errs && $item->{type} eq 'file' && !defined($fields->{what}) && !defined($item->{row}->{what});
        push @{$plan{writes}} => $entry unless @errs;
    }

    return (\%plan, \@errors);
}

# The item an entry fills and its non-null fields, or nothing when it is
# skipped (no field, or a topics item sent back as it came), plus any errors.
sub check_item($self, $in, $items, $n) {
    return (undef, undef, "Item " . ($n + 1) . " must be an object with an 'id'") unless ref($in) eq 'HASH' && defined($in->{id}) && !ref($in->{id});
    my $id = $in->{id};
    return (undef, undef, "$id: 'fields' must be an object") unless ref($in->{fields}) eq 'HASH';

    my %fields = map { ($_ => $in->{fields}->{$_}) } grep { defined $in->{fields}->{$_} } keys %{$in->{fields}};
    return () unless %fields;

    my $item = $items->{$id} or return (undef, undef, "$id: unknown item");
    my @errors;
    push @errors => "$id: type must be '$item->{type}'"    unless ($in->{type} // '') eq $item->{type};
    push @errors => "$id: stale revision; get a new sheet" unless ($in->{rev}  // '') eq $item->{rev};
    my %known = map { ($_ => 1) } keys %{$item->{fields}};
    push @errors => map { "$id: unknown field '$_'" } sort grep { !$known{$_} } keys %fields;
    return (undef, undef, @errors) if @errors;
    return ()                      if $item->{type} eq 'topics' && $self->same_topics($fields{topics}, $item->{fields}->{topics});

    return ($item, \%fields);
}

# Whether given topics are the stored ones: the same names, in the same
# order, each with the same paths in any order.
sub same_topics($self, $given, $stored) {
    return 0 unless $stored && ref($given) eq 'ARRAY' && @$given == @$stored;
    for my $n (0 .. $#$stored) {
        my $topic = $given->[$n];
        return 0 unless ref($topic) eq 'HASH' && keys(%$topic) == 2 && ref($topic->{paths}) eq 'ARRAY';
        return 0 unless $JSON->encode([$topic->{name}, sort @{$topic->{paths}}]) eq $JSON->encode([$stored->[$n]->{name}, sort @{$stored->[$n]->{paths}}]);
    }
    return 1;
}

sub check_text($self, $item, $fields, @names) {
    return map { "'$_' must be a non-empty string or null" } grep { exists($fields->{$_}) && !$self->is_text($fields->{$_}) } @names;
}

sub check_file($self, $ctx, $item, $fields, $plan) { $self->check_text($item, $fields, @{$TEXT_FIELDS{file}}) }

sub check_section($self, $ctx, $item, $fields, $plan) {
    my @errors = $self->check_text($item, $fields, 'what');
    push @errors => "its file is re-split in this sheet; explain its sections from the next sheet" if ($plan->{splits}->{$item->{row}->{file_id}} // {})->{sections};
    return @errors;
}

sub check_order($self, $ctx, $item, $fields, $plan) {
    my $paths = $fields->{paths};
    return "'paths' must be an array of paths" unless ref($paths) eq 'ARRAY' && !grep { !$self->is_text($_) } @$paths;

    my $want = join "\0" => sort @{$item->{about}->{paths}};
    my $got  = join "\0" => sort @$paths;
    return "'paths' must list every path of the commit exactly once" unless $want eq $got;
    return;
}

# Every path of the iteration in exactly one topic, each topic named once.
sub check_topics($self, $ctx, $item, $fields, $plan) {
    my $topics = $fields->{topics};
    return "'topics' must be a non-empty array of { name, paths }" unless ref($topics) eq 'ARRAY' && @$topics;

    my %want = map { ($_ => 1) } @{$item->{about}->{paths}};
    my (@errors, %names, %in);
    for my $n (1 .. @$topics) {
        my $topic = $topics->[$n - 1];
        unless (ref($topic) eq 'HASH') { push @errors => "topic $n: must be an object with 'name' and 'paths'"; next }
        push @errors => map { "topic $n: unknown field '$_'" } sort grep { !m/^(?:name|paths)$/ } keys %$topic;

        my $name = $topic->{name} = $self->trim($topic->{name});
        if    (!$self->is_text($name) || $name =~ m/[[:cntrl:]]/) { push @errors => "topic $n: 'name' must be a non-empty string with no control character" }
        elsif ($names{$name}++)                                   { push @errors => "topic $n: name '$name' repeats" }

        my $paths = $topic->{paths};
        unless (ref($paths) eq 'ARRAY' && @$paths && !grep { !$self->is_text($_) } @$paths) {
            push @errors => "topic $n: 'paths' must be a non-empty array of paths";
            next;
        }
        for my $path (@$paths) {
            if    (!$want{$path}) { push @errors => "topic $n: '$path' is not a path of this iteration" }
            elsif ($in{$path})    { push @errors => "topic $n: '$path' is already in topic $in{$path}" }
            else                  { $in{$path} = $n }
        }
    }

    my @missing = grep { !$in{$_} } @{$item->{about}->{paths}};
    push @errors => 'in no topic: ' . join(', ' => map { "'$_'" } @missing) if @missing;
    return @errors if @errors;

    $plan->{topics} = $topics;
    return;
}

sub check_feedback($self, $ctx, $item, $fields, $plan) {
    my @errors = $self->check_text($item, $fields, 'response');
    if (exists $fields->{status}) {
        my $status = $fields->{status};
        push @errors => "'status' must be 'addressed' or 'declined'" unless !ref($status) && ($status eq 'addressed' || $status eq 'declined');
        push @errors => "'status' needs a 'response'"                unless defined($fields->{response} // $item->{row}->{response});
    }
    return @errors;
}

sub check_note($self, $ctx, $item, $fields, $plan) {
    return "'commit' is required to place a note" unless exists $fields->{commit};
    my ($commit, $error) = $self->find_commit($ctx, $fields->{commit}, $fields->{topic}, $fields->{path});
    return "'commit': $error" if $error;

    my ($path, $lines) = @$fields{qw/path lines/};
    return "'lines' needs a 'path'" if defined($lines) && !defined($path);

    my $file;
    if (defined $path) {
        return "'path' must be a string" if ref $path;
        my $in = defined($commit->{topic}) ? "topic '$commit->{topic}' of commit $commit->{revision}" : "commit $commit->{revision}";
        $file = $self->find_file($commit, $path) or return "'path': '$path' is not changed in $in";
    }

    if (defined $lines) {
        my $side  = $file->{status} eq 'D' ? 'old' : 'new';
        my $error = $self->check_lines($file, $side, $lines);
        return "'lines': $error" if $error;
    }

    $plan->{notes}->{$item->{row}->{id}} = $commit;
    return;
}

# A decision on a flag: keep, recolor (a new color and the reason) or
# retire (nothing else).
sub check_flag($self, $ctx, $item, $fields, $plan) {
    my $decision = $fields->{decision};
    return "'decision' must be 'keep', 'recolor' or 'retire'" unless $self->is_text($decision) && $decision =~ m/\A(?:keep|recolor|retire)\z/;

    # A keep or retire ignores 'color' and 'reason'.
    my @errors;
    if ($decision eq 'recolor') {
        push @errors => "'color' must be 'yellow' or 'red'"                          unless $self->is_text($fields->{color}) && $fields->{color} =~ m/\A(?:yellow|red)\z/;
        push @errors => "'reason' must be a non-empty string: why the color changed" unless $self->is_text($fields->{reason});
        push @errors => "'color' is the flag's color already; use 'keep'" if !@errors && $fields->{color} eq $item->{row}->{color};
    }
    return @errors if @errors;

    $plan->{retired}->{$item->{row}->{note_id}} = 1 if $decision eq 'retire';
    return;
}

# The entry a full revision id names. In a squashed iteration
# split into topics every topic's entry has the head's revision: the topic picks
# one, else the one holding the path, else, for a path in none (a view of a
# file the iteration did not change), the first; with neither, it is an error.
sub find_commit($self, $ctx, $revision, $topic = undef, $path = undef) {
    return (undef, "must be a commit's revision id") unless $self->is_text($revision);
    my @found = grep { $_->{revision} eq $revision } @{$ctx->{commits}};
    return (undef, "'$revision' is not a commit of this iteration; give its full revision id") unless @found;

    if (defined $topic) {
        return (undef, "'topic' must be a topic name") unless $self->is_text($topic);
        my ($entry) = grep { ($_->{topic} // "\0") eq $topic } @found;
        return $entry ? ($entry, undef) : (undef, "commit $found[0]->{revision} has no topic '$topic'");
    }
    return ($found[0], undef) if @found == 1;

    return (undef, "commit $found[0]->{revision} is split into topics; give 'topic'") unless $self->is_text($path);
    my ($held) = grep { $_->{by_path}->{$path} } @found;
    return ($held // $found[0], undef);
}

# An error message, or nothing when the range is [start, end].
sub check_range($self, $lines) {
    return 'must be [start, end]' unless ref($lines) eq 'ARRAY' && @$lines == 2 && !grep { !$self->is_line($_) } @$lines;
    return 'start is after end' if $lines->[0] > $lines->[1];
    return;
}

# An error message, or nothing when the range fits the file side.
sub check_lines($self, $file, $side, $lines) {
    my $error = $self->check_range($lines);
    return $error if $error;
    return "'$file->{path}' has no lines" unless $file->{size_unit} eq 'lines';

    my $size = $side eq 'old' ? $file->{size_before} : $file->{size_after};
    return "'$file->{path}' has no $side side" unless defined $size;
    return "beyond the end of '$file->{path}' ($size lines)" if $lines->[1] > $size;
    return;
}

sub check_split($self, $ctx, $item, $fields, $plan) {
    my $file    = $item->{row};
    my $entries = $fields->{sections};
    return "'sections' must be an array" unless ref($entries) eq 'ARRAY';

    my $texts = $self->file_texts($ctx, $item->{commit}, $file);
    my $lines = {map { ($_ => Review::Helper::Split->lines($texts->{$_} // '')) } qw/before after/};

    my (@errors, %claimed, %names);
    for my $n (0 .. $#$entries) {
        my @errs = $self->check_unit($file, $lines, $entries->[$n], \%claimed, $n + 1);
        push @errs   => $self->check_name($entries->[$n], \%names) unless @errs;
        push @errors => map { 'section ' . ($n + 1) . ": $_" } @errs;
    }
    push @errors => $self->check_coverage($lines->{after}, $claimed{new}) if @$entries && !@errors;
    return @errors if @errors;

    $plan->{splits}->{$file->{id}} = {source => 'agent', sections => $self->resplit($ctx, $item->{commit}, $file, $texts, $entries)};
    return;
}

# Every line with text after the commit is in a section; blank lines may be
# left out, and join the section before them.
sub check_coverage($self, $lines, $claimed) {
    my @free = grep { !defined($claimed->[$_]) && $lines->[$_ - 1] =~ m/\S/ } 1 .. scalar @$lines;
    return unless @free;
    my $ranges = join ', ' => map { $_->[0] == $_->[1] ? $_->[0] : "$_->[0]-$_->[1]" } @{Review::Helper::Split->to_ranges(@free)};
    return "lines $ranges are in no section; cover every line of the file, or give [] to leave it whole";
}

my %UNIT_FIELDS = map { ($_ => 1) } qw/name package lines first_line doc_lines old_lines old_first_line/;

# A section of a split: a name, ranges inside the file that no other section
# holds, and the text of its first line (old side too) to catch an offset.
# Its ranges are claimed even when its name is bad, so a later section that
# overlaps it is caught in the same fill.
sub check_unit($self, $file, $lines, $unit, $claimed, $n) {
    return 'must be an object' unless ref($unit) eq 'HASH';

    my (@errors, @shape);
    $unit->{$_} = $self->trim($unit->{$_}) for grep { exists $unit->{$_} } qw/name package/;
    push @errors => "'name' must be a non-empty string" unless $self->is_text($unit->{name});
    push @errors => "'package' must be a non-empty string or null" if defined($unit->{package}) && !$self->is_text($unit->{package});
    push @errors => "unknown field '$_'" for sort grep { !$UNIT_FIELDS{$_} } keys %$unit;
    for my $key (qw/lines doc_lines old_lines/) {
        my $ranges = $unit->{$key} // next;
        push @shape => "'$key' must be an array of [start, end] ranges" unless ref($ranges) eq 'ARRAY' && !grep { ref($_) ne 'ARRAY' } @$ranges;
    }
    return (@errors, @shape) if @shape;

    my ($code, $docs, $old) = map { $unit->{$_} // [] } qw/lines doc_lines old_lines/;
    push @shape => "'lines' or 'old_lines' must hold a range" unless @$code || @$old;
    push @shape => "'doc_lines' needs 'lines'"          if @$docs                           && !@$code;
    push @shape => "'first_line' needs 'lines'"         if defined($unit->{first_line})     && !@$code;
    push @shape => "'old_first_line' needs 'old_lines'" if defined($unit->{old_first_line}) && !@$old;
    return (@errors, @shape) if @shape;

    push @errors => $self->check_ranges($file, 'new', [@$code, @$docs], $claimed, $n);
    push @errors => $self->check_ranges($file, 'old', $old,             $claimed, $n);
    return @errors if @errors;

    push @errors => $self->check_first_line($unit, 'first_line',     $code, $lines->{after})  if @$code;
    push @errors => $self->check_first_line($unit, 'old_first_line', $old,  $lines->{before}) if @$old;
    return @errors;
}

# Each line remembers the section that claimed it, to name it in an overlap.
sub check_ranges($self, $file, $side, $ranges, $claimed, $n) {
    my @errors;
    for my $range (@$ranges) {
        my $error = $self->check_lines($file, $side, $range);
        unless ($error) {
            my ($other) = grep { defined } map { $claimed->{$side}->[$_] } $range->[0] .. $range->[1];
            $error = $other == $n ? 'overlaps itself' : "overlaps section $other" if defined $other;
            $claimed->{$side}->[$_] //= $n for $range->[0] .. $range->[1];
        }
        push @errors => "$side range " . $JSON->encode($range) . ": $error" if $error;
    }
    return @errors;
}

# Whitespace at either end does not count.
sub check_first_line($self, $unit, $key, $ranges, $lines) {
    my $want = $unit->{$key};
    return "'$key' is required: the text of its first line" unless defined($want) && !ref($want);

    my $first = (sort { $a <=> $b } map { $_->[0] } @$ranges)[0];
    my ($got) = map { s/\A\s+|\s+\z//gr } $lines->[$first - 1] // '';
    return if ($want =~ s/\A\s+|\s+\z//gr) eq $got;
    return "'$key' does not match line $first, which reads " . $JSON->encode($got);
}

# Names are unique in their package within a file.
sub check_name($self, $unit, $names) {
    my $package = $unit->{package} // '';
    return if !$names->{$package}->{$unit->{name}}++;
    return "name '$unit->{name}' repeats" . (length($package) ? " in package '$package'" : '') . "; make it unique, for example with ' (2)'";
}

# The file's new sections: the agent's units and blank lines between. Line
# counts come from the diff. Explanations start empty: the agent explains a
# re-split file afresh.
sub resplit($self, $ctx, $commit, $file, $texts, $entries) {
    my @units = map {
        +{
            name       => $_->{name},
            package    => $_->{package},
            ranges     => $self->sorted($_->{lines}     // []),
            doc_ranges => $self->sorted($_->{doc_lines} // []),
            old_ranges => $self->sorted($_->{old_lines} // []),
        }
    } @$entries;

    my $builder = Review::Helper::Builder->new(repo => $self->{+REPO}, db => $self->{+DB});
    return $builder->split_sections($texts, \@units);
}

# }}} Validation

# {{{ Guide validation

sub check_guide($self, $ctx, $item, $fields, $plan) {
    my $steps = $fields->{steps};
    return "'steps' must be a non-empty array" unless ref($steps) eq 'ARRAY' && @$steps;

    my @errors;
    for my $n (0 .. $#$steps) {
        push @errors => map { 'step ' . ($n + 1) . ": $_" } $self->check_step($ctx, $plan, $steps->[$n]);
    }
    return @errors;
}

sub check_step($self, $ctx, $plan, $step) {
    return 'must be an object' unless ref($step) eq 'HASH';
    my @errors = map { "unknown field '$_'" } sort grep { !m/^(?:target|highlight|commentary)$/ } keys %$step;
    push @errors => $self->check_commentary($step->{commentary});

    my ($commit, @target_errors) = $self->check_target($ctx, $plan, $step->{target});
    push @errors => map { "target: $_" } @target_errors;

    my $highlight = $step->{highlight} // [];
    if (ref($highlight) ne 'ARRAY') {
        push @errors => "'highlight' must be an array";
    }
    elsif (@$highlight && !$commit) {
        push @errors => "'highlight' needs a target in a commit" unless @target_errors;
    }
    elsif ($commit) {
        my $view = ref($step->{target}) eq 'HASH' && ($step->{target}->{type} // '') eq 'view';
        for my $mark (@$highlight) {
            push @errors => map { "highlight: $_" } $self->check_highlight($ctx, $commit, $mark, $view);
        }
    }

    return @errors;
}

sub check_commentary($self, $text) {
    return "'commentary' must be a non-empty string" unless $self->is_text($text);
    return "'commentary' is over 400 characters"                                                       if length($text) > 400;
    return "'commentary' must be read aloud: no backticks, '->', '::', '()', or a sigil before a word" if $text =~ m/`|->|::|\(\)|[\$\@%]\w/;
    return;
}

# The commit the target is in (undef for the summary) and any errors.
sub check_target($self, $ctx, $plan, $target) {
    return (undef, 'must be an object with a type') unless ref($target) eq 'HASH' && defined($target->{type}) && !ref($target->{type});
    my $keys    = $TARGET_KEYS{$target->{type}} or return (undef, "unknown type '$target->{type}'");
    my %allowed = map { ($_ => 1) } 'type', @$keys;
    my @unknown = sort grep { !$allowed{$_} } keys %$target;
    return (undef, map { "unknown field '$_'" } @unknown) if @unknown;

    return (undef)                                        if $target->{type} eq 'summary';
    return $self->check_flag_target($ctx, $plan, $target) if $target->{type} eq 'flag';

    my ($commit, $error) = $self->find_commit($ctx, $target->{commit}, $target->{topic}, $target->{path});
    return (undef, "'commit': $error")                                                           if $error;
    return ($commit)                                                                             if $target->{type} eq 'commit' || ($target->{type} eq 'diff' && !defined($target->{path}));
    return ($commit, $self->check_view($ctx, $commit, 'new', $target->{path}, $target->{lines})) if $target->{type} eq 'view';

    my $file = $self->is_text($target->{path}) ? $self->find_file($commit, $target->{path}) : undef;
    return ($commit, "'path' must be a path changed in commit $commit->{revision}") unless $file;
    return ($commit) if $target->{type} eq 'file';

    return ($commit) if $target->{type} eq 'diff' && !defined($target->{section});
    return ($commit, $self->check_section_target($plan, $file, $target->{section}));
}

# A view shows a file as of any commit of the iteration, changed there or not.
# Lines are checked for shape only: the page tints what exists.
sub check_view($self, $ctx, $commit, $side, $path, $lines) {
    return "'side' must be 'new' on a view step"                 unless $side eq 'new';
    return "'path' must be a path in commit $commit->{revision}" unless $self->is_text($path) && defined($self->{+REPO}->file_id($commit->{revision}, $path));

    my $error = $self->check_range($lines);
    return $error ? "'lines': $error" : ();
}

sub check_flag_target($self, $ctx, $plan, $target) {
    my $id = $target->{flag};
    return (undef, "'flag' must be a note id") unless $self->is_text($id);

    my $placed = $plan->{notes}->{$id};
    return ($placed)                                      if $placed;
    return (undef, "flag '$id' is retired in this sheet") if $plan->{retired}->{$id};

    my $commit_id = $ctx->{flags}->{$id} or return (undef, "no flag '$id' in this iteration; 'flag' takes a note id");
    my ($commit) = grep { $_->{id} == $commit_id } @{$ctx->{commits}};
    return ($commit);
}

sub check_section_target($self, $plan, $file, $section) {
    return "'section' must be an object with a 'name'" unless ref($section) eq 'HASH' && $self->is_text($section->{name});

    my $split    = $plan->{splits}->{$file->{id}};
    my $sections = $split && $split->{sections} ? $split->{sections} : $file->{sections};
    my $package  = $section->{package} // '';
    my ($found)  = grep { $_->{name} eq $section->{name} && ($_->{package} // '') eq $package } @$sections;
    return "no section '$section->{name}' in '$file->{path}'" unless $found;
    return if $self->{+DB}->section_touched($found);
    return "section '$section->{name}' in '$file->{path}' has no change to show";
}

sub check_highlight($self, $ctx, $commit, $mark, $view) {
    return 'must be an object with path, side and lines' unless ref($mark) eq 'HASH';
    return $self->check_view($ctx, $commit, $mark->{side} // '', $mark->{path}, $mark->{lines}) if $view;

    my $file = $self->is_text($mark->{path}) ? $self->find_file($commit, $mark->{path}) : undef;
    return "'path' must be a path changed in commit $commit->{revision}" unless $file;

    my $side = $mark->{side} // '';
    return "'side' must be 'old' or 'new'" unless $side eq 'old' || $side eq 'new';

    my $error = $self->check_range($mark->{lines});
    return $error ? "'lines': $error" : ();
}

# }}} Guide validation

# {{{ Writing

sub write_summary($self, $ctx, $item, $fields, $plan) { $self->update(iteration    => {number => $item->{row}->{number}}, $fields) }
sub write_commit($self, $ctx, $item, $fields, $plan)  { $self->update(commit_entry => {id     => $item->{row}->{id}},     $fields) }
sub write_file($self, $ctx, $item, $fields, $plan)    { $self->update(file_change  => {id     => $item->{row}->{id}},     $fields) }
sub write_section($self, $ctx, $item, $fields, $plan) { $self->update(section      => {id     => $item->{row}->{id}},     $fields) }

sub write_order($self, $ctx, $item, $fields, $plan) {
    my $commit = $item->{row};
    my $n      = 0;
    $self->update(file_change  => {commit_id => $commit->{id}, path => $_}, {read_position => ++$n}) for @{$fields->{paths}};
    $self->update(commit_entry => {id        => $commit->{id}},             {order_set     => 1});
    return;
}

sub write_split($self, $ctx, $item, $fields, $plan) {
    my $file  = $item->{row};
    my $split = $plan->{splits}->{$file->{id}};
    my $dbh   = $self->{+DB}->dbh;

    if ($split->{sections}) {
        $self->move_feedback($item->{commit}, $file, $split->{sections});
        $dbh->do('DELETE FROM section WHERE file_id = ?', undef, $file->{id});
        my $builder = Review::Helper::Builder->new(repo => $self->{+REPO}, db => $self->{+DB});
        $builder->store_sections($file->{id}, $split->{sections});
    }

    $self->update(file_change => {id => $file->{id}},            {split_source => $split->{source}});
    $self->update(request     => {id => $item->{request}->{id}}, {status       => 'done'}) if $item->{request};
    return;
}

# Section feedback and requests follow their section into a re-split, by
# name and package. With no such touched section (the page shows no other)
# they move to the whole file, keeping the name they were on as context;
# nothing else about them changes.
sub move_feedback($self, $commit, $file, $sections) {
    my $dbh     = $self->{+DB}->dbh;
    my $name_of = sub ($s) { join "\0" => $s->{name}, $s->{package} // '' };
    my %kept    = map { ($name_of->($_) => 1) } grep { $self->{+DB}->section_touched($_) } @$sections;

    for my $table (qw/feedback request/) {
        my $rows = $dbh->selectall_arrayref("SELECT id, section_name AS name, section_package AS package FROM $table WHERE target = 'section' AND revision = ? AND path = ?", {Slice => {}}, $commit->{revision}, $file->{path});
        $self->update($table => {id => $_->{id}}, {target => 'file'}) for grep { !$kept{$name_of->($_)} } @$rows;
    }

    return;
}

# The iteration's entries become the topics, in order. A topic keeps the
# entry of its name, else an entry with exactly its files (so a first fill
# with one topic, or a renamed one, keeps what was written); a kept entry
# whose files change loses its text and reading order. Files and flags
# follow their paths; a flag on no path follows its entry, or goes to the
# first topic when that entry goes. Commit feedback and requests of this
# iteration follow their entry's new name, or move to the review, keeping
# the commit and topic they were on as context, when it goes.
sub write_topics($self, $ctx, $item, $fields, $plan) {
    my $dbh     = $self->{+DB}->dbh;
    my $number  = $ctx->{iteration}->{number};
    my @entries = @{$ctx->{commits}};
    my $topics  = $fields->{topics};
    my $key     = sub (@paths) { join "\0" => sort @paths };
    my %files   = map { ($_->{id}    => $key->(map { $_->{path} } @{$_->{files}})) } @entries;
    my %file_id = map { ($_->{path}  => $_->{id}) } map { @{$_->{files}} } @entries;
    my %named   = map { ($_->{topic} => $_) } grep      { defined $_->{topic} } @entries;

    my (@pick, %kept);
    for my $n (0 .. $#$topics) {
        my $entry = $named{$topics->[$n]->{name}} or next;
        ($pick[$n], $kept{$entry->{id}}) = ($entry, 1);
    }
    for my $n (grep { !$pick[$_] } 0 .. $#$topics) {
        my ($entry) = grep { !$kept{$_->{id}} && $files{$_->{id}} eq $key->(@{$topics->[$n]->{paths}}) } @entries or next;
        ($pick[$n], $kept{$entry->{id}}) = ($entry, 1);
    }

    $dbh->do('UPDATE commit_entry SET position = -id WHERE iteration = ?', undef, $number);
    my (%entry_of, @ids);
    for my $n (0 .. $#$topics) {
        my ($name, $paths) = @{$topics->[$n]}{qw/name paths/};
        my $id = $pick[$n] ? $self->keep_entry($ctx, $pick[$n], $name, $n + 1, $files{$pick[$n]->{id}} eq $key->(@$paths)) : $self->new_entry($entries[0], $name, $n + 1);
        $self->update(file_change => {id => $file_id{$_}}, {commit_id => $id}) for @$paths;
        $entry_of{$_} = $id for @$paths;
        push @ids => $id;
    }

    my @gone = grep { !$kept{$_->{id}} } @entries;
    my %gone = map  { ($_->{id} => 1) } @gone;
    for my $flag (@{$ctx->{flag_rows}}) {
        my $id = defined($flag->{path}) ? $entry_of{$flag->{path}} : undef;
        $id //= $ids[0]                                                if $gone{$flag->{commit_id}};
        $self->update(flag => {id => $flag->{id}}, {commit_id => $id}) if $id;
    }
    # Feedback on the entry with no topic keeps a topic of '' when the
    # iteration had topics then: it was on the files not in a topic yet, not
    # on the whole change.
    my $named = grep { defined $_->{topic} } @entries;
    for my $entry (@gone) {
        my $was = $entry->{topic} // ($named ? '' : undef);
        $dbh->do("UPDATE $_ SET target = 'review', topic = ? WHERE iteration = ? AND target = 'commit' AND revision = ? AND topic IS ?", undef, $was, $number, $entry->{revision}, $entry->{topic}) for qw/feedback request/;
        $dbh->do('DELETE FROM commit_entry WHERE id = ?', undef, $entry->{id});
    }
    return;
}

# A topic's entry kept from before: renamed, its commit feedback and
# requests with it, and placed; its text and reading order cleared when its
# files changed.
sub keep_entry($self, $ctx, $entry, $name, $position, $same) {
    my $dbh = $self->{+DB}->dbh;
    if (($entry->{topic} // "\0") ne $name) {
        $dbh->do("UPDATE $_ SET topic = ? WHERE iteration = ? AND target = 'commit' AND revision = ? AND topic IS ?", undef, $name, $ctx->{iteration}->{number}, $entry->{revision}, $entry->{topic}) for qw/feedback request/;
    }
    $self->update(commit_entry => {id => $entry->{id}}, {topic => $name, position => $position, $same ? () : (what => undef, why => undef, how => undef, order_set => 0)});
    return $entry->{id};
}

# A topic's new entry: the squashed entry's commit facts, with no text yet.
sub new_entry($self, $from, $name, $position) {
    my @cols = qw/iteration revision parent subject message author authored/;
    my $dbh  = $self->{+DB}->dbh;
    $dbh->do('INSERT INTO commit_entry (position, topic, ' . join(', ' => @cols) . ') VALUES (?, ?' . (', ?' x @cols) . ')', undef, $position, $name, @$from{@cols});
    return $dbh->last_insert_id(undef, undef, 'commit_entry', 'id');
}

sub write_note($self, $ctx, $item, $fields, $plan) {
    my $note   = $item->{row};
    my $commit = $plan->{notes}->{$note->{id}};
    my $lines  = $fields->{lines} // [undef, undef];

    $self->{+DB}->dbh->do(
        'INSERT INTO flag (note_id, commit_id, path, line_start, line_end, color, kind, sentence, detail, created) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', undef,
        $note->{id}, $commit->{id}, $fields->{path}, @$lines, @$note{qw/flag kind sentence detail created/},
    );
    return;
}

# Keep and recolor settle a pending flag; turning
# it red makes it unseen for everyone again. Retire takes it
# out of the iteration: its feedback moves to its file (its commit, for a
# whole-commit flag), keeping the flag as context.
sub write_flag($self, $ctx, $item, $fields, $plan) {
    my $flag = $item->{row};
    my $dbh  = $self->{+DB}->dbh;

    if ($fields->{decision} eq 'retire') {
        my $target = defined($flag->{path}) ? 'file' : 'commit';
        $dbh->do(q{UPDATE feedback SET target = ? WHERE target = 'flag' AND flag = ?}, undef, $target, $flag->{note_id});
        $dbh->do('DELETE FROM flag_seen WHERE flag = ?', undef, $flag->{id});
        $dbh->do('DELETE FROM flag WHERE id = ?',        undef, $flag->{id});
        return;
    }

    my %set = (pending => 0);
    if ($fields->{decision} eq 'recolor') {
        @set{qw/color color_reason/} = @$fields{qw/color reason/};
        $dbh->do('DELETE FROM flag_seen WHERE flag = ?', undef, $flag->{id}) if $set{color} eq 'red' && $flag->{color} ne 'red';
    }
    $self->update(flag => {id => $flag->{id}}, \%set);
    return;
}

sub write_feedback($self, $ctx, $item, $fields, $plan) {
    my %set = (%$fields, updated => now());
    $set{resolved_in} = $ctx->{iteration}->{number} if ($fields->{status} // '') eq 'addressed';
    $self->update(feedback => {id => $item->{row}->{id}}, \%set);
    return;
}

sub write_debate($self, $ctx, $item, $fields, $plan) {
    my %set  = %$fields;
    my %have = (%{$item->{fields}}, %set);
    $set{status} = 'done' if defined($have{case_for}) && defined($have{case_against});
    $self->update(request => {id => $item->{row}->{id}}, \%set);
    return;
}

sub write_guide($self, $ctx, $item, $fields, $plan) {
    my $dbh    = $self->{+DB}->dbh;
    my $number = $ctx->{iteration}->{number};

    $dbh->do('DELETE FROM guide_step WHERE iteration = ?', undef, $number);
    my $sth = $dbh->prepare('INSERT INTO guide_step (iteration, position, target, highlight, commentary) VALUES (?, ?, ?, ?, ?)');
    my $n   = 0;
    for my $step (@{$fields->{steps}}) {
        $sth->execute($number, ++$n, $JSON->encode($step->{target}), $JSON->encode($step->{highlight} // []), $step->{commentary});
    }
    return;
}

sub update($self, $table, $where, $set) {
    my @cols  = sort keys %$set;
    my @conds = sort keys %$where;
    my $sql   = "UPDATE $table SET " . join(', ' => map { "$_ = ?" } @cols) . ' WHERE ' . join(' AND ' => map { "$_ = ?" } @conds);
    $self->{+DB}->dbh->do($sql, undef, @$set{@cols}, @$where{@conds});
    return;
}

# }}} Writing

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Sheet - Export the fill sheet and import a filled one.

=head1 DESCRIPTION

The fill sheet is the only way an agent writes review text. C<sheet> lists
every item of the latest iteration that still needs agent input; C<fill>
validates a filled sheet as a whole and writes it in one transaction.

Item types: C<summary> (from iteration 2 it also takes C<note>, what the
iteration changed), C<topics> (a squashed iteration's files grouped into
named topics, each an entry of its own), C<commit>, C<order> (reading order), C<file>,
C<section>, C<split>, C<note> (placing a journal note as a flag), C<flag>
(keeping, re-rating or retiring a flag), C<feedback>, C<debate> and C<guide>. Each item has an C<id>, a C<type>, a
C<rev>, read-only C<about> context, and C<fields> holding the current
values. The C<rev> is a SHA-256 hex digest of the item's C<about> and current
field values, so an item filled from an out-of-date sheet is rejected.

An item is done once its required fields are set: C<what> for files and
sections, C<sections> for splits, C<commit> for notes (a null
C<path> places the note on the whole commit, null C<lines> on the whole file),
C<decision> for a pending flag (any other flag is done), and every field for
the other types. Done items are
left out of the sheet unless it is asked for C<all>; then they are listed with
their current values and revs, and C<fill> replaces what is given, checked as
fully as a first fill. Flags that are not pending and finished debates are
done items; note items never are, since a placed note leaves the journal. A done split
item keeps null fields; its C<about> shows the current units. Feedback is
listed only while open, since its status may be the reviewer's. Every text
file its commit adds, or changes a line of without deleting it, has a split
item (a rename or mode change alone has none): required (optional in a
squashed iteration) until the file is split, and required again while a
C<split> request on it is open. Its C<about> gives the file's old path and status, its sizes, its stored units (the whole
split), and, for a file not split yet, the newest split an earlier iteration
stored for it, as stored, with that commit's revision. Section items are given only for touched sections: deleted,
or with a line added, removed or changed. Deleted, image and binary files have no lines to split and get no split
item, even when requested. Note items are always optional, since the journal can hold
notes from unrelated work, and so are section and reading order items of a
squashed iteration. A flag item is required for each pending flag: one the
builder carried onto code that changed; with C<all> every flag of the
iteration has one. Feedback and
debate items cover everything still open, from any iteration, and with C<all>
every debate. A commit with no file changes, such as a merge, has no reading
order item. A commit item's C<about> names the merge that brought the commit
in, if any.

C<fill> skips items whose fields are all null and writes only non-null
fields. It rejects the whole sheet, naming every failing item, on: unknown
ids or fields, wrong types, stale revisions, empty strings, ranges outside
the file, a split section that overlaps another, repeats a name in its
package, or whose C<first_line> (C<old_first_line>) is not the text of its
first line, a split that leaves a line with text in no section (it covers
every line or is empty), a reading order that is not exactly the
commit's paths, guide targets or highlights missing from the iteration (a
C<view> step may show any file as of any commit of the iteration, new side
only), and guide commentary over 400 characters or containing code tokens
(backticks, C<< -> >>, C<::>, C<()>, or C<$>, C<@> or C<%> before a word
character).

The C<topics> item of a squashed iteration is required while a file is in no
topic, which before its first fill means every file, in the iteration's one
entry. Filled, every path in exactly one topic and the names unique, it
makes the entries the topics, in order: a topic keeps the entry of its name,
else one with exactly its files, else gets a new one; a kept entry whose files
change loses its text and reading order; flags follow their paths; C<commit>
feedback and requests on an entry that goes move to the review, keeping the
commit and topic as context. Commit, order, note and guide items are refused
in the sheet that fills the topics. Every topic's entry has the head's revision,
so a note or guide target picks its entry by C<topic>, or by the path it
names; a C<commit> or C<diff> step with no path, and a note with none, must
name the topic.

Writing a split replaces the file's sections: the agent's units, with the
blank lines it left out joined to them, and its deleted units; an empty
split leaves the file with none. Line counts are computed from the diff,
and every section is kept, touched or not, with no explanation: a re-split
file is explained afresh. Section feedback and section requests whose
section is gone, or no longer touched, move to the file, keeping its name as
context. The file is labeled C<agent>, and an open split request on it is
marked done. Placed notes become flags and leave the journal once the
transaction commits; a note the iteration already holds as a flag (its
removal failed) gets no item and leaves at the next fill. A filled flag item
settles a pending flag: C<keep> leaves it as it is, C<recolor> stores a new
color and its reason (yellow turned red makes the flag unseen by everyone
again); C<retire> deletes
it from the iteration, turning its feedback into C<file> feedback (C<commit>
for a whole-commit flag) that keeps the flag's note id. A stored guide step
naming a retired flag makes the guide due again. Addressed feedback records the latest iteration as
C<resolved_in>; a debate is done once both cases are set. A guide replaces
the iteration's steps, storing each target's commit as its full revision id.

=head1 SYNOPSIS

    use Review::Helper::Sheet;

    my $sheet = Review::Helper::Sheet->new(repo => $repo, db => $db);

    my $data = $sheet->sheet;
    $_->{fields}->{what} = '...' for grep { $_->{type} eq 'section' } @{$data->{items}};

    my $result = $sheet->fill($data);    # { filled => 3, remaining => 7 }

=head1 ATTRIBUTES

=over 4

=item $repo = $sheet->repo()

The repository the review belongs to, a L<Review::Helper::VCS>. Required.

=item $db = $sheet->db()

The L<Review::Helper::DB> of the review. Required.

=item $journal = $sheet->journal()

The L<Review::Helper::Journal> holding notes to place. Defaults to the
repository's journal.

=back

=head1 PUBLIC METHODS

=over 4

=item $data = $sheet->sheet()

=item $data = $sheet->sheet(all => 1)

The fill sheet for the latest iteration: a hashref with C<format>
(C<review-sheet>), C<format_version> (1), C<review>, C<iteration> and
C<items>. With C<all>, done items are listed too.

=item $result = $sheet->fill($data)

Validate and import a decoded sheet. Returns
C<< { filled => $n, remaining => $m } >>: the items written, and the required
items still not done. Dies with one line per problem when the sheet is
rejected, writing nothing.

=item $ctx = $sheet->context()

The latest iteration loaded for building items: review, iteration, commits
with their files and sections, open feedback, every request, guide steps,
the journal's flag notes (journal entries go in at the next build or
iteration), the iteration's flags by note id, and its flag rows (with
their entry's revision and topic).

=item $hex = $sheet->rev($item)

The item's revision hash.

=item $items = $sheet->items($ctx)

Every item of the iteration, done or not, with internal keys (C<done>,
C<optional>, C<row>, and C<names> for text items) beside the exported ones.

=item $item = $sheet->summary_item($ctx)

=item $item = $sheet->topics_item($ctx)

=item $item = $sheet->text_item($ctx, $type, $id, $row, $about)

=item $item = $sheet->order_item($commit)

=item $about = $sheet->commit_about($ctx, $commit)

=item $about = $sheet->file_about($commit, $file)

=item $about = $sheet->section_about($commit, $file, $section)

=item @items = $sheet->split_item($ctx, $commit, $file)

=item $entry = $sheet->split_entry($section)

=item $texts = $sheet->file_texts($ctx, $commit, $file)

=item $previous = $sheet->previous_split($ctx, $commit, $file)

=item $bool = $sheet->is_split_request($request, $commit, $file)

=item $item = $sheet->note_item($note)

=item $item = $sheet->flag_item($ctx, $flag)

=item $item = $sheet->feedback_item($ctx, $feedback)

=item $item = $sheet->debate_item($request)

=item $item = $sheet->guide_item($ctx)

=item $bool = $sheet->is_stale_step($ctx, $target)

Build one item, or part of one. Only the sections the commit changed
(L<Review::Helper::DB/section_touched>) get section items.
C<is_stale_step> is true for a stored guide step naming a section that a
later re-split removed or left untouched, a flag the iteration no longer has
(a retired one), or a commit, topic or path that a
later topics fill took away (a commit with no topic, once the iteration is
split into topics); the guide item is then not done, so the sheet asks for
the guide again.

=item $bool = $sheet->is_text($value)

=item @errors = $sheet->check_summary($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_commit($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_file($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_debate($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_flag($ctx, $item, $fields, $plan)

=item $file = $sheet->find_file($commit, $path)

=item $value = $sheet->trim($value)

=item $bool = $sheet->is_line($value)

=item $ranges = $sheet->sorted($ranges)

Small validation helpers: C<is_text> and C<is_line> test one value,
C<trim> drops whitespace at both ends of a string (section, package and
topic names are trimmed before they are checked), the
C<check_*> methods check an item's fields (C<check_flag> also records a
retired flag in C<$plan>, so a guide step in the same sheet cannot name it),
C<find_file> finds a changed
file of a commit, and C<sorted> orders ranges.

=item ($plan, $errors) = $sheet->validate($ctx, $data)

Check a whole sheet. C<$errors> lists every problem; C<$plan> holds the
writes and the splits and note placements they need.

=item ($item, $fields, @errors) = $sheet->check_item($entry, $items, $index)

Match one sheet entry to its item and check its id, type, rev and field
names. Returns nothing for a skipped entry.

=item $bool = $sheet->same_topics($given, $stored)

Whether given topics are the stored ones: the same names in the same order,
each with the same paths in any order. A topics entry that repeats the stored
topics is skipped.

=item @errors = $sheet->check_text($item, $fields, @names)

=item @errors = $sheet->check_section($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_order($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_feedback($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_note($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_topics($ctx, $item, $fields, $plan)

Check one item's fields. C<check_topics> also records the topics in
C<$plan>, so the items a topics fill would move are refused.

=item ($commit, $error) = $sheet->find_commit($ctx, $revision)

=item ($commit, $error) = $sheet->find_commit($ctx, $revision, $topic, $path)

A commit entry of the iteration by its full revision id, matched exactly.
In a squashed iteration split into topics, where every topic's entry has the
head's revision, C<$topic> picks one; else the entry holding C<$path>, else the
first; with neither, it is an error.

=item $error = $sheet->check_range($lines)

=item $error = $sheet->check_lines($file, $side, $lines)

=item @errors = $sheet->check_split($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_coverage(\@lines, \@claimed)

=item @errors = $sheet->check_unit($file, \%lines, $unit, \%claimed, $n)

=item @errors = $sheet->check_ranges($file, $side, $ranges, \%claimed, $n)

=item @errors = $sheet->check_first_line($unit, $key, $ranges, $lines)

=item @errors = $sheet->check_name($unit, \%names)

=item @errors = $sheet->check_guide($ctx, $item, $fields, $plan)

=item @errors = $sheet->check_step($ctx, $plan, $step)

=item @errors = $sheet->check_commentary($text)

=item ($commit, @errors) = $sheet->check_target($ctx, $plan, $target)

=item @errors = $sheet->check_view($ctx, $commit, $side, $path, $lines)

=item ($commit, @errors) = $sheet->check_flag_target($ctx, $plan, $target)

=item @errors = $sheet->check_section_target($plan, $file, $section)

=item @errors = $sheet->check_highlight($ctx, $commit, $mark, $is_view)

Validation steps. Each returns error messages; an empty list means valid.

=item $sections = $sheet->resplit($ctx, $commit, $file, $texts, \@entries)

A split item's file sections from its entries: the agent's units and the
blank lines between them, line counts from the diff, and no explanations.

=item $sheet->write_summary($ctx, $item, $fields, $plan)

=item $sheet->write_commit($ctx, $item, $fields, $plan)

=item $sheet->write_file($ctx, $item, $fields, $plan)

=item $sheet->write_section($ctx, $item, $fields, $plan)

=item $sheet->write_flag($ctx, $item, $fields, $plan)

=item $sheet->write_order($ctx, $item, $fields, $plan)

=item $sheet->write_split($ctx, $item, $fields, $plan)

=item $sheet->write_note($ctx, $item, $fields, $plan)

=item $sheet->write_feedback($ctx, $item, $fields, $plan)

=item $sheet->write_debate($ctx, $item, $fields, $plan)

=item $sheet->write_guide($ctx, $item, $fields, $plan)

=item $sheet->write_topics($ctx, $item, $fields, $plan)

Write one validated item. Called inside the fill transaction.

=item $id = $sheet->keep_entry($ctx, $entry, $name, $position, $same_files)

=item $id = $sheet->new_entry($from_entry, $name, $position)

Called by C<write_topics>: keep an entry for a topic (renamed, its C<commit>
feedback and requests taking the new name; its text and reading order
cleared unless C<$same_files>), or make a new one with C<$from_entry>'s
commit facts and no text.

=item $sheet->move_feedback($commit, $file, \@sections)

Called by C<write_split> before an agent split replaces the file's sections.
Section feedback and section requests on the file stay on the new section
with its name and package. Those whose section is gone, or is no longer
touched (the page shows only touched sections), move to the file,
keeping the section's name and package as context: where they were given.
Nothing else about them changes.

=item $sheet->update($table, \%where, \%set)

Run one C<UPDATE>.

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
