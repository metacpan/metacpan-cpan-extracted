# Test origin: AI
use v5.36;
use Test2::V0;
use Cpanel::JSON::XS ();
use lib 't/lib';

use HTTP::Request::Common qw/GET POST/;
use File::Temp ();
use Plack::Test;
use Sys::Hostname ();

use TestRepo qw/make_repo commit_file run_git/;
use TestSplit qw/fill_splits/;
use Review::Helper::Builder;
use Review::Helper::DB;
use Review::Helper::Registry;
use Review::Helper::VCS;
use Review::Helper::Server;
use Review::Helper::Util qw/json_encode json_decode/;

my $HOST = 'http://127.0.0.1:5000';

my $FOO_V1 = join '' => map { "$_\n" } 'package Foo;', 'use v5.36;', '', 'sub new ($class) {', '    return bless {}, $class;', '}', '', q{sub name ($self) { 'foo' }}, '', '1;';
my $FOO_V2 = join '' => map { "$_\n" } 'package Foo;', 'use v5.36;', '', 'sub new ($class) {', '    return bless {}, $class;', '}', '', q{sub name ($self) { 'bar' }}, '',
    'sub greet ($self) {', q{    return 'hi ' . $self->name;}, '}', '', '1;';
my $PNG = "\x89PNG\r\n\x1a\n\0\0\0\rIHDR";

my $dir  = make_repo();
my $c0   = commit_file($dir, 'Start',   'README'     => "hello\n", 'data.bin'       => "x\0y", 'bin/tool'  => "#!/usr/bin/perl\nprint 1;\n");
my $c1   = commit_file($dir, 'Add Foo', 'lib/Foo.pm' => $FOO_V1,   'share/logo.png' => $PNG,   'notes.txt' => "caf\xe9\n");
my $c2   = commit_file($dir, 'Greet',   'lib/Foo.pm' => $FOO_V2);
my $repo = Review::Helper::VCS->detect($dir);
my $file = $repo->state_dir . '/test.sqlite';
my $db   = Review::Helper::DB->create($file, title => 'Test review', source => 'https://example.com/pr/1');
my $dbh  = $db->dbh;

sub insert($table, %row) {
    my @cols = sort keys %row;
    $dbh->do("INSERT INTO $table (" . join(', ' => @cols) . ') VALUES (' . join(', ' => ('?') x @cols) . ')', undef, @row{@cols});
    return $dbh->sqlite_last_insert_rowid;
}

sub insert_file($commit_id, %row) {
    return insert(file_change => (commit_id => $commit_id, size_unit => 'lines', split_source => 'agent', %row));
}

sub insert_section($file_id, $position, $name, $ranges, %row) {
    return insert(section => (file_id => $file_id, position => $position, name => $name, package => 'Foo', ranges => json_encode($ranges), %row));
}

insert(iteration => (number => 1, base => $c0, head => 'f' x 40, pin => 'refs/review-helper/x/1', created => 100));
insert(iteration => (number => 2, base => $c0, head => $c2, pin => 'refs/review-helper/x/2', created => 200, note => 'Second', what => 'W', why => 'Y', how => 'H'));

my $commit1 = insert(commit_entry => (iteration => 2, position => 1, revision => $c1, parent => $c0, subject => 'Add Foo', message => "Add Foo\n", author => 'Tester <tester@example.com>', authored  => 300));
my $commit2 = insert(commit_entry => (iteration => 2, position => 2, revision => $c2, parent => $c1, subject => 'Greet',   message => "Greet\n",   what   => 'Adds greet',                  order_set => 1));

my $foo1  = insert_file($commit1, path => 'lib/Foo.pm',     status => 'A', kind => 'perl',  size_after  => 10,      added      => 10);
my $logo  = insert_file($commit1, path => 'share/logo.png', status => 'A', kind => 'image', size_unit   => 'bytes', size_after => length($PNG), split_source => 'none');
my $notes = insert_file($commit1, path => 'notes.txt',      status => 'A', kind => 'text',  size_after  => 1,       added      => 1,            split_source => 'none');
my $foo2  = insert_file($commit2, path => 'lib/Foo.pm',     status => 'M', kind => 'perl',  size_before => 10,      size_after => 14,           added        => 4, changed => 1, what => 'Adds greet', read_position => 1);

my $s_top   = insert_section($foo2, 1, 'rest', [[1, 3], [7, 7], [9, 9], [13, 14]], changed => 1);
my $s_new   = insert_section($foo2, 2, 'new', [[4, 6]]);
my $s_name  = insert_section($foo2, 3, 'name', [[8, 8]], changed => 1);
my $s_greet = insert_section($foo2, 4, 'greet', [[10, 12]], added => 3, what => 'Says hi');

insert(flag          => (note_id   => 'n1', commit_id => $commit2, path => 'lib/Foo.pm', line_start => 10, line_end => 12, color => 'yellow', color_reason => 'Fixed in the next commit.', kind => 'deviation', sentence => 'Check greet.', created => 400));
insert(journal_entry => (id        => 'j1', iteration => 2, kind   => 'note',  path => 'lib/Foo.pm', unit     => 'greet', sentence => 'Greet stays short.', detail => 'Kept to one line.', created => 410));
insert(journal_entry => (id        => 'j0', iteration => 1, kind   => 'other', path => 'notes.txt',  sentence => 'Only in iteration 1.', created => 300));
insert(guide_step    => (iteration => 2,    position  => 1, target => '{"type":"summary"}', highlight => '[]', commentary => 'Start here.'));

my $ANN  = "Ann \x{c5}berg <ann\@example.com>";
my $app  = Review::Helper::Server->new(db_path => $file, reviewer => $ANN)->to_app;
my $test = Plack::Test->create($app);

sub request($req) { $test->request($req) }

sub get_json($path) {
    my $res = request(GET "$HOST$path");
    is($res->code, 200, "GET $path") or diag($res->content);
    return json_decode($res->content);
}

sub post_json($path, $data) {
    my $res = request(POST "$HOST$path", 'Content-Type' => 'application/json', Content => json_encode($data));
    return ($res->code, json_decode($res->content));
}

subtest access => sub {
    my $res = request(GET 'http://evil.example.com/api/review');
    is($res->code, 403, 'foreign host refused');
    like($res->content, qr/127\.0\.0\.1, localhost or an allowed host/, 'says why');

    is(request(GET 'http://localhost/api/review')->code,      200, 'localhost accepted');
    is(request(GET 'http://LOCALHOST:8080/api/review')->code, 200, 'localhost with a port accepted');
    is(request(GET "$HOST/api/review")->code,                 200, '127.0.0.1 with a port accepted');

    my $bad = GET "$HOST/api/review";
    $bad->header(Host => '127.0.0.1.evil.example.com');
    is(request($bad)->code, 403, 'a host that only starts like 127.0.0.1 is refused');

    $res = request(GET "$HOST/?token=anything");
    is($res->code,                 200,   'no token is needed, and a stale token URL still opens the page');
    is($res->header('Set-Cookie'), undef, 'no cookie is set');

    is(request(GET "$HOST/nowhere")->code,     404, 'unknown route');
    is(request(POST "$HOST/api/review")->code, 404, 'wrong method');

    my $host = sub ($test, $name) {
        my $req = GET "$HOST/api/review";
        $req->header(Host => $name);
        return $test->request($req)->code;
    };
    is($host->($test, '[::1]:5000'),        200, '[::1] accepted');
    is($host->($test, '[0:0:0:0:0:0:0:1]'), 200, 'in any spelling');
    is($host->($test, 'dev1'),              403, 'loopback-only mode refuses other names');
    is($host->($test, '[::1'),              403, 'a broken IPv6 host is refused');
    is($host->($test, '::1'),               403, 'an IPv6 host needs its brackets');
};

subtest allow_hosts => sub {
    my $server = Review::Helper::Server->new(db_path => $file, reviewer => $ANN, allow_hosts => ['dev1', 'Dev1.Example.COM', '10.1.2.3', '[2001:DB8:0::5]']);
    my $wide   = Plack::Test->create($server->to_app);
    my $code   = sub ($name) {
        my $req = GET "$HOST/api/review";
        $req->header(Host => $name);
        return $wide->request($req)->code;
    };
    is($code->('dev1:8080'),             200, 'a hostname');
    is($code->('dev1.example.com'),      200, 'an FQDN, in any case');
    is($code->('10.1.2.3:8080'),         200, 'an address');
    is($code->('[2001:db8::5]:8080'),    200, 'an IPv6 address, in any spelling');
    is($code->('127.0.0.1:8080'),        200, 'loopback still accepted');
    is($code->('localhost'),             200, 'localhost still accepted');
    is($code->('evil.example.com'),      403, 'other hosts refused');
    is($code->('dev1.evil.example.com'), 403, 'a host that only starts like an allowed one is refused');
    is($code->('10.1.2.4'),              403, 'other addresses refused');

    my $res = $wide->request(POST "$HOST/api/close", Host => 'dev1:8080', 'Content-Type' => 'application/json', Origin => 'http://evil.example.com', Content => '{}');
    is($res->code, 403, 'an allowed host still needs a matching Origin');
    $res = $wide->request(POST "$HOST/api/flag/1", Host => 'dev1:8080', 'Content-Type' => 'application/json', Origin => 'http://127.0.0.1:8080', Content => '{"seen":false}');
    is($res->code, 403, 'including an Origin naming another allowed host');
    $res = $wide->request(POST "$HOST/api/flag/1", Host => 'dev1:8080', 'Content-Type' => 'application/json', Origin => 'http://dev1:8080', Content => '{"seen":false}');
    is($res->code, 200, 'a same-host Origin passes');
};

subtest token => sub {
    ok(Review::Helper::Server->is_loopback($_),     "$_ is loopback")     for qw/127.0.0.1 127.0.0.2 ::1 ::ffff:127.0.0.1/;
    ok(!Review::Helper::Server->is_loopback($_),    "$_ is not loopback") for qw/0.0.0.0 :: 10.0.0.1 ::2 fe80::1 ::ffff:10.0.0.1/;
    ok(!Review::Helper::Server->is_loopback(undef), 'no address is not loopback');

    my $token = 'ab' x 32;
    my $from  = sub ($server, $addr) {
        my $app = $server->to_app;
        return Plack::Test->create(sub ($env) {
            $app->({%$env, REMOTE_ADDR => $addr});
        });
    };
    my $server = Review::Helper::Server->new(db_path => $file, reviewer => $ANN, allow_hosts => ['dev1'], token => $token);
    my $remote = $from->($server, '192.0.2.7');
    my $get    = sub ($url, @headers) { $remote->request(GET $url, Host => 'dev1:5000', @headers) };

    my $res = $get->("$HOST/api/review");
    is($res->code, 401, 'another machine needs the token');
    like($res->content, qr/Open the URL review-helper printed/, 'and is told where to find it');
    is($get->("$HOST/?token=" . ('ab' x 31) . 'ac')->code, 401, 'a wrong token is refused');
    is($get->("$HOST/?token=ab")->code,                    401, 'so is a short one');

    $res = $get->("$HOST/?token=$token");
    is($res->code,                 303,                                                    'the token URL logs in');
    is($res->header('Location'),   '/',                                                    'and goes to the page without the token');
    is($res->header('Set-Cookie'), "rh_token_5000=$token; Path=/; HttpOnly; SameSite=Lax", 'setting a cookie for this port');
    $res = $get->("$HOST/api/review?iteration=2&token=$token&x=1");
    is($res->header('Location'), '/', 'from any path and query');
    for my $path ('//evil.example.com/', '/%2F%2Fevil.example.com/', '/%0d%0aX-Evil:%201', '/tok%65n') {
        $res = $get->("$HOST$path?tok%65n=$token");
        is([$res->code, scalar $res->header('Location'), scalar $res->header('X-Evil')], [303, '/', undef], "$path goes to the page, nothing of it in Location");
    }

    my $cookie = "rh_token_5000=$token";
    is($get->("$HOST/api/review", Cookie => $cookie)->code,                        200, 'the cookie lets that machine in');
    is($get->("$HOST/api/review", Cookie => "rh_token_5001=$token")->code,         401, "another port's cookie does not");
    is($get->("$HOST/api/review", Cookie => "rh_token_5000=" . ('cd' x 32))->code, 401, 'nor a wrong one');

    is($remote->request(GET "$HOST/api/review", Host => 'evil.example.com', Cookie => $cookie)->code, 403, 'the Host check still applies');
    $res = $remote->request(POST "$HOST/api/close", Host => 'dev1:5000', Cookie => $cookie, 'Content-Type' => 'application/json', Origin => 'http://evil.example.com', Content => '{}');
    is($res->code, 403, 'and so does the Origin check');

    is($from->($server, $_)->request(GET "$HOST/api/review")->code,             200, "loopback ($_) needs no token") for qw/127.0.0.1 ::1 ::ffff:127.0.0.1/;
    is($from->($server, '127.0.0.1')->request(GET "$HOST/?token=$token")->code, 200, 'nor logs in with one');

    my $mock     = mock 'Review::Helper::Server' => (override => [api_review => sub { die "Broke at /secret/path line 1.\n" }]);
    my $warnings = warnings {
        $res = $get->("$HOST/api/review", Cookie => $cookie);
        is([$res->code, json_decode($res->content)], [500, {error => 'Internal error; the details are in the server output'}], 'beyond loopback, an internal error hides its details');
        $res = $from->($server, '127.0.0.1')->request(GET "$HOST/api/review");
        is([$res->code, json_decode($res->content)], [500, {error => "Internal error: Broke at /secret/path line 1.\n"}], 'loopback sees them');
    };
    is($warnings, ["Broke at /secret/path line 1.\n", "Broke at /secret/path line 1.\n"], 'both go to the server output');
    $mock = undef;

    my $open = Review::Helper::Server->new(db_path => $file, reviewer => $ANN);
    is($from->($open, '192.0.2.7')->request(GET "$HOST/api/review")->code, 200, 'without a token (loopback-only serving) nothing is asked');
};

subtest static => sub {
    my $res = request(GET "$HOST/");
    is($res->code, 200, 'index');
    like($res->header('Content-Type'), qr{^text/html},            'index is HTML');
    like($res->content,                qr{<script type="module"}, 'the page');

    $res = request(GET "$HOST/static/js/app.js");
    is([$res->code, $res->header('Content-Type')], [200, 'text/javascript; charset=utf-8'], 'JavaScript modules get text/javascript');

    $res = request(GET "$HOST/static/css/review.css");
    is([$res->code, $res->header('Content-Type')], [200, 'text/css; charset=utf-8'], 'CSS');

    is(request(GET "$HOST/static/js/missing.js")->code,   404, 'missing asset');
    is(request(GET "$HOST/static/html/index.html")->code, 200, 'the page shell is an asset too');

    # Each of these names ux/css/review.css, which exists, by a route through '..'.
    is(request(GET "$HOST/static/js/%2e%2e/css/review.css")->code, 404, 'encoded .. refused');
    is(request(GET "$HOST/static/js/..%2Fcss%2Freview.css")->code, 404, 'encoded slash .. refused');

    is(request(GET "$HOST/static/AGENTS.md")->code,        404, 'files beside the assets are not served');
    is(request(GET "$HOST/static/t/logic.test.mjs")->code, 404, 'nor the page\'s tests');
    is(request(GET "$HOST/static/js")->code,               404, 'a directory is not a file');
};

subtest review => sub {
    my $data = get_json('/api/review');
    is(
        $data,
        {
            standard_version => 1,
            review           => {id   => $db->review->{id},    title => 'Test review',             source => 'https://example.com/pr/1', state    => 'open'},
            identity         => {user => scalar(getpwuid($<)), host  => Sys::Hostname::hostname(), repo   => $dir,                       reviewer => $ANN},
            iteration        => 2,
            iterations       => [
                {number => 1, base => $c0, head => 'f' x 40, created => 100, note => undef,    available => F()},
                {number => 2, base => $c0, head => $c2,      created => 200, note => 'Second', available => T()},
            ],
            summary => {what => 'W', why => 'Y', how => 'H'},
            commits => [
                {
                    id     => $commit1, revision => $c1, parent => $c0, position => 1, merge_id => undef, topic => undef, subject => 'Add Foo', message => "Add Foo\n",
                    author => 'Tester <tester@example.com>', authored => 300, what => undef, why => undef, how => undef, order_set => 0, resolution => F(),
                    files  => [
                        {
                            id            => $foo1,   path       => 'lib/Foo.pm', old_path      => undef, status    => 'A', kind    => 'perl', size_unit     => 'lines',
                            size_before   => undef,   size_after => 10,           added         => 10,    removed   => 0,   changed => 0,      read_position => undef,
                            split_source  => 'agent', what       => undef,        object_system => undef, paradigms => undef,
                            section_names => array {
                                all_items hash { field name => T(); field package => E(); end() };
                                etc()
                            },
                        },
                        hash { field id => $logo;  field kind => 'image'; etc() },
                        hash { field id => $notes; field kind => 'text';  etc() },
                    ],
                },
                hash {
                    field id        => $commit2;
                    field revision  => $c2;
                    field order_set => 1;
                    field files     => [hash { field id => $foo2; field read_position => 1; field what => 'Adds greet'; etc() }];
                    etc();
                },
            ],
            flags => [{
                id    => 1,        note_id      => 'n1',                        commit => $c2,         entry    => $commit2,       path   => 'lib/Foo.pm', line_start => 10,  line_end => 12,
                color => 'yellow', color_reason => 'Fixed in the next commit.', kind   => 'deviation', sentence => 'Check greet.', detail => undef,        pending    => F(), seen     => [],
            }],
            guide         => [{position => 1, target => {type => 'summary'}, highlight => [], commentary => 'Start here.'}],
            journal       => [{id => 'j1', kind => 'note', path => 'lib/Foo.pm', unit => 'greet', sentence => 'Greet stays short.', detail => 'Kept to one line.', created => 410}],
            content_kinds => {},
            feedback      => [],
            requests      => [],
        },
        'review shape',
    );

    $data = get_json('/api/review?iteration=1');
    is([$data->{iteration}, $data->{commits}, $data->{flags}, $data->{guide}], [1, [], [], []], 'an earlier iteration');
    is([map { $_->{id} } @{$data->{journal}}],                                 ['j0'],          "with only that iteration's journal");

    is(request(GET "$HOST/api/review?iteration=9")->code, 404, 'unknown iteration');
    is(request(GET "$HOST/api/review?iteration=x")->code, 400, 'bad iteration');
};

subtest file => sub {
    my $data = get_json("/api/file/$foo2");
    is(
        $data,
        {
            file     => hash { field id => $foo2; field path => 'lib/Foo.pm'; field status => 'M'; etc() },
            commit   => $c2,
            parent   => $c1,
            sections => [
                hash { field id => $s_top;  field name => 'rest'; field ranges => [[1, 3], [7, 7], [9, 9], [13, 14]]; etc() },
                hash { field id => $s_name; field name => 'name'; etc() },
                {
                    id         => $s_greet, position => 4, name => 'greet', package => 'Foo', ranges => [[10, 12]],
                    doc_ranges => [], old_ranges => [], deleted => 0, added => 3, removed => 0, changed => 0, what => 'Says hi',
                },
            ],
        },
        'file shape; the untouched section (new) is not shown',
    );

    is(request(GET "$HOST/api/file/999")->code, 404, 'unknown file');
};

subtest blob => sub {
    my $res = request(GET "$HOST/api/content/$c2/lib/Foo.pm");
    is([$res->code, $res->header('Content-Type'), $res->content], [200, 'text/plain; charset=utf-8', $FOO_V2], 'text content');
    is($res->header('Content-Security-Policy'),                   'sandbox',                                   'sandboxed');
    is($res->header('X-Content-Type-Options'),                    'nosniff',                                   'no sniffing');

    is(request(GET "$HOST/api/content/$c1/lib/Foo.pm")->content, $FOO_V1, 'content at an earlier commit');

    $res = request(GET "$HOST/api/content/$c1/share/logo.png");
    is([$res->code, $res->header('Content-Type'), $res->content], [200, 'image/png', $PNG], 'image by extension, raw bytes');

    is(request(GET "$HOST/api/content/$c2/lib")->code,                   404, 'a directory is not a file');
    is(request(GET "$HOST/api/content/$c0/lib/Foo.pm")->code,            404, 'absent at that commit');
    is(request(GET "$HOST/api/content/" . ('0' x 40) . '/README')->code, 404, 'unknown commit');
    is(request(GET "$HOST/api/content/$c2/lib/%2e%2e/README")->code,     404, '.. refused');
};

subtest diff => sub {
    my $data = get_json("/api/diff/$foo2");
    is($data->{binary}, F(), 'text diff');
    is(
        $data->{hunks},
        array {
            all_items hash { field old_start => D(); field old_count => D(); field new_start => D(); field new_count => D(); field lines => D(); end() };
            etc()
        },
        'hunk shape',
    );

    my @lines = map { @{$_->{lines}} } @{get_json("/api/diff/$foo2?section=$s_greet")->{hunks}};
    is([map { [$_->{type}, $_->{new}] } @lines], [['+', 10], ['+', 11], ['+', 12]], 'section diff keeps only its lines');

    @lines = map { @{$_->{lines}} } @{get_json("/api/diff/$foo2?section=$s_name")->{hunks}};
    is([grep { $_->{type} eq '-' } @lines], [hash { field old => 8; etc() }], 'a removed line goes with the section after it');

    is(get_json("/api/diff/$foo2?section=$s_new")->{hunks}, [], 'context alone leaves no hunk');

    my $ranges = sub ($sid) { [map { [@{$_}{qw/old_start old_count new_start new_count/}] } @{get_json("/api/diff/$foo2?section=$sid")->{hunks}}] };
    is($ranges->($s_greet), [[8, 0, 10, 3]], 'a section hunk spans only its own lines');
    is($ranges->($s_name),  [[8, 1, 8,  1]], 'a changed line keeps both sides');

    # A section with several ranges shows each.
    my $top = get_json("/api/diff/$foo2?section=$s_top")->{hunks};
    is(
        [map { [map { $_->{type} . $_->{new} } @{$_->{lines}}] } @$top],
        [[' 1', ' 2', ' 3'], [' 7'], ['+9'], [' 13', ' 14']],
        'every line of a section with several ranges, one hunk per range',
    );

    is(get_json("/api/diff/$logo")->{binary}, T(), 'binary diff');

    my ($line) = map { @{$_->{lines}} } @{get_json("/api/diff/$notes")->{hunks}};
    is($line->{text}, "caf\x{FFFD}", 'invalid UTF-8 is replaced, not fatal');

    is(request(GET "$HOST/api/diff/$foo1?section=$s_greet")->code, 404, 'section of another file');
    is(request(GET "$HOST/api/diff/$foo2?section=x")->code,        400, 'bad section id');
};

subtest feedback => sub {
    my %file = (commit => $c2, path => 'lib/Foo.pm');
    my @good = (
        {target => 'review',  body   => 'Overall fine.'},
        {target => 'commit',  commit => $c1, body => 'Commit note.'},
        {target => 'file',    %file, body    => 'File note.'},
        {target => 'section', %file, section => {name => 'greet', package => 'Foo'}, body => 'Section note.'},
        {target => 'line',    %file, line    => 11, side => 'new', body    => 'Line note.'},
        {target => 'line',    %file, line    => 8,  side => 'old', section => {name => 'name', package => 'Foo'}, body => 'Old line.', iteration => 2},
    );
    my @ids = map { my ($code, $out) = post_json('/api/feedback', $_); is($code, 200, "add $_->{target} feedback"); $out->{id} } @good;
    is(\@ids, [1 .. 6], 'ids returned');

    my %bad = (
        'unknown target'      => {target => 'nope', body => 'x'},
        'missing body'        => {target => 'review'},
        'blank body'          => {target => 'review', body   => '  '},
        'body not a string'   => {target => 'review', body   => [1]},
        'unknown commit'      => {target => 'commit', commit => $c0, body => 'x'},
        'commit not a string' => {target => 'commit', commit => {},  body => 'x'},
        'unchanged path'      => {target => 'file', commit => $c2, path => 'README', body => 'x'},
        'missing section'     => {target => 'section', %file, body => 'x'},
        'unknown section'     => {target => 'section', %file, section => {name => 'nope', package => 'Foo'}, body => 'x'},
        'wrong package'       => {target => 'section', %file, section => {name => 'greet', package => 'Bar'}, body => 'x'},
        'missing line'        => {target => 'line', %file, side => 'new', body => 'x'},
        'zero line'           => {target => 'line', %file, line => 0, side => 'new',  body => 'x'},
        'bad side'            => {target => 'line', %file, line => 3, side => 'both', body => 'x'},
        'unknown iteration'   => {target => 'review', iteration => 7, body => 'x'},
        'wrong iteration'     => {target => 'commit', commit => $c1, iteration => 1, body => 'x'},
    );
    for my $name (sort keys %bad) {
        my ($code, $out) = post_json('/api/feedback', $bad{$name});
        ok($code == 400 || $code == 404, "rejects $name ($code)");
        like($out->{error}, qr/\S/, "message for $name");
    }

    my ($untouched_code, $untouched) = post_json('/api/feedback', {target => 'section', %file, section => {name => 'new', package => 'Foo'}, body => 'x'});
    is([$untouched_code, $untouched->{error}], [400, "'lib/Foo.pm' has no section 'new' with a change to show"], 'an untouched section, which the page does not show, takes no feedback');

    my $res = request(POST "$HOST/api/feedback", 'Content-Type' => 'application/json', Content => 'not json');
    is($res->code, 400, 'non-JSON body');
    $res = request(POST "$HOST/api/feedback", 'Content-Type' => 'application/json', Content => '[1]');
    is($res->code, 400, 'JSON that is not an object');

    my ($code, $out) = post_json('/api/feedback/2', {status => 'declined', body => 'Commit note, edited.'});
    is([$code, $out], [200, {}], 'edit feedback');
    ($code) = post_json('/api/feedback/2', {status => 'nope'});
    is($code, 400, 'bad status');
    ($code) = post_json('/api/feedback/2', {});
    is($code, 400, 'nothing to change');
    ($code) = post_json('/api/feedback/99', {status => 'open'});
    is($code, 404, 'unknown feedback');

    my $export = get_json('/api/feedback');
    is(
        $export,
        {
            format         => 'review-feedback',
            format_version => 1,
            review         => $db->review->{id},
            source         => 'https://example.com/pr/1',
            iteration      => 2,
            base           => $c0,
            head           => $c2,
            feedback       => [
                {id => 1, iteration => 2, target => 'review', commit => undef, topic => undef, path => undef, section => undef, flag => undef, line => undef, side => undef, body => 'Overall fine.', status => 'open', response => undef, resolved_in => undef, published => undef, reviewer => $ANN},
                hash { field id => 2; field commit  => $c1;                                 field body    => 'Commit note, edited.'; field status => 'declined'; etc() },
                hash { field id => 3; field path    => 'lib/Foo.pm';                        field section => undef;                  etc() },
                hash { field id => 4; field section => {name => 'greet', package => 'Foo'}; etc() },
                hash { field id => 5; field line    => 11;                                  field side => 'new'; etc() },
                hash { field id => 6; field line    => 8;                                   field side => 'old'; field section => {name => 'name', package => 'Foo'}; etc() },
            ],
            requests => [],
        },
        'feedback export',
    );

    is(get_json('/api/review')->{feedback},             $export->{feedback}, 'the review carries the same feedback');
    is(get_json('/api/review?iteration=1')->{feedback}, $export->{feedback}, 'from every iteration, whichever is selected');
};

subtest requests => sub {
    my ($code, $out) = post_json('/api/request', {kind => 'debate', target => 'review', note => 'Is this needed?'});
    is([$code, $out], [200, {id => 1}], 'debate the review');
    ($code, $out) = post_json('/api/request', {kind => 'split', target => 'file', commit => $c1, path => 'notes.txt'});
    is([$code, $out], [200, {id => 2}], 'split a file');
    ($code, $out) = post_json('/api/request', {kind => 'debate', target => 'section', commit => $c2, path => 'lib/Foo.pm', section => {name => 'greet', package => 'Foo'}});
    is([$code, $out], [200, {id => 3}], 'debate a section');
    my ($untouched_code, $untouched) = post_json('/api/request', {kind => 'debate', target => 'section', commit => $c2, path => 'lib/Foo.pm', section => {name => 'new', package => 'Foo'}});
    is([$untouched_code, $untouched->{error}], [400, "'lib/Foo.pm' has no section 'new' with a change to show"], 'nor a debate');

    ($code, $out) = post_json('/api/request', {kind => 'split', target => 'commit', commit => $c1});
    is([$code, $out->{error}], [400, "A 'split' request must target a file"], 'splits need a file');
    ($code, $out) = post_json('/api/request', {kind => 'split', target => 'file', commit => $c1, path => 'share/logo.png'});
    is([$code, $out->{error}], [400, "'share/logo.png' has no lines to split: it is deleted, an image, or binary"], 'an image cannot be split');
    my $gone = insert_file($commit2, path => 'gone.txt', status => 'D', kind => 'text', size_before => 2, size_after => undef, removed => 2, split_source => 'none');
    ($code, $out) = post_json('/api/request', {kind => 'split', target => 'file', commit => $c2, path => 'gone.txt'});
    is([$code, $out->{error}], [400, "'gone.txt' has no lines to split: it is deleted, an image, or binary"], 'a deleted file cannot be split');
    $dbh->do('DELETE FROM file_change WHERE id = ?', undef, $gone);
    my $moved = insert_file($commit2, path => 'moved.txt', old_path => 'was.txt', status => 'R', kind => 'text', size_before => 2, size_after => 2, split_source => 'none');
    ($code, $out) = post_json('/api/request', {kind => 'split', target => 'file', commit => $c2, path => 'moved.txt'});
    is([$code, $out->{error}], [400, "'moved.txt' has nothing to split: a rename or mode change alone leaves its content as it was"], 'a file only renamed cannot be split: no sheet would ever list it');
    $dbh->do('DELETE FROM file_change WHERE id = ?', undef, $moved);
    ($code) = post_json('/api/request', {kind => 'vote', target => 'review'});
    is($code, 400, 'unknown kind');
    ($code) = post_json('/api/request', {kind => 'debate', target => 'line', commit => $c1});
    is($code, 400, 'requests cannot target a line');
    ($code) = post_json('/api/request', {kind => 'debate', target => 'review', note => ''});
    is($code, 400, 'an empty note');

    is(
        get_json('/api/feedback')->{requests},
        [
            {id => 1, iteration => 2, kind => 'debate', target => 'review', commit => undef, topic => undef, path => undef, section => undef, note => 'Is this needed?', status => 'open', case_for => undef, case_against => undef, reviewer => $ANN},
            hash { field id => 2; field kind    => 'split';                             field path => 'notes.txt'; field note => undef; etc() },
            hash { field id => 3; field section => {name => 'greet', package => 'Foo'}; etc() },
        ],
        'requests exported',
    );
};

subtest published => sub {
    $dbh->do('UPDATE feedback SET published = 1 WHERE id = 1');
    my $feedback = get_json('/api/review')->{feedback};
    is([map { $_->{published} } @$feedback[0, 1]], [1, undef], 'published passed through');
};

subtest cross_origin => sub {
    my $res = request(POST "$HOST/api/close", 'Content-Type' => 'text/plain', Content => '{}');
    is($res->code, 415, 'a text/plain POST is refused');
    $res = request(POST "$HOST/api/close", Content => [x => 1]);
    is($res->code, 415, 'a form POST is refused');
    $res = request(POST "$HOST/api/close");
    is($res->code, 415, 'a POST with no body type is refused');

    $res = request(POST "$HOST/api/close", 'Content-Type' => 'application/json', Origin => 'http://127.0.0.1:3000', Content => '{}');
    is($res->code, 403, 'a POST from another origin is refused');
    like($res->content, qr/Cross-origin/, 'says why');

    is(Review::Helper::DB->open($file)->review->{state}, 'open', 'none of them closed the review');

    ($res) = request(POST "$HOST/api/feedback/1", 'Content-Type' => 'application/json; charset=utf-8', Origin => 'http://127.0.0.1:5000', Content => '{"status":"open"}');
    is($res->code, 200, 'same origin with a charset is accepted');
};

subtest content_kinds => sub {
    my $view = sub ($position, $commit, $path) {
        insert(guide_step => (iteration => 2, position => $position, target => json_encode({type => 'view', commit => $commit, path => $path, lines => [1, 1]}), commentary => 'A view.'));
    };
    $view->(2 + $_->[0], @$_[1, 2]) for [0, $c2, 'README'], [1, $c2, 'share/logo.png'], [2, $c2, 'data.bin'], [3, $c2, 'bin/tool'], [4, $c2, 'nope.txt'], [5, $c2, 'lib/Foo.pm'], [6, $c1, 'README'];
    insert(flag => (note_id => 'n2', commit_id => $commit2, path => 'notes.txt', line_start => 1, line_end => 1, color => 'yellow', kind => 'note', sentence => 'Unchanged here.', created => 400));

    is(
        get_json('/api/review')->{content_kinds},
        {
            "$c2:README"         => 'text',
            "$c2:share/logo.png" => 'image',
            "$c2:data.bin"       => 'binary',
            "$c2:bin/tool"       => 'perl',
            "$c2:nope.txt"       => undef,
            "$c2:notes.txt"      => 'text',
            "$c1:README"         => 'text',
        },
        'each file shown whole at a commit that did not change it, with the kind a file change would get; none for a file the commit changed',
    );

    my $reads = 0;
    my $mock  = mock 'Review::Helper::VCS::Git' => (override => [file => sub { $reads++; die "git cat-file failed\n" }]);
    $view->(9, $c1, 'bin/tool');
    my $kinds = get_json('/api/review')->{content_kinds};
    is([@$kinds{"$c2:share/logo.png", "$c2:bin/tool", "$c1:bin/tool", "$c2:nope.txt"}], ['image', 'perl', 'text', 'text'], 'kinds found are kept; a git failure gives plain text rather than failing the load');
    is($reads,                                                                          2,                                 'git is read again only for what is not known: the new file and the absent one');
    $mock = undef;
    is(get_json('/api/review')->{content_kinds}->{"$c1:bin/tool"}, 'perl', 'a failure is not kept');
    $dbh->do('DELETE FROM guide_step WHERE position > 1');
    $dbh->do(q{DELETE FROM flag WHERE note_id = 'n2'});
};

subtest non_ascii_guide => sub {
    my $path = "lib/Caf\x{e9}.pm";
    my $json = Cpanel::JSON::XS->new->canonical;    # columns hold character strings
    insert(guide_step => (iteration => 2, position => 2, target => $json->encode({type => 'view', commit => $c2, path => $path, lines => [1, 2]}), highlight => $json->encode([{path => $path, side => 'new', lines => [1, 1]}]), commentary => 'Caf\x{e9}.'));
    my $res = request(GET "$HOST/api/review");
    is($res->code, 200, 'a guide naming a non-ASCII path still serves');
    my $step = json_decode($res->content)->{guide}[1];
    is([$step->{target}{path}, $step->{highlight}[0]{path}], [$path, $path], 'paths come back intact');
    $dbh->do('DELETE FROM guide_step WHERE position = 2');
};

subtest close => sub {
    my $mock = mock 'Review::Helper::VCS::Git' => (override => [find => sub { die "looked the repository up again\n" }]);
    my ($code, $out) = post_json('/api/close', {});
    $mock = undef;
    is([$code, $out],                                                              [200, {}],                          'close, through the server\'s repository');
    is(Review::Helper::DB->open($file)->review->{state},                           'closed',                           'closed in the file');
    is(get_json('/api/review')->{review}{state},                                   'closed',                           'the page sees it');
    is(Review::Helper::Registry->new(repo => $repo)->reviews->{$db->review->{id}}, {path => $file, state => 'closed'}, 'closed in the registry');
};

# A merge resolved by hand, and a clean one, each bringing in one commit.
subtest resolution => sub {
    my $mdir = make_repo();
    my $m0   = commit_file($mdir, 'Start', 'f.txt' => "a\nb\nc\n", 'g.txt' => "x\n");
    run_git($mdir, qw/checkout -q -b side/);
    my $side = commit_file($mdir, 'Side', 'f.txt' => "a\nB-side\nc\n");
    run_git($mdir, qw/checkout -q main/);
    my $main = commit_file($mdir, 'Main', 'f.txt' => "a\nB-main\nc\n");
    ok(!eval { run_git($mdir, qw/merge -q side/); 1 }, 'the merge conflicts');
    my $conflicted = commit_file($mdir, 'Merge side', 'f.txt' => "a\nB-both\nc\n");
    run_git($mdir, qw/checkout -q -b other/, $m0);
    my $other = commit_file($mdir, 'Other', 'h.txt' => "z\n");
    run_git($mdir, qw/checkout -q main/);
    run_git($mdir, qw/merge -q --no-ff -m/, 'Merge other', 'other');
    my $clean = run_git($mdir, qw/rev-parse HEAD/) =~ s/\n//r;

    my $mrepo = Review::Helper::VCS->detect($mdir);
    my $mfile = $mrepo->state_dir . '/merge.sqlite';
    my $mdb   = Review::Helper::DB->create($mfile, title => 'Merges');
    my $mdbh  = $mdb->dbh;
    $mdbh->do('INSERT INTO iteration (number, base, head, pin, created) VALUES (1, ?, ?, ?, 1)', undef, $m0, $clean, 'refs/review-helper/m/1');
    my $add = sub ($position, $revision, $subject, $merge_id = undef) {
        $mdbh->do('INSERT INTO commit_entry (iteration, position, revision, subject, message, merge_id) VALUES (1, ?, ?, ?, ?, ?)', undef, $position, $revision, $subject, "$subject\n", $merge_id);
        return $mdbh->sqlite_last_insert_rowid;
    };
    my $id_main       = $add->(1, $main,       'Main');
    my $id_conflicted = $add->(3, $conflicted, 'Merge side');
    $add->(2, $side, 'Side', $id_conflicted);
    my $id_clean = $add->(5, $clean, 'Merge other');
    $add->(4, $other, 'Other', $id_clean);

    my $mtest = Plack::Test->create(Review::Helper::Server->new(db_path => $mfile)->to_app);
    my $mget  = sub ($path) { $mtest->request(GET "$HOST$path") };
    my $none  = {Main => F(), Side => F(), 'Merge side' => F(), Other => F(), 'Merge other' => F()};

    SKIP: {
        skip 'remerge diffs need git 2.36', 10 unless $mrepo->_has_remerge_diff;

        my $calls  = 0;
        my $count  = mock 'Review::Helper::VCS::Git' => (around => [resolution_changes => sub ($orig, @args) { $calls++; $orig->(@args) }]);
        my $review = json_decode($mget->('/api/review')->content);
        is({map { ($_->{subject} => $_->{resolution}) } @{$review->{commits}}}, {%$none, 'Merge side' => T()}, 'only the merge resolved by hand has a resolution');
        ok($calls, 'the review computes remerge diffs');

        my $res = $mget->("/api/resolution/$id_conflicted");
        is($res->code, 200, 'remerge diff of the conflicted merge');
        my $data = json_decode($res->content);
        is([$data->{commit}, [map { [@{$_}{qw/path old_path status/}, $_->{binary}] } @{$data->{files}}]], [$conflicted, [['f.txt', undef, 'M', F()]]], 'one file');
        my @lines = map { "$_->{type}$_->{text}" } map { @{$_->{lines}} } @{$data->{files}[0]{hunks}};
        ok((grep { $_ eq '+B-both' } @lines), 'the resolution is added');
        ok((grep { m/^-<<<<<<< / } @lines),   'over the conflict markers');
        ok((grep { $_ eq '-B-main' } @lines), 'and both sides');

        is(json_decode($mget->("/api/resolution/$id_clean")->content)->{files}, [], 'a clean merge has no resolutions');

        my $before = $calls;
        my $looked = 0;
        my $probe  = mock 'Review::Helper::VCS::Git' => (around => [has_revision => sub ($orig, $self, $revision) { $looked++ if $revision eq $conflicted; $self->$orig($revision) }]);
        $mget->('/api/review');
        is($looked, 0, 'a cached merge is not looked up in git again');
        $mget->("/api/resolution/$id_conflicted");
        is($calls, $before, 'remerge diffs are computed once per server');
    }

    is($mget->("/api/resolution/$id_main")->code, 404, 'a plain commit is not a merge');
    is($mget->('/api/resolution/999')->code,      404, 'unknown commit');

    # An imported iteration whose merge was never fetched.
    my $absent = 'e' x 40;
    $mdbh->do('INSERT INTO iteration (number, base, head, pin, created) VALUES (2, ?, ?, ?, 2)',                   undef, $absent, $absent,        'refs/review-helper/m/2');
    $mdbh->do('INSERT INTO commit_entry (iteration, position, revision, subject, message) VALUES (2, 1, ?, ?, ?)', undef, $absent, 'Absent merge', "Absent merge\n");
    my $id_absent = $mdbh->sqlite_last_insert_rowid;
    my $ares      = $mget->('/api/review?iteration=2');
    is($ares->code,                                                                             200,                     'a review whose merge is not here loads');
    is({map { ($_->{subject} => $_->{resolution}) } @{json_decode($ares->content)->{commits}}}, {'Absent merge' => F()}, 'with no resolution');
    is($mget->("/api/resolution/$id_absent")->code,                                             404,                     'and no remerge diff');

    my $old   = mock 'Review::Helper::VCS::Git' => (override => [_git => sub ($self, @args) { $args[0] eq 'version' ? "git version 2.35.1\n" : die "unexpected git @args" }]);
    my $fresh = Plack::Test->create(Review::Helper::Server->new(db_path => $mfile)->to_app);
    my $after = $fresh->request(GET "$HOST/api/review?iteration=1");
    is($after->code,                                                                             200,   'git before 2.36 loads the review');
    is({map { ($_->{subject} => $_->{resolution}) } @{json_decode($after->content)->{commits}}}, $none, 'and reports no resolutions');
};

# A sub changed at the top whose POD, under __END__, changed too.
subtest unit_diffs => sub {
    my $v1 = <<'PERL';
package Foo;
use v5.36;

sub name ($self) {
    return $self->{name};
}

sub other ($self) {
    return 1;
}

sub gone {
    gone();
}

1;

__END__

=head1 NAME

Foo - a thing

=head2 name

Returns the name.

=head2 other

Other.

=cut
PERL
    my $v2 = <<'PERL';
package Foo;
use v5.36;

sub name ($self) {
    return $self->{name} // 'anon';
}

sub other ($self) {
    return 1;
}

1;

__END__

=head1 NAME

Foo - a thing

=head2 name

Returns the name, or C<anon>. See L<http://evil.example/> and L<Foo::Bar>.

=for html <script>alert(1)</script>

=head2 other

Other.

=cut
PERL

    my $udir  = make_repo();
    my $base  = commit_file($udir, 'Add Foo',    'lib/Foo.pm' => $v1);
    my $head  = commit_file($udir, 'Default it', 'lib/Foo.pm' => $v2);
    my $urepo = Review::Helper::VCS->detect($udir);
    my $ufile = Review::Helper::Builder->new(repo => $urepo)->build(base => $base, title => 'Units');
    my @units = (
        {name => 'sub name ($self)',  lines     => [[4,  6]],            doc_lines => [[20, 25]], package => 'Foo'},
        {name => 'sub other ($self)', lines     => [[8,  10]],           doc_lines => [[26, 29]], package => 'Foo'},
        {name => 'sub gone',          old_lines => [[12, 15]],           package   => 'Foo'},
        {name => 'header',            lines     => [[1,  2]],            package   => 'Foo'},
        {name => '=head1 NAME',       lines     => [[16, 18]],           package   => 'Foo'},
        {name => 'end',               lines     => [[12, 14], [30, 30]], package   => 'Foo'},
    );
    fill_splits($urepo, Review::Helper::DB->open($ufile), sub ($about) { \@units });
    my $utest = Plack::Test->create(Review::Helper::Server->new(db_path => $ufile)->to_app);
    my $uget  = sub ($path) { json_decode($utest->request(GET "$HOST$path")->content) };

    my ($fid)    = map { $_->{files}[0]{id} } @{$uget->('/api/review')->{commits}};
    my $sections = $uget->("/api/file/$fid")->{sections};
    my %by_name  = map { ($_->{name} => $_) } @$sections;
    is(
        $uget->('/api/review')->{commits}->[0]->{files}->[0]->{section_names},
        [map { +{name => $_->{name}, package => $_->{package}} } @$sections],
        'the review names the sections the page shows for each file',
    );
    my $name = $by_name{'sub name ($self)'};
    is([$name->{ranges}, $name->{doc_ranges}], [[[4, 7]], [[20, 25]]], 'the unit (with the blank line after it) and its documentation are far apart');

    my $hunks = $uget->("/api/diff/$fid?section=$name->{id}")->{hunks};
    my $shape = [map { [$_->{part}, @{$_}{qw/old_start old_count new_start new_count/}, [map { $_->{type} . ($_->{new} // $_->{old}) } @{$_->{lines}}]] } @$hunks];
    is(
        $shape,
        [
            ['code', 4,  4, 4,  4, [' 4',  '-5',  '+5',  ' 6',  ' 7']],
            ['docs', 24, 4, 20, 6, [' 20', ' 21', '-26', '+22', '+23', '+24', ' 25']],
        ],
        'the whole unit, then its whole documentation, changes marked, nothing between',
    );
    is([map { $_->{text} } grep { $_->{type} eq ' ' } map { @{$_->{lines}} } @$hunks], ['sub name ($self) {', '}', '', '=head2 name', '', ''], 'unchanged lines come from the file');

    my $gone = $uget->("/api/diff/$fid?section=$by_name{'sub gone'}{id}")->{hunks};
    is([map { $_->{part} } @$gone],                        ['code'],                       'a deleted unit is one code part');
    is([map { $_->{type} } map { @{$_->{lines}} } @$gone], array { all_items '-'; etc() }, 'shown as removed');
    ok((grep { $_->{text} eq 'sub gone {' } map { @{$_->{lines}} } @$gone), 'with its old lines');

    my $html = $name->{doc_html};
    like($html, qr{<h2>name</h2>},                'the POD renders as HTML');
    like($html, qr{<code>anon</code>},            'with its formatting codes');
    like($html, qr{<a>http://evil\.example/</a>}, 'a link shows as its text');
    unlike($html, qr{href|<script|\bid=}, 'no links out, no raw HTML, no ids to clash with the page');
    is($by_name{'sub gone'}{doc_html}, undef, 'no documentation, no HTML');

    my $server = Review::Helper::Server->new(db_path => $ufile);
    my @docs   = ({doc_ranges => [[18, 18]]}, {doc_ranges => [[16, 18]]}, {doc_ranges => [[16, 18], [18, 18]]});
    $server->_add_doc_html($server->_file_and_commit($fid), \@docs);
    is([map { defined($_->{doc_html}) ? 1 : 0 } @docs], [0, 1, 0], 'only documentation whose every range starts as POD is rendered');

    my $item = Review::Helper::Server->can('_pod_html')->(undef, "=item \$x = foo()\n\nDoes foo.");
    like($item, qr{<dt>\$x = foo\(\)</dt>}, 'an item excerpt renders inside a list');
};

subtest flag_seen => sub {
    my $before = time;
    my ($code, $out) = post_json('/api/flag/1', {seen => \1});
    is([$code, $out], [200, {seen => [{reviewer => $ANN, at => match qr/^\d+$/}]}], 'mark a flag seen');
    my $at = $out->{seen}[0]{at};
    ok($at >= $before && $at <= time, 'marked now');

    $dbh->do(q{INSERT INTO flag_seen (flag, reviewer, at) VALUES (1, 'Bob', 1)});
    $dbh->do(q{UPDATE flag_seen SET at = 5 WHERE reviewer = ?}, undef, $ANN);
    ($code, $out) = post_json('/api/flag/1', {seen => \1});
    is($out->{seen},                              [{reviewer => 'Bob', at => 1}, {reviewer => $ANN, at => 5}], 'marking again keeps the first time; every reviewer listed, oldest first');
    is(get_json('/api/review')->{flags}[0]{seen}, $out->{seen},                                                'the review carries the marks');

    ($code, $out) = post_json('/api/flag/1', {seen => \0});
    is($out->{seen}, [{reviewer => 'Bob', at => 1}], 'unmark removes only this reviewer\'s mark');

    ($code, $out) = post_json('/api/flag/9', {seen => \1});
    is($code, 404, 'unknown flag');
    ($code, $out) = post_json('/api/flag/1', {seen => 1});
    is([$code, $out->{error}],                        [400, "'seen' must be true or false"],            'seen must be a JSON boolean');
    is([post_json('/api/flag/1', {unflagged => \1})], [400, {error => "'seen' must be true or false"}], 'seen is the only state a reviewer sets');
    my $res = request(POST "$HOST/api/flag/1", 'Content-Type' => 'text/plain', Content => '{"seen":true}');
    is($res->code, 415, 'the JSON content type is required');
    $res = request(POST "$HOST/api/flag/1", 'Content-Type' => 'application/json', Origin => 'http://evil.example.com', Content => '{"seen":true}');
    is($res->code, 403, 'cross-origin refused');
    $dbh->do('DELETE FROM flag_seen');
};

subtest flag_feedback => sub {
    my ($code, $out) = post_json('/api/feedback', {target => 'flag', flag => 'n1', body => 'Why here?'});
    is($code, 200, 'feedback on a flag');
    my $row = $db->feedback($out->{id});
    is([@$row{qw/iteration target revision path topic flag flag_sentence reviewer/}],     [2, 'flag', $c2, 'lib/Foo.pm', undef, 'n1', 'Check greet.', $ANN],                   'anchored at the flag\'s commit and path, by its note id, with its sentence');
    is([map { $_->{reviewer} } @{get_json('/api/review')->{flags}[0]{seen}}],             [$ANN],                                                                              'commenting marks the flag seen');
    is((grep { $_->{id} == $out->{id} } @{get_json('/api/review')->{feedback}})[0]{flag}, {note => 'n1', sentence => 'Check greet.', path => 'lib/Foo.pm', lines => [10, 12]}, 'the review lists it with its flag');

    is([post_json('/api/feedback', {target => 'flag', flag => 'zz', body => 'x'})],                 [400, {error => "Iteration 2 has no flag 'zz'"}],    'an unknown note id');
    is([post_json('/api/feedback', {target => 'flag', body => 'x'})],                               [400, {error => "'flag' must be a flag's note id"}], 'a note id is needed');
    is([post_json('/api/feedback', {target => 'flag', flag => 'n1', body => 'x', iteration => 1})], [400, {error => "Iteration 1 has no flag 'n1'"}],    'the flag must be in the iteration');

    $dbh->do('DELETE FROM feedback');
    $dbh->do('DELETE FROM flag_seen');
};

subtest reviewer => sub {
    my $who = sub { Review::Helper::Server->new(db_path => $file, @_)->reviewer };
    local $ENV{REVIEW_HELPER_REVIEWER};
    is($who->(),                 'Tester <tester@example.com>', "default: the repository's git name and email");
    is($who->(reviewer => 'Cy'), 'Cy',                          'given');
    {
        local $ENV{REVIEW_HELPER_REVIEWER} = 'Dee';
        is($who->(), 'Dee', 'from the environment');
        is($who->(reviewer => 'Cy'), 'Cy',  'a given reviewer beats the environment');
        is($who->(reviewer => '  '), 'Dee', 'a blank one counts as not given');
    }
    {
        local $ENV{REVIEW_HELPER_REVIEWER} = '';
        is($who->(), 'Tester <tester@example.com>', 'a blank environment variable counts as unset');
    }

    # The user's own configuration, here a scratch one, is read too. A
    # scratch repository, so the shared one keeps its git identity.
    my $home = File::Temp::tempdir(CLEANUP => 1);
    local $ENV{HOME}                = $home;
    local $ENV{XDG_CONFIG_HOME}     = $home;
    local $ENV{GIT_CONFIG_NOSYSTEM} = 1;
    delete local $ENV{GIT_CONFIG_GLOBAL};

    my $sdir = make_repo();
    commit_file($sdir, 'Start', README => "hello\n");
    my $sfile = Review::Helper::VCS->detect($sdir)->state_dir . '/scratch.sqlite';
    Review::Helper::DB->create($sfile)->dbh->disconnect;
    my $swho = sub { Review::Helper::Server->new(db_path => $sfile)->reviewer };

    run_git($sdir, qw/config user.name/, "Zo\xc3\xab");
    is($swho->(), "Zo\x{eb} <tester\@example.com>", 'a non-ASCII git name is decoded');
    run_git($sdir, qw/config --unset user.email/);
    is($swho->(), "Zo\x{eb}", 'only a name');
    run_git($sdir, qw/config --unset user.name/);
    is($swho->(), scalar(getpwuid($<)) // getlogin() // 'unknown', 'no git identity: the login name');
    {
        my $mock = mock 'Review::Helper::Server' => (override => [_login => sub { undef }]);
        is($swho->(), 'unknown', 'no login name either: unknown');
    }
    run_git($sdir, qw/config user.email tester@example.com/);
    is($swho->(), '<tester@example.com>', 'only an email');

    open(my $fh, '>', "$home/.gitconfig") or die "Cannot write $home/.gitconfig: $!";
    print $fh "[user]\n\tname = Glo Bal\n";
    close($fh);
    is($swho->(), 'Glo Bal <tester@example.com>', "the user's global git name, with the repository's email");
};

subtest 'only the author edits feedback' => sub {
    my %row  = (iteration => 2, target => 'review');
    my $mine = $db->add_feedback(%row, body => 'Mine.',   reviewer => $ANN);
    my $bobs = $db->add_feedback(%row, body => "Bob's.",  reviewer => 'Bob');
    my $old  = $db->add_feedback(%row, body => 'Before.', reviewer => undef);
    my $body = sub ($id) { $db->feedback($id)->{body} };

    my ($code, $out) = post_json("/api/feedback/$mine", {body => 'Mine, edited.'});
    is([$code, $out, $body->($mine)], [200, {}, 'Mine, edited.'], 'the author edits their feedback');

    ($code, $out) = post_json("/api/feedback/$bobs", {body => 'Hijacked.'});
    is([$code, $out], [403, {error => 'Only Bob can edit this feedback'}], "another reviewer's feedback is refused");
    ($code) = post_json("/api/feedback/$bobs", {status => 'declined'});
    is($code,                403,                                                            'its status too');
    is($db->feedback($bobs), hash { field body => "Bob's."; field status => 'open'; etc() }, 'and it is unchanged');

    ($code) = post_json("/api/feedback/$old", {body => 'Before, edited.'});
    is([$code, $body->($old)], [200, 'Before, edited.'], 'feedback with no reviewer is anyone\'s to edit');
};

# A squashed iteration split into topics: every topic's entry has the head's
# sha, so a commit target names its topic and a path picks the topic holding it.
subtest topics => sub {
    my $tfile = $repo->state_dir . '/topics.sqlite';
    my $tdb   = Review::Helper::DB->create($tfile);
    my $tdbh  = $tdb->dbh;
    $tdbh->do(q{INSERT INTO iteration (number, base, head, squashed, pin, created) VALUES (1, ?, ?, 1, 'refs/review-helper/t/1', 1)}, undef, $c0, $c2);
    my %entry;
    for (['Perl', 1, 'lib/Foo.pm', 'perl'], ['Notes', 2, 'notes.txt', 'text']) {
        my ($topic, $position, $path, $kind) = @$_;
        $tdbh->do(q{INSERT INTO commit_entry (iteration, position, revision, parent, subject, message, topic) VALUES (1, ?, ?, ?, 'Greet', 'Greet', ?)}, undef, $position, $c2, $c0, $topic);
        $entry{$topic} = $tdbh->sqlite_last_insert_rowid;
        $tdbh->do(q{INSERT INTO file_change (commit_id, path, status, kind, size_unit, size_after, added, split_source) VALUES (?, ?, 'A', ?, 'lines', 1, 1, 'none')}, undef, $entry{$topic}, $path, $kind);
    }
    $tdbh->do(q{INSERT INTO flag (note_id, commit_id, path, color, kind, sentence, created) VALUES ('n', ?, 'notes.txt', 'red', 'note', 'S.', 1)}, undef, $entry{Notes});

    my $ttest = Plack::Test->create(Review::Helper::Server->new(db_path => $tfile, reviewer => $ANN)->to_app);
    my $post  = sub ($path, $data) {
        my $res = $ttest->request(POST "$HOST$path", 'Content-Type' => 'application/json', Content => json_encode($data));
        return [$res->code, json_decode($res->content)];
    };
    my $review = json_decode($ttest->request(GET "$HOST/api/review")->content);
    is([map { [$_->{topic}, $_->{revision}, [map { $_->{path} } @{$_->{files}}]] } @{$review->{commits}}], [['Perl', $c2, ['lib/Foo.pm']], ['Notes', $c2, ['notes.txt']]], 'each topic is a commit entry with its files');
    is([map { $_->{entry} } @{$review->{flags}}],                                                          [$entry{Notes}],                                                'a flag names its entry');

    is($post->('/api/feedback', {target => 'commit', commit => $c2, body => 'Which?'}),                                                                   [400, {error => "Commit '$c2' is split into topics; give 'topic'"}], 'a commit target names its topic');
    is($post->('/api/feedback', {target => 'commit', commit => $c2, topic => 'Nope', body => 'Which?'}),                                                  [400, {error => "Commit '$c2' has no topic 'Nope'"}],                'one that exists');
    is($post->('/api/feedback', {target => 'commit', commit => $c2, topic => 'Notes', body => 'Notes?'})->[0],                                            200,                                                                 'feedback on a topic');
    is($post->('/api/feedback', {target => 'line', commit => $c2, path => 'notes.txt', line => 1, side => 'new', topic => 'Perl', body => 'Line?'})->[0], 200,                                                                 'a path finds its topic, whatever topic is given');
    is($post->('/api/request', {kind => 'split', target => 'file', commit => $c2, path => 'notes.txt'})->[0],                                             200,                                                                 'a split request in the second topic');
    is($post->('/api/request', {kind => 'debate', target => 'commit', commit => $c2, topic => 'Perl', note => 'Why?'})->[0],                              200,                                                                 'a debate on a topic');

    is(
        [map { [$_->{target}, $_->{topic}, $_->{path}] } @{$tdbh->selectall_arrayref('SELECT target, topic, path FROM feedback UNION ALL SELECT target, topic, path FROM request', {Slice => {}})}],
        [['commit', 'Notes', undef], ['line', undef, 'notes.txt'], ['file', undef, 'notes.txt'], ['commit', 'Perl', undef]],
        'a topic is stored for a commit target only',
    );
    is([map { $_->{topic} } @{json_decode($ttest->request(GET "$HOST/api/feedback")->content)->{feedback}}], ['Notes', undef], 'the export names it');

    # A whole-commit flag's feedback keeps its entry's topic, so it finds
    # that topic again once the agent retires the flag.
    $tdbh->do(q{INSERT INTO flag (note_id, commit_id, color, kind, sentence, created) VALUES ('w', ?, 'yellow', 'note', 'All of Perl.', 1)}, undef, $entry{Perl});
    is($post->('/api/feedback', {target => 'flag', flag => 'w', body => 'Why?'})->[0],                               200,                                                                                'feedback on a whole-commit flag of a topic');
    is($tdbh->selectrow_hashref(q{SELECT revision, path, topic, flag_sentence FROM feedback WHERE target = 'flag'}), {revision => $c2, path => undef, topic => 'Perl', flag_sentence => 'All of Perl.'}, 'it stores the topic of the flag\'s entry');
};

subtest construction => sub {
    like(dies { Review::Helper::Server->new }, qr/'db_path' is a required attribute/, 'needs a file');
};

done_testing;
