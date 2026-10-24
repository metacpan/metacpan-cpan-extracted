package Punk::Model::Computed;

use 5.010;
use strict;
use warnings;
use Punk ();
use Punk::Model::Computed::Error ();

our $VERSION = '0.66';

1;

__END__

=head1 NAME

Punk::Model::Computed - a base for read-only model backends whose rows are worked out, not stored

=head1 SYNOPSIS

    # the backend
    package MyApp::Backend::Clock;
    use parent 'Punk::Model::Computed';

    __PACKAGE__->answers(
        zones => { ask => [qw(zone at)], ops => { zone => ['in'] } },
        runs  => { ask => [qw(rule at)], ops => { at => [qw(> >= < <=)] } },
    );

    sub _get_zones {
        my ($self, $f) = @_;
        my $zone = $f->{zone}{'='} // $self->error(zone => 'zone is required');
        return $self->wrap(zone => sub { My::Zones->row($zone) });
    }

    sub _search_runs {
        my ($self, $f, $o) = @_;
        my $limit = $self->limit($o, 10, 50, 'runs');
        my $key   = $self->cache_key(search => $f, $o);
        return $self->cached($key, sub { ... { rows => \@rows, has_more_data => 0, next => undef } });
    }

    # the application
    database clock => { backend => 'MyApp::Backend::Clock', cache => 512 };

    # a model
    package MyApp::Model::Zone;
    use Punk::Model;
    database 'clock';
    table    'zones';
    field zone   => { type => 'string', primary => 1 };
    field at     => { type => 'integer' };
    field offset => { type => 'integer' };

    # a controller
    my $row = eval { $c->model('Zone')->get(zone => $c->param('zone')) };
    return $c->json({ error => $@ }, 400)
        if ref $@ && $@->isa('Punk::Model::Computed::Error');

=head1 DESCRIPTION

A backend for L<Punk::Model> whose rows are not kept anywhere but worked out from
the filter: a calculator, a parser, a call into a module. The filter is the
question, and the rows are its answers. A subclass says which tables it answers and
how each may be asked, and writes one method a verb. The base does the rest of the
contract: it checks every filter and option the way Punk's own backends check
theirs, hands the subclass a question in one shape, and croaks on C<create>,
C<update> and C<delete>.

Two kinds of mistake are told apart. A program's (a field the model does not
declare, a field the table is not asked by, an operator or option it does not take,
an C<order_by>) croaks, as on L<Punk::Model::DBI>. A visitor's (a zone that does not
exist, input over a cap) dies with a L<Punk::Model::Computed::Error> naming the
field, which a controller can catch and show.

=head1 DECLARING THE TABLES

=head2 answers

    __PACKAGE__->answers($table => \%spec, ...);
    my @tables = __PACKAGE__->answers;

Declares the tables the class answers, each with:

=over 4

=item ask

The fields the table may be asked by. A filter on any other declared field of the
model croaks, as an answer and not a question.

=item ops

C<< { field => [operators] } >>: the operators each field takes beyond C<=>, from
Punk's set (C<!=>, C<< < >>, C<< <= >>, C<< > >>, C<< >= >>, C<in>, C<not_in>,
C<like>, C<starts_with>). A field not named here takes C<=> only.

=item as_is

Fields whose value is taken whole, a hash or a list included, rather than read as
operators: an C<options> hash given to C<get>.

=back

A subclass of a subclass inherits its parent's tables and may add or redeclare
some. With no arguments, C<answers> lists them all.

=head1 WRITING ONE

A model's C<table> names the table it asks, and C<new> croaks for a table the class
does not answer. Each verb calls a method of the subclass named for it and the
table:

    _get_<table>($self, $filter)
    _search_<table>($self, $filter, $options)
    _count_<table>($self, $filter)

C<$filter> is C<< { field => { op => value } } >>, a plain value being C<<
{ '=' => value } >>. C<$options> holds only C<limit> and C<after>. C<_get_> returns a
row or undef, C<_search_> the page C<< { rows, has_more_data, next } >> (C<next> a
token the same method reads back from C<after>), and C<_count_> a number. A verb a
table has no method for croaks, naming the ones it has.

C<all> is C<search({}, {})>.

=head1 METHODS

=head2 new

Built by L<Punk::Model>, once a worker a model, with the C<database> options, the
model's C<table>, C<primary> and C<columns>, and the application. The C<database>
may give C<cache>, how many answers L</cached> keeps (256 when not given, 0 for
none).

=head2 table

The table this backend answers for.

=head2 app

The application, or undef when built without one. It is held weakly.

=head2 get

=head2 search

=head2 count

=head2 all

The contract, as L</WRITING ONE> describes.

=head2 create

=head2 update

=head2 delete

Croak: nothing is stored. A subclass may define its own.

=head2 filter

    my $f = $self->filter(\%filter);

A filter checked and normalised as the verbs do it, for a method of the subclass's
own that takes the same fields.

=head2 options

    my $o = $self->options(\%options);

The search options checked: C<limit> and C<after>.

=head2 limit

    my $n = $self->limit($options, $default, $max, $what);

The page size: C<limit> from the options, else C<$default>. Not a whole number from
1 is an error on C<limit> ("limit must be a whole number from 1 to 50"), and over
C<$max> is one too ("at most 50 runs at a time"). C<$what> names the rows, C<rows>
when not given.

=head2 error

    $self->error($field, $message);

Dies with a L<Punk::Model::Computed::Error>.

=head2 wrap

    my @r = $self->wrap($field => sub { Some::Module->work($input) });

Runs the code in the caller's context and returns what it returns. A die inside
becomes an error on C<$field> in the module's own words (see
L<Punk::Model::Computed::Error/said>). One that is already a
L<Punk::Model::Computed::Error> passes through unchanged.

=head2 cached

    my $answer = $self->cached($key, sub { ... });

What the code returns, kept under C<$key> among the backend's last C<cache>
answers and given back from there while it stays, the least recently used going
first. An undef key runs the code every time, for an answer that depends on when it
is asked. The cache is the worker's own, and a kept answer is the same reference
each time, so a caller must not change it.

=head2 cache_key

    my $key = $self->cache_key(search => $filter, $options);

A key for L</cached>: the table and the parts, written so that two different values
never give the same key. Hashes are read in sorted order, so two equal filters give
one key. An object is its string.

=head2 cache_size

How many answers are kept.

=head2 cache_clear

Forgets them.

=head1 SEE ALSO

L<Punk::Model>, L<Punk::Model::Computed::Error>, L<Punk::Model::JSONFile>,
L<Punk::Model::Markdown>.

=cut
