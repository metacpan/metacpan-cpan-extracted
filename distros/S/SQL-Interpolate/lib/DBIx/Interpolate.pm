package DBIx::Interpolate;

use strict;
use warnings;
use Carp;
use DBI;
use SQL::Interpolate qw(:all);
use base qw(Exporter SQL::Interpolate);

our $VERSION = '0.32';

our @EXPORT;
our %EXPORT_TAGS = (all => [qw(
    attr
    dbi_interp
    key_field
    make_dbi_interp
)]);
our @EXPORT_OK = @{$EXPORT_TAGS{all}};

sub _wrap(&);

# internal helper function to filter use parameters
sub _filter_params {
    my ($skip_names, $skip_keys, @parts) = @_;
    my @out;
    my %skip_names = map {($_=>1)} @$skip_names;
    my %skip_keys  = map {($_=>1)} @$skip_keys;
    while (@parts) {
        if ($skip_names{$parts[0]})   { shift @parts; }
        elsif ($skip_keys{$parts[0]}) { shift @parts; shift @parts; }
        else                          { push @out, shift @parts; }
    }
    return @out;
}

sub import {
    my @params = @_;

    # handle local exports
    my @params2 = _filter_params($SQL::Interpolate::EXPORT_TAGS{all},
                                [SQL::Interpolate::_use_params()], @params);
    __PACKAGE__->export_to_level(1, @params2);

    # pass use parameters to wrapped module.
    # use goto since non-returnable on FILTER => 1.
    @_ = _filter_params($EXPORT_TAGS{all}, [], @params);
    push @_, __WRAP => 1;
    goto &SQL::Interpolate::import; # @_
}

sub new {
    my $class = shift;
    my $dbh;
    if (UNIVERSAL::isa($_[0], 'DBI:db')) {
        $dbh = shift;
    }
    elsif (ref($_[0]) eq 'ARRAY') {
        $dbh = DBI->connect(@{shift @_});
    }

    my $self = SQL::Interpolate->new(($dbh ? $dbh : ()), @_);
    bless $self, $class;
    $self->{stx} = $self->prepare();

    return $self;
}

sub connect {
    my $class = shift;
    my $self;
    eval {
        my $dbh = DBI->connect(@_);
        return if !$dbh;
        $self = DBIx::Interpolate->new($dbh);  #Q: OK?
    };
    if ($@) { croak $@; }
    return $self;
}

sub dbh {
    my $self = shift;
    return $self->{dbh};
}

# new in 0.31
sub stx {
    my $self = shift;
    return $self->{stx};
}

sub dbi_interp {
    my $key;
    my $attr;
    my @args = grep {
        my $save = 1;
        if (ref($_) eq 'SQL::Interpolate::Key') {
            $key = $_; $save = 0;
        }
        elsif (ref($_) eq 'SQL::Interpolate::Attr') {
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

sub make_dbi_interp {
    my (@params) = @_;

    my $interp = sub {
        return dbi_interp(@params, @_);
    };
    return $interp;
}

sub key_field {
    my $key = shift;
    return bless \$key, "SQL::Interpolate::Key";
}

sub attr {
    return bless {@_}, "SQL::Interpolate::Attr";
}

# based on function in DBI
sub _do_selectrow {
    my ($self, $method, @list) = @_;

    #my ($method, $dbh, $stmt, $attr, @bind) = @_;
    #my $sth = $dbh->prepare($stmt, $attr) or return;
    #_do_execute($sth, @bind) or return;
    $self->{stx}->execute(@list) or return;
    my $sth = $self->{stx}->sth();
    my $row = $sth->$method() and $sth->finish;
    return $row;
}

sub prepare {
    my ($self) = @_;
    return DBIx::Interpolate::STX->new($self);
}

sub do {
    my ($self, @list) = @_;
    return _wrap {
        # based on DBI::do
        #   my $sth = $dbh->prepare($sql, $attr) or return undef;
        #   _do_execute(@bind) or return undef;

        $self->{stx}->execute(@list) or return undef;
        my $sth = $self->{stx}->sth();
        my $rows = $sth->rows;
        return ($rows == 0) ? "0E0" : $rows;
    };
}

sub selectrow_array {
    my ($self, @list) = @_;
    my $want = wantarray;
    return _wrap {
        # based on DBI::selectrow_array

        my $row = $self->_do_selectrow('fetchrow_arrayref', @list)
            or return;
        return $row->[0] unless $want;
        return @$row;
    };
}

sub selectrow_arrayref {
    my ($self, @list) = @_;
    return _wrap {
        # based on DBI::selectrow_arrayref

        return $self->_do_selectrow('fetchrow_arrayref', @list);
    };
}

sub selectrow_hashref {
    my ($self, @list) = @_;
    return _wrap {
        # based on DBI::selectrow_hashref

        return $self->_do_selectrow('fetchrow_hashref', @list);
    };
}

sub selectall_arrayref {
    my ($self, @list) = @_;
    return _wrap {
        # improve: no need to to a full dbi_interp call here and elsewhere
        my ($sql, $attr, @bind) = $self->dbi_interp(@list); # need $attr

        # based on DBI::selectall_arrayref
        #   my $sth = $dbh->prepare($sql, $attr) or return;
        #   _do_execute($sth, @bind) or return;

        $self->{stx}->execute(@list) or return;
        my $sth = $self->{stx}->sth();
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

sub selectall_hashref {
    my ($self, @list) = @_;
    return _wrap {
        #need $key_field
        my ($sql, $key_field, $attr, @bind) = $self->dbi_interp(@list);

        # based on DBI::selectall_hashref
        #   my $sth = $dbh->prepare($sql, $attr);
        #   return unless $sth;
        #   _do_execute($sth, @bind) or return;

        $self->{stx}->execute(@list) or return;
        my $sth = $self->{stx}->sth();
        return $sth->fetchall_hashref($key_field);
    };
}

sub selectcol_arrayref {
    my ($self, @list) = @_;
    return _wrap {
        my ($sql, $attr, @bind) = $self->dbi_interp(@list); # need $attr

        # based on DBI::selectcol_arrayref
        #   my $sth = $dbh->prepare($sql, $attr);
        #   return unless $sth;
        #   _do_execute($sth, @bind) or return;

        $self->{stx}->execute(@list) or return;
        my @columns = ($attr->{Columns}) ? @{$attr->{Columns}} : (1);
        my @values  = (undef) x @columns;
        my $idx = 0;
        my $sth = $self->{stx}->sth();
        for (@columns) {
            $sth->bind_col($_, \$values[$idx++]) || return;
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

#old: sub _do_execute {
#    my ($sth, @bind) = @_;
#    if (ref($bind[0]) eq 'ARRAY') {
#        _bind_params($sth, @bind);
#        return $sth->execute();
#    }
#    else {
#        return $sth->execute(@bind);
#    }
#}
#old: sub _bind_params {
#    my ($sth, @bind) = @_;
#    my $num = 1;
#    for my $val (@bind) {
#        $sth->bind_param($num++, $val->[0], $val->[1]->{type});
#    }
#}

1;

package DBIx::Interpolate::STX;
use strict;

sub new {
    my ($class, $dbx) = @_;
    my $self = bless {
        # active sth
        sth => undef,

        # map: SQL --> sth (sth cache)
        sths => {},

        # queue of SQL. used to select sth to delete if cache is full
        sql_queue => [],

        # DBIx::Interpolate
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

sub execute {
    my ($self, @list) = @_;
    my $dbx = $self->{dbx};
    return DBIx::Interpolate::_wrap {
        my ($sql, @bind) = $dbx->dbi_interp(@list);
        shift @bind if defined $bind[0] && ref $bind[0] eq ''; # remove any key_field()
        my $attr = shift @bind;
        my $sth = $self->{sths}->{$sql};
        if (! defined $sth) {
	  my $dbx = $self->{dbx};
            $sth = $dbx->dbh()->prepare($sql, $attr) or return;
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
    return DBIx::Interpolate::_wrap {
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
    return DBIx::Interpolate::_wrap {
        return $self->{sth}->fetchrow_arrayref();
    };
}

sub fetchrow_array {
    my $self = shift;
    return DBIx::Interpolate::_wrap {
        return $self->{sth}->fetchrow_array();
    };
}

sub fetchrow_hashref {
    my ($self, @params) = @_;
    return DBIx::Interpolate::_wrap {
        return $self->{sth}->fetchrow_hashref(@params);
    };
}

sub fetchall_arrayref {
    my ($self, @params) = @_;
    return DBIx::Interpolate::_wrap {
        return $self->{sth}->fetchall_arrayref(@params);
    };
}

sub fetchall_hashref {
    my ($self, @params) = @_;
    return DBIx::Interpolate::_wrap {
        return $self->{sth}->fetchall_hashref(@params);
    };
}

1;

__END__

=head1 NAME

DBIx::Interpolate - Integrates SQL::Interpolate into DBI

=head1 SYNOPSIS

  use DBI;
  use DBIx::Interpolate qw(:all);

  # simple usage
  my $dbx = DBIx::Interpolate->new($dbh);
  $dbx->selectall_arrayref(
      "SELECT * FROM table WHERE color IN", \@colors,
      "AND y =", \$x
  );

  # using the DBI adapter (dbi_interp) directly
  $dbh->selectall_arrayref(dbi_interp
      "SELECT * FROM mytable WHERE color IN", \@colors,
      "AND y =", \$x, "OR", {z => 3, w => 2}
  );
  # note: dbi_interp typically returns ($sql, \%attr, @bind)

  # caching statement handles for performance
  # (note: it is easier to instead enable auto-caching)
  my $stx = $dbx->prepare();
      # note: $stx represents a set of statement handles ($sth)
      # for a class of queries.
  for my $colors (@colorlists) {
      $stx->execute("SELECT * FROM table WHERE color IN", $colors);
          # note: this will transparently prepare a new $sth whenever
          # one compatible with the given query invocation is not cached.
      my $ary_ref = $stx->fetchall_arrayref();
  }

=head1 DESCRIPTION

DBIx::Interpolate wraps L<DBI|DBI> and inherits from
L<SQL::Interpolate|SQL::Interpolate>.  It does nothing more than bring
SQL::Interpolate behavior into DBI.  The DBIx::Interpolate interface
is very close to that of DBI.  All DBI-derived methods look and behave
identically or analogously to their DBI counterparts.  They differ
mainly in that certain methods, such as do and select.*, expect an
interpolation list as input:

  $dbx->selectall_arrayref(
      "SELECT * from mytable WHERE height > ", \$x);

rather than the typical ($statement, \%attr, @bind_values) of
DBI:

  $dbh->selectall_arrayref(
      "SELECT * from mytable WHERE height > ?", undef, $x);

DBIx::Interpolate also supports I<statement handle sets>.  A statement
handle set is an abstraction of a statement handle and represents an
entire I<set of statement handles> for a given I<class of SQL
queries>.  This abstraction is used because a single interpolation
list may interpolate into any number of SQL queries (depending on
variable input), so multiple statement handles may need to be managed
and cached.  DBIx::Interpolate also provides a way to handle this
caching transparently.

=head1 INTERFACE

The parameters for most DBIx::Interpolate methods are internally
passed to C<dbi_interp()>, which is a thin wrapper around
L<sql_interp|SQL::Interpolate/sql_interp>.  C<dbi_interp()> accepts a
few additional types of parameters and typically returns a parameter
list suitable for DBI, typically ($statement, \%attr, @bind_values).
Therefore, the previous example is equivalent to

  $dbh->select_arrayref(dbi_interp
      "SELECT * from mytable WHERE height > ", \$x );

which in this particular case is equivalent to

  my ($sql, @bind) = sql_interp
      "SELECT * from mytable WHERE height > ", \$x ;
  $dbh->selectall_arrayref($sql, undef, @bind);

It is a design goal of DBIx::Interpolate to maintaining as much
resemblance to DBI as reasonably possible.

=head2 C<dbi_interp>

  ($sql, $attr, @bind) = dbi_interp(@interp_list);
  ($sql, $key_field, $attr, @bind) = dbi_interp(@interp_list);

C<dbi_interp()> is a wrapper function around C<sql_interp()>.  It
serves as an adapter that returns also the \%attr value (and sometimes
$key_field value) so that the result can be passed directly to the DBI
functions.

In addition to the parameters accepted by
SQL::Interpolate::sql_interp, @interp_list may contain the macros
returned by C<attr> and C<key_field> functions.  C<dbi_interp()> will
convert these DBI-specific objects into additional return values
expected by certain DBI methods.  For example, selectall_hashref
accepts an additional $key_field parameter:

  $dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values);

dbi_interp can generate the $key_field parameter (as well as \%attr)
as follows:

  my ($sql, $key_field, $attr, @bind) = dbi_interp
      "SELECT * FROM mytable WHERE x=", \$x,
      key_field("y"), attr(myatt => 1)
  # Sets
  #   ($sql, $key_field, $attr, @bind) =
  #       ("SELECT * FROM mytable WHERE x=?", 'y', {myatt=>1}, $x)

Therefore, one may do

C<dbi_interp()> is typically unnecessary to use directly since it is
called internally by the DBI wrapper methods:

  $dbx->selectall_hashref(
      "SELECT * FROM mytable WHERE x=", \$x,
      key_field("y"), attr(myatt => 1));
  # same as
  # $dbh->selectall_hashref(dbi_interp
  #     "SELECT * FROM mytable WHERE x=", \$x,
  #     key_field("y"), attr(myatt => 1));

=head2 C<key_field>

  $keyobj = key_field($key_field);

Creates and returns an SQL::Interpolate::Key macro object, which if
processed by dbi_interp will cause dbi_interp to return an extra
$key_field value in the result so that it is suitable for passing into
$dbh->fetchrow_hashref and related methods.

  my ($sql, $key, $attr, @bind) =
  my @params = dbi_interp "SELECT * FROM mytable", key_field('itemid');
  $dbh->selectall_hashref(@params);

=head2 C<attr>

  $attrobj = attr(%attr);

Creates and returns an SQL::Interpolate::Attr macro object, which if
processed by dbi_interp will cause dbi_interp to add the provided
key-value pair to the $attr hashref used by DBI methods.

  my ($sql, $attr, @bind) =
  my @params =
    dbi_interp "SELECT a, b FROM mytable", attr(Columns=>[1,2]);
  $dbh->selectcol_arrayref(@params);

=head2 Additional public functions/methods

=over 4

=item C<make_dbi_interp>

  $dbi_interp = make_dbi_interp(@params);          # functional
  $dbi_interp = $interp->make_dbi_interp(@params); # OO

This is similar in make_sql_interp except that is generates a closure
around the dbi_interp function or method rather than sql_interp.

=back

=head2 Database object (DBX) methods

Most of these methods are wrappers around the DBI methods.

=over 4

=item C<new> (static method)

 my $dbx = DBX::Interpolate->new($db, %params);

Creates a new object and optionally creates or attached a DBI handle.

$db [optional] is either a DBI database handle or an ARRAYREF
containing parameters that will be passed to DBI::connect, e.g.
[$data_source, $username, $auth, \%attr].  This parameter may be
omitted.

Any additional %params are passed onto
L<SQL::Interpolate::new|SQL::Interpolate/new>.

=item C<connect> (static method)

 $dbx = DBIx::Interpolate->connect($data_source, $username, $auth, \%attr);

Connects to a database.

This is identical to DBI::connect except that it returns at
DBIx::Interpolate object.  An alternate way to connect or attach an
existing DBI handle is via the C<new> method.

=item C<dbh>

 $dbh = $dbx->dbh();

Returns the underlying DBI handle $dbh.  The is useful if you need to
pass the DBI handle to code that does not use SQL::Interpolate.

 $dbx->dbh()->selectall_arrayref(
     "SELECT * FROM mytable WHERE x = ?", undef, $x);

=item C<stx>

 $stx = $dbx->stx();

Returns the underlying statement handle set $stx.
Each DBIx::Interpolate object contains one statement handle
set for use on non-prepared database calls (e.g. selectall_.*()
methods).

 $dbx->stx()->max_sths(10);

=item do

=item selectall_arrayref

=item selectall_hashref

=item selectcol_arrayref

=item selectrow_array

=item selectrow_arrayref

=item selectrow_hashref

These methods are identical to those in DBI except that it takes a parameter
list identical to C<dbi_interp()>.

 my $res = $dbx->selectall_hashref("SELECT * FROM mytable WHERE x=", \$x);

=item prepare

 $stx = $dbx->prepare();

Creates a new statement handle set ($stx of type
SQL::Interpolate::STX) associated with $dbx.  There are no parameters.

A statement handle set represents a set of statement handles for a
class of queries.  Up to one statement handle is considered I<active>.
Other operations performed on the statement handle set are passed to
the active statement handle so that the statement handle set often
looks and feels like a regular statement handle.

=back

=head2 Statement handle set (STX) methods

These methods are for statement handle set objects.

=over 4

=item C<new>

  $stx = SQL::Interpolate::STX->new($dbx);

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

@list is an interpolation list (suitable for passing to dbi_interp).

=item C<fetch...>

  $ary_ref = $stx->fetchrow_arrayref();

Various fetch.* methods analogous to those in DBIx::Interpolate are
available.  The fetch will be performed against the active statement
handle in the set.

=back

=head1 DEPENDENCIES

This module depends on SQL::Interpolate and DBI.

=head1 ADDITIONAL EXAMPLES

These are more advanced examples.

=head2 Preparing and reusing statement handles

  # preparing and reusing statement handles
  my $stx = $dbx->prepare();
      # note: $stx represents a set of statement handles ($sth) for a class
      # of queries.
  $stx->max_sths(3);
  for my $colors (@colorlists) {
      $stx->execute("SELECT * FROM table WHERE color IN", $colors);
          # note: this will transparently prepare a new $sth whenever
          # one compatible with the given query is not cached.
      my $ary_ref = $stx->fetchall_arrayref();
  }

The statement handle set transparently prepare statement handles if
ever and whenever the underlying SQL string (and number of bind
values) changes.  The size of the statement handle cache (3) may be
configured to optimize performance on given data sets.  Compare this
simpler and more flexible code to L<the example in
SQL::Interpolate|SQL::Interpolate/additional_examples>.

=head2 Binding variable types (DBI bind_param)

  $dbx->selectall_arrayref(
      "SELECT * FROM mytable WHERE",
      "x=", \$x, "AND y=", sql_var(\$y, SQL_VARCHAR), "AND z IN",
      sql_var([1, 2], SQL_INTEGER)
  );

Compare this much simpler code to L<the example in
SQL::Interpolate|SQL::Interpolate/additional_examples>.

=head1 DESIGN NOTES

=head2 Philosophy and requirements

DBIx::Interpolate is designed to look an feel like DBI even when the
DBI interface is not entirely user friendly (e.g. the
(fetch|select)(all|row)?_(array|hash)(ref)? and do methods).  Still,
the approach lowers the learning code and could simplify the process
of converting existing DBI code over to SQL::Interpolate.

The use of statement handle sets (STX) is not strictly necessary but
is rather designed to mimic DBI's statement handles more than anything
else.  The DBX object itself contains a statement handle set, which
can be used for non-prepared calls such as to selectall_.*() methods
(i.e. cache statement handles like in DBIx::Simple's keep_statements).

  $dbx->stx()->max_sths(2);
  $dbx->do(...) for 1..5;
  $dbx->do(...) for 1..5;

An ideal solution would probably be to I<integrate SQL::Interpolate
into DBIx::Simple> rather than directly into DBI.

=head2 Proposed enhancements

The following enhancements to SQL::Interpolate have been proposed.
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
  my $stx = $dbx->prepare("SELECT * FROM mytable WHERE", sql_var(\$x);
  $stx->execute_vars();
  ...
  $x->{two} = 'three';
  $stx->execute_vars();
  ...

  my $x = {one => 'two'};
  my $y = {one => 'three', two => 'four'};
  my $stx = $dbx->prepare("SELECT * FROM mytable WHERE", sql_var($x, 'x'));
  $stx->execute_vars();
  ...
  $stx->execute_vars(sql_var($x, 'x'); # or?
  $stx->execute_vars(x => $x); # or?
  ...

Conditional macros: (made possible by late expansion of macros)

  $blue = 1;
  $z = 123;
  $stx = $dbx->prepare(
      "SELECT * FROM mytable WHERE",
      sql_and( sql_if(\$blue,  "color = "blue""),
              sql_if(\$shape, sql("shape =", \$shape)),
              'z=', \$z),
      "LIMIT 10"
  );
  $stx->execute_vars();
  $stx->selectall_arrayref();
  $z = 234;
  $stx->execute_vars();  # note: $sth unchanged
  $stx->selectall_arrayref();
  $blue = 0;
  $stx->execute_vars();  # note: $sth changed
  $stx->selectall_arrayref();

=head1 CONTRIBUTORS

David Manura (http://math2.org/david)--author.  The existence and
original design of this module as a wrapper around DBI was suggested
by Jim Cromie.

=head1 FEEDBACK

Bug reports and comments on the design are most welcome.  See the main
L<SQL::Interpolate|SQL::Interpolate> module for details.

=head1 LEGAL

Copyright (c) 2004-2005, David Manura.  This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.  See
L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 SEE ALSO

=head2 Other modules in this distribution

L<SQL::Interpolate|SQL::Interpolate>,
L<SQL::Interpolate::Filter|SQL::Interpolate::Filter>,
L<SQL::Interpolate::Macro|SQL::Interpolate::Macro>.

Dependencies: L<DBI|DBI>.

Related modules:
L<DBIx::Simple|DBIx::Simple>,
L<SQL::Abstract|SQL::Abstract>,
L<DBIx::Abstract|DBIx::Abstract>,
L<Class::DBI|Class::DBI>.

=cut
