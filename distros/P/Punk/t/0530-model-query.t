#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk::Model;

BEGIN {
    eval { require DBI; require DBD::SQLite; 1 }
        or plan skip_all => 'DBI + DBD::SQLite required for these tests';
}

# The model tier's second layer, as one conformance suite over both shipped
# backends: filter operators, ordering, the keyset continuation under an
# ordering, and count. An operator that works on one backend and not the
# other is a failure of the contract, so every assertion below runs twice
# when DBIx::Loop is installed - against Punk::Model::DBI, and against
# Punk::Model::DBIx::Loop with each future awaited.
#
# What is checked is the CONTRACT, never the SQL: the rows that come back,
# the rows that do not, and the words of the croak when a filter is wrong.

{
    package T::Model::Book;
    use Punk::Model;
    table 'books';
    field id        => { type => 'integer', primary => 1 };
    field title     => { type => 'string', required => 1 };
    field author    => { type => 'string' };
    field price     => { type => 'integer' };
    field published => { type => 'integer' };
}

my $dir = File::Temp->newdir;
my $dsn = "dbi:SQLite:dbname=$dir/books.db";
{
    my $dbh = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
    $dbh->do(q{
        CREATE TABLE books (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            title     TEXT NOT NULL,
            author    TEXT,
            price     INTEGER,
            published INTEGER
        )
    });
    my $ins = $dbh->prepare(
        'INSERT INTO books (title, author, price, published) VALUES (?,?,?,?)');
    # id  title            author      price published
    $ins->execute('Neuromancer',     'Gibson',     12, 1984);   # 1
    $ins->execute('Count Zero',      'Gibson',     10, 1986);   # 2
    $ins->execute('Snow Crash',      'Stephenson', 15, 1992);   # 3
    $ins->execute('Cryptonomicon',   'Stephenson', 20, 1999);   # 4
    $ins->execute('Accelerando',     'Stross',     11, 2005);   # 5
    $ins->execute('100% Perl',       undef,        5,  undef);  # 6
    $ins->execute('10 Things',       'Stross',     8,  undef);  # 7
    $dbh->disconnect;
}

my @backends = ([ 'Punk::Model::DBI', { dsn => $dsn } ]);
if (eval { require DBIx::Loop; 1 }) {
    push @backends, [ 'Punk::Model::DBIx::Loop',
                      { dsn => $dsn, workers => 2,
                        backend => 'Punk::Model::DBIx::Loop',
                        attr => { PrintError => 0 } } ];
}

# a result, awaited when it is a future
sub r { my ($x) = @_; ref $x && eval { $x->isa('Punk::Future') } ? ($x->get)[0] : $x }
sub ids { my ($page) = @_; [ map { $_->{id} } @{ $page->{rows} } ] }

my %model;   # class => instance, for the cross-backend token test

for my $be (@backends) {
    my ($cls, $db) = @$be;
    my $m = T::Model::Book->_instantiate({ %$db });
    $model{$cls} = $m;
    isa_ok($m->backend, $cls, "backend under test");
    my $short = $cls =~ /Loop/ ? 'Loop' : 'DBI';
    note "---- $cls";

    # ---- operators ----------------------------------------------------------
    is_deeply(ids(r($m->search({ author => 'Gibson' }))), [1, 2],
        "$short: a plain value is equality");
    is_deeply(ids(r($m->search({ author => undef }))), [6],
        "$short: a plain undef is IS NULL, not a comparison nothing can match");
    is_deeply(ids(r($m->search({ author => { '!=' => 'Gibson' } }))), [3, 4, 5, 7],
        "$short: != (and SQL's NULL is not unequal to anything)");
    is_deeply(ids(r($m->search({ author => { '!=' => undef } }))), [1, 2, 3, 4, 5, 7],
        "$short: != undef is IS NOT NULL");
    is_deeply(ids(r($m->search({ price => { '<' => 10 } }))), [6, 7], "$short: <");
    is_deeply(ids(r($m->search({ price => { '<=' => 10 } }))), [2, 6, 7], "$short: <=");
    is_deeply(ids(r($m->search({ price => { '>' => 15 } }))), [4], "$short: >");
    is_deeply(ids(r($m->search({ price => { '>=' => 15 } }))), [3, 4], "$short: >=");
    is_deeply(ids(r($m->search({ price => { '>=' => 10, '<' => 15 } }))), [1, 2, 5],
        "$short: two operators on one column AND together");
    is_deeply(ids(r($m->search({ id => { in => [5, 1, 3] } }))), [1, 3, 5],
        "$short: in");
    is_deeply(ids(r($m->search({ id => { in => [] } }))), [],
        "$short: in an empty list is nothing");
    is_deeply(ids(r($m->search({ id => { not_in => [1, 2, 3, 4, 5] } }))), [6, 7],
        "$short: not_in");
    is_deeply(ids(r($m->search({ id => { not_in => [] } }))), [1 .. 7],
        "$short: not_in an empty list is everything");
    is_deeply(ids(r($m->search({ title => { like => '%Crash' } }))), [3],
        "$short: like, with the caller's wildcards");
    is_deeply(ids(r($m->search({ title => { like => '10%' } }))), [6, 7],
        "$short: like '10%' is a wildcard and matches both 10 titles");
    is_deeply(ids(r($m->search({ title => { starts_with => '10' } }))), [6, 7],
        "$short: starts_with a plain prefix");
    is_deeply(ids(r($m->search({ title => { starts_with => '100%' } }))), [6],
        "$short: starts_with escapes the percent - '100%' is four characters");
    is_deeply(ids(r($m->search({ author => 'Stross', price => { '<' => 10 } }))), [7],
        "$short: a plain value and an operator hash in one filter");

    # ---- what a bad filter says ---------------------------------------------
    {
        my $e = ''; eval { r($m->search({ colour => 'red' })) } or $e = $@;
        like($e, qr/the filter names 'colour', which is not a field of books/,
            "$short: a column that is not a field croaks");
        like($e, qr/have: author, id, price, published, title/,
            "$short: listing the fields");
    }
    {
        my $e = ''; eval { r($m->search({ price => { between => [1, 2] } })) } or $e = $@;
        like($e, qr/unknown operator 'between' on price/, "$short: an unknown operator croaks");
        like($e, qr/known: =, !=, <, <=, >, >=, in, not_in, like, starts_with/,
            "$short: listing the set");
    }
    {
        my $e = ''; eval { r($m->search({ id => [1, 2] })) } or $e = $@;
        like($e, qr/plain arrayref.*spelled \{ in => \[\.\.\.\] \}/,
            "$short: a bare arrayref croaks and names in");
    }
    {
        my $e = ''; eval { r($m->search({ price => { '>' => undef } })) } or $e = $@;
        like($e, qr/'>' on price needs a value, not undef/, "$short: > undef croaks");
    }
    {
        my $e = ''; eval { r($m->search({ id => { in => 5 } })) } or $e = $@;
        like($e, qr/'in' on id takes an arrayref/, "$short: in without a list croaks");
    }
    {
        my $e = ''; eval { r($m->search({ price => {} })) } or $e = $@;
        like($e, qr/empty hashref.*needs an operator/, "$short: an empty operator hash croaks");
    }
    {
        my $e = ''; eval { r($m->search({}, { limt => 5 })) } or $e = $@;
        like($e, qr/unknown search option 'limt' \(known: after, limit, order_by\)/,
            "$short: a misspelled option croaks instead of returning twenty rows");
    }

    # ---- ordering ------------------------------------------------------------
    is_deeply(ids(r($m->search({}, { order_by => 'price' }))), [6, 7, 2, 5, 1, 3, 4],
        "$short: order_by a column name, ascending");
    is_deeply(ids(r($m->search({}, { order_by => [ price => 'desc' ] }))),
        [4, 3, 1, 5, 2, 7, 6], "$short: order_by pairs, descending");
    is_deeply(ids(r($m->search({}, { order_by => [ author => 'asc', id => 'desc' ] }))),
        [6, 2, 1, 4, 3, 7, 5],
        "$short: a mixed ordering (nulls first on SQLite ascending)");
    is_deeply(ids(r($m->search({ author => 'Stross' }, { order_by => [ price => 'DESC' ] }))),
        [5, 7], "$short: direction is case-insensitive, and a filter still applies");
    {
        my $e = ''; eval { r($m->search({}, { order_by => [ price => 'down' ] })) } or $e = $@;
        like($e, qr/direction for price must be 'asc' or 'desc', not 'down'/,
            "$short: a direction typo croaks");
    }
    {
        my $e = ''; eval { r($m->search({}, { order_by => [ price => 'asc', price => 'desc' ] })) } or $e = $@;
        like($e, qr/order_by names price twice/, "$short: a repeated column croaks");
    }
    {
        my $e = ''; eval { r($m->search({}, { order_by => 'colour' })) } or $e = $@;
        like($e, qr/order_by names 'colour', which is not a field/,
            "$short: an order_by column that is not a field croaks");
    }
    {
        my $e = ''; eval { r($m->search({}, { order_by => [ 'price' ] })) } or $e = $@;
        like($e, qr/order_by takes \[ column => 'asc'\|'desc', \.\.\. \] pairs/,
            "$short: an odd list croaks");
    }

    # ---- the keyset continuation under an ordering ---------------------------
    {
        # page through a mixed ordering two at a time and prove the union of
        # the pages is the whole ordering with nothing skipped or repeated
        my @want = @{ ids(r($m->search({}, { order_by => [ author => 'asc', id => 'desc' ] }))) };
        my (@got, $after, $pages);
        do {
            my $p = r($m->search({}, { order_by => [ author => 'asc', id => 'desc' ],
                                       limit => 2, after => $after }));
            push @got, @{ ids($p) };
            $after = $p->{next};
            $pages++;
        } while (defined $after);
        is_deeply(\@got, \@want, "$short: paging under a mixed ordering walks the whole set");
        is($pages, 4, "$short: in four pages of two (the last short)");
    }
    {
        # the same, descending on a non-unique column: the pk tie-break keeps
        # the two Gibsons and the two Stephensons from straddling a page wrongly
        my @want = @{ ids(r($m->search({ author => { '!=' => undef } },
                                       { order_by => [ author => 'desc' ] }))) };
        my (@got, $after);
        do {
            my $p = r($m->search({ author => { '!=' => undef } },
                                 { order_by => [ author => 'desc' ], limit => 2, after => $after }));
            push @got, @{ ids($p) };
            $after = $p->{next};
        } while (defined $after);
        is_deeply(\@got, \@want, "$short: paging a non-unique sort column with a filter");
        is_deeply(\@want, [7, 5, 4, 3, 2, 1],
            "$short: and the tie-break follows the last direction - ids descend too");
    }
    {
        my $p1 = r($m->search({}, { order_by => [ price => 'asc' ], limit => 3 }));
        ok($p1->{has_more_data}, "$short: a page with more behind it says so");
        my $tok = $p1->{next};
        like($tok, qr/\A[A-Za-z0-9_-]+\z/, "$short: the token is url-safe");
        my $e = ''; eval { r($m->search({}, { order_by => [ price => 'desc' ], after => $tok })) } or $e = $@;
        like($e, qr/issued for a different ordering/,
            "$short: a token presented against another ordering is refused");
        $e = ''; eval { r($m->search({}, { after => $tok })) } or $e = $@;
        like($e, qr/issued for a different ordering/,
            "$short: ... including the plain pk ordering");
        my $plain = r($m->search({}, { limit => 2 }))->{next};
        $e = ''; eval { r($m->search({}, { order_by => 'price', after => $plain })) } or $e = $@;
        like($e, qr/issued without an order_by and cannot continue one/,
            "$short: and a plain token cannot continue an ordering");
        is_deeply(ids(r($m->search({}, { limit => 2, after => $plain }))), [3, 4],
            "$short: while the plain token still pages the plain ordering as it always did");
        $e = ''; eval { r($m->search({}, { after => 'not a token' })) } or $e = $@;
        like($e, qr/invalid pagination token/, "$short: garbage is refused");
    }

    # ---- count ---------------------------------------------------------------
    is(r($m->count), 7, "$short: count with no filter");
    is(r($m->count({ author => 'Stephenson' })), 2, "$short: count with a filter");
    is(r($m->count({ price => { '>=' => 10 }, published => { '!=' => undef } })), 5,
        "$short: count with operators");
    is(r($m->count({ id => { in => [] } })), 0, "$short: count over an empty in");
    {
        my $e = ''; eval { r($m->count({ colour => 1 })) } or $e = $@;
        like($e, qr/not a field of books/, "$short: count validates the filter too");
    }
    is(r($m->backend->count({ author => 'Gibson' })), 2,
        "$short: count on the backend directly, the same answer");

    # ---- a NULL in a sort column does not end the walk -----------------------
    # SQLite sorts NULL below every value, so an ascending walk starts in the
    # NULLs. A page that ended on one used to mint a token nothing came
    # after, and every later row - none of them NULL - was unreachable.
    my $walk = sub {
        my ($order, $limit) = @_;
        my (@seen, $after, $pages);
        while (++$pages <= 12) {
            my $p = r($m->search({}, { order_by => $order, limit => $limit,
                                       (defined $after ? (after => $after) : ()) }));
            push @seen, @{ ids($p) };
            last unless $p->{has_more_data};
            $after = $p->{next};
        }
        return \@seen;
    };
    for my $order ([ published => 'asc' ], [ author => 'asc' ],
                   [ author => 'asc', published => 'asc' ],
                   [ published => 'asc', author => 'desc' ]) {
        my $whole = ids(r($m->search({}, { order_by => $order, limit => 100 })));
        is(scalar @$whole, 7, "$short: @$order in one page is every row");
        for my $limit (1, 2, 3, 5) {
            is_deeply($walk->($order, $limit), $whole,
                "$short: @$order, $limit a page, reaches every row in order");
        }
    }
    # descending, the NULLs are last: a page that ends inside them continues
    # through them
    is_deeply($walk->([ published => 'desc' ], 6), [5, 4, 3, 2, 1, 7, 6],
        "$short: a page ending on a NULL at the END of the order continues");
    {
        my $p = r($m->search({}, { order_by => [ published => 'desc' ], limit => 7 }));
        ok(!$p->{has_more_data} && !defined $p->{next},
            "$short: and the last row being a NULL ends the walk cleanly");
    }

    # ---- limit ---------------------------------------------------------------
    for my $big ('9223372036854775807', '99999999999999999999999', 9**30) {
        my $p = r($m->search({}, { limit => $big }));
        is(scalar @{ $p->{rows} }, 7, "$short: limit => $big is every row");
        ok(!$p->{has_more_data}, "$short: ...and there is no more");
    }
    is(scalar @{ r($m->search({}, { limit => 0 }))->{rows} }, 1,
        "$short: a limit below one is one");

    # ---- an order_by with a hole in it ---------------------------------------
    {
        my @sparse; $sparse[1] = 'asc';
        my $e = ''; eval { r($m->search({}, { order_by => \@sparse })); 1 } or $e = $@;
        like($e, qr/one of the columns is undefined/,
            "$short: a sparse order_by croaks, where it used to crash");
        $e = ''; eval { r($m->search({}, { order_by => [ undef, 'asc' ] })); 1 } or $e = $@;
        like($e, qr/one of the columns is undefined/, "$short: ...and an undef column");
        my @gap = ('price'); $#gap = 1;
        $e = ''; eval { r($m->search({}, { order_by => \@gap })); 1 } or $e = $@;
        like($e, qr/must be 'asc' or 'desc'/, "$short: ...and a missing direction");
    }

    # ---- get and delete check their key columns ------------------------------
    for my $what (qw(get delete)) {
        my $e = ''; eval { r($m->backend->$what(nosuch => 1)); 1 } or $e = $@;
        like($e, qr/\Q$cls\E: $what names 'nosuch', which is not a field of books/,
            "$short: $what on an unknown column croaks");
        $e = ''; eval { r($m->backend->$what(id => 1, 'title" OR 1=1 --' => 1)); 1 } or $e = $@;
        like($e, qr/which is not a field of books/,
            "$short: ...and so does one that is not a name at all");
    }
    is(r($m->backend->get(id => 3))->{title}, 'Snow Crash',
        "$short: a known key column still fetches");
    is(r($m->count), 7, "$short: and nothing was deleted along the way");
}

# ---- a token minted on one backend decodes on the other ---------------------
if (@backends == 2) {
    my ($dbi, $loop) = @model{ 'Punk::Model::DBI', 'Punk::Model::DBIx::Loop' };
    my %o = (order_by => [ author => 'asc', id => 'desc' ], limit => 3);
    my $p1 = $dbi->search({}, { %o });
    my $p2 = r($loop->search({}, { %o, after => $p1->{next} }));
    is_deeply(ids($p2), [4, 3, 7],
        'a next token minted by the DBI backend continues on the async one');
    my $p3 = $dbi->search({}, { %o, after => $p2->{next} });
    is_deeply(ids($p3), [5], 'and back again to the last page');
    ok(!$p3->{has_more_data} && !defined $p3->{next}, 'which ends the walk');
}
else {
    note 'DBIx::Loop not installed: the cross-backend token test is skipped';
}

done_testing();
