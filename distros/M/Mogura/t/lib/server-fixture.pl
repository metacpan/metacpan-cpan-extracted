use Mojo::JSON qw(to_json from_json);

sub save_inventory {
    my ($store, $snapshot, $scanner) = @_;
    $store->db->do(
        'UPDATE scanners SET seen=?,inventory=? WHERE id=?',
        undef, $snapshot->{updated_at} // time,
        to_json($snapshot), $scanner // 'fixture'
    );
}

sub seed_scan {
    my ($store, $scan) = @_;
    $store->db->do(
        'INSERT INTO jobs(id,scanner,token,created,tags,note,record,finished) VALUES (?,?,?,?,?,?,?,1)',
        undef,
        $scan->{id},
        'fixture',
        'a' x 64,
        $scan->{created_at},
        to_json($scan->{tags}),
        $scan->{note},
        to_json($scan)
    );
    $store->directory($scan->{id})->make_path;
}

sub seed_artifact {
    my ($store, $id, $kind, $bytes) = @_;
    my $name = Mogura::Protocol::artifact_name($kind);
    $store->directory($id)->child($name)->spurt($bytes);
    $store->db->do('INSERT INTO receipts(job,run,kind,hash,indexed) VALUES (?,?,?,?,1)',
        undef, $id, 'e' x 32, $kind, Digest::SHA::sha256_hex($bytes));
}
1;
