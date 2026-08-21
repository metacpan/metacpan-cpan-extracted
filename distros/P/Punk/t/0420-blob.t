#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Punk::Plugin::Blob;
use Apophis;

# Content-addressed storage for uploads.
#
# Bytes are stored by their contents, so the user's filename never becomes a
# filesystem path and one file uploaded a hundred times is stored once. The
# three things that need proving are the three that are not obvious:
#
#   - two different files never silently share an id, because Apophis
#     identifies content with SHA-1 and its store() does not compare bytes;
#   - a blob is never served as its uploader's claimed type;
#   - a sweep whose `live` answer failed removes nothing.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'punk-blob-test', store_dir => $root);

# ---- an id is a UUID, exactly ------------------------------------------------
{
    ok(Punk::Plugin::Blob->_id_ok('a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a'),
        'a UUID is an id');
    my @bad = ('../../etc/passwd',
               'a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a/../../etc/passwd',
               '/a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a',
               'a3bb189e8bf95f18b3f61b2f5f5c1e3a',
               'A3BB189E-8BF9-5F18-B3F6-1B2F5F5C1E3A',
               'a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3',
               'g3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a',
               "a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a\0",
               '');
    is_deeply([ grep { Punk::Plugin::Blob->_id_ok($_) } @bad ], [],
        'and nothing else is - the check is the whole shape, not a scan for '
      . 'the bad ones, because a rule that enumerates those misses one');
}

# ---- storing ------------------------------------------------------------------
{
    my $a = 'hello blob';
    my $id1 = Punk::Plugin::Blob->_store($ca, \$a);
    ok(Punk::Plugin::Blob->_id_ok($id1), 'storing returns an id');

    my $again = 'hello blob';
    is(Punk::Plugin::Blob->_store($ca, \$again), $id1,
        'the same content stores once and returns the same id');

    my $b = 'a different blob';
    isnt(Punk::Plugin::Blob->_store($ca, \$b), $id1,
        'and different content gets a different id');
    is(${ $ca->fetch($id1) }, 'hello blob', 'the bytes come back');

    my $empty = '';
    my $eid = Punk::Plugin::Blob->_store($ca, \$empty);
    my $e2 = '';
    is(Punk::Plugin::Blob->_store($ca, \$e2), $eid,
        'an empty file is content, and dedups against itself rather than '
      . 'tripping the collision check');
}

# ---- GATE 1: two different files never share an id silently -------------------
# Contrived rather than waiting for a SHA-1 collision, and the contrivance is
# the honest one: reach past the plugin, overwrite a stored blob's bytes, then
# offer the original. To the plugin that is indistinguishable from a collision
# - the id is present and the stored bytes are not the bytes offered - which
# is exactly the state the check exists to refuse.
{
    my $content = 'the original content';
    my $id = Punk::Plugin::Blob->_store($ca, \$content);
    my $path = $ca->path_for($id);
    ok(-f $path, 'the blob is on disk where path_for says');

    open my $fh, '>', $path or die "$path: $!";
    print $fh 'SUBSTITUTED';
    close $fh;

    my $err = do { local $@; eval {
        Punk::Plugin::Blob->_store($ca, \$content); 1 } ? '' : $@ };
    like($err, qr/refusing to store/,
        'TWO DIFFERENT FILES SHARING AN ID IS REFUSED - the dedup hit reads '
      . 'the stored blob and compares it, so a collision is an error rather '
      . 'than a silent substitution');
    like($err, qr/\Q$id\E/, 'and the error names the id');
    like($err, qr/SHA-1/, 'and says why the check exists');

    unlink $path;
}

# ---- through a real application -----------------------------------------------
my $XSS = '<script>alert(1)</script>';
{
    package BlobApp;
    use Punk;
    plugin 'Blob' => { root => $root, namespace => 'punk-blob-test' };

    post '/up'        => sub { $_[0]->text($_[0]->blob_put('through the app')) };
    get  '/plain/:id' => sub { $_[0]->blob_send($_[0]->param('id')) };
    get  '/image/:id' => sub { $_[0]->blob_send($_[0]->param('id'),
                                                type => 'image/png',
                                                inline => 1) };
    get  '/public/:id' => sub { $_[0]->blob_send($_[0]->param('id'),
                                                 public => 1) };
    get  '/claimed/:id' => sub {
        my ($c) = @_;
        my $t = $c->blob_safe_type('text/html');
        return $t ? $c->blob_send($c->param('id'), type => $t, inline => 1)
                  : $c->blob_send($c->param('id'));
    };
}

my $app = BlobApp->to_app;
sub hit {
    my (%o) = @_;
    return $app->({ REQUEST_METHOD => $o{method} || 'GET',
                    PATH_INFO => $o{path}, SCRIPT_NAME => '',
                    QUERY_STRING => '', SERVER_NAME => 'l', SERVER_PORT => 80,
                    'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                    'psgi.errors' => \*STDERR, %{ $o{env} || {} } });
}
sub hdr { my %h = @{ $_[0][1] }; return \%h }

{
    my $r = hit(method => 'POST', path => '/up');
    is($r->[0], 200, 'the helper works inside a request');
    ok(Punk::Plugin::Blob->_id_ok($r->[2][0]), 'and returns an id');
}

# ---- GATE 2: a blob cannot be served as HTML by accident ---------------------
my $xid = Punk::Plugin::Blob->_store($ca, \$XSS);
{
    my $h = hdr(hit(path => "/plain/$xid"));
    is($h->{'Content-Type'}, 'application/octet-stream',
        'A BLOB WHOSE CONTENTS ARE HTML IS NOT SERVED AS HTML - the type is '
      . 'octet-stream unless the application named one');
    like($h->{'Content-Disposition'}, qr/^attachment/,
        'and it is a download rather than something rendered');
    is($h->{'X-Content-Type-Options'}, 'nosniff',
        'and nosniff, which matters as much: without it a browser may sniff '
      . 'HTML out of an octet-stream response and render it anyway');

    my $i = hdr(hit(path => "/image/$xid"));
    is($i->{'Content-Type'}, 'image/png',
        'an application that names a type gets it');
    is($i->{'X-Content-Type-Options'}, 'nosniff',
        'but nosniff is still set - not something this helper lets a caller '
      . 'turn off');

    my $c = hdr(hit(path => "/claimed/$xid"));
    is($c->{'Content-Type'}, 'application/octet-stream',
        'a claimed type that fails the allowlist falls back to a download '
      . 'rather than being passed through');
}

# ---- the allowlist, which is why there is a list and not a pattern ----------
{
    is(Punk::Plugin::Blob->safe_inline_type('image/png'), 'image/png',
        'a raster image may be inline');
    is(Punk::Plugin::Blob->safe_inline_type('IMAGE/PNG'), 'image/png',
        'case is normalised');
    is(Punk::Plugin::Blob->safe_inline_type('image/png; charset=binary'),
        'image/png', 'and parameters dropped');
    is(Punk::Plugin::Blob->safe_inline_type('image/svg+xml'), undef,
        'SVG IS NOT ALLOWED INLINE - it is a document that can carry script, '
      . 'so serving one from your own origin is the XSS this defends '
      . 'against, and it passes every naive image check ever written');
    is(Punk::Plugin::Blob->safe_inline_type('text/html'), undef, 'nor HTML');
    is(Punk::Plugin::Blob->safe_inline_type('application/pdf'), undef,
        'nor a PDF, which browsers render and which can carry script');
}

# ---- caching: right lifetime, wrong audience is a leak ----------------------
{
    my $h = hdr(hit(path => "/plain/$xid"));
    like($h->{'Cache-Control'}, qr/immutable/,
        'a content-addressed URL cannot come to mean anything else, so a '
      . 'long lifetime is correct');
    like($h->{'Cache-Control'}, qr/\bprivate\b/,
        'but PRIVATE by default - public on a blob behind authorisation '
      . 'tells a shared cache it may keep somebody\'s document');
    like(hdr(hit(path => "/public/$xid"))->{'Cache-Control'}, qr/\bpublic\b/,
        'and an application that says the route is public gets public');
}

# ---- ids that are not ids, and ids that name nothing ------------------------
{
    is(hit(path => '/plain/00000000-0000-5000-8000-000000000000')->[0], 404,
        'a well-formed id naming no blob is a 404 - that is a reference the '
      . 'sweep collected');
    isnt(hit(path => '/plain/..%2F..%2Fetc%2Fpasswd')->[0], 200,
        'and an id that is not an id is refused rather than served');

    my $r = hit(path => "/plain/$xid", env => { HTTP_RANGE => 'bytes=0-4' });
    is($r->[0], 206, 'a range request rides send_file');
}

# ---- GATE 3: a failing sweep answer removes nothing --------------------------
{
    my $sroot = File::Temp::tempdir(CLEANUP => 1);
    my $sca = Apophis->new(namespace => 'sweep', store_dir => $sroot);
    my $put = sub { my $b = $_[0]; Punk::Plugin::Blob->_store($sca, \$b) };
    my $count = sub { scalar grep { -f } glob "$sroot/*/*/*" };
    my $sweep = sub { Punk::Plugin::Blob->sweep($sroot, grace => 0, @_) };

    my $keep = $put->('keep me');
    my $drop = $put->('drop me');
    is($count->(), 2, 'two blobs in the store');

    my $err = do { local $@; eval {
        $sweep->(live => sub { die "the database is gone\n" }); 1 } ? '' : $@ };
    like($err, qr/died/, 'a `live` callback that DIES aborts the sweep');
    like($err, qr/NOTHING was removed/, 'and says so');
    is($count->(), 2, 'and the store is untouched');

    $err = do { local $@; eval { $sweep->(live => sub { () }); 1 } ? '' : $@ };
    like($err, qr/returned no blob ids/,
        'a callback returning NOTHING aborts too - an empty answer is '
      . 'indistinguishable from a query that failed');
    like($err, qr/unlink the whole store/,
        'and the message says what acting on it would have done');
    is($count->(), 2, 'store still untouched');

    $err = do { local $@; eval { $sweep->(live => sub { undef }); 1 } ? '' : $@ };
    like($err, qr/returned no blob ids/, 'and so does undef');
    is($count->(), 2, 'store untouched');

    # the ordinary sweep
    my ($removed, $kept) = $sweep->(live => sub { ($keep) });
    is($removed, 1, 'an unreferenced blob is removed');
    is($kept, 1,    'and a referenced one is kept');
    ok($sca->exists($keep),  'the kept blob is still there');
    ok(!$sca->exists($drop), 'and the orphan is gone');

    # one reference going does not take shared bytes with it
    my @refs = ($put->('shared'), $put->('shared'));
    is($refs[0], $refs[1], 'two references, one blob - dedup working');
    pop @refs;
    $sweep->(live => sub { ($keep, @refs) });
    ok($sca->exists($refs[0]),
        'DELETING ONE REFERENCE DOES NOT REMOVE THE BYTES - the other row '
      . 'still names the blob, and the sweep asks rather than counting');
    $sweep->(live => sub { ($keep) });
    ok(!$sca->exists($refs[0]),
        'and when the LAST reference goes the bytes are collected');

    # an arrayref, because that is what a model returns
    $put->('temp');
    my ($r2) = $sweep->(live => sub { [ $keep ] });
    is($r2, 1, 'the callback may return an arrayref');

    # allow_empty is how "really none" is said in as many words
    my ($all) = $sweep->(live => sub { () }, allow_empty => 1);
    is($all, 1, 'allow_empty is acted on, and only then');

    # grace, dry_run, and leaving alone what it does not recognise
    my $fresh = $put->('just written');
    Punk::Plugin::Blob->sweep($sroot, live => sub { ('x') x 0, $keep },
                              grace => 3600, allow_empty => 1);
    ok($sca->exists($fresh),
        'a blob younger than the grace period is never collected, which is '
      . 'what stops the race between a live snapshot and this walk');

    my ($would) = Punk::Plugin::Blob->sweep($sroot, live => sub { ($keep) },
                                            grace => 0, dry_run => 1);
    cmp_ok($would, '>', 0, 'a dry run reports what it would remove');
    ok($sca->exists($fresh), 'and removes nothing');

    my ($shard) = glob "$sroot/*/*";
    my $stray = "$shard/README";
    open my $fh, '>', $stray or die $!;
    print $fh 'notes';
    close $fh;
    Punk::Plugin::Blob->sweep($sroot, live => sub { ($keep) }, grace => 0);
    ok(-f $stray,
        'a file not shaped like a blob id is left alone - a sweep that '
      . 'removes what it does not recognise eventually removes something '
      . 'that mattered');
}

# ---- what registration requires ----------------------------------------------
{
    my $err = do { local $@; eval {
        package NoRoot;
        use Punk;
        plugin 'Blob' => { namespace => 'x' };
        NoRoot->to_app; 1 } ? '' : $@ };
    like($err, qr/`root` is required/, 'root is required');

    $err = do { local $@; eval {
        package NoNs;
        use Punk;
        plugin 'Blob' => { root => $root };
        NoNs->to_app; 1 } ? '' : $@ };
    like($err, qr/`namespace` is required/, 'and so is namespace');
    like($err, qr/tenant/,
        'and the message says why, because a required option with no reason '
      . 'is one somebody fills in with anything');
}

# ---- GATE 4: two tenants uploading one file cannot detect each other --------
# Deduplication crosses tenants, and a dedup hit is measurably faster than a
# write - so one account can upload a file, time the response, and learn
# whether another already holds it. For most applications that is
# uninteresting; where possession of a document is itself the confidential
# fact it is a real disclosure.
#
# A namespace per tenant makes the ids disjoint, so there is nothing to
# detect. The timing half is not asserted here - a timing test on a filesystem
# is a flake generator - but the structural property that removes it is, which
# is the honest thing to test.
{
    my $troot = File::Temp::tempdir(CLEANUP => 1);

    package TenantApp;
    use Punk;
    our $TENANT = 'acme';
    plugin 'Blob' => { root      => $troot,
                       namespace => sub { "tenant-$TENANT" } };
    post '/up'        => sub { $_[0]->text($_[0]->blob_put('one secret file')) };
    get  '/get/:id'   => sub { $_[0]->blob_send($_[0]->param('id')) };

    package main;
    my $tapp = TenantApp->to_app;
    my $call = sub {
        my (%o) = @_;
        return $tapp->({ REQUEST_METHOD => $o{method} || 'GET',
                         PATH_INFO => $o{path}, SCRIPT_NAME => '',
                         QUERY_STRING => '', SERVER_NAME => 'l',
                         SERVER_PORT => 80, 'psgi.url_scheme' => 'http',
                         'psgi.input' => undef, 'psgi.errors' => \*STDERR });
    };
    my $up = sub {
        $TenantApp::TENANT = shift;
        return $call->(method => 'POST', path => '/up')->[2][0];
    };

    my $acme   = $up->('acme');
    my $globex = $up->('globex');

    isnt($acme, $globex,
        'THE SAME FILE UNDER TWO TENANTS GETS TWO IDS - so neither can probe '
      . 'for the other\'s, and there is no shared entry whose presence a '
      . 'timing difference could reveal');

    is($up->('acme'), $acme,
        'while the same tenant twice still dedups, which is the half worth '
      . 'keeping');

    is(scalar(grep { -f } glob "$troot/*/*/*"), 2,
        'and the file is stored once PER TENANT - that is the cost of the '
      . 'namespace, and it is the trade being made deliberately');

    # both are independently servable, from whichever tenant is current
    $TenantApp::TENANT = 'acme';
    is($call->(path => "/get/$acme")->[0], 200, 'the acme copy serves');
    $TenantApp::TENANT = 'globex';
    is($call->(path => "/get/$globex")->[0], 200, 'and the globex copy');

    # And the limit of what namespacing buys, asserted rather than assumed.
    #
    # path_for shards on the ID, not on the namespace, so both tenants share
    # one directory tree: a namespace changes which id content maps to, not
    # where a given id lives. An id from another namespace is still readable
    # BY SOMEBODY WHO HAS IT.
    #
    # That is not the hole it looks like - ids are 128 bits and unguessable,
    # and the probe this phase closes is deriving one from content you have.
    # But whether this request may see this blob is authorisation, which this
    # plugin says plainly is the application's job, and the test says so too
    # rather than leaving a comfortable assumption in place.
    $TenantApp::TENANT = 'acme';
    is($call->(path => "/get/$globex")->[0], 200,
        'a known id from another namespace still serves - namespacing makes '
      . 'ids underivable, NOT unreachable, and the difference is exactly '
      . 'where authorisation starts');

    # a namespace callback that answers nothing would silently put this
    # request in somebody else's namespace
    {
        package EmptyNs;
        use Punk;
        plugin 'Blob' => { root => $troot, namespace => sub { '' } };
        post '/up' => sub { $_[0]->text($_[0]->blob_put('x')) };
        package main;
        my $e = EmptyNs->to_app;
        my $r = $e->({ REQUEST_METHOD => 'POST', PATH_INFO => '/up',
                       SCRIPT_NAME => '', QUERY_STRING => '',
                       SERVER_NAME => 'l', SERVER_PORT => 80,
                       'psgi.url_scheme' => 'http', 'psgi.input' => undef,
                       'psgi.errors' => \*STDERR });
        isnt($r->[0], 200,
            'a namespace callback that gives back nothing is refused rather '
          . 'than defaulted, because the default would be another tenant');
    }
}

# ---- the C ABI: both paths must agree ----------------------------------------
#
# Since Punk 0.24 the plugin reaches Apophis through its C ABI (ap_abi.h)
# rather than through method calls - identifying, sharding and writing a blob
# are snprintf and memcpy underneath, and a Perl method call for each of them
# was most of what blob_send cost.
#
# The assertion that matters is not that it is faster. It is that NOTHING
# CHANGED. If the two paths ever derive an id differently, or shard it
# differently, every blob written by one becomes invisible to the other while
# staying perfectly findable by its own - silent, total, and it looks exactly
# like data loss.
#
# Which is why these count FILES. An earlier version of this block asserted
# `-f $store->path_for($id)` after both paths had run, and passed with the
# sharding rule deliberately broken: the Perl store had already written a
# correct copy, so the file was there whatever Punk had done. Two paths
# writing two files is the symptom, and only a count sees it.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $store = Apophis->new(namespace => 'abi-agree', store_dir => $dir);
    my $files = sub { scalar grep { -f } glob "$dir/*/*/*" };

    my $bytes = "a blob that both paths have to agree about\n" x 60;

    # The C path ALONE, before Apophis has written anything here.
    my $c_id = Punk::Plugin::Blob->_store($store, \$bytes);

    ok(-f $store->path_for($c_id),
        'THE PHASE-6 GATE: a blob written through the C ABI lands exactly '
      . 'where path_for looks for it - Punk calls the ABI\'s build_path '
      . 'rather than reimplementing the sharding, and a second copy of that '
      . 'rule is how every blob on disk goes missing the day it changes');

    is(${ $store->fetch($c_id) }, $bytes,
        '...and Apophis reads back exactly the bytes it wrote - the content '
      . 'agrees, not just the name');

    # Now the Perl API on the same content. Same id, and NO second file: if
    # the two disagreed about either, this would be 2.
    is($store->store(\$bytes), $c_id,
        'the id derived through the C ABI is the id Apophis->store derives - '
      . 'two implementations of one algorithm agreeing is something to '
      . 'assert, not to assume');
    is($files->(), 1,
        '...and there is still ONE file, which is the assertion that fails '
      . 'if they shard differently');

    # The other direction: a blob written by the Perl API must be recognised
    # and deduplicated by the C path rather than written again.
    my $other = "written by Apophis, found by Punk\n";
    my $o_id  = $store->store(\$other);
    is(Punk::Plugin::Blob->_store($store, \$other), $o_id,
        'a blob stored through the Perl API dedups through the C path - '
      . 'which is what upgrading an existing store depends on');
    is($files->(), 2,
        '...without writing a second copy of it');
}

# ---- the ABI version guard: a hard boot error, never a silent fallback ------
#
# Apophis 0.05+ is a prerequisite and there is no Perl path to fall back to,
# so an incompatible table has to stop the application at registration rather
# than surface out of the first request that touches a blob.
#
# PUNK_FAKE_AP_BAD makes the C resolver reject the table as if its abi_version
# were too old. Run in a child, because the resolve happens once per process.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    local $ENV{PUNK_FAKE_AP_BAD} = 1;
    my $prog = <<"PROG";
package GuardBlobApp;
use Punk;
plugin 'Blob' => { root => '$dir', namespace => 'guard' };
get '/x' => sub { 1 };
PROG
    my $status = do {
        open my $olderr, '>&', \*STDERR or die;
        open STDERR, '>', File::Spec->devnull or die;
        my $rc = system($^X, '-Mblib', '-e', $prog . '1;');
        open STDERR, '>&', $olderr or die;
        $rc;
    };
    ok($status != 0,
        'a table Punk cannot use stops the app at boot - there is no second '
      . 'implementation to fall back to, and quietly having one would be '
      . 'worse than the croak');
}

# ---- an upload already on disk is stored WITHOUT being read into memory -----
# Phases 1 to 3 of the upload work got a large file from the wire to a temp
# file without it being resident anywhere. Storing it through ->content would
# have undone all of that at the last step - an id derived from the contents
# means the contents must be READ, and reading them into a scalar to hash them
# is exactly the copy that was removed.
#
# Apophis ships identify_fh for this, and says why a consumer must not
# reimplement it: get the chunking or the namespace prefix subtly wrong and
# the ids disagree with every other path. So the assertion that matters is not
# "it stored something" - it is that the id is THE SAME ONE.
{
    my $bytes = join '', map { chr(($_ * 11) % 256) } 1 .. 400_000;

    my $in_memory = Punk::Plugin::Blob->_store($ca, \$bytes);

    my $tmp = "$root/an-upload.bin";
    open my $fh, '>:raw', $tmp or die $!;
    print $fh $bytes;
    close $fh;

    my $upload = bless {
        filename => 'whatever.bin',
        name     => 'f',
        type     => 'application/octet-stream',
        size     => length $bytes,
        path     => $tmp,
    }, 'Punk::Upload';

    my $streamed = Punk::Plugin::Blob->_store($ca, $upload);

    is($streamed, $in_memory,
        'THE SAME ID as the in-memory path produced for the same bytes - if '
      . 'it were not, the streaming hash would be a different hash and every '
      . 'blob stored before this change would be unreachable');
    ok(-e $tmp,
        'and nothing was moved, because those bytes were already stored - '
      . 'this call took the dedup path');
}

# ---- storing something NEW moves the file rather than copying it -------------
{
    my $bytes = join '', map { chr(($_ * 13 + 5) % 256) } 1 .. 300_000;
    my $tmp = "$root/fresh-upload.bin";
    open my $fh, '>:raw', $tmp or die $!;
    print $fh $bytes;
    close $fh;
    my $upload = bless { filename => 'n.bin', name => 'f',
                         size => length $bytes, path => $tmp,
                         type => 'application/octet-stream' },
                 'Punk::Upload';

    my $id = Punk::Plugin::Blob->_store($ca, $upload);
    like($id, qr/\A[0-9a-f-]{36}\z/, 'a new upload stores and gets an id');
    ok(!-e $tmp,
        'and the file was MOVED into the store, not copied - which is the '
      . 'point of putting the spill directory on the same filesystem');

    # and it is really there, whole
    is(Punk::Plugin::Blob->_store($ca, \$bytes), $id,
        'storing the same bytes again finds it - so what was moved is what '
      . 'the id says it is');
}

# ---- a duplicate stores nothing -----------------------------------------------
# The case this is most obviously worth having: one file uploaded by a hundred
# users is stored once, and the ninety-nine after the first move nothing.
{
    my $bytes = 'duplicate me' x 5000;
    my $first = Punk::Plugin::Blob->_store($ca, \$bytes);

    my $tmp = "$root/dup-upload.bin";
    open my $fh, '>:raw', $tmp or die $!;
    print $fh $bytes;
    close $fh;
    my $upload = bless { filename => 'd.bin', name => 'f', size => length $bytes,
                         type => 'application/octet-stream', path => $tmp },
                 'Punk::Upload';

    is(Punk::Plugin::Blob->_store($ca, $upload), $first,
        'a duplicate returns the id already held');
    ok(-e $tmp,
        'and the upload is STILL THERE - nothing was moved, because there was '
      . 'nothing to store. Moving it would have been a write for no reason '
      . 'and would have taken the caller\'s file away from them');
}

# ---- two different files still refuse to share an id --------------------------
# The existing rule, through the new path: a dedup hit reads the stored blob
# and compares, so a collision is a refusal rather than one file being served
# in place of another.
{
    my $bytes = 'collision check' x 1000;
    my $id = Punk::Plugin::Blob->_store($ca, \$bytes);

    # rewrite the stored blob so its contents no longer match its address
    my $path;
    my $walk;
    $walk = sub {
        my ($d) = @_;
        opendir my $dh, $d or return;
        for my $e (grep { !/\A\./ } readdir $dh) {
            my $p = "$d/$e";
            if (-d $p) { $walk->($p) }
            elsif (-f $p && -s $p == length $bytes) {
                open my $r, '<:raw', $p or next;
                local $/;
                $path = $p if <$r> eq $bytes;
                close $r;
            }
        }
        closedir $dh;
    };
    $walk->($root);

    SKIP: {
        skip 'could not locate the stored blob', 1 unless $path;
        open my $w, '>:raw', $path or die $!;
        print $w 'something else entirely';
        close $w;

        my $tmp = "$root/collide-upload.bin";
        open my $fh, '>:raw', $tmp or die $!;
        print $fh $bytes;
        close $fh;
        my $upload = bless { filename => 'c.bin', name => 'f',
                             size => length $bytes, path => $tmp,
                             type => 'application/octet-stream' },
                     'Punk::Upload';

        my $err = do { local $@; eval { Punk::Plugin::Blob->_store($ca, $upload) }; $@ };
        like($err, qr/two DIFFERENT files share the id/,
            'the streaming path compares the stored bytes too - a dedup hit '
          . 'that trusted the id would serve one file in place of another');
    }
}

done_testing;
