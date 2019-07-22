#!perl

use 5.010;
use strict;
use warnings;
use experimental 'smartmatch';
use FindBin '$Bin';
use lib "$Bin/lib";

use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Monkey::Patch::Action qw(patch_package);
use Test::More 0.96;

use Perinci::Access::Schemeless;

my $pa_cached;
my $pa;

package Foo;

package Bar;
our $VERSION = 0.123;
our $DATE = '1999-01-01';

our %SPEC;
$SPEC{f1} = {v=>1.1, args=>{}};
sub f1 { [200] }

package Baz;
our $VERSION = 0.124;

our %SPEC;
$SPEC{':package'} = {v=>1.1, entity_v=>9};
$SPEC{f1} = {v=>1.1, entity_v=>10};
sub f1 { [200] }

package Test::Perinci::Access::Schemeless;
our %SPEC;

$SPEC{':package'} = {v=>1.1, summary=>"A package"};

$SPEC{'$v1'} = {v=>1.1, summary=>"A variable"};
our $VERSION = 1.2;
our $v1 = 123;

$SPEC{f1} = {
    v => 1.1,
    summary => "An example function",
    args => {
        a1 => {schema=>"int"},
    },
    result => {
        schema => 'int*',
    },
    _internal1=>1,
};
sub f1 { [200, "OK", 2] }

$SPEC{f2} = {v=>1.1};
sub f2 { [200, "OK", 3] }

$SPEC{req_confirm} = {v=>1.1};
sub req_confirm {
    my %args = @_;
    return [331, "Confirmation required"] unless $args{-confirm};
    [200, "OK"];
}

$SPEC{dry_run} = {v=>1.1, features=>{dry_run=>1}};
sub dry_run {
    my %args = @_;
    [200, "OK", $args{-dry_run} ? 1:2];
}

$SPEC{tx} = {v=>1.1, features=>{tx=>{v=>2}, idempotent=>1}};
sub tx {
    my %args = @_;
    [200, "OK", ($args{-tx_action}//'') eq 'check_state' ? 1:2];
}

package Test::Perinci::Access::Schemeless2;
our %SPEC;

$SPEC{no_progress} = {v=>1.1};
sub no_progress {
    my %args = @_;
    $args{-progress} ? [200, "OK"] : [500, "No -progress passed"];
}

$SPEC{has_progress} = {v=>1.1, features=>{progress=>1}};
sub has_progress {
    my %args = @_;
    $args{-progress} ? [200, "OK"] : [500, "No -progress passed"];
}

$SPEC{test_uws} = {v=>1.1, args=>{a=>{}}};
sub test_uws { [200] }

# this metadata marks that argument has been validated and that periap shouldn't wrap again
$SPEC{test_double_wrap1} = {v=>1.1, args=>{a=>{}}, 'x.perinci.sub.wrapper.logs'=>[{validate_args=>1}]};
sub test_double_wrap1 { [200] }

package main;

subtest __match_paths => sub {
    ok(!Perinci::Access::Schemeless::__match_paths("/"   , "/a") , "/ vs /a");
    ok(!Perinci::Access::Schemeless::__match_paths("/"   , "/a/"), "/ vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths("/a"  , "/a") , "/a vs /a");
    ok( Perinci::Access::Schemeless::__match_paths("/a/" , "/a") , "/a/ vs /a");
    ok( Perinci::Access::Schemeless::__match_paths("/a"  , "/a/"), "/a vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths("/a/" , "/a/"), "/a/ vs /a/");
    ok(!Perinci::Access::Schemeless::__match_paths("/ab" , "/a") , "/ab vs /a");
    ok(!Perinci::Access::Schemeless::__match_paths("/ab" , "/a/"), "/ab vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b", "/a") , "/a/b vs /a");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b", "/a/"), "/a/b vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b/c", "/a/b"), "/a/b/c vs /a/b");
    ok(!Perinci::Access::Schemeless::__match_paths("/a/bc" , "/a/b"), "/a/bc vs /a/b");

    ok(!Perinci::Access::Schemeless::__match_paths("/"    , "/a/b") , "/ vs /a/b/");
    ok(!Perinci::Access::Schemeless::__match_paths("/"    , "/a/b/"), "/ vs /a/b/");
    ok(!Perinci::Access::Schemeless::__match_paths("/a"   , "/a/b") , "/a vs /a/b");
    ok(!Perinci::Access::Schemeless::__match_paths("/a"   , "/a/b/"), "/a vs /a/b/");
    ok(!Perinci::Access::Schemeless::__match_paths("/a/"  , "/a/b") , "/a/ vs /a/b");
    ok(!Perinci::Access::Schemeless::__match_paths("/a/"  , "/a/b/"), "/a/ vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b" , "/a/b") , "/a/ vs /a/b");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b/", "/a/b") , "/a/b/ vs /a/b");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b" , "/a/b/"), "/a/b vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b/", "/a/b/"), "/a/b/ vs /a/b/");

    ok( Perinci::Access::Schemeless::__match_paths("/a"  , qr{\A/a(?:/|\z)}) , "/a vs qr{\\A/a(?:/|\\z)}");
    ok( Perinci::Access::Schemeless::__match_paths("/a/" , qr{\A/a(?:/|\z)}) , "/a vs qr{\\A/a(?:/|\\z)}");
    ok( Perinci::Access::Schemeless::__match_paths("/a/b", qr{\A/a(?:/|\z)}) , "/a/b vs qr{\\A/a(?:/|\\z)}");
    ok(!Perinci::Access::Schemeless::__match_paths("/ab" , qr{\A/a(?:/|\z)}) , "/ab vs qr{\\A/a(?:/|\\z)}");
};

subtest __match_paths2 => sub {
    ok( Perinci::Access::Schemeless::__match_paths2("/"   , "/a") , "/ vs /a");
    ok( Perinci::Access::Schemeless::__match_paths2("/"   , "/a/"), "/ vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a"  , "/a") , "/a vs /a");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/" , "/a") , "/a/ vs /a");
    ok( Perinci::Access::Schemeless::__match_paths2("/a"  , "/a/"), "/a vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/" , "/a/"), "/a/ vs /a/");
    ok(!Perinci::Access::Schemeless::__match_paths2("/ab" , "/a") , "/ab vs /a");
    ok(!Perinci::Access::Schemeless::__match_paths2("/ab" , "/a/"), "/ab vs /a/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b", "/a") , "/a/b vs /a");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b", "/a/"), "/a/b vs /a/");

    ok( Perinci::Access::Schemeless::__match_paths2("/"    , "/a/b") , "/ vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths2("/"    , "/a/b/"), "/ vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a"   , "/a/b") , "/a vs /a/b");
    ok( Perinci::Access::Schemeless::__match_paths2("/a"   , "/a/b/"), "/a vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/"  , "/a/b") , "/a/ vs /a/b");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/"  , "/a/b/"), "/a/ vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b" , "/a/b") , "/a/b vs /a/b");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b/", "/a/b") , "/a/b/ vs /a/b");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b" , "/a/b/"), "/a/b vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b/", "/a/b/"), "/a/b/ vs /a/b/");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b/c", "/a/b"), "/a/b/c vs /a/b");
    ok(!Perinci::Access::Schemeless::__match_paths2("/a/bc" , "/a/b"), "/a/bc vs /a/b");

    ok( Perinci::Access::Schemeless::__match_paths2("/a"  , qr{\A/a(?:/|\z)})  , "/a vs qr{\\A/a(?:/|\\z)}");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/" , qr{\A/a(?:/|\z)}) , "/a vs qr{\\A/a(?:/|\\z)}");
    ok( Perinci::Access::Schemeless::__match_paths2("/a/b", qr{\A/a(?:/|\z)}) , "/a/b vs qr{\\A/a(?:/|\\z)}");
    ok( Perinci::Access::Schemeless::__match_paths2("/ab" , qr{\A/a(?:/|\z)}) , "/ab vs qr{\\A/a(?:/|\\z)}");
};

# test after_load first, for first time loading of
# Perinci::Examples

my $var = 12;
test_request(
    name => 'opt: after_load called',
    object_opts=>{after_load=>sub {$var++}},
    req => [call => '/Perinci/Examples/noop'],
    status => 200,
    posttest => sub {
        is($var, 13, "\$var incremented");
    },
);
test_request(
    name => 'opt: after_load not called twice',
    object_opts=>{after_load=>sub {$var++}},
    req => [call => '/Perinci/Examples/noop'],
    status => 200,
    posttest => sub {
        is($var, 13, "\$var not incremented again");
    },
);
# XXX test trapping of die in after_load

subtest "failure in loading module" => sub {
    local @INC = @INC;
    my $tmpdir = tempdir(CLEANUP=>1);
    unshift @INC, $tmpdir;
    my $prefix = "M" . int(rand()*900_000_000+100_000_000);
    my $prefix2;
    while (1) {
        $prefix2 = "M" . int(rand()*900_000_000+100_000_000);
        last unless $prefix eq $prefix2;
    }
    mkdir "$tmpdir/$prefix";
    write_text "$tmpdir/$prefix/OK.pm", "package $prefix\::OK; 1;";
    write_text "$tmpdir/$prefix/Err.pm", "package $prefix\::Err; 1=;";
    test_request(
        name => "ok",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [meta => "/$prefix/OK/"],
        status => 200,
    );

    test_request(
        name => "missing module/prefix on actions",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [actions => "/$prefix2/"],
        status => 404,
    );
    test_request(
        name => "missing module/prefix is cached",
        req => [actions => "/$prefix2/"],
        status => 404,
    );
    test_request(
        name => "missing module/prefix on list",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [list => "/$prefix2/"],
        status => 404,
    );
    test_request(
        name => "missing module/prefix on info",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [info => "/$prefix2/"],
        status => 404,
    );
    test_request(
        name => "missing module/prefix on meta",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [meta => "/$prefix2/"],
        status => 404,
    );

    test_request(
        name => "missing module but existing prefix is okay on actions",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [actions => "/$prefix/"],
        status => 200,
    );
    test_request(
        name => "missing module but existing prefix is okay on list",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [list => "/$prefix/"],
        status => 200,
        result => ["Err/", "OK/"],
    );
    test_request(
        name => "missing module but existing prefix is okay on info",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [info => "/$prefix/"],
        status => 200,
    );
    test_request(
        name => "missing module but existing prefix is okay on meta",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [meta => "/$prefix/"],
        status => 200,
    );

    test_request(
        name => "missing function on meta (1)",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [meta => "/$prefix/foo"],
        status => 404,
    );
    test_request(
        name => "missing function on meta (2)",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [meta => "/$prefix/OK/foo"],
        status => 404,
    );

    test_request(
        name => "compile error in module on actions",
        object_opts=>{}, # so it creates a new riap client and defeat cache
        req => [actions => "/$prefix/Err/"],
        status => 500,
    );
    test_request(
        name => "compile error in module is cached",
        req => [actions => "/$prefix/Err/"],
        status => 500,
    );
};

test_request(
    name => 'unknown action',
    req => [zzz => "/"],
    status => 501,
);
test_request(
    name => 'unknown action for a type (1)',
    req => [call => "/"],
    status => 501,
);
test_request(
    name => 'unknown action for a type (2)',
    req => [list => "/Bar/f1"],
    status => 501,
);

subtest "opt: {allow,deny}_schemes" => sub {
    test_request(
        name => 'allow_schemes matches',
        object_opts => {allow_schemes=>['foo']},
        req => [meta => "foo:/Perinci/Examples/"],
        status => 200,
    );
    test_request(
        name => "allow_schemes doesn't match",
        object_opts => {allow_schemes=>['foo']},
        req => [meta => "/Perinci/Examples/"],
        status => 501,
    );
    test_request(
        name => 'deny_schemes matches',
        object_opts => {deny_schemes=>['foo']},
        req => [meta => "foo:/Perinci/Examples/"],
        status => 501,
    );
    test_request(
        name => "deny_schemes doesn't match",
        object_opts => {deny_schemes=>['foo']},
        req => [meta => "/Perinci/Examples/"],
        status => 200,
    );
};

subtest "opt: {allow,deny}_paths" => sub {
    test_request(
        name => 'allow_paths',
        object_opts => {allow_paths=>qr!^/foo!},
        req => [meta => "/Perinci/Examples/"],
        status => 403,
    );
    test_request(
        name => 'allow_paths on list /',
        object_opts => {allow_paths=>'/Perinci/Examples'},
        req => [list => "/"],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} == 1, "number of results"); # Perinci/
        },
    );
    test_request(
        name => 'allow_paths on list /Perinci/',
        object_opts => {allow_paths=>'/Perinci/Examples'},
        req => [list => "/Perinci/"],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} == 1, "number of results"); # Examples/
        },
    );
    test_request(
        name => 'allow_paths on list /Perinci/Examples/',
        object_opts => {allow_paths=>'/Perinci/Examples'},
        req => [list => "/Perinci/Examples/"],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} > 5, "number of results"); # lots of func
        },
    );
    test_request(
        name => 'allow_paths on list /Perinci/Examples/Completion/',
        object_opts => {allow_paths=>'/Perinci/Examples'},
        req => [list => "/Perinci/Examples/Completion/"],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} == 2, "number of results"); # fruits, animals
        },
    );
    test_request(
        name => 'deny_paths 1',
        object_opts => {deny_paths=>qr!^/foo!},
        req => [meta => "/Perinci/Examples/"],
        status => 200,
    );
    test_request(
        name => 'deny_paths 2',
        object_opts => {deny_paths=>qr!^/P!},
        req => [meta => "/Perinci/Examples/"],
        status => 403,
    );
    test_request(
        name => 'deny_paths on list',
        object_opts => {deny_paths=>qr!^/Perinci/Examples/[^c]!},
        req => [list => "/Perinci/Examples/"],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} <= 3, "number of results"); # call_gen_array, call_randlog
        },
    );
};

subtest 'schema in metadata is normalized' => sub {
    test_request(
        name => 'first request (meta)',
        req => [meta => '/Test/Perinci/Access/Schemeless/f1'],
        status => 200,
        result => {
            v => 1.1,
            summary => "An example function",
            args => {
                a1 => {schema=>["int"=>{}, {}]},
            },
            result => {
                schema => ['int'=>{req=>1}, {}],
            },
            result_naked=>0,
            _orig_result_naked=>undef,
            args_as=>'hash',
            _orig_args_as=>undef,
            entity_v=>1.2,
            _internal1=>1,
        },
    );

    test_request(
        name   => 'second request (call) to trigger wrapper',
        req    => [call => '/Test/Perinci/Access/Schemeless/f1'],
        status => 200,
    );

    test_request(
        name => 'third request (second meta) already uses meta from wrapper',
        req => [meta => '/Test/Perinci/Access/Schemeless/f1'],
        status => 200,
        result => {
            v => 1.1,
            summary => "An example function",
            args => {
                a1 => {schema=>["int"=>{}, {}]},
            },
            result => {
                schema => ['int'=>{req=>1}, {}],
            },
            result_naked=>0,
            _orig_result_naked=>undef,
            args_as=>'hash',
            _orig_args_as=>undef,
            entity_v=>1.2,
            _internal1=>1,
            "x.perinci.sub.wrapper.logs" => [
                {normalize_schema=>1, validate_args=>1, validate_result=>1},
            ],
        },
    );
};

subtest "avoid double wrapping" => sub {
    my $h = patch_package("Perinci::Sub::Wrapper", "wrap_sub", "replace", sub { say "WRAPPING AGAIN!"; die });
    test_request(
        req => [call => "/Test/Perinci/Access/Schemeless2/test_double_wrap1"],
        #req => [call => "/App/GenPericmdScript/gen_perinci_cmdline_script"],
        status => 200,
    );
};

subtest "action: info" => sub {
    test_request(
        name => "info on / works",
        req => [info => "/"],
        status => 200,
        result => {uri=>"/", type=>"package"},
    );
    test_request(
        name => 'info on package',
        req => [info => "/Foo/"],
        status => 200,
        result => {uri=>'/Foo/', type=>'package'},
    );
    test_request(
        name => 'info on function',
        req => [info => "/Baz/f1"],
        status => 200,
        result => {uri=>'/Baz/f1', type=>'function'},
    );
};

subtest "action: meta" => sub {
    test_request(
        name => 'meta on / works',
        req => [meta => "/"],
        status => 200,
    );
    test_request(
        name => 'meta on non-package under / = 404',
        req => [meta => sprintf "/%016d", rand()*1e16],
        status => 404,
    );
    test_request(
        name => 'meta on package',
        req => [meta => "/Test/Perinci/Access/Schemeless/"],
        status => 200,
        result => { summary => "A package",
                    v => 1.1,
                    entity_v => $Test::Perinci::Access::Schemeless::VERSION },
    );
    test_request(
        name => 'meta on package (default meta, no VERSION)',
        req => [meta => "/Foo/"],
        status => 200,
        result => { v => 1.1 },
    );
    test_request(
        name => 'meta on package (default meta, entity_v from VERSION)',
        req => [meta => "/Bar/"],
        status => 200,
        result => { v => 1.1, entity_v => 0.123, entity_date=>'1999-01-01' },
    );
    test_request(
        name => 'meta on function (entity_v from VERSION)',
        object_opts=>{wrap=>0},
        req => [meta => "/Bar/f1"],
        status => 200,
        result => {v=>1.1, args=>{}, result_naked=>0, _orig_result_naked=>undef, args_as=>'hash', _orig_args_as=>undef, entity_v => 0.123, entity_date=>'1999-01-01'},
    );
    test_request(
        name => 'meta on package (entity_v not overridden)',
        object_opts=>{wrap=>0},
        req => [meta => "/Baz/"],
        status => 200,
        result => {v=>1.1, entity_v=>9},
    );
    test_request(
        name => 'meta on function (entity_v not overridden)',
        object_opts=>{wrap=>0},
        req => [meta => "/Baz/f1"],
        status => 200,
        result => {v=>1.1, entity_v=>10, args=>{}, _orig_result_naked=>undef, result_naked=>0, args_as=>'hash', _orig_args_as=>undef},
    );
    test_request(
        name => 'ending slash matters',
        req => [meta => "/Perinci/Examples"],
        status => 404,
    );
};

subtest "action: actions" => sub {
    test_request(
        name => 'actions on package',
        req => [actions => "/Perinci/Examples/"],
        status => 200,
        result => [qw/actions begin_tx child_metas commit_tx discard_all_txs
                      discard_tx info list list_txs meta redo
                      release_tx_savepoint rollback_tx savepoint_tx undo/],
    );
    test_request(
        name => 'actions on function',
        req => [actions => "/Perinci/Examples/gen_array"],
        status => 200,
        result => [qw/actions begin_tx call commit_tx complete_arg_elem
                      complete_arg_val discard_all_txs discard_tx info list_txs
                      meta redo release_tx_savepoint rollback_tx savepoint_tx
                      undo/],
    );
    test_request(
        name => 'actions on variable',
        req => [actions => "/Perinci/Examples/\$Var1"],
        status => 200,
        result => [qw/actions begin_tx commit_tx discard_all_txs discard_tx get
                      info list_txs meta redo release_tx_savepoint rollback_tx
                      savepoint_tx undo/],
    );
    # XXX actions: detail
};

subtest "action: list" => sub {
    test_request(
        name => 'default',
        req => [list => "/Perinci/Examples/"],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} > 5, "number of results"); # safe number
            ok("noop" ~~ @{$res->[2]}, "has entry: noop"); # testing some result
            ok("\$Var1" ~~ @{$res->[2]}, "has entry: \$Var1"); # ditto
            ok("Completion/" ~~ @{$res->[2]}, "has entry: Completion/"); # ditto
            ok(!ref($res->[2][0]), "record is scalar");
        },
    );
    test_request(
        name => 'opt: detail',
        req => [list => "/Perinci/Examples/", {detail=>1}],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            ok(@{$res->[2]} > 5, "number of results");
            is(ref($res->[2][0]), 'HASH', "record is hash");
        },
    );
    # XXX opt: type
};

subtest "action: call" => sub {
    test_request(
        name => 'call 1',
        req => [call => "/Perinci/Examples/gen_array", {args=>{len=>1}}],
        status => 200,
        result => [1],
    );
    test_request(
        name => 'call: die trapped by wrapper',
        req => [call => "/Perinci/Examples/dies"],
        status => 500,
    );
    # XXX call: invalid args
    test_request(
        name => 'call: confirm (w/o)',
        req => [call => "/Test/Perinci/Access/Schemeless/req_confirm",
                {}],
        status => 331,
    );
    test_request(
        name => 'call: confirm (w/)',
        req => [call => "/Test/Perinci/Access/Schemeless/req_confirm",
                {confirm=>1}],
        status => 200,
    );
    test_request(
        name => 'call: dry_run to function that cannot do dry run -> 412',
        req => [call => "/Test/Perinci/Access/Schemeless/f1",
                {dry_run=>1}],
        status => 412,
    );
    test_request(
        name => 'call: dry_run (using dry_run) (w/o)',
        req => [call => "/Test/Perinci/Access/Schemeless/dry_run",
                {}],
        status => 200,
        result => 2,
    );
    test_request(
        name => 'call: dry_run (using dry_run) (w/)',
        req => [call => "/Test/Perinci/Access/Schemeless/dry_run",
                {dry_run=>1}],
        status => 200,
        result => 1,
    );
    test_request(
        name => 'call: dry_run (using tx) (w/o)',
        req => [call => "/Test/Perinci/Access/Schemeless/tx",
                {}],
        status => 200,
        result => 2,
    );
    test_request(
        name => 'call: dry_run (using tx) (w/)',
        req => [call => "/Test/Perinci/Access/Schemeless/tx",
                {dry_run=>1}],
        status => 200,
        result => 1,
    );

    test_request(
        name => 'call: argv',
        req => [call => "/Perinci/Examples/gen_array",
                {argv=>[5]}],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            is(~~@{ $res->[2] }, 5);
        },
    );
    test_request(
        name => 'call: failure in parsing argv -> 400',
        req => [call => "/Perinci/Examples/gen_array",
                {argv=>[5, 5]}],
        status => 400,
    );
};

subtest "action: complete_arg_val" => sub {
    test_request(
        name => 'complete_arg_val: missing arg',
        req => [complete_arg_val => "/Perinci/Examples/test_completion", {}],
        status => 400,
    );
    test_request(
        name => 'complete: str\'s in',
        req => [complete_arg_val => "/Perinci/Examples/test_completion",
                {arg=>"s1", word=>"r"}],
        status => 200,
        result => {static=>0, words=>[{word=>"red date",summary=>undef}, {word=>"red grape",summary=>undef}]},
    );
    test_request(
        name => 'complete: int\'s min+max',
        req => [complete_arg_val => "/Perinci/Examples/test_completion",
                {arg=>"i1", word=>"1"}],
        status => 200,
        result => {static=>0, words=>[map {+{word=>$_, summary=>undef}} 1, 10..19]},
    );
    test_request(
        name => 'complete: sub',
        req => [complete_arg_val => "/Perinci/Examples/test_completion",
                {arg=>"s2", word=>"z"}],
        status => 200,
        result => {static=>0, words=>["za".."zz"]},
    );
    test_request(
        name => 'complete: sub die trapped',
        req => [complete_arg_val => "/Perinci/Examples/test_completion",
                {arg=>"s3"}],
        status => 200,
    );
};

test_request(
    name => 'action: child_metas',
    req => [child_metas => '/Test/Perinci/Access/Schemeless/'],
    status => 200,
    result => {
        '$v1' =>
            {
                v=>1.1,
                summary=>"A variable",
                entity_v=>1.2,
            },
        'f1' =>
            {
                v=>1.1,
                summary => "An example function",
                args => {
                    a1 => {schema=>["int"=>{}, {}]},
                },
                result => {
                    schema => ['int'=>{req=>1}, {}],
                },
                args_as => 'hash', result_naked => 0,
                _orig_args_as => undef, _orig_result_naked => undef,
                entity_v=>1.2,
                "x.perinci.sub.wrapper.logs" => [
                    {normalize_schema=>1, validate_args=>1, validate_result=>1},
                ],
                _internal1=>1,
            },
        'f2' =>
            {
                v=>1.1,
                args => {},
                args_as => 'hash', result_naked => 0,
                _orig_args_as => undef, _orig_result_naked => undef,
                entity_v=>1.2,
            },
        'req_confirm' =>
            {
                v=>1.1,
                args_as => 'hash', result_naked => 0,
                _orig_args_as => undef, _orig_result_naked => undef,
                entity_v=>1.2,
                features=>{},
                "x.perinci.sub.wrapper.logs" => [
                    {normalize_schema=>1, validate_args=>1, validate_result=>1},
                ],
            },
        'dry_run' =>
            {
                v=>1.1,
                args_as => 'hash', result_naked => 0,
                _orig_args_as => undef, _orig_result_naked => undef,
                entity_v=>1.2,
                features => {dry_run=>1},
                "x.perinci.sub.wrapper.logs" => [
                    {normalize_schema=>1, validate_args=>1, validate_result=>1},
                ],
            },
        'tx' =>
            {
                v=>1.1,
                args_as => 'hash', result_naked => 0,
                _orig_args_as => undef, _orig_result_naked => undef,
                entity_v=>1.2,
                features => {tx=>{v=>2}, idempotent=>1},
                "x.perinci.sub.wrapper.logs" => [
                    {normalize_schema=>1, validate_args=>1, validate_result=>1},
                ],
            },
    },
);

test_request(
    name => 'no progress',
    req => [call => "/Test/Perinci/Access/Schemeless2/no_progress", {}],
    status => 500,
);
test_request(
    name => 'has progress',
    req => [call => "/Test/Perinci/Access/Schemeless2/has_progress", {}],
    status => 200,
);

test_request(
    name => 'opt: wrap=0',
    object_opts=>{wrap=>0},
    req => [call => '/Test/Perinci/Access/Schemeless2/test_uws', {args=>{x=>1}}],
    status => 200,
);
test_request(
    name => 'opt: wrap=1 (the default)',
    object_opts=>{},
    req => [call => '/Test/Perinci/Access/Schemeless2/test_uws', {args=>{x=>1}}],
    status => 400,
);

subtest 'opt: set_function_properties' => sub {
    plan skip_all => 'Currently release testing only'
        unless $ENV{RELEASE_TESTING};

    test_request(
        name => 'opt: set_function_properties',
        object_opts=>{set_function_properties=>{retry=>1}},
        req => [meta => '/Test/Perinci/Access/Schemeless/f1'],
        status => 200,
        posttest => sub {
            my ($res) = @_;
            my $meta = $res->[2];
            ok($meta->{retry}) or diag explain $meta;
        },
    );
};

test_request(
    name => 'opt: normalize_metadata=0',
    object_opts=>{normalize_metadata=>0},
    req => [meta => '/Test/Perinci/Access/Schemeless/f1'],
    status => 200,
    posttest => sub {
        my ($res) = @_;
        my $meta = $res->[2];
        is($meta->{args}{a1}{schema}, "int") or diag explain $meta;
    },
);

subtest "parse_url" => sub {
    my $pa = Perinci::Access::Schemeless->new;
    is_deeply($pa->parse_url("/Perinci/Examples/"),
              {proto=>'', path=>"/Perinci/Examples/"},
              "/Perinci/Examples/");
    is_deeply($pa->parse_url("foo:/Perinci/Examples/"),
              {proto=>'', path=>"/Perinci/Examples/"},
              "/Perinci/Examples/");
};

DONE_TESTING:
done_testing();

# riap client uses one from last test, unless object_opts is specified where it
# will create a new object.
sub test_request {
    my %args = @_;
    my $req = $args{req};
    my $test_name = ($args{name} // "") . " (req: $req->[0] $req->[1])";
    subtest $test_name => sub {
        my $pa;
        if ($args{object_opts}) {
            $pa = Perinci::Access::Schemeless->new(%{$args{object_opts}});
        } else {
            unless ($pa_cached) {
                $pa_cached = Perinci::Access::Schemeless->new();
            }
            $pa = $pa_cached;
        }
        my $res = $pa->request(@$req);
        if ($args{status}) {
            is($res->[0], $args{status}, "status")
                or diag explain $res;
        }
        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}, "result")
                or diag explain $res;
        }
        if ($args{posttest}) {
            $args{posttest}($res);
        }
        done_testing();
    };
}
