#!perl

# Punk::Model::Computed: a base for read-only backends whose rows are worked
# out from the filter. The subclass declares its tables and writes one method
# a verb; the base checks the question and croaks on writes.
# Punk::Model::Computed::Error is the visitor's error, naming a field.

use 5.010;
use strict;
use warnings;
use utf8;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use B ();

my %RAN;

{
    package CTBackend;
    use parent -norequire, 'Punk::Model::Computed';
    BEGIN { require Punk::Model::Computed }

    __PACKAGE__->answers(
        squares => { ask => [qw(n upto)], ops => { upto => ['<', '<='] } },
        runs    => { ask => [qw(slug input options)], as_is => ['options'] },
    );

    sub _get_squares {
        my ($self, $f) = @_;
        my $n = $f->{n}{'='};
        $self->error(n => 'n is required') unless defined $n;
        $self->error(n => "n is a whole number, not '$n'") unless $n =~ /\A\d+\z/;
        return $self->cached($self->cache_key(get => $f), sub {
            $RAN{get}++;
            return { n => $n, square => $n * $n };
        });
    }

    sub _search_squares {
        my ($self, $f, $o) = @_;
        my $limit = $self->limit($o, 3, 5, 'squares');
        my $upto = $f->{upto} or $self->error(upto => 'upto is required');
        my $end = exists $upto->{'<='} ? $upto->{'<='} : $upto->{'<'} - 1;
        my $from = defined $o->{after} ? $o->{after} + 1 : 1;
        my @rows = map { { n => $_, square => $_ * $_ } } grep { $_ <= $end } $from .. $from + $limit;
        my $more = @rows > $limit;
        splice @rows, $limit;
        return { rows => \@rows, has_more_data => $more ? 1 : 0, next => $more ? $rows[-1]{n} : undef };
    }

    sub _count_squares {
        my ($self, $f) = @_;
        my $u = $f->{upto} or $self->error(upto => 'upto is required');
        return exists $u->{'<='} ? $u->{'<='} : $u->{'<'} - 1;
    }

    sub _get_runs {
        my ($self, $f) = @_;
        my $input = $f->{input}{'='} // '';
        my @out = $self->wrap(input => sub {
            die "Some::Dist->parse: unbalanced bracket at /x/y/Dist.pm line 12.\n" if $input eq '[';
            die CTBackend::MyError->new(input => 'mine') if $input eq 'own';
            die { not => 'an object' } if $input eq 'hash';
            return (uc $input, wantarray ? 'list' : 'scalar');
        });
        return { slug => $f->{slug}{'='}, output => $out[0], context => $out[1], options => $f->{options}{'='} };
    }

    package CTBackend::MyError;
    our @ISA = ('Punk::Model::Computed::Error');

    package CTChild;
    our @ISA = ('CTBackend');
    __PACKAGE__->answers(cubes => { ask => ['n'] });
    sub _get_cubes { my ($self, $f) = @_; return { n => $f->{n}{'='}, cube => $f->{n}{'='} ** 3 } }
}

{
    package CTApp;
    use Punk;
    database sq    => { backend => 'CTBackend', cache => 2 };
    database child => { backend => 'CTChild' };
}
{
    package CTApp::Model::Square;
    use Punk::Model;
    database 'sq';
    table 'squares';
    field n      => { type => 'integer', primary => 1 };
    field upto   => { type => 'integer' };
    field square => { type => 'integer' };
}
{
    package CTApp::Model::Run;
    use Punk::Model;
    database 'sq';
    table 'runs';
    field slug    => { type => 'string', primary => 1 };
    field input   => { type => 'string' };
    field options => { type => 'object' };
    field output  => { type => 'string' };
}
{
    package CTApp::Model::Cube;
    use Punk::Model;
    database 'child';
    table 'cubes';
    field n    => { type => 'integer', primary => 1 };
    field cube => { type => 'integer' };
}
CTApp->to_app;
my $app = CTApp->punk_app;
my $SQ = $app->model_instance('Square');
my $RUN = $app->model_instance('Run');
my $B = $SQ->backend;

sub dies_like (&$$) {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    my $e = $@;
    ok !$ok && "$e" =~ $re, $name or diag "got: " . ($ok ? 'no death' : "$e");
    return $e;
}

sub visitor (&$$$) {
    my ($code, $field, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    my $e = $@;
    my $good = !$ok && ref $e && $e->isa('Punk::Model::Computed::Error')
        && $e->field eq $field && $e->message =~ $re;
    ok $good, $name or diag "got: " . ($ok ? 'no death' : ref $e ? $e->field . ': ' . $e->message : $e);
    return $e;
}

# ---- declaring --------------------------------------------------------------------

isa_ok $B, 'Punk::Model::Computed';
is $B->table, 'squares', 'table';
is ref $B->app, ref $app, 'app: handed over by Punk::Model';
is_deeply [ CTBackend->answers ], [qw(runs squares)], 'answers: the tables, sorted';
is_deeply [ CTChild->answers ], [qw(cubes runs squares)], 'answers: a subclass adds to its parent';

dies_like { CTBackend->answers('bad name' => {}) } qr/a table's name is a word, not 'bad name'/, 'a table is a word';
dies_like { CTBackend->answers(t => []) } qr/t's declaration is a hash reference/, 'a declaration is a hash';
dies_like { CTBackend->answers(t => { asks => [] }) } qr/t's declaration has no 'asks' \(known: ask, as_is, ops\)/,
    'an unknown key croaks';
dies_like { CTBackend->answers(t => { ask => 'n' }) } qr/t's ask is a list of field names/, 'ask is a list';
dies_like { CTBackend->answers(t => { ask => ['n'], ops => { m => ['<'] } }) }
    qr/t's ops names 'm', which it is not asked by/, 'ops names an asked field';
dies_like { CTBackend->answers(t => { ask => ['n'], ops => { n => ['~'] } }) }
    qr/t's 'n' names an operator '~' \(known: =, !=/, 'ops: a known operator';
dies_like { CTBackend->answers(t => { ask => ['n'], as_is => ['m'] }) }
    qr/t's as_is names 'm', which it is not asked by/, 'as_is names an asked field';
dies_like { CTBackend->answers(t => { ask => ['n'], as_is => ['n'], ops => { n => ['<'] } }) }
    qr/t's 'n' is taken as it is and takes no operators/, 'as_is and ops exclude each other';
dies_like { CTBackend->answers('t') } qr/answers takes table => \{ \.\.\. \} pairs/, 'pairs';
is_deeply [ CTBackend->answers ], [qw(runs squares)], 'a refused declaration is not kept';

dies_like { CTBackend->new(table => 'nope', columns => []) }
    qr/CTBackend: no table 'nope' \(it answers runs, squares\)/, 'new: a table the class does not answer';
dies_like { CTBackend->new(table => 'squares', database => { cache => 'lots' }) }
    qr/the database's cache is how many answers to keep, a whole number \(0 for none\), not 'lots'/,
    'new: cache is a whole number';
{
    package CTEmpty;
    our @ISA = ('Punk::Model::Computed');
}
dies_like { CTEmpty->new(table => 'x') } qr/CTEmpty: no table 'x' \(it declares none: answers\(table => \{\.\.\.\}\)\)/,
    'new: a class that declares nothing says so';

# ---- get, search, count -------------------------------------------------------------

is_deeply $SQ->get(n => 7), { n => 7, square => 49 }, 'get';
is_deeply $SQ->search({ upto => { '<=' => 4 } }), {
    rows => [ map { { n => $_, square => $_ * $_ } } 1 .. 3 ], has_more_data => 1, next => 3,
}, 'search: the first page';
is_deeply $SQ->search({ upto => { '<=' => 4 } }, { after => 3 })->{rows}, [ { n => 4, square => 16 } ],
    'search: the page after';
is scalar @{ $SQ->search({ upto => { '<' => 100 } }, { limit => 5 })->{rows} }, 5, 'search: limit';
is $SQ->count({ upto => { '<' => 10 } }), 9, 'count';

# the program's faults croak
dies_like { $SQ->get(square => 4) } qr/'square' is an answer of squares, not something to ask it by/,
    'a filter on an answer croaks';
dies_like { $SQ->get(m => 4) } qr/a filter names 'm', which is not a field of squares \(have: n, square, upto\)/,
    'a field the model does not declare croaks';
dies_like { $SQ->search({ n => { '<' => 3 } }) } qr/'n' takes no operator '<' here \(only =\)/,
    'an operator the field does not take';
dies_like { $SQ->search({ upto => { '>' => 3 } }) } qr/'upto' takes no operator '>' here \(it takes =, <, <=\)/,
    'an operator the field does not take names those it does';
dies_like { $SQ->search({ upto => {} }) } qr/an empty operator hash for 'upto'/, 'an empty operator hash';
dies_like { $SQ->search({ n => [1, 2] }) } qr/a list for 'n' is \{ in => \[\.\.\.\] \}/, 'a bare list';
dies_like { $B->search([]) } qr/CTBackend: a filter is a hash reference/, 'a filter is a hash';
dies_like { $B->search({}, []) } qr/CTBackend: options are a hash reference/, 'options are a hash';
dies_like { $SQ->search({ upto => 3 }, { limt => 3 }) } qr/unknown search option 'limt' \(known: after, limit\)/,
    'an unknown option';
dies_like { $SQ->search({ upto => 3 }, { order_by => ['n'] }) }
    qr/the squares rows come in their own order, which order_by cannot change/, 'order_by croaks';
is $B->search({ upto => { '<' => 2 } }, { order_by => undef })->{rows}[0]{n}, 1, 'an undef order_by is no ordering';
dies_like { $SQ->get('n') } qr/get takes field => value pairs/, 'get: pairs';

# a verb the table has no method for
my $CU = $app->model_instance('Cube');
is_deeply $CU->get(n => 2), { n => 2, cube => 8 }, 'a subclass answers its own table';
dies_like { $CU->search({ n => 2 }) } qr/CTChild: the cubes table answers get, not search \(define _search_cubes\)/,
    'search with no _search_ method croaks, naming what there is';
dies_like { $CU->all } qr/the cubes table answers get, not search/, 'all is search({}, {})';

# writes
for my $verb (qw(create update delete)) {
    dies_like { $SQ->backend->$verb({ n => 1 }) } qr/CTBackend: $verb - the squares rows are worked out, not stored/,
        "$verb croaks";
}

# ---- the visitor's errors ---------------------------------------------------------------

my $e = visitor { $SQ->get(n => 'x') } n => qr/\An is a whole number, not 'x'\z/, 'error: field and message';
is "$e", "n is a whole number, not 'x'", 'error: stringifies to the message';
is_deeply $e->TO_JSON, { field => 'n', message => "n is a whole number, not 'x'" }, 'error: TO_JSON';
visitor { $SQ->search({ upto => 3 }, { limit => 0 }) } limit => qr/\Alimit must be a whole number from 1 to 5\z/,
    'limit: 0';
visitor { $SQ->search({ upto => 3 }, { limit => '2x' }) } limit => qr/\Alimit must be a whole number from 1 to 5\z/,
    'limit: not a number';
visitor { $SQ->search({ upto => 3 }, { limit => 6 }) } limit => qr/\Aat most 5 squares at a time\z/, 'limit: over';
visitor { $SQ->search({ upto => 3 }, { limit => '99999999999999999999' }) } limit => qr/\Aat most 5 squares/,
    'limit: far over';
visitor { $B->limit({}, undef, 5) } limit => qr/\Alimit must be/, 'limit: no default and none given';
is $B->limit({}, 3, 5), 3, 'limit: the default';
is $B->limit({ limit => '4' }, 3, 5), 4, 'limit: the option';
visitor { $B->limit({ limit => 9 }, 3, 5) } limit => qr/\Aat most 5 rows at a time\z/, 'limit: rows by default';
visitor { $B->error(zone => 'no such zone') } zone => qr/\Ano such zone\z/, 'error';
visitor { Punk::Model::Computed::Error->throw(f => 'm') } f => qr/\Am\z/, 'throw';

# wrap
is_deeply $RUN->get(slug => 's', input => 'abc', options => { gfm => 1, list => [1] }),
    { slug => 's', output => 'ABC', context => 'list', options => { gfm => 1, list => [1] } },
    'wrap: returns in the caller\'s context, and as_is keeps a hash whole';
visitor { $RUN->get(slug => 's', input => '[') } input => qr/\Aunbalanced bracket\z/,
    'wrap: a die becomes the field\'s error in the dist\'s words';
$e = visitor { $RUN->get(slug => 's', input => 'own') } input => qr/\Amine\z/, 'wrap: an error of the kind passes through';
isa_ok $e, 'CTBackend::MyError', 'wrap: ... unchanged';
visitor { $RUN->get(slug => 's', input => 'hash') } input => qr/\AHASH\(0x/, 'wrap: a plain reference is its string';
is scalar($B->wrap(f => sub { wantarray ? 'list' : 'scalar' })), 'scalar', 'wrap: scalar context';
is_deeply [ $B->wrap(f => sub { (1, 2, 3) }) ], [1, 2, 3], 'wrap: list context';
dies_like { $B->wrap(f => 'nope') } qr/wrap takes a field and a code reference/, 'wrap: a code reference';

# said and from
my $E = 'Punk::Model::Computed::Error';
is $E->said("Time::Keeper->new: no such month at lib/Time/Keeper.pm line 40.\n"), 'no such month', 'said';
is $E->said("bad at x.pm line 3, <STDIN> line 2.\n"), 'bad', 'said: the filehandle\'s line too';
is $E->said("bad at x.pm line 3, <\$fh> chunk 7.\n"), 'bad', 'said: a chunk';
is $E->said("plain\n"), 'plain', 'said: a newline';
is $E->said("what is at stake line 3 here"), 'what is at stake line 3 here', 'said: " at " mid-text stays';
is $E->said("a -> b: c"), 'a -> b: c', 'said: not a method prefix';
is $E->said("Café at x.pm line 1.\n"), 'Café', 'said: characters';
ok utf8::is_utf8($E->said("Café at x.pm line 1.\n")), 'said: ... kept as characters';
my $f = $E->from(zone => "Z->m: gone at a line 1.\n");
is ref $f, $E, 'from: a new error';
is $f->field . '|' . $f->message, 'zone|gone', 'from: field and words';
my $own = CTBackend::MyError->new(x => 'y');
is $E->from(zone => $own), $own, 'from: an error of the kind is itself';
is ref(CTBackend::MyError->new(a => 'b')), 'CTBackend::MyError', 'new: the subclass';

# ---- the cache --------------------------------------------------------------------------

$B->cache_clear;
%RAN = ();
$SQ->get(n => 2) for 1 .. 3;
is $RAN{get}, 1, 'cached: asked three times, worked out once';
my $first = $SQ->get(n => 2);
is $SQ->get(n => 2), $first, 'cached: the same reference';
$SQ->get(n => 3);
is $B->cache_size, 2, 'cache_size';
$SQ->get(n => 2);
$SQ->get(n => 4);
is $B->cache_size, 2, 'cached: kept to the database\'s cache';
%RAN = ();
$SQ->get(n => 2);
is $RAN{get} // 0, 0, 'cached: the most recently used stays';
$SQ->get(n => 3);
is $RAN{get}, 1, 'cached: the least recently used went first';
$B->cache_clear;
is $B->cache_size, 0, 'cache_clear';

%RAN = ();
my $n = 0;
$B->cached(undef, sub { $n++ }) for 1 .. 3;
is $n, 3, 'cached: an undef key runs every time';
is $B->cache_size, 0, '... and keeps nothing';
dies_like { $B->cached('k', 'v') } qr/cached takes a key and a code reference/, 'cached: a code reference';
dies_like { $B->cached('k', sub { die "inside\n" }) } qr/\Ainside\n\z/, 'cached: a die passes through';
is $B->cache_size, 0, '... and nothing is kept';

my $none = CTBackend->new(table => 'squares', database => { cache => 0 });
$none->cached('k', sub { 1 }) for 1 .. 2;
is $none->cache_size, 0, 'cache => 0 keeps nothing';

is $B->cache_key(a => { y => 1, x => [2, undef] }), $B->cache_key(a => { x => [2, undef], y => 1 }),
    'cache_key: hash order does not matter';
isnt $B->cache_key('a', 'b'), $B->cache_key("a\ts1:b"), 'cache_key: parts cannot run together';
isnt $B->cache_key(undef), $B->cache_key(''), 'cache_key: undef is not empty';
isnt $B->cache_key([1]), $B->cache_key({ 1 => undef }), 'cache_key: a list is not a hash';
is $B->cache_key('é'), do { my $b = 'é'; utf8::encode($b); utf8::decode($b); $B->cache_key($b) },
    'cache_key: characters, however held';
like $B->cache_key(bless {}, 'CTObj'), qr/oCTObj=/, 'cache_key: an object as its class and string';
my $num = 10;
$B->cache_key($num);
ok !(B::svref_2object(\$num)->FLAGS & B::SVf_POK()), 'cache_key: leaves a number a number';
dies_like { $B->cache_key(sub {}) } qr/a cache key is made of plain values, hashes, lists and objects, not a CODE reference/,
    'cache_key: a code reference croaks';
my $loop = []; push @$loop, $loop;
dies_like { $B->cache_key($loop) } qr/a cache key nested deeper than 64/, 'cache_key: a cycle croaks';

# ---- filter and options, for the subclass's own methods ----------------------------------

is_deeply $B->filter({ n => 3, upto => { '<' => 5 } }), { n => { '=' => 3 }, upto => { '<' => 5 } }, 'filter';
is_deeply $B->filter(undef), {}, 'filter: none';
is_deeply $B->options({ limit => 2, after => 'x' }), { limit => 2, after => 'x' }, 'options';
my $given = { upto => { '<' => 5 } };
$B->filter($given)->{upto}{'<'} = 99;
is $given->{upto}{'<'}, 5, 'filter: a copy';

done_testing;
