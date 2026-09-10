package Punk::Model;

use 5.010;
use strict;
use warnings;
use Punk (); 

our $VERSION = '0.48';

1;

__END__

=head1 NAME

Punk::Model - the storage-agnostic model tier

=head1 SYNOPSIS

    package MyApp::Model::Book;
    use Punk::Model;

    table 'books';
    field id      => { type => 'integer', primary => 1 };
    field title   => { type => 'string', required => 1, minLength => 1 };
    field author  => { type => 'string' };
    field created => { type => 'string' };

    1;

    # in the app
    database dsn => 'dbi:SQLite:dbname=myapp.db';
    model    'Book';

    # in a controller
    my $book = $c->model('Book')->get(id => $c->param('id'));
    my $page = $c->model('Book')->search({ author => 'Gibson' },
                                         { limit => 20 });

    # ... or, on the non-blocking backend, the same calls return futures
    return $c->model('Book')->get(id => $c->param('id'))->then(sub {
        my ($book) = @_;
        $c->render('book/view', { book => $book });
    });

=head1 DESCRIPTION

A model class C<use>s C<Punk::Model>, names its C<table> and its
C<field>s, and inherits a fixed six-method contract that delegates to a
storage backend - L<Punk::Model::DBI> by default. Rows are plain
hashrefs: fast, and directly JSON-encodable by a controller.

The class is registered with C<< model 'Book' >> in the app; the
instance is built once per worker on first C<< $c->model('Book') >> and
cached (fork-safe). Backends swap with C<< database backend => 'Class' >>
- any class honouring the contract works.

=head2 A backend may return futures

The contract fixes the B<methods> and the B<result shapes>, not whether a
result has arrived yet. The model tier passes a backend's return value
through untouched, and Punk's dispatcher awaits any future a handler
returns, so a backend is free to be asynchronous.

Both shipped backends use that freedom differently, and which one you pick
decides how handlers are written:

=over 4

=item * L<Punk::Model::DBI> (the B<default>) returns the value itself, and
blocks the worker for the whole database round trip.

    my $book = $c->model('Book')->get(id => 1);

=item * L<Punk::Model::DBIx::Loop> returns a L<Punk::Future> from every
method. The query runs on the worker's event loop, so the worker serves
other requests while it is in flight. Select it with
C<< database backend => 'Punk::Model::DBIx::Loop' >>.

    return $c->model('Book')->get(id => 1)->then(sub { ... });

=back

Validation is synchronous on both: C<create>/C<update> croak at the call
site on a bad payload rather than failing a future, because a payload that
does not match the field schema is a programming error rather than a query
failure.

=head1 DECLARING A MODEL

=head2 table $name

The backing table (or collection) name. Required.

=head2 field $name => \%spec

One field. The spec is JSON-Schema-flavoured; C<primary =E<gt> 1> marks
the primary key (used for ordering and keyset pagination), C<required>
marks it required for C<create>, and the schema keywords C<type>,
C<format>, C<pattern>, C<enum>, C<minLength>/C<maxLength>,
C<minimum>/C<maximum>, C<multipleOf>, C<minItems>/C<maxItems> flow into
the validator. With no field marked primary an C<id> field is assumed.

=head2 Subclassing a model

    package MyApp::Model::PushSubscription;
    use parent 'Punk::Model::PushSubscription';
    use Punk::Model;                       # only if you declare something

    field team_id => { type => 'integer' };

A subclass inherits its parent's table and fields. C<use Punk::Model> in the
subclass is needed only when it declares something of its own: another field,
a different C<table>, or a C<field> redeclared to change its spec.

Nearest wins. A redeclared field keeps the position the parent gave it, so
adding a subclass does not shift the column order. Declaring nothing needs no
C<use Punk::Model> at all - C<< use parent 'Some::Model' >> is a complete
model.

This is how a plugin's shipped model is adapted: L<Punk::Plugin::Push> ships
L<Punk::Model::PushSubscription>, and an application that wants an extra
column subclasses it rather than copying the table out.

The metadata is merged when it is read, not when the subclass is compiled.
C<table> and C<field> are statements in the package body and run when the
class loads, which is after C<use Punk::Model> has already returned - a
subclass that copied its parent at C<use> time would copy an empty one.

=head2 validate $bool

Force create/update validation on or off. The default is on when any
field carries a constraint (C<required> or a schema keyword), off
otherwise.

=head2 database $name

The configured database this model lives in - one of the names given to
the app's C<database> keyword. Defaults to the unnamed default database.
Every model on the same database shares one connection per worker.

=head1 THE CONTRACT

    get(%key)                  -> row hashref | undef
    search(\%filter, \%opts)   -> { rows => [...], has_more_data => 0|1,
                                    next => $token | undef }
    count(\%filter)            -> how many rows match
    all()                      -> search({}, {})
    create(\%data)             -> created row hashref
    update(\%key_and_changes)  -> updated row hashref
    delete(%key)               -> count

C<create> validates C<\%data> against the field schema (required
included); C<update> validates the changes (the primary key excluded,
required relaxed). A validation failure croaks. Both shipped backends take
the same C<search> options - C<limit>, C<order_by> and an opaque C<after>
pagination token - and mint the token the same way, so a C<next> from one
decodes on the other.

On L<Punk::Model::DBIx::Loop> each of these is the result the returned
L<Punk::Future> B<resolves to>, not what the call hands back - see
L</"A backend may return futures">.

=head2 The filter

A filter is a hashref of field name to either a plain value or a hashref
of operator to value. Terms AND together.

    { status => 'open' }                          status = ?
    { closed => undef }                           closed IS NULL
    { price  => { '>=' => 10, '<' => 50 } }       price >= ? AND price < ?
    { id     => { in => \@ids } }                 id IN (?, ?, ...)
    { email  => { like => '%@example.com' } }     email LIKE ?
    { title  => { starts_with => '100%' } }       title LIKE ? ESCAPE '\'

The operators are C<=> C<!=> C<E<lt>> C<E<lt>=> C<E<gt>> C<E<gt>=> C<in>
C<not_in> C<like> and C<starts_with>, and that is the whole set. C<=> and
C<!=> against C<undef> are C<IS NULL> and C<IS NOT NULL>; the ordered
comparisons and C<like> refuse an undef. C<in> over an empty list matches
nothing and C<not_in> over one matches everything, rather than being a
syntax error. C<like> passes the value through with the caller's own
wildcards; C<starts_with> escapes C<%>, C<_> and C<\> in the value and
appends the wildcard itself, so C<'100%'> is the four characters and a
prefix search cannot be widened by what a user typed.

Every field name in a filter is checked against the model's declared
fields and every operator against the set above B<before> any SQL exists,
and the values are bound, never interpolated. That is what makes a filter
that arrived in a request body safe to hand to C<search> - with one thing
said plainly: names and operators are validated, values are not typed. A
string where the column is an integer is the driver's to compare or
refuse.

A bare arrayref as a value croaks and names C<in>; an unknown field, an
unknown operator, an empty operator hash and a misspelled option all
croak naming what they saw.

=head2 Ordering

    order_by => 'created'
    order_by => [ created => 'desc' ]
    order_by => [ author => 'asc', created => 'desc' ]

Columns and directions, validated the same way. The primary key is always
appended as the tie-breaker when it is not named, in the direction of the
last named column - so C<< created => 'desc' >> pages newest-first all the
way down, ids included. Without that a non-unique sort column would skip
and repeat rows across pages, invisibly. With no C<order_by> a search is
ordered by the primary key, as it always was.

=head2 Paging

C<search> returns one page: C<limit> rows (default 20), C<has_more_data>
from fetching one row past it, and C<next>, an opaque url-safe token that
continues from the last row under the same ordering - a keyset
continuation, never an offset, so a page is stable while rows are inserted
ahead of it. Hand C<next> back as C<after>.

A token belongs to the ordering it was minted under. Presented against a
different C<order_by> it is refused rather than applied to the wrong
columns; the plain token a search without C<order_by> mints has the shape
it always had and still pages the plain ordering. A sort column holding
NULL compares unknown and falls out of every page, which is the
database's rule - order by columns that are NOT NULL.

=head2 Schema

A model declares its fields; it does not create its table. The
Punk-Sqitch distribution manages the schema as a Sqitch plan:
C<punk sqitch init> once, C<< punk sqitch add users --model User >> for a
change drafted from the model's fields, C<punk sqitch deploy> to apply
it, and a boot check that refuses to start an application whose schema is
behind its plan. See L<Punk::Sqitch>.

=head2 Transactions

A transaction belongs to a database, not to a model, so it lives on the
context: see L<Punk::Context/txn> and L<Punk::Txn>.

    my $order = $c->txn(sub {
        my ($tx) = @_;
        my $o = $tx->model('Order')->create(\%data);
        $tx->model('Stock')->update({ id => $sku, held => $held + 1 });
        return $o;
    });

C<< $tx->model >> is the model bound to the transaction. On
L<Punk::Model::DBI> every model on that database is inside it anyway -
one connection per worker - so the binding is a check. On
L<Punk::Model::DBIx::Loop> it is the only way in: a statement runs on a
pool, DBIx::Loop pins a transaction to one slot, and a model reached
through C<< $c->model >> inside the block runs B<outside> the
transaction. The block's value comes back, on DBI as the value and on
DBIx::Loop as a L<Punk::Future> that resolves after COMMIT; a die rolls
back and rethrows.

=head1 METHODS

=head2 get(%key)

The row named by C<%key> (usually the primary key) as a hashref, or undef.

=head2 search(\%filter, \%opts)

The C<{ rows, has_more_data, next }> page for C<%filter> (see L</"The
filter">) and C<%opts>: C<limit>, C<order_by> and C<after>.

=head2 count(\%filter)

How many rows match C<%filter> - the same filter C<search> takes, the same
validation, no page.

=head2 all

C<search({}, {})> - every row, first page.

=head2 create(\%data)

Validate (when the model has constraints) and insert; the stored row.

=head2 update(\%key_and_changes)

Validate the changes and update the row named by the primary key; the
stored row.

=head2 delete(%key)

Delete the row(s) named by C<%key>; the affected count.

=head2 backend

The backend instance the contract delegates to.

=head2 meta

The compiled class metadata (table, fields, primary key).

=head1 CUSTOM METHODS

A model class is an ordinary package - add your own methods. The instance
C<< $c->model('Book') >> hands back is blessed into the model class, so a
method receives it as its invocant and can call the contract (and the
backend) directly:

    package MyApp::Model::Book;
    use Punk::Model;

    table 'books';
    field id     => { type => 'integer', primary => 1 };
    field title  => { type => 'string', required => 1 };
    field author => { type => 'string' };

    sub by_author {
        my ($self, $who) = @_;
        return $self->search({ author => $who }, { limit => 50 })->{rows};
    }

    sub latest {
        my ($self) = @_;
        return $self->search({}, { limit => 1 })->{rows}[0];
    }

    # in a controller
    my $books = $c->model('Book')->by_author('Gibson');

Your methods sit alongside the six contract methods; keep query logic here
rather than in controllers. Everything the contract exposes - C<search>,
C<get>, C<create>, C<< $self->backend >>, C<< $self->meta >> - is available
to them.

=head1 WRITING A BACKEND

L<Punk::Model::DBI> is the default backend, not the only one. A backend is
any class implementing the six-method contract; point a database at it with
C<< database $name => { backend => 'Class', ... } >> and a model reaches it
by selecting that database (L</database>). This is how a model tier over
something other than SQL - a search index, a document store, an HTTP
service - plugs in without touching the framework.

The class must provide a constructor and the six methods:

    package Punk::Model::ElasticSearch;

    # Built once per worker by Punk::Model. %args carries:
    #   database => \%conn   the database options minus `backend`
    #                        (your dsn / nodes / auth / ...)
    #   table    => $name    the model's table keyword (here: the index)
    #   primary  => $field   the primary-key field name
    #   columns  => \@names  the declared field names, in order
    sub new {
        my ($class, %args) = @_;
        bless { ... }, $class;
    }

    sub get    { my ($self, %key) = @_;  ... }   # row hashref | undef
    sub search { my ($self, $filter, $opts) = @_;
                 ...
                 return { rows => \@rows, has_more_data => 0|1,
                          next => $token|undef };
    }
    sub all    { $_[0]->search({}, {}) }
    sub create { my ($self, $data) = @_;  ...; return \%row }
    sub update { my ($self, $data) = @_;  ...; return \%row }
    sub delete { my ($self, %key) = @_;   ...; return $count }

Contract notes: rows are plain hashrefs; C<search> returns the
C<{ rows, has_more_data, next }> page (C<next> an opaque token your own
C<search> understands via C<< $opts->{after} >>, or undef); C<create> and
C<update> return the stored row; C<delete> returns a count. Field
validation happens in L<Punk::Model> before C<create>/C<update> are called,
so a backend never re-validates. Nothing else is required - no base class,
no C<use Punk::Model>.

=head1 SEE ALSO

L<Punk::Model::DBI>, L<Punk>, L<Punk::Context>, L<JSON::Schema::Fast>.

L<Punk::Validate> is the other half of the same coin: the model
croaks at write time because bad data reaching it is a bug, while the
request edge collects, because bad input there is the expected case.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
