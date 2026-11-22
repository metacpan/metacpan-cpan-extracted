package Mogura::Server::Store;
use Mojo::Base -base;
use DBI;
use Digest::SHA qw(sha256_hex);
use Mojo::File qw(path);
use Mojo::JSON qw(to_json from_json);
use Mogura::Protocol qw(random_id valid_id now artifact_name);
use Mogura::Server::Tags;

use constant BLOCKS_REMOVAL => q{finished=0 OR
    COALESCE(json_extract(record, '$.cleanup_status'), '') NOT IN ('unmounted', 'not_needed')};

has state =>
    sub { path($ENV{XDG_STATE_HOME} || path($ENV{HOME}, '.local/state'), 'mogura')->to_string };

sub db {
    my ($self) = @_;
    return $self->{db} if ($self->{pid} // 0) == $$;
    path($self->state)->make_path({mode => 0700});
    my $db = DBI->connect('dbi:SQLite:dbname=' . path($self->state, 'mogura.sqlite'),
        '', '', {RaiseError => 1, PrintError => 0, sqlite_unicode => 1, AutoInactiveDestroy => 1});
    $db->do('PRAGMA busy_timeout=5000');
    $db->do('PRAGMA synchronous=FULL');
    $self->{pid} = $$;
    return $self->{db} = $db;
}

sub initialize {
    my ($self) = @_;
    my $db = $self->db;
    $db->do('PRAGMA journal_mode=WAL');
    $db->do('CREATE TABLE IF NOT EXISTS settings(name TEXT PRIMARY KEY, value TEXT NOT NULL)');
    $db->do("INSERT OR IGNORE INTO settings VALUES ('session', ?)",
        undef, random_id() . random_id());
    $db->do("INSERT OR IGNORE INTO settings VALUES ('id',?)", undef, random_id());
    $db->do(
        'CREATE TABLE IF NOT EXISTS scanners(id TEXT PRIMARY KEY, digest TEXT UNIQUE, seen INTEGER, inventory TEXT)'
    );
    $db->do(
        q{CREATE TABLE IF NOT EXISTS jobs(id TEXT PRIMARY KEY, scanner TEXT NOT NULL, token TEXT NOT NULL,
        run TEXT, created TEXT NOT NULL, tags TEXT NOT NULL, note TEXT NOT NULL,
        record TEXT NOT NULL, finished INTEGER NOT NULL DEFAULT 0)}
    );
    $db->do('CREATE INDEX IF NOT EXISTS assigned ON jobs(scanner,finished,created)');
    $db->do('CREATE INDEX IF NOT EXISTS removal_blockers ON jobs(scanner) WHERE ' . BLOCKS_REMOVAL);
    $db->do(
        'CREATE TABLE IF NOT EXISTS receipts(job TEXT, run TEXT, kind TEXT, hash TEXT NOT NULL, indexed INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(job,run,kind))'
    );
    $db->do('CREATE INDEX IF NOT EXISTS pending_indexes ON receipts(job,kind) WHERE indexed=0');
    $db->do('CREATE INDEX IF NOT EXISTS history ON jobs(created DESC,id DESC)');
    return $self;
}

sub transaction {
    my ($self, $operation) = @_;
    my $db = $self->db;
    $db->begin_work;
    my $result;
    eval { $result = $operation->($db); $db->commit; 1 } or do {
        my $error = $@;
        $db->rollback;
        die $error;
    };
    return $result;
}

sub register {
    my ($self, $id, $token) = @_;
    die 'Invalid scanner name' unless ($id // '') =~ /\A[a-zA-Z0-9_-]{1,64}\z/;
    $self->db->do('INSERT INTO scanners(id,digest) VALUES (?,?)', undef, $id, sha256_hex($token));
}

sub authenticate {
    my ($self, $header) = @_;
    return unless ($header // '') =~ /\ABearer ([a-f0-9]{64})\z/;
    return
        scalar $self->db->selectrow_array('SELECT id FROM scanners WHERE digest=?', undef,
        sha256_hex($1));
}

sub inventories {
    my ($self, $page) = @_;
    my $rows = $self->db->selectall_arrayref(
        'SELECT id,seen,inventory FROM scanners WHERE digest IS NOT NULL ORDER BY id LIMIT 5 OFFSET ?',
        {Slice => {}},
        (($page // 1) - 1) * 4
    );
    return [
        map {
            {
                %{from_json($_->{inventory} // '{"disks":[]}')},
                    scanner_id => $_->{id},
                    stale => ($_->{seen} // 0) <
                    time - 30
            }
        } @$rows
    ];
}

sub selectable {
    my ($self, $scanner, $token) = @_;
    my ($json) = $self->db->selectrow_array(
        'SELECT inventory FROM scanners WHERE id=? AND digest IS NOT NULL AND seen>=?',
        undef, $scanner, time - 30);
    return unless $json;
    my $inv = from_json($json);
    return if @{$inv->{blocked} // []} || @{$inv->{errors} // []};
    my @targets = grep { $_ && $_->{selectable} && ($_->{token} // '') eq $token }
        ($inv->{host}, map { @{$_->{targets}} } @{$inv->{disks}});
    return @targets == 1 ? $targets[0] : undef;
}

# Linux assigns a disk sequence to the whole attachment for the lifetime of a boot.
sub _attachment {
    my ($target) = @_;
    return unless ref($target) eq 'HASH' && ref($target->{disk}) eq 'HASH';
    my ($boot, $sequence) = ($target->{boot_id}, $target->{disk}{diskseq});
    return
        unless defined($boot)
        && !ref($boot)
        && $boot =~ /\S/
        && ($sequence // '') =~ /\A[1-9][0-9]*\z/;
    return "$boot:$sequence";
}

sub can_disconnect {
    my ($self, $scan) = @_;
    return unless ($scan->{cleanup_status} // '') eq 'unmounted';
    my $attachment = _attachment($scan->{target}) // return;
    my $current = $self->selectable($scan->{scanner_id}, $scan->{token}) or return;
    return unless (_attachment($current->{identity}) // '') eq $attachment;

    my $disk = $scan->{target}{disk};
    return unless length($disk->{serial} // '') || length($disk->{wwn} // '');
    for my $field (qw(serial wwn)) {
        return if ($disk->{$field} // '') ne ($current->{identity}{disk}{$field} // '');
    }

    my $jobs = $self->db->prepare(
        q{SELECT json_extract(record, '$.target') FROM jobs WHERE scanner=? AND id<>? AND (}
            . BLOCKS_REMOVAL
            . ')');
    $jobs->execute($scan->{scanner_id}, $scan->{id});
    while (my $row = $jobs->fetchrow_arrayref) {
        my $target = defined($row->[0]) ? from_json($row->[0]) : undef;
        next if ref($target) eq 'HASH' && ($target->{kind} // '') eq 'host';
        my $other = _attachment($target) // return;
        return if $attachment eq $other;
    }
    return 1;
}

sub submit {
    my ($self, $id, $scanner, $token, $tags, $note) = @_;
    die 'Invalid job' unless valid_id($id) && ($token // '') =~ /\A[a-f0-9]{64}\z/;
    return $self->transaction(
        sub {
            my ($db) = @_;
            my $old = $self->get($id);
            return $old->{scanner_id} eq $scanner && $old->{token} eq $token ? 200 : 409 if $old;
            my $target = $self->selectable($scanner, $token) or return 409;
            return 409 if $db->selectrow_array(
                q{SELECT 1 FROM jobs WHERE scanner=? AND token=? AND
            (finished=0 OR json_extract(record,'$.cleanup_status')='needs_cleanup')}, undef,
                $scanner, $token
            );
            my $record = {
                status => 'queued',
                phase => 'queued',
                cleanup_status => 'unknown',
                target => $target->{identity},
                warnings => []
            };
            $db->do(
                'INSERT INTO jobs(id,scanner,token,created,tags,note,record) VALUES (?,?,?,?,?,?,?)',
                undef, $id, $scanner, $token, now(), to_json($tags), $note, to_json($record)
            );
            return 202;
        }
    );
}

sub cancel {
    my ($self, $id) = @_;
    return $self->transaction(
        sub {
            my ($db) = @_;
            my $scan = $self->get($id) or return;
            my $status = $scan->{status};
            if ($status eq 'queued') {
                $db->do(
                    q{UPDATE jobs SET finished=1, record=json_set(record,
                '$.status','cancelled','$.phase','finished','$.finished_at',?,
                '$.cleanup_status','not_needed') WHERE id=?}, undef, now(), $id
                );
            }
            elsif ($status eq 'running') {
                $db->do(
                    q{UPDATE jobs SET record=json_set(record,'$.status','cancelling') WHERE id=?},
                    undef, $id);
            }

            # A repeated click or a completion racing the form keeps the last result.
            return 1;
        }
    );
}

sub pending_cancellations {
    my ($self, $scanner) = @_;
    return $self->db->selectall_arrayref(
        q{SELECT id,run FROM jobs WHERE scanner=?
        AND finished=0 AND json_extract(record,'$.status')='cancelling' AND run IS NOT NULL},
        {Slice => {}}, $scanner
    );
}

sub offer {
    my ($self, $scanner) = @_;
    return $self->db->selectrow_hashref(
        'SELECT id,token FROM jobs WHERE scanner=? AND run IS NULL AND finished=0 ORDER BY created,id LIMIT 1',
        undef, $scanner
    );
}

sub claim {
    my ($self, $scanner, $id, $run) = @_;
    return $self->transaction(
        sub {
            my ($db) = @_;
            my $row = $db->selectrow_hashref(
                q{SELECT run,token,finished,json_extract(record,'$.status') AS status FROM jobs WHERE scanner=? AND id=?},
                undef, $scanner, $id
            ) or return;
            if (defined $row->{run}) {
                return unless $row->{run} eq $run;
                return 'cancel' if $row->{status} eq 'cancelling' || $row->{status} eq 'cancelled';
                return 1;
            }
            return 'expired' if $row->{finished};
            unless ($self->selectable($scanner, $row->{token})) {
                $db->do(
                    q{UPDATE jobs SET finished=1,record=json_set(record,'$.status','failed','$.phase','finished','$.error','Target no longer available','$.cleanup_status','not_needed') WHERE id=?},
                    undef, $id
                );
                return 'expired';
            }
            $db->do(
                q{UPDATE jobs SET run=?, record=json_set(record,'$.status','running','$.phase','validating') WHERE id=?},
                undef, $run, $id
            );
            return 1;
        }
    );
}

sub owns {
    my ($self, $scanner, $id, $run) = @_;
    return
        scalar $self->db->selectrow_array('SELECT 1 FROM jobs WHERE scanner=? AND id=? AND run=?',
        undef, $scanner, $id, $run);
}

sub get {
    my ($self, $id) = @_;
    return unless valid_id($id);
    my $row = $self->db->selectrow_hashref('SELECT * FROM jobs WHERE id=?', undef, $id) or return;
    return {
        %{from_json($row->{record})},
        id => $id,
        scanner_id => $row->{scanner},
        token => $row->{token},
        created_at => $row->{created},
        tags => from_json($row->{tags}),
        note => $row->{note}
    };
}

sub history {
    my ($self, $tag, $page) = @_;
    my $filter = length($tag) ? 'WHERE EXISTS(SELECT 1 FROM json_each(tags) WHERE value=?)' : '';
    my $rows = $self->db->selectall_arrayref(
        "SELECT id, scanner AS scanner_id, created AS created_at, tags, json_extract(record,'\$.status') AS status, json_extract(record,'\$.phase') AS phase, json_extract(record,'\$.cleanup_status') AS cleanup_status FROM jobs $filter ORDER BY created DESC,id DESC LIMIT 51 OFFSET ?",
        {Slice => {}},
        (length($tag) ? ($tag) : ()),
        ($page - 1) * 50
    );
    $_->{tags} = from_json($_->{tags}) for @$rows;
    return $rows;
}

sub change_tags {
    my ($self, $id, $operation, $values) = @_;
    return $self->transaction(
        sub {
            my $tags = $self->get($id)->{tags};
            $tags =
                $operation eq 'add'
                ? Mogura::Server::Tags->validate([@$tags, @$values])
                : [grep { $_ ne $values->[0] } @$tags];
            $self->db->do('UPDATE jobs SET tags=? WHERE id=?', undef, to_json($tags), $id);
            return $tags;
        }
    );
}

sub directory {
    my ($self, $id) = @_;
    die 'Invalid job' unless valid_id($id);
    return path($self->state, 'artifacts', $id);
}

sub artifact {
    my ($self, $id, $kind) = @_;
    my $name = artifact_name($kind) or return;
    return
        unless valid_id($id)
        && $self->db->selectrow_array('SELECT 1 FROM receipts WHERE job=? AND kind=?',
        undef, $id, $kind);
    my $file = $self->directory($id)->child($name);
    return -f $file && !-l $file ? $file : undef;
}

sub receive {
    my ($self, $scanner, $id, $run, $kind, $source, $size, $digest) = @_;
    my $name = artifact_name($kind) or die 'Invalid kind';
    die 'Unassigned run' unless $self->owns($scanner, $id, $run);
    die 'Incomplete upload' unless -s $source == $size;
    open my $fh, '<:raw', $source or die "Open upload: $!";
    die 'Checksum mismatch' unless Digest::SHA->new(256)->addfile($fh)->hexdigest eq $digest;
    my ($accepted) =
        $self->db->selectrow_array('SELECT hash FROM receipts WHERE job=? AND run=? AND kind=?',
        undef, $id, $run, $kind);
    die 'Conflicting receipt' if defined($accepted) && $accepted ne $digest;
    return if defined($accepted) && $self->artifact($id, $kind);

    if ($kind eq 'log') {
        seek $fh, 0, 0 or die "Seek log: $!";
        while (1) {
            my $read = read $fh, my $chunk, 65536;
            die "Read log: $!" unless defined $read;
            last unless $read;
            die 'Expected a text log' if index($chunk, "\0") >= 0;
        }
    }
    else {
        require Mogura::ResultStream;
        Mogura::ResultStream->valid_artifact($source, $kind);
    }
    my $file = $self->directory($id)->make_path({mode => 0700})->child($name);

    # An immutable link survives a crash before the receipt commits. A retry
    # checks the actual file before adopting an orphaned publication.
    $fh->sync or die "Sync upload: $!";
    unless (link $source, $file) {
        die "Publish upload: $!" unless $!{EEXIST};
        open my $old, '<:raw', $file or die "Open published artifact: $!";
        die 'Conflicting artifact'
            unless -s $old == $size && Digest::SHA->new(256)->addfile($old)->hexdigest eq $digest;
    }
    my $dir = $file->dirname;
    for my $parent ($dir, $dir->dirname, path($self->state)) {
        $parent->open('<')->sync or die "Sync artifact directory: $!";
    }
    $self->db->do('INSERT OR IGNORE INTO receipts(job,run,kind,hash) VALUES (?,?,?,?)',
        undef, $id, $run, $kind, $digest);
}

sub update_run {
    my ($self, $scanner, $id, $run, $data, $final) = @_;
    return $self->transaction(
        sub {
            my ($db) = @_;
            my $row = $db->selectrow_hashref(
                'SELECT record,finished FROM jobs WHERE id=? AND scanner=? AND run=?',
                undef, $id, $scanner, $run)
                or return;
            my $old = from_json($row->{record});
            if ($row->{finished}) {
                if ($final
                    && ($old->{cleanup_status} // '') eq 'needs_cleanup'
                    && ($data->{cleanup_status} // '') eq 'unmounted'
                    && $data->{sequence} > $old->{sequence})
                {
                    $db->do(
                        q{UPDATE jobs SET record=json_set(record,'$.cleanup_status','unmounted','$.sequence',?) WHERE id=?},
                        undef, 0 + $data->{sequence}, $id
                    );
                }
                return 1;
            }
            return !$final if ($old->{sequence} // 0) > $data->{sequence};
            return 1 if !$final && ($old->{sequence} // 0) == $data->{sequence};
            my $cleanup = $data->{cleanup_status} // '';
            return unless $cleanup =~ /\A(?:unknown|mounted|unmounted|not_needed|needs_cleanup)\z/;
            my $record =
                {map { exists $data->{$_} ? ($_ => $data->{$_}) : () }
                    qw(sequence phase started_at finished_at warnings error failed_phase syft_version grype_version grype_db sbom_sha256 exclusions)
                };
            $record->{target} = $old->{target};
            $record->{status} =
                $final ? $data->{status}
                : ($data->{phase} // '') eq 'finished' ? 'transferring'
                : 'running';

            if ($old->{status} eq 'cancelling') {
                if (!$final) {
                    $record->{status} = 'cancelling';
                }
                elsif ($record->{status} eq 'interrupted') {
                    $record->{status} = 'cancelled';
                }
            }
            $record->{outcome} = $final ? $record->{status} : $data->{status}
                if ($data->{phase} // '') eq 'finished';
            $record->{cleanup_status} = $cleanup;

            if ($final) {
                return
                    unless ($record->{status} // '') =~
                    /\A(?:completed|partial|failed|interrupted|cancelled)\z/;
                return if $record->{status} eq 'cancelled' && $old->{status} ne 'cancelling';
                if ($record->{status} eq 'completed') {
                    return
                        unless $cleanup eq
                        (($old->{target}{kind} // '') eq 'host' ? 'not_needed' : 'unmounted');
                    return if grep { !$self->artifact($id, $_) } qw(syft cdx grype);
                }
            }
            $db->do('UPDATE jobs SET record=?,finished=? WHERE id=?',
                undef, to_json($record), $final ? 1 : 0, $id);
            return 1;
        }
    );
}

1;
