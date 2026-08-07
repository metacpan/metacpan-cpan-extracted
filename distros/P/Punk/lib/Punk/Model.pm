package Punk::Model;

use 5.010;
use strict;
use warnings;
use Punk (); 

our $VERSION = '0.02';

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

=head1 DESCRIPTION

A model class C<use>s C<Punk::Model>, names its C<table> and its
C<field>s, and inherits a fixed six-method contract that delegates to a
storage backend - L<Punk::Model::DBI> by default. Rows are plain
hashrefs: fast, and directly JSON-encodable by a controller.

The class is registered with C<< model 'Book' >> in the app; the
instance is built once per worker on first C<< $c->model('Book') >> and
cached (fork-safe). Backends swap with C<< database backend => 'Class' >>
- any class honouring the contract works.

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
    all()                      -> search({}, {})
    create(\%data)             -> created row hashref
    update(\%key_and_changes)  -> updated row hashref
    delete(%key)               -> count

C<create> validates C<\%data> against the field schema (required
included); C<update> validates the changes (the primary key excluded,
required relaxed). A validation failure croaks. C<search> options are
the backend's; L<Punk::Model::DBI> takes C<limit> and an opaque C<after>
pagination token.

=head1 METHODS

=head2 get(%key)

The row named by C<%key> (usually the primary key) as a hashref, or undef.

=head2 search(\%filter, \%opts)

The C<{ rows, has_more_data, next }> page for the equality C<%filter> and
backend C<%opts> (L<Punk::Model::DBI> takes C<limit> and C<after>).

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

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
