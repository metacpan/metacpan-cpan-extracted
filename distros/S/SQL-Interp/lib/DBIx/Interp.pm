package DBIx::Interp;

use strict;
use warnings;
use Carp;
use SQL::Interp ':all';
use base 'DBI';
use Sub::Exporter -setup => {
    exports => [
        qw{attr dbi_interp key_field},
        qw{  sql_interp
             sql_interp_strict
             sql_type
             sql },
    ],
};

our $VERSION = '1.24';

our @CARP_NOT =
    qw(DBIx::Interp DBIx::Interp::db DBIx::Interp::STX);

sub key_field {
    my $key = shift;
    return bless \$key, "DBIx::Interp::Key";
}

sub attr {
    return bless {@_}, "DBIx::Interp::Attr";
}

sub dbi_interp {
    return DBIx::Interp::db::dbi_interp(@_);
}

sub new {
    shift;
    return DBIx::Interp::db->new(@_);
}

sub _wrap(&) {
    my $code = shift;
    my $x;
    my @x;
    my $want = wantarray();
    eval {
        if ($want) { @x = $code->(); }
        else       { $x = $code->(); }
    };
    if ($@) { croak $@; }
    return $want ? @x : $x;
}

#####
package DBIx::Interp::db;
use strict;
use warnings;
use Carp;
use base 'DBI::db';
use Scalar::Util 'weaken';

our @CARP_NOT = @DBIx::Interp::CARP_NOT;

my $priv = 'private_DBIxInterpolate';

sub new {
    my $class = shift;
    my $dbh;

    if (UNIVERSAL::isa($_[0], 'DBI::db')) {
        $dbh = shift;
    }
    elsif (ref $_[0] eq 'ARRAY') {
        $dbh = DBI->connect(@{shift @_});
        return if ! defined $dbh;
    }
    else {
        croak 'DBIx::Interp::db::new() not passed database connection';
    }

    my $interp = SQL::Interp->new(($dbh || ()), @_);
    my $self = $dbh;
    bless $self, $class;
    my $private = $self->{$priv} = {};
    $private->{stx} = $self->prepare_i();
    $private->{interp} = $interp;

    # weaken circular references to allow garbage collection
    weaken $private->{stx}->{dbx};
    weaken $private->{interp}->{dbh};

    return $self;
}

#sub DESTROY {
#    my ($self) = @_;
#    $self->SUPER::DESTROY();
#}

sub connect {
    my $class = shift;
    my $self;
    eval {
        my $dbh = DBI->connect(@_);
        return if ! $dbh;
        $self = DBIx::Interp->new($dbh);  #Q: OK?
    };
    if ($@) { croak $@; }
    return $self;
}

# removed in 0.40:
#sub dbh


# new in 0.31
sub stx {
    my $self = shift;
    return $self->{$priv}->{stx};
}

# new in 0.40
sub interp {
    my $self = shift;
    return $self->{$priv}->{interp};
}

sub dbi_interp {
    my $key;
    my $attr;
    my @args = grep {
        my $save = 1;
        if (ref($_) eq 'DBIx::Interp::Key') {
            $key = $_; $save = 0;
        }
        elsif (ref($_) eq 'DBIx::Interp::Attr') {
            $attr = {%$_}; $save = 0;
        }
        $save;
    } @_;
    my ($sql, @bind) = sql_interp(@args);
    my @params = ($sql);
    push @params, $$key if defined $key;
    push @params, $attr, @bind;
    return @params;
}

sub sql_interp {
    my (@params) = @_;
    if (UNIVERSAL::isa($_[0], 'DBIx::Interp::db')) {
        my $self = shift;
        return SQL::Interp::sql_interp($self->interp(), @_);
    }
    else {
        return SQL::Interp::sql_interp(@_);
    }
}

# based on function in DBI
sub _do_selectrow_i {
    my ($self, $method, @list) = @_;

    #my $sth = $dbh->prepare($stmt, $attr) or return;
    #_do_execute($sth, @bind) or return;
    my $stx = $self->{$priv}->{stx};
    $stx->execute_i(@list) or return;
    my $sth = $stx->sth();
    my $row = $sth->$method() and $sth->finish;
    return $row;
}

# new in 0.40
sub prepare_i {
    my ($self) = @_;
    return DBIx::Interp::STX->new($self);
}

# new in 0.40
sub do_i {
    my ($self, @list) = @_;
    return _wrap {
        # based on DBI::do
        #   my $sth = $dbh->prepare($sql, $attr) or return undef;
        #   _do_execute(@bind) or return undef;
        my $stx = $self->{$priv}->{stx};
        $stx->execute_i(@list) or return undef;
        my $sth = $stx->sth();
        my $rows = $sth->rows;
        return ($rows == 0) ? "0E0" : $rows;
    };
}

# new in 0.40
sub selectrow_array_i {
    my ($self, @list) = @_;
    my $want = wantarray;
    return _wrap {
        # based on DBI::selectrow_array

        my $row = $self->_do_selectrow_i('fetchrow_arrayref', @list)
            or return;
        return $row->[0] unless $want;
        return @$row;
    };
}

# new in 0.40
sub selectrow_arrayref_i {
    my ($self, @list) = @_;
    return _wrap {
        # based on DBI::selectrow_arrayref

        return $self->_do_selectrow_i('fetchrow_arrayref', @list);
    };
}

# new in 0.40
sub selectrow_hashref_i {
    my ($self, @list) = @_;
    return _wrap {
        # based on DBI::selectrow_hashref

        return $self->_do_selectrow_i('fetchrow_hashref', @list);
    };
}

# new in 0.40
sub selectall_arrayref_i {
    my ($self, @list) = @_;
    return _wrap {
        # improve: no need to to a full dbi_interp call here and elsewhere
        my ($sql, $attr, @bind) = $self->dbi_interp(@list); # need $attr

        # based on DBI::selectall_arrayref
        #   my $sth = $dbh->prepare($sql, $attr) or return;
        #   _do_execute($sth, @bind) or return;

        my $stx = $self->{$priv}->{stx};
        $stx->execute_i(@list) or return;
        my $sth = $stx->sth();
        # typically undef, else hash or array ref
        my $slice = $attr->{Slice};
        if (!$slice and $slice=$attr->{Columns}) {
            if (ref $slice eq 'ARRAY') {
                $slice = [ @{$attr->{Columns}} ];
                for (@$slice) { $_-- }
            }
        }
        my $rows = $sth->fetchall_arrayref(
            $slice, my $MaxRows = $attr->{MaxRows});
        $sth->finish if defined $MaxRows;
        return $rows;
    };
}

# new in 0.40
sub selectall_hashref_i {
    my ($self, @list) = @_;
    return _wrap {
        #need $key_field
        my ($sql, $key_field, $attr, @bind) = $self->dbi_interp(@list);

        # based on DBI::selectall_hashref
        #   my $sth = $dbh->prepare($sql, $attr);
        #   return unless $sth;
        #   _do_execute($sth, @bind) or return;

        my $stx = $self->{$priv}->{stx};
        $stx->execute_i(@list) or return;
        my $sth = $stx->sth();
        return $sth->fetchall_hashref($key_field);
    };
}

# new in 0.40
sub selectcol_arrayref_i {
    my ($self, @list) = @_;
    return _wrap {
        my ($sql, $attr, @bind) = $self->dbi_interp(@list); # need $attr

        # based on DBI::selectcol_arrayref
        #   my $sth = $dbh->prepare($sql, $attr);
        #   return unless $sth;
        #   _do_execute($sth, @bind) or return;

        my $stx = $self->{$priv}->{stx};
        $stx->execute_i(@list) or return;
        my @columns = ($attr->{Columns}) ? @{$attr->{Columns}} : (1);
        my @values  = (undef) x @columns;
        my $idx = 0;
        my $sth = $stx->sth();
        for (@columns) {
            $sth->bind_col($_, \$values[$idx++]) or return;
        }
        my @col;
        if (my $max = $attr->{MaxRows}) {
            push @col, @values while @col<$max && $sth->fetch;
        }
        else {
            push @col, @values while $sth->fetch;
        }
        return \@col;
    };
}

1;

#####
package DBIx::Interp::STX;
use strict;
use warnings;
use Carp;

our @CARP_NOT = @DBIx::Interp::CARP_NOT;

sub new {
    my ($class, $dbx) = @_;
    my $self = bless {
        # active sth
        sth => undef,

        # map: SQL --> sth (sth cache)
        sths => {},

        # queue of SQL. used to select sth to delete if cache is full
        sql_queue => [],

        # DBIx::Interp
        dbx => $dbx,

        # max sths allowed in the cache
        max_sths => 1
    }, $class;
    return $self;
}

sub max_sths {
    my ($self, $max_sths) = @_;
    if (defined $max_sths) {
        $self->{max_sths} = $max_sths;
    }
    else {
        return $self->{max_sths};
    }
}

sub sth {
    my $self = shift;
    return $self->{sth};
}

sub sths {
    my $self = shift;
    return {%{$self->{sths}}};
}

# renamed execute --> execute_i in 0.40
sub execute_i {
    my ($self, @list) = @_;

    return DBIx::Interp::_wrap {
        my ($sql, @bind) = $self->{dbx}->dbi_interp(@list);
        shift @bind if defined $bind[0] && ref $bind[0] eq ''; # remove any key_field()
        my $attr = shift @bind;
        my $sth = $self->{sths}->{$sql};
        if (! defined $sth) {
            $sth = $self->{dbx}->prepare($sql, $attr) or return;
            if (@{$self->{sql_queue}} + 1 > $self->{max_sths}) {
                my $sql_remove = shift @{$self->{sql_queue}};
                delete $self->{sths}->{$sql_remove};
            }
            $self->{sths}->{$sql} = $sth;
            push @{$self->{sql_queue}}, $sql;
        }
        $self->{sth} = $sth;
        _bind_params($sth, @bind);
        return $sth->execute();
    };
}

sub _bind_params {
    my ($sth, @bind) = @_;
    my $num = 1;
    return DBIx::Interp::_wrap {
        if (ref($bind[0]) eq 'ARRAY') {
            for my $val (@bind) {
                $sth->bind_param($num++, $val->[0], $val->[1]->{type});
            }
        }
        else {
            for my $val (@bind) {
                $sth->bind_param($num++, $val);
            }
        }
    };
}

sub fetchrow_arrayref {
    my $self = shift;
    return DBIx::Interp::_wrap {
        return $self->{sth}->fetchrow_arrayref();
    };
}

sub fetchrow_array {
    my $self = shift;
    return DBIx::Interp::_wrap {
        return $self->{sth}->fetchrow_array();
    };
}

sub fetchrow_hashref {
    my ($self, @params) = @_;
    return DBIx::Interp::_wrap {
        return $self->{sth}->fetchrow_hashref(@params);
    };
}

sub fetchall_arrayref {
    my ($self, @params) = @_;
    return DBIx::Interp::_wrap {
        return $self->{sth}->fetchall_arrayref(@params);
    };
}

sub fetchall_hashref {
    my ($self, @params) = @_;
    return DBIx::Interp::_wrap {
        return $self->{sth}->fetchall_hashref(@params);
    };
}

1;

__END__

=head1 NAME

DBIx::Interp - Interpolate Perl variables into SQL with DBI

=head1 SYNOPSIS

  use DBI;
  use DBIx::Interp ':all';

  my $dbx = DBIx::Interp->new($dbh);

  my $rv = $dbx->do_i('INSERT INTO table', \%item);
  my $rv = $dbx->do_i('UPDATE table SET',  \%item, 'WHERE item_id <> ', \2);
  my $rv = $dbx->do_i('DELETE FROM table WHERE item_id = ', \2);

  my $LoH = $dbx->selectall_arrayref_i('
        SELECT * FROM table WHERE x = ', \$s, 'AND y IN', \@v
        ,attr(Slice=>{}));


=head1 DESCRIPTION

DBIx::Interp brings L<SQL::Interp|SQL::Interp> and L<DBI|DBI> together in a
natural way.  Please read the documentation of those two modules if you are
unfamiliar with them.  The DBIx::Interp interface adds methods to the DBI
interface with an "_i" suffix, indicating that SQL::Interp interpolatation is performed
in these cases.

I< Note that this module is no longer used by the maintainer. DBIx::Simple now features SQL::Interp
integration and is the recommended alternative. >

=head1 Helper Functions you may need

=head2 C<attr>

  dbi_interp("SELECT * from my_table", attr( Slice => {} ) );

Creates and returns an DBIx::Interp::Attr object. When processed
by L<dbi_interp()>, it will add the provided key/value pairs
to the "%attrs" hash that is accepted by many DBI methods.

=head2 C<key_field>

  $keyobj = key_field($key_field);

Creates and returns an DBIx::Interp::Key object. When processed by
L<dbi_interp()>, an extra C<$key_field> value will be returned in the result so
that the result is suitable for passing into $dbh->fetchrow_hashref and related
methods.

  my ($sql, $key, $attr, @bind) =
  my @params = dbi_interp "SELECT * FROM mytable", key_field('itemid');
  $dbh->selectall_hashref(@params);

=head1 Database object (DBX) methods

An object of type DBIx::Interp represents (and wraps) a database
handle.  Most of its methods are wrappers around corresponding DBI
methods.

=over 4

=item C<new> (static method)

 my $dbx = DBIx::Interp->new($db, %params);

Creates a new object, creating or attaching a DBI handle.

$db is either a DBI database handle or an ARRAYREF
containing parameters that will be passed to DBI::connect, e.g.
[$data_source, $username, $auth, \%attr].  This parameter may be
omitted.

Any additional %params are passed onto
L<SQL::Interp::new|SQL::Interp/new>.

=item C<connect> (static method)

 $dbx = DBIx::Interp->connect($data_source, $username, $auth, \%attr);

Connects to a database.

This is identical to DBI::connect except that it returns at
DBIx::Interp object.  An alternate way to connect or attach an
existing DBI handle is via the C<new> method.

=item C<dbh>

 $dbh = $dbx->dbh();

Returns the underlying DBI handle $dbh.  The is useful if you need to
pass the DBI handle to code that does not use SQL::Interp.

 $dbx->dbh()->selectall_arrayref(
     "SELECT * FROM mytable WHERE x = ?", undef, $x);

=item C<stx>

 $stx = $dbx->stx();

Returns the underlying statement handle set $stx. (These are discussed
later.)  Each DBIx::Interp object contains one statement handle
set for use on non-prepared database calls (e.g. selectall_.*()
methods).

 $dbx->stx()->max_sths(10);

=back

=head2 do_i

=head2 selectall_arrayref_i

=head2 selectall_hashref_i

=head2 selectcol_arrayref_i

=head2 selectrow_array_i

=head2 selectrow_arrayref_i

=head2 selectrow_hashref_i

These methods are identical to those in DBI except interpolation is performed
via L<SQL::Interp>.

=head2 prepare

 $stx = $dbx->prepare();

Creates a new statement handle set ($stx of type
SQL::Interp::STX) associated with $dbx.  There are no parameters.

A statement handle set (stx) is an abstraction of a statement handle
and represents an entire I<set of statement handles> for a given
I<class of SQL queries>.  This abstraction is used because a single
interpolation list may interpolate into any number of SQL queries
(depending on variable input), so multiple statement handles may need
to be managed and cached.  Typically, you do not need to call
"prepare" directly because DBIx::Interp can transparently mangage
a statement handle set (see $dbx->stx()->max_sths(10)).

Up to one statement handle in a set is considered I<active>.
Other operations performed on the statement handle set are passed to
the active statement handle so that the statement handle set often
looks and feels like a regular statement handle.

=head2 Statement handle set (STX) methods

These methods are for statement handle set objects.

=over 4

=item C<new>

  $stx = SQL::Interp::STX->new($dbx);

Creates a new statement handle set.  Typically this is not
called directly but rather is invoked through C<prepare()>.

=item C<max_sths>

  $max_sths = $stx->max_sths(); # get
  $stx->max_sths($max_sths);    # set

Gets or sets the maximum number of statement handles to cache
in the statement handle set.  The default and minimum value is 1.

=item C<sth>

  $sth = $stx->sth();

Gets the current active statement handle (e.g. the only that was
just executed).  Returns undef on none.

=item C<sths>

  $sths = $stx->sths();

Return a hashref of contained statement handles (map: $sql -> $sth).

=item C<execute>

  $rv = $stx->execute(@list);

Executes the query in the given interpolation list against a statement
handle.  If no statement matching statement handle exists, a new one
is prepared.  The used statement handle is made the active statement
handle.  Return on error behavior is similar to DBI's execute.

@list is an interpolation list (suitable for passing to C<dbi_interp()>).

=item C<fetch...>

  $ary_ref = $stx->fetchrow_arrayref();

Various fetch.* methods analogous to those in DBIx::Interp are
available.  The fetch will be performed against the active statement
handle in the set.

=back

=begin private

=head1 Internal functions

You normally don't need to care about this functions.

=head2 C<dbi_interp>

  ($sql, $attr, @bind) = dbi_interp(@interp_list);
  ($sql, $key_field, $attr, @bind) = dbi_interp(@interp_list);

C<dbi_interp()> is a thin wrapper around C<sql_interp()>.  It
serves as an adapter that returns the exact parameter list
expected by the DBI functions (including the \%attr value and sometimes
the $key_field value).

In addition to the parameters accepted by SQL::Interp::sql_interp, @interp_list
may contain the results constructed by the C<attr()> and C<key_field()>
functions discussed later.  C<dbi_interp()> will convert these DBI-specific
values as needed into additional return values expected by certain DBI methods.

Typically, you need not call C<dbi_interp()> directly since it is
called internally by the DBI wrapper methods:

  $dbx->selectall_hashref(
      "SELECT * FROM mytable WHERE x=", \$x,
      key_field("y"), attr(myatt => 1));
  # largely equivalent to
  #   $dbh->selectall_hashref(dbi_interp
  #       "SELECT * FROM mytable WHERE x=", \$x,
  #       key_field("y"), attr(myatt => 1));

=end private

These are more advanced examples.

=head2 Binding variable types (DBI bind_param)

Compare this much simpler code to L<the example in
SQL::Interp|SQL::Interp/ADDITIONAL_EXAMPLES>.

  $dbx->selectall_arrayref(
      "SELECT * FROM mytable WHERE",
      "x=", \$x, "AND y=", sql_type(\$y, SQL_VARCHAR), "AND z IN",
      sql_type([1, 2], SQL_INTEGER)
  );

=head1 DESIGN NOTES

=head2 Philosophy and requirements

DBIx::Interp is designed to look an feel like DBI even when the
DBI interface is not entirely user friendly (e.g. the
(fetch|select)(all|row)?_(array|hash)(ref)? and do methods).  Still,
the approach lowers the learning code and could simplify the process
of converting existing DBI code over to SQL::Interp.

The use of statement handle sets (STX) is not strictly necessary but
is rather designed to mimic DBI's statement handles more than anything
else.  The DBX object itself contains a statement handle set, which
can be used for non-prepared calls such as to selectall_.*() methods
(i.e. cache statement handles like in DBIx::Simple's keep_statements).

  $dbx->stx()->max_sths(2);
  $dbx->do(...) for 1..5;
  $dbx->do(...) for 1..5;

An ideal solution would probably be to I<integrate SQL::Interp
into DBIx::Simple> rather than directly into DBI.

=head2 Proposed enhancements

The following enhancements to SQL::Interp have been proposed.
The most important suggestions are listed at top, and some
suggestions could be rejected.

DBI database handle and statement handle attributes are not currently
exposed from the wrapper except via $dbx->dbh()->{...}.  Maybe a Tie
can be used. e.g. $dbx->{mysql_insert_id}

Support might be added for something analogous to DBI's
bind_param_inout.

DBI's bind_param_array is not currently supported.
A syntax as follows might be used:

  "INSERT INTO mytable", [[...], [...], ...]

Passing identified variables:

  my $x = {one => 'two'};
  my $stx = $dbx->prepare("SELECT * FROM mytable WHERE", sql_type(\$x);
  $stx->execute_vars();
  ...
  $x->{two} = 'three';
  $stx->execute_vars();
  ...

  my $x = {one => 'two'};
  my $y = {one => 'three', two => 'four'};
  my $stx = $dbx->prepare("SELECT * FROM mytable WHERE", sql_type($x, 'x'));
  $stx->execute_vars();
  ...
  $stx->execute_vars(sql_type($x, 'x'); # or?
  $stx->execute_vars(x => $x); # or?
  ...

=head1 CONTRIBUTORS

David Manura (L<http://math2.org/david>) (author).  The existence and
original design of this module as a wrapper around DBI was suggested
by Jim Cromie.

=head1 FEEDBACK

Bug reports and comments on the design are most welcome.  See the main
L<SQL::Interp|SQL::Interp> module for details.

=head1 LEGAL

Copyright (c) 2004-2005, David Manura.  This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.  See
L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 SEE ALSO

=head2 Other modules in this distribution

L<SQL::Interp|SQL::Interp>,

L<DBI|DBI>.

Related modules:
L<DBIx::Simple|DBIx::Simple>,
L<SQL::Abstract|SQL::Abstract>,
L<DBIx::Abstract|DBIx::Abstract>,
L<Class::DBI|Class::DBI>,
L<DBIx::Class|DBIx::Class>,
L<Rose::DB|Rose::DB>.

=cut
