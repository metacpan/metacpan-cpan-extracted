#!perl

# Punk::Model::JSONFile: the model contract over a JSON file. The filter,
# order_by and paging are punk_dbq.h's, shared with Punk::Model::DBI, and are
# evaluated here in memory with SQL's three-valued logic; writes lock,
# re-read, and rename a new file into place.

use 5.010;
use strict;
use warnings;
use utf8;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use File::Raw ();
use File::Raw::JSON ();

my $DIR = File::Temp->newdir;
my $FILE = "$DIR/data.json";

sub put {
    my ($file, $doc) = @_;
    File::Raw::atomic_spew($file, File::Raw::JSON::file_json_encode($doc));
}
sub slurp_json { File::Raw::slurp($_[0], plugin => 'json') }

put($FILE, {
    count  => 5,
    things => [
        { id => 1, name => 'bravo',   n => 10, tag => 'x' },
        { id => 2, name => 'alpha',   n => 9,  tag => 'y' },
        { id => 3, name => 'charlie', n => undef, tag => 'x' },
        { id => 4, name => 'Café',    n => 100, tag => undef },
        { id => 5, name => 'a_b%c',   n => 2,  tag => 'z', nested => { k => [1, 2] } },
    ],
});

{
    package JFApp;
    use Punk;
    database data => { backend => 'Punk::Model::JSONFile', file => $FILE };
}
{
    package JFApp::Model::Thing;
    use Punk::Model;
    database 'data';
    table 'things';
    field id     => { type => 'integer', primary => 1 };
    field name   => { type => 'string' };
    field n      => { type => 'integer' };
    field tag    => { type => 'string' };
    field nested => { type => 'object' };
}
JFApp->to_app;
my $M = JFApp->punk_app->model_instance('Thing');
my $B = $M->backend;

sub ids { [ map $_->{id}, @{ $M->search(@_)->{rows} } ] }

# ---- reading ------------------------------------------------------------------

isa_ok $B, 'Punk::Model::JSONFile';
is $B->file, $FILE, 'file';
is $B->document->{count}, 5, 'document: values beside the tables';
is $M->get(id => 2)->{name}, 'alpha', 'get by primary key';
is $M->get(id => 99), undef, 'get: none is undef';
is $M->get(id => 4)->{name}, 'Café', 'get: characters';
is $M->count({}), 5, 'count';
is_deeply ids({}), [1, 2, 3, 4, 5], 'search: the primary key order by default';

# ---- operators, with SQL's NULL rules ------------------------------------------

is_deeply ids({ tag => 'x' }), [1, 3], '=';
is_deeply ids({ tag => undef }), [4], '= undef is IS NULL';
is_deeply ids({ tag => { '!=' => 'x' } }), [2, 5], '!= leaves NULL out';
is_deeply ids({ tag => { '!=' => undef } }), [1, 2, 3, 5], '!= undef is IS NOT NULL';
is_deeply ids({ n => { '>' => 9 } }), [1, 4], '> compares numbers as numbers (10, 100 > 9)';
is_deeply ids({ n => { '>=' => 9, '<' => 100 } }), [1, 2], 'two operators AND';
is_deeply ids({ n => { '<=' => 2 } }), [5], '<= (NULL never compares)';
is_deeply ids({ name => { '<' => 'b' } }), [2, 4, 5], '< on strings (uppercase first)';
is_deeply ids({ tag => { in => ['y', 'z'] } }), [2, 5], 'in';
is_deeply ids({ tag => { in => [] } }), [], 'in over nothing';
is_deeply ids({ tag => { not_in => ['x'] } }), [2, 5], 'not_in leaves NULL out';
is_deeply ids({ tag => { not_in => [] } }), [1, 2, 3, 4, 5], 'not_in over nothing is everything';
is_deeply ids({ tag => { not_in => ['x', undef] } }), [], 'not_in over a list holding NULL is nothing';
is_deeply ids({ name => { like => '%a%' } }), [1, 2, 3, 4, 5], 'like %';
is_deeply ids({ name => { like => 'a_p%' } }), [2], 'like _';
is_deeply ids({ name => { like => 'Caf_' } }), [4], 'like _ is one character, not one byte';
is_deeply ids({ name => { like => 'A%' } }), [], 'like is case-sensitive';
is_deeply ids({ name => { starts_with => 'a_b%' } }), [5], 'starts_with is literal';
is_deeply ids({ name => { starts_with => 'a_' } }), [5], '...not a pattern';
is_deeply ids({ tag => 'x', n => undef }), [3], 'terms AND';

# ---- ordering and paging ---------------------------------------------------------

is_deeply ids({}, { order_by => 'n' }), [3, 5, 2, 1, 4], 'order_by: NULL first, numbers numerically';
is_deeply ids({}, { order_by => [ n => 'desc' ] }), [4, 1, 2, 5, 3], 'desc: NULL last';
is_deeply ids({}, { order_by => [ tag => 'asc', n => 'desc' ] }), [4, 1, 3, 2, 5], 'two columns';
{
    my @seen;
    my $page = $M->search({}, { order_by => [ name => 'asc' ], limit => 2 });
    push @seen, map $_->{id}, @{ $page->{rows} };
    while ($page->{has_more_data}) {
        $page = $M->search({}, { order_by => [ name => 'asc' ], limit => 2, after => $page->{next} });
        push @seen, map $_->{id}, @{ $page->{rows} };
    }
    is_deeply \@seen, [4, 5, 2, 1, 3], 'paging walks every row once, in order';
    my $p1 = $M->search({}, { limit => 2 });
    is $p1->{next}, 'eyJrIjoyfQ', 'the plain token is DBI\'s shape ({"k":2})';
    my $err = do { local $@; eval { $M->search({}, { order_by => 'n', after => $p1->{next} }) }; $@ };
    like $err, qr/issued without an order_by/, 'a token is refused under another ordering';
    $err = do { local $@; eval { $M->search({}, { after => 'not-a-token!' }) }; $@ };
    like $err, qr/invalid pagination token/, 'a foreign token';
    is scalar @{ $M->search({}, { limit => 0 })->{rows} }, 1, 'limit below 1 is 1';
    is scalar @{ $M->all->{rows} }, 5, 'all';
}

# ---- the croaks are DBI's ------------------------------------------------------------

for my $case (
    [ { nope => 1 },                   qr/names 'nope', which is not a field of things/ ],
    [ { n => { '~' => 1 } },           qr/unknown operator '~' on n/ ],
    [ { n => {} },                     qr/is an empty hashref/ ],
    [ { n => [1] },                    qr/plain arrayref/ ],
    [ { n => { '<' => undef } },       qr/'<' on n needs a value/ ],
    [ { n => { in => 1 } },            qr/'in' on n takes an arrayref/ ],
) {
    my $err = do { local $@; eval { $M->search($case->[0]) }; $@ };
    like $err, $case->[1], "croaks: $case->[1]";
}
like do { local $@; eval { $M->search({}, { offset => 1 }) }; $@ },
    qr/unknown search option 'offset'/, 'croaks: an unknown option';
like do { local $@; eval { $M->get(nope => 1) }; $@ }, qr/not a field/, 'croaks: get on an unknown column';

# ---- copies, and the cache ------------------------------------------------------------

{
    my $r = $M->get(id => 5);
    $r->{name} = 'CHANGED';
    push @{ $r->{nested}{k} }, 3;
    my $again = $M->get(id => 5);
    is $again->{name}, 'a_b%c', 'a row is a copy';
    is_deeply $again->{nested}{k}, [1, 2], '...all the way down';
    my $doc = $B->document;
    $doc->{count} = 99;
    is $B->document->{count}, 5, 'document is a copy';
}
{
    my $t = (stat $FILE)[9];
    my $doc = slurp_json($FILE);
    pop @{ $doc->{things} };
    put($FILE, $doc);
    utime $t, $t, $FILE;
    is $M->count({}), 4, 'a file replaced within the same second is re-read';
    $doc->{things}[0]{name} = 'bravX';
    File::Raw::spew($FILE, File::Raw::JSON::file_json_encode($doc));
    utime $t + 5, $t + 5, $FILE;
    is $M->get(id => 1)->{name}, 'bravX', 'a file rewritten in place is re-read';
}

# ---- missing, broken ----------------------------------------------------------------------

{
    my %args = (table => 'things', primary => 'id', columns => [qw(id name)]);
    my $none = Punk::Model::JSONFile->new(%args, database => { file => "$DIR/none.json" });
    is $none->count({}), 0, 'a missing file has no rows';
    is $none->document, undef, '...and no document';
    File::Raw::spew("$DIR/bad.json", '{ broken');
    my $bad = Punk::Model::JSONFile->new(%args, database => { file => "$DIR/bad.json" });
    my @w;
    local $SIG{__WARN__} = sub { push @w, @_ };
    is $bad->count({}), 0, 'a broken file has no rows';
    $bad->count({}) for 1 .. 3;
    is scalar @w, 1, '...and warns once';
    like $w[0], qr/bad\.json is unusable/, '...naming the file';
    my $err = do { local $@; eval { $bad->create({ name => 'x' }) }; $@ };
    like $err, qr/unusable, so nothing was written/, 'a broken file is never written over';
    is File::Raw::slurp("$DIR/bad.json"), '{ broken', '...it is as it was';
    $err = do { local $@; eval { Punk::Model::JSONFile->new(%args, database => {}) }; $@ };
    like $err, qr/needs a `file`/, 'new without a file croaks';
}

# ---- writing ----------------------------------------------------------------------------

{
    put($FILE, { count => 1, things => [ { id => 1, name => 'one', n => 1 } ] });
    my $c = $M->create({ name => 'two', n => 2, junk => 'dropped', tag => undef });
    is $c->{id}, 2, 'create: the next integer key';
    ok !exists $c->{junk}, '...unknown columns dropped';
    ok !exists $c->{tag}, '...undefined values dropped';
    my $c2 = $M->create({ id => 10, name => 'ten' });
    is $c2->{id}, 10, 'create: a given key is kept';
    is $M->create({ name => 'eleven' })->{id}, 11, '...and the next one follows it';
    like do { local $@; eval { $M->create({ id => 10, name => 'dup' }) }; $@ },
        qr/a row with id = 10 already exists/, 'create: a duplicate key croaks';
    like do { local $@; eval { $M->create({ junk => 1 }) }; $@ },
        qr/create with no known columns/, 'create: nothing known croaks';

    my $doc = slurp_json($FILE);
    is $doc->{count}, 1, 'writes keep the values beside the table';
    is_deeply [ map $_->{id}, @{ $doc->{things} } ], [1, 2, 10, 11], '...and append the rows';
    unlike File::Raw::slurp($FILE), qr/\d\.0\b/, '...integers stay integers in the file';
    like File::Raw::slurp($FILE), qr/\n  "count"/, '...pretty, with sorted keys';

    my $u = $M->update({ id => 2, name => 'TWO', tag => 't', junk => 1 });
    is $u->{name}, 'TWO', 'update: changed';
    is $u->{n}, 2, '...the rest kept';
    ok !exists $u->{junk}, '...unknown columns ignored';
    is $M->update({ id => 99, name => 'x' }), undef, 'update: no such row is undef';
    like do { local $@; eval { $M->update({ name => 'x' }) }; $@ },
        qr/update needs the primary key in the data/, 'update without the key croaks';
    is $M->update({ id => 2, tag => undef })->{tag}, undef, 'update can set null';

    is $M->delete(id => 10), 1, 'delete: one row';
    is $M->delete(id => 10), 0, 'delete: none left';
    is $M->delete(name => 'one'), 1, 'delete by another column';
    is_deeply [ map $_->{id}, @{ $M->all->{rows} } ], [2, 11], 'what is left';
    ok !glob("$FILE.tmp.*"), 'no temporary file left behind';

    put($FILE, { things => [ { id => 'abc', name => 'x' } ] });
    like do { local $@; eval { $M->create({ name => 'y' }) }; $@ },
        qr/existing keys are not all integers/, 'create: no next key after a string key';

    unlink $FILE;
    is $M->create({ name => 'first' })->{id}, 1, 'create on a missing file makes it';
    is_deeply slurp_json($FILE), { things => [ { id => 1, name => 'first' } ] }, '...with just the table';
}

# ---- two writers ----------------------------------------------------------------------------

SKIP: {
    skip 'no fork', 1 unless $Config::Config{d_fork} || eval { require Config; $Config::Config{d_fork} };
    put($FILE, { things => [] });
    my @kids;
    for my $w (1 .. 4) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            my $m = JFApp->punk_app->model_instance('Thing');
            $m->create({ id => $w * 100 + $_, name => "w$w" }) for 1 .. 25;
            require POSIX;
            POSIX::_exit(0);
        }
        push @kids, $pid;
    }
    waitpid $_, 0 for @kids;
    is scalar @{ slurp_json($FILE)->{things} }, 100, 'four forked writers lose none of 100 rows';
}

done_testing;
