#!perl

use strict;
use warnings;
use Test::More tests => 29;

BEGIN { use_ok('Store::CouchDB'); }

use Store::CouchDB;
use Scalar::Util qw(looks_like_number);

my $sc      = Store::CouchDB->new();
my $db      = 'store_couchdb_' . time;
my $cleanup = 0;

# use delete DB to figure out whether we can connect to CouchDB
# and clean out test DB if exists.
$sc->delete_db($db);

SKIP: {
    skip 'needs admin party CouchDB on localhost:5984', 28
        if ($sc->has_error and $sc->error !~ m/Object Not Found/);

    # operate on test DB from now on
    $sc->db($db);

    my $result = $sc->create_db();
    ok($result->{ok} == 1, "create DB $db");

    # trigger DB removal on exit as last test
    $cleanup = 1 if $result->{ok} == 1;

    # all DBs
    my @db = $sc->all_dbs;
    ok((grep { $_ eq $db } @db), 'get all databases');

    # create doc (array return)
    my ($id, $rev) = $sc->put_doc({
            doc => {
                _id   => 314235,
                key   => 'value',
                int   => 1234,
                float => 12.34,
            },
        });
    ok(($id and $rev =~ m/^1-/), 'create document (array return)');

    # head doc
    $rev = $sc->head_doc($id);
    ok($rev =~ /^1-/, 'get document head');

    # get doc (single scalar input)
    my $doc = $sc->get_doc($id);
    is_deeply(
        $doc, {
            _id   => $id,
            _rev  => $rev,
            key   => 'value',
            int   => 1234,
            float => 12.34,
        },
        "get document (single scalar input)"
    );

    # get doc (hashref input)
    $doc = $sc->get_doc({ id => $id });
    is_deeply(
        $doc, {
            _id   => $id,
            _rev  => $rev,
            key   => 'value',
            int   => 1234,
            float => 12.34,
        },
        "get document (hashref input)"
    );

    # create design doc for show/view/list tests
    $result = $sc->put_doc({
            doc => {
                _id      => '_design/test',
                language => 'javascript',
                lists    => {
                    list =>
                        'function(head, req) { var row; var result = []; start({ "headers": { "Content-Type": "application/json"}}); while (row = getRow()) { result.push(row.key); } return JSON.stringify(result); }'
                },
                views => {
                    view => {
                        map    => 'function(doc) { emit(doc.key, 2); }',
                        reduce => '_count',
                    }
                },
                shows => {
                    show =>
                        'function(doc, req) { return JSON.stringify(doc.key); }',
                },
            },
        });
    ok($result, 'create design doc');

    # show doc
    $result = $sc->show_doc({ id => $id, show => 'test/show' });
    ok($result eq 'value', 'show document');

    # update doc (missing ID)
    my ($fid, $frev) = $sc->update_doc({
            doc => {
                key   => "newvalue",
                int   => 456,
                float => 4.56
            } });
    ok((!defined($fid) and !defined($frev)), "update document (missing ID)");

    # update doc (non-existent)
    ($fid, $frev) = $sc->update_doc({
            doc => {
                _id   => $id . '1',
                key   => "newvalue",
                int   => 456,
                float => 4.56
            } });
    ok((!defined($fid) and !defined($frev)), "update non-existent document");

    # update doc (no rev)
    ($id, $rev) = $sc->update_doc({
            doc => {
                _id   => $id,
                key   => "42",
                int   => 456,
                float => 4.56
            } });
    ok(($id and $rev =~ m/2-/), "update document");

    # copy doc
    my ($copy_id, $copy_rev) = $sc->copy_doc($id);
    ok(($copy_id and $copy_rev =~ m/1-/), "copy document");

    # delete doc
    $copy_rev = $sc->del_doc($copy_id);
    ok(($copy_rev =~ m/2-/), "delete document");

    # get design docs
    $result = $sc->get_design_docs;
    is_deeply($result, ['test'], 'get design documents');

    # get view (key)
    $result = $sc->get_view({
        view => 'test/view',
        opts => { key => 42, reduce => 'false' },
    });
    is_deeply($result, { 42 => 2 }, 'get view (plain)');

    # get view reduce
    $result = $sc->get_view({
        view => 'test/view',
        opts => { reduce => 'true', group => 'true' },
    });
    is_deeply($result, { 42 => 1 }, 'get view (reduce)');

    # list view
    $result = $sc->list_view({
            view => 'test/view',
            list => 'list',
            opts => { reduce => 'false' } });
    is_deeply($result, [42], 'list view');

    # get array view
    $result = $sc->get_array_view({
        view => 'test/view',
        opts => { reduce => 'false' },
    });
    is_deeply(
        $result,
        [ { id => $id, key => 42, value => 2 } ],
        'get array view'
    );

    # get view array
    my @result = $sc->get_view_array({
        view => 'test/view',
        opts => { reduce => 'false' },
    });
    is_deeply(
        \@result,
        [ { id => $id, key => 42, value => 2 } ],
        'get view array'
    );

    # purge
    $result = $sc->purge();
    is_deeply(
        $result, {
            5 => {
                purge_seq => 1,
                purged    => { $copy_id => [$copy_rev] },
            },
        },
        'purge'
    );

    # compact
    $result = $sc->compact({ purge => 1, view_compact => 1 });
    ok((
                    $result->{compact}->{ok} == 1
                and $result->{test_compact}->{ok} == 1
                and $result->{view_compact}->{ok} == 1
        ),
        "purge DB, compact views and DB"
    );

    # put file
    ($id, $rev) =
        $sc->put_file({ file => 'content', filename => 'file.txt' });
    ok(($id and $rev =~ m/2-/), "create attachment");

    # get file
    $result = $sc->get_file({ id => $id, filename => 'file.txt' });
    is_deeply(
        $result,
        { file => 'content', content_type => 'text/plain' },
        'get attachment'
    );

    # create doc (single variable return)
    my $newid = $sc->put_doc({ doc => { key => 'somevalue' } });
    ok(($newid and $newid !~ m/^1-/), 'create document');

    # all_docs
    $result = $sc->all_docs;
    @result = sort { $a->{value}->{rev} cmp $b->{value}->{rev} } @$result;
    ok((
                    scalar(@result) == 4
                and $result[0]->{value}->{rev} =~ m/1-/
                and $result[1]->{value}->{rev} =~ m/1-/
                and $result[2]->{value}->{rev} =~ m/2-/
                and $result[3]->{value}->{rev} =~ m/2-/
        ),
        "all docs"
    );

    # all_docs (include_docs)
    $result = $sc->all_docs({ include_docs => 'true' });
    @result = sort { $a->{value}->{rev} cmp $b->{value}->{rev} } @$result;
    ok((
                    scalar(@result) == 4
                and $result[0]->{value}->{rev} =~ m/1-/
                and $result[1]->{value}->{rev} =~ m/1-/
                and $result[2]->{value}->{rev} =~ m/2-/
                and $result[3]->{value}->{rev} =~ m/2-/
                and exists $result[0]->{doc}
        ),
        "all docs (include_docs)"
    );

    $result = $sc->changes({
        limit        => 100,
        doc_ids      => ['_design/test'],
        filter       => '_doc_ids',
        include_docs => 'true',
    });
    ok((
            scalar(@{ $result->{results} }) == 1
                and $result->{results}->[0]->{doc}->{_id} eq '_design/test'
        ),
        "changes feed"
    );
}

END {
    if ($cleanup) {
        my $result = $sc->delete_db();
        ok($result->{ok} == 1, 'delete DB');
    }

    done_testing();
}
