package SQL::Interpolate;

our $VERSION = '0.32';

use strict;
use warnings;
use Carp;
use base 'Exporter';

our @EXPORT;
our %EXPORT_TAGS = (all => [qw(
    make_sql_interp
    sql_interp
    sql_var
    sql
    sql_literal
)]); # note: sql_literal depreciated
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

# whether TRACE_SQL is enabled
my $trace_sql_enabled = 0;

# whether TRACE_FILTER is enabled
my $trace_filter_enabled = 0;

# whether macros are enabled
my $macros_enabled = 0;

sub import {
    my $class  = shift;
    my @params = @_;

    # process any special "use" parameters
    my $filter_enabled = 0;  # whether filtering enabled
    my $is_wrapped     = 0;  # whether module wrapped
                             #   (e.g. by DBIx::Interpolate)
    my %action_for = (
        FILTER       => sub { $filter_enabled = shift @params; },
        TRACE_SQL    => sub { $trace_sql_enabled = shift @params;
                              print STDERR "TRACE_SQL enabled\n"
                                  if $trace_sql_enabled; },
        TRACE_FILTER => sub { $trace_filter_enabled = shift @params;
                              print STDERR "TRACE_FILTER enabled\n"
                                  if $trace_filter_enabled; },
        __WRAP       => sub { $is_wrapped = shift @params; }
    );
    @_ = ($class);  # unprocessed params
    while (my $item = shift @params) {
        my $action = $action_for{$item};
        if ($action) { $action->(); }
        else         { push @_, $item; }
    }

    # handle exports
    my $level = $is_wrapped ? 2 : 1;
    __PACKAGE__->export_to_level($level, @_);

    # handle source filtering (if enabled)
    if ($filter_enabled) {
        require SQL::Interpolate::Filter;
        goto &SQL::Interpolate::Filter::import;  # @_
    }

    return;
}

sub new {
    my $class = shift;

    # process special params.
    my $dbh;
    my $filters = [];
    while (ref $_[0] ne '') {
        if (UNIVERSAL::isa($_[0], 'DBI::db')) {
            $dbh = shift;
        }
        elsif (UNIVERSAL::isa($_[0], 'SQL::Interpolate::SQLFilter')) {
            push @$filters, shift;
        }
    }
    my %params = @_;

    # build indicies on $filters for quick access
    my $filters_hash          = {};  # filter class name --> [filter]
    my $text_filters          = [];  # filter
    my $inits                 = [];  # filter
    my $text_fragment_filters = [];  # filter
    for my $filter (@$filters) {
        push @{$filters_hash->{ref $filter}}, $filter;
        push @$text_filters, $filter
            if $filter->can("filter_text");
        push @$inits, $filter
            if $filter->can("init");
        push @$text_fragment_filters, $filter
            if $filter->can("filter_text_fragment");
    }

    # build object
    my $self = bless {
        dbh                   => $dbh,
        filters               => $filters,
        filters_hash          => $filters_hash,
        text_filters          => $text_filters,
        inits                 => $inits,
        text_fragment_filters => $text_fragment_filters
    }, $class;
    return $self;
}

sub sql_interp {
    my @items = @_;

    # extract state item (if any)
    my $state;
    my $interp;
    if (UNIVERSAL::isa($items[0], 'SQL::Interpolate')) {
        $state = $interp = $items[0];
    }
    elsif (UNIVERSAL::isa($items[0], 'DBI::db')) {
        $state = $items[0];
    }

    # process macros (if enabled)
    if ($macros_enabled) {
        if ($interp) {
            for my $initer (@{$interp->{inits}}) { $initer->init(); }
        }
        @items = SQL::Interpolate::Macro::sql_flatten(@items);
    }
    else {
        shift @items if $state;
    }

    # interpolate!
    my $varobj_used = 0;  # whether typed sql_var() ever used (if so,
                          # format of @bind result is more complicated)
    my ($sql, @bind) = _sql_interp($state, \$varobj_used, @items);

    # convert bind values to complex format (if needed)
    if ($varobj_used) {
        for my $val (@bind) {
            my $valcopy = $val;
            ! ref $val and $val = [$val, sql_var(\$valcopy)];
        }
    }

    # process text filters (if any)
    if ($interp) {
        for my $text_filter (@{$interp->{text_filters}}) {
            $sql = $text_filter->filter_text($sql);
        }
    }

    $trace_sql_enabled
        and print STDERR "DEBUG:interp[sql=$sql,bind="
                         . join(':', @bind) . "]\n";

    return ($sql, @bind);
}

# helper called by sql_interp()
# $state - SQL::Interpolate derived object, DBI handle, or undef
# $varobj_used_ref - reference to Boolean indicator of complex
#                    bind format [out]
# @items - interpolation list (no macros)
sub _sql_interp {
    my ($state, $varobj_used_ref, @items) = @_;

    my $sql = '';
    my @bind;
    my $id_match = qr/[a-zA-Z_\.]+/;
    my $idx = 0;

    foreach my $item (@items) {
        my $varobj;
        my $bind_size = @bind;
        if (ref $item eq 'SQL::Interpolate::Variable') {
            unless (keys %$item == 1 && defined($item->{value})) {
                $varobj = $item;
                $$varobj_used_ref = 1;
            }
            $item = $item->{value};
        }

        if (ref $item eq 'SQL::Interpolate::SQL') {
            my ($sql2, @bind2) = _sql_interp($state, $varobj_used_ref, @$item);
            $sql .= " $sql2";
            push @bind, @bind2;
        }
        elsif (ref $item) {
            if ($sql =~ /\bIN\s*$/si) {
                $item = [ $$item ] if ref $item eq 'SCALAR';
                if (ref $item eq 'ARRAY') {
                    if (@$item == 0) {
                        $sql =~ s/$id_match\s+IN\s*$/1=0/si or croak 'ASSERT';
                    }
                    else {
                        $sql .= " (" . join(', ', map {
                            _sql_interp_data($state, \@bind,
                                $varobj_used_ref, $_);
                        } @$item) . ")";
                    }
                }
                else {
                    _error_item($idx, \@items);
                }
            }
            elsif ($sql =~ /\bSET\s*$/si && ref $item eq 'HASH') {
                _error('Hash has zero elements.') if keys %$item == 0;
                $sql .= " " . join(', ', map {
                    my $key = $_;
                    my $val = $item->{$key};
                    "$key=" .
                        _sql_interp_data($state, \@bind,
                                         $varobj_used_ref, $val);
                } keys %$item);
            }
            elsif ($sql =~ /\bINSERT[\w\s]*\sINTO\s*$id_match\s*$/si)
            {
                $item = [ $$item ] if ref $item eq 'SCALAR';
                if (ref $item eq 'ARRAY') {
                    $sql .= " VALUES(" . join(', ', map {
                        _sql_interp_data($state, \@bind,
                                         $varobj_used_ref, $_);
                    } @$item) . ")";
                }
                elsif (ref $item eq 'HASH') {
                    $sql .=
                        " (" . join(', ', keys %$item) . ")" .
                        " VALUES(" . join(', ', map {
                            _sql_interp_data($state, \@bind,
                                             $varobj_used_ref, $_);
                        } values %$item) . ")";
                }
                else { _error_item($idx, \@items); }
            }
            elsif (ref $item eq 'SCALAR') {
                push @bind, $$item;
                $sql .= ' ?';
            }
            elsif (ref $item eq 'HASH') {  # e.g. WHERE {x = 3, y = 4}
                if (keys %$item == 0) {
                    $sql .= ' 1=1';
                }
                else {
                    my $s = join ' AND ', map {
                        my $key = $_;
                        my $val = $item->{$key};
                        if (ref $val eq 'ARRAY') {
                            _in_list($state, \@bind, $varobj_used_ref,
                                     $key, $val);
                        }
                        else {
                            "$key=" .
                            _sql_interp_data($state, \@bind,
                                             $varobj_used_ref, $val);
                        }
                    } keys %$item;
                    $s = "($s)" if keys %$item > 1;
                    $s = " $s";
                    $sql .= $s;
                }
            }
            else { _error_item($idx, \@items); }
        }
        else {
            $sql .= ' ' unless $sql =~ /(^|\s)$/ || $item =~ /^\s/;  # style
            $sql .= $item;
        }

        # attach $varobj to any bind values it generates
        if ($varobj) {
            my $num_pushed = @bind - $bind_size;
            for my $val (@bind[-$num_pushed..-1]) {
                $val = [$val, $varobj];
            }
        }
        $idx++;
    }

    return ($sql, @bind);
}

# sql_interp helper function.
# Interpolate data element in aggregate variable (hashref or arrayref).
# $state - (may be undef)
# $bindref - \@bind (is modified--appended to)
# $varobj_usedref - \$varobj_used (is modified)
# $ele - raw input element from aggregate.
# returns $sql
sub _sql_interp_data {
    my ($state, $bindref, $varobj_usedref, $ele) = @_;
    if (ref $ele) {
        my ($sql2, @bind2) = sql_interp($state || (), $ele);
        push @$bindref, @bind2;
        $$varobj_usedref = 1 if ref $bind2[0];
        return $sql2;
    }
    else {
        push @$bindref, $ele;
        return '?';
    }
}

# sql_interp helper function to interpolate "key IN list",
# assuming context ("WHERE", {key => $list, ...}).
sub _in_list {
    my ($state, $bindref, $varobj_usedref, $key, $list) = @_;
    if (@$list == 0) {
        return "1=0";
    }
    else {
        my @sqle;
        for my $ele (@$list) {
            my $sqle
                = _sql_interp_data($state, $bindref, $varobj_usedref, $ele);
            push @sqle, $sqle;
        }
        my $sql2 = $key . " IN (" . join(', ', @sqle) . ")";
        return $sql2;
    }
}

sub sql {
    return SQL::Interpolate::SQL->new(@_);
}

sub make_sql_interp {
    my (@params) = @_;
    my $interp = sub {
        return sql_interp(@params, @_);
    };
    return $interp;
}

sub sql_var {
    return SQL::Interpolate::Variable->new(@_);
}

# helper function to throw error
sub _error_item {
    my ($idx, $items_ref) = @_;
    my $prev      = $idx > 0       ? $items_ref->[$idx-1] : undef;
    my $prev_text = defined($prev) ? " following '$prev'" : "";
    my $cur  = $items_ref->[$idx];
    _error("SQL::Interpolate error: Unrecognized "
         . "'$cur'$prev_text in interpolation list.");
    return;
}

sub _error {
    croak "SQL::Interpolate error: $_[0]";
}

# This shall only be called by SQL::Interpolate::Macro.
sub _enable_macros {
    scalar(caller()) eq 'SQL::Interpolate::Macro' or die 'ASSERT';
    $macros_enabled = 1;  # enable macros
    return;
}

# This shall only be called by DBIx::Interpolate.
sub _use_params {
    scalar(caller()) eq 'DBIx::Interpolate' or die 'ASSERT';

    # supported use parameters.
    return qw(FILTER TRACE_SQL TRACE_FILTER);
}

# depreciated
sub sql_literal {
    print STDERR
        "SQL::Interpolate - WARNING: "
        . "sql_literal() is depreciated. use sql() instead.\n";
    return sql(@_);
}

1;

package SQL::Interpolate::Variable;
use strict;
use Carp;

sub new {
    my ($class, $value, %params) = @_;
    SQL::Interpolate::_error(
        "Value '$value' in sql_var constructor is not a reference")
        if ! ref $value;
    my $self = bless {value => $value, %params}, $class;
    return $self;
}

1;


package SQL::Interpolate::SQL;
use strict;
use Carp;
use overload '.' => \&concat, '""' => \&stringify;

sub new {
    my ($class, @list) = @_;

    my $self = \@list;
    bless $self, $class;
    return $self;
}

# Concatenate SQL object with another expression.
# An SQL object can be concatenated with another SQL object,
# variable reference, or an SQL string.
# This is particularly useful to SQL::Interpolate::Filter.
sub concat {
    my ($a, $b, $inverted) = @_;

    my @params = ( @$a, ref $b eq __PACKAGE__ ? @$b : $b );
    @params = reverse @params if $inverted;
    my $o = SQL::Interpolate::SQL->new(@params);
    return $o;
}

sub stringify {
    my ($a) = @_;
    return $a;
}

1;

__END__

=head1 NAME

SQL::Interpolate - Simplified interpolation of Perl variables into SQL statements

=head1 SYNOPSIS

  use SQL::Interpolate qw(:all);
  
  # Some sample data.
  my $s = "blue"; my @v = (5, 6);
  
In the most basic usage, scalarrefs (and even arrayrefs) are
transformed into bind parameters.

  my ($sql, @bind) = sql_interp
    "SELECT * FROM table WHERE x = ", \$s, "AND y IN", \@v;
  # RESULT:
  #   $sql  = "SELECT * FROM mytable WHERE x = ? AND y IN (?, ?)"
  #   @bind = ($s, @v);

  # Hashrefs and arrayrefs provide a short-cut syntax.
  # A hashref typically acts as a logical-AND construction:
  my ($sql, @bind) = sql_interp
    "SELECT * FROM table WHERE", {x => $s, y => \@v};
  # RESULT:
  #   $sql  = "SELECT * FROM mytable WHERE (x = ? AND y IN (?, ?))";
  #   @bind = ($s, @v);

  # In certain contexts, an arrayref or hashref acts as a tuple:
  my ($sql, @bind) = sql_interp
    "INSERT INTO table", {x => $s, y => 1};
  # RESULT:
  #   $sql  = "INSERT INTO mytable (x, y) VALUES(?, ?)";
  #   @bind = ($s, 1);
  my ($sql, @bind) = sql_interp
    "UPDATE table SET", {x => $s, y => 1}, "WHERE y <> ", \2;
  # RESULT:
  #   $sql  = "UPDATE mytable SET x = ?, y = ? WHERE y <> ?";
  #   @bind = ($s, 1, 2);
  
  # The result is suitable for passing to DBI:
  my $res = $dbh->selectall_arrayref($sql, undef, @bind);

Besides these simple techniques shown, SQL-Interpolate includes
various optional modules to further integrate SQL::Interpolate with
DBI and streamline the syntax with source filtering and macros (see
the L</SEE ALSO> section):

  use DBIx::Interpolate FILTER => 1;
  ...
  my $rows = $dbx->selectall_arrayref(sql[
      SELECT thid, date, title, subject
      FROM threads
      WHERE date > $x AND subject IN @subjects
  ]);

=head1 DESCRIPTION

=head2 Purpose

SQL::Interpolate interpolates Perl variables into SQL statements in a
simplified manner.  It converts a list of intermixed SQL
fragments and variable references into a conventional SQL string and
I<list of bind values> suitable for passing onto DBI.

When using plain DBI, one traditionally interpolates reliably with
bind values, which can become unwieldy:

  $dbh->do(qq(
      INSERT INTO table (color, shape, width, height, length)
                  VALUES(?,     ?,     ?,     ?,      ?     )
  ), undef, $c, $s, $w, $h, $l);

This can be ameliorated somewhat with "SQL building techniques,"
but SQL::Interpolate eliminates much of this need with a terse
Perl-like syntax:

  my ($sql, @bind) = sql_interp
      "INSERT INTO table",
      {color => $c, shape => $s, width => $w, height => $h, length => $l};
  $dbh->do($sql, undef, @bind);

=head2 Security notes

SQL::Interpolate properly binds or escapes variables.  This
recommended practice safeguards against "SQL injection" attacks. The
L<DBI|DBI> documentation has several links on the topic.

=head1 INTERFACE

The central function of this module is C<sql_interp>.  The rest of
this distribution provides alternative interfaces, supporting
functionality, and wrappers for sql_interp.

=head2 C<sql_interp>

  ($sql, @bind) = sql_interp @params;            # functional interface
  ($sql, @bind) = $interp->sql_interp(@params);  # OO interface

C<sql_interp()> strings together the given list of elements to
interpolate (@params), called the "interpolation list," and returns
both an SQL string ($sql) with placeholders ("?") and a
corresponding list of bind values (@bind) suitable
for passing to DBI.

The interpolation list can contain elements of these types (the first
two are most often used):

* B<SQL> - strings containing raw SQL fragments such as
"SELECT * FROM mytable WHERE".

* B<variable references> - scalarrefs, arrayrefs, hashrefs, or
L</sql_var> objects referring to data to interpolate between
the SQL.

* B<macros> - objects that may be further expanded into previous
three types of elements.  Some strings may expand into macro objects.
Macros are explained in L<SQL::Interpolate::Macro|SQL::Interpolate::Macro>.

* B<other interpolation lists> - an interpolation list can be nested
inside another interpolation list.  This is possible with the sql()
function.

In addition, the first element in the interpolation list may
optionally be a database handle or (for the OO interface) an instance
of SQL::Interpolate.  sql_interp and macros may use this state data to
customize the output such as for a dialect of SQL.

The basic interpolation process is as follows. Strings are appended to
the output SQL ($sql), possibly with some context-dependent tweaking.
For each scalar variable reference, a corresponding placeholder ("?")
and other SQL is appended to $sql, and the de-referenced value is
pushed onto @bind.  Nested interpolation lists are generally flattened.

B<Interpolation Examples>

 # sample data
 my $s  = \3;                   # scalarref
 my $v  = [1, 2];               # arrayref (vector)
 my $h  = {m => 1, n => 2};     # hashref
 my $hv = {v => $v, s => $$s};  # hashref containing arrayref
 Let $x stand for \$s, $h, $v, or $hv.

B<Default scalar behavior>

 INPUT:  "foo", $s, "bar"
 OUTPUT: "foo ? bar", $$s

B<Default hashref behavior>

 INPUT:  "WHERE", $x
 OUTPUT: "WHERE (m=? AND n=?)", $h->{m}, $h->{n}    # $x = $h
 OUTPUT: "WHERE (v IN (?, ?) AND s = ?)", @$v, $$s  # $x = $hv

B<IN clause>

 INPUT:  "WHERE x IN", $x
 OUTPUT: "WHERE x IN (?)", $$s                      # $x = $s
 OUTPUT: "WHERE x IN (?, ?)", @$v                   # $x = $v
 OUTPUT: "WHERE 1=0", @$x                           # @x = ()
 # Note: An arrayref of length 0 is handled specially
 # because "WHERE x IN ()" can be invalid SQL (e.g. MySQL).

B<INSERT statements>

 INPUT:  "INSERT INTO mytable", $x
 OUTPUT: "INSERT INTO mytable VALUES(?)", $$s;      # $x = $s
 OUTPUT: "INSERT INTO mytable VALUES(?, ?)", @$v;   # $x = $v
 OUTPUT: "INSERT INTO mytable (m, n) VALUES(?, ?)", # $x = $h
         $h->{m}, $h->{n}

B<UPDATE statements>

 INPUT:  "UPDATE mytable SET", $h
 OUTPUT: "UPDATE mytable SET m = ?, n = ?", $h->{m}, $h->{n}

B<Other rules>

Whitespace is automatically added between parameters:

 INPUT:  "UPDATE", "mytable SET", {x => 2}, "WHERE y IN", \@colors;
 OUTPUT: "UPDATE mytable SET x = ? WHERE y in (?, ?)", 2, @colors

Variables must be passed as references (possibly using the
sql// operator when source filtering is enabled); otherwise, they will
processed as SQL fragments and interpolated verbatim into the
result SQL string, negating the security and performance benefits
of binding values.

In contrast, any scalar values I<inside> an arrayref or hashref are by
default treated as binding variables, not SQL.  The contained
elements may be also be sql_var(), sql(), or macro objects.

sql_interp will Do The Right Thing(TM) on trivial cases:

  INPUT: "SELECT * FROM table WHERE color IN", []
  OUTPUT: "SELECT * FROM table WHERE 1=0"
  # invalid to MySQL: SELECT * FROM table WHERE color IN ()

SQL::Interpolate does not attempt to further optimize away such
expressions.  Databases are designed to do query optimization, without
loss of generality.

Variable interpolation is context-sensitive.  The same variable
references can generate different SQL sub-expressions depending on
context:

  INPUT:  "INSERT INTO mytable", $h
  OUTPUT: "INSERT INTO mytable (m, n) VALUES(?, ?)", ...

  INPUT:  "UPDATE mytable SET", $h
  OUTPUT: "UPDATE mytable SET m = ?, n = ?", ...

B<Error handling:> On error, sql_interp will croak with a string message.

=head2 C<sql>

  my $sqlobj = sql(@params);

C<sql> creates an object of type SQL::Interpolate::SQL representing an
interpolation list of the elements in @params.

sql() is useful only in exceptional cases.  For example, if you want
insert raw SQL as a value in an arrayref or hashref, it cannot
be done with a plain string because any scalar value in an arrayref or
hashref is interpreted as a binding variable.  An sql object must be
used explicitly for force a change in context:

  sql_interp "INSERT INTO mytable",
      {x => $x, y => sql("CURRENT_TIMESTAMP")};
  # OUTPUT: "INSERT INTO mytable (x, y) VALUES(?, CURRENT_TIMESTAMP)", $x
  
  sql_interp "INSERT INTO mytable", [$x, sql(\$y, "*", \$z)];
  # OUTPUT: "INSERT INTO mytable VALUES(?, ? * ?)", $x, $y, $z

=head2 C<sql_var>

  my $sqlvar = sql_var($value_ref, type => $sql_type, %params);

C<sql_var()> create an I<sql_var> object (of type
SQL::Interpolate::Variable), which provides a general way to represent
a binding variable I<along with> metadata.

$value_ref - variable reference contained

$sql_type - any DBI SQL_DATA_TYPE (e.g. SQL_INTEGER).  Optional.
Default is undef.

Any other named parameters (%params) passed in will be saved into the
object as attributes.

sql_var objects are useful only in special cases where additional
information should be tagged onto the variable.  For example, DBI
allows bind variables to be given an explicit type:

  my ($sql, @bind) = sql_interp "SELECT * FROM mytable WHERE",
      "x=", \$x, "AND y=", sql_var(\$y, SQL_VARCHAR), "AND z IN",
      sql_var([1, 2], SQL_INTEGER);
  # RESULT: @bind =
  #   ([$x, sql_var(\$x)], [$y, sql_var(\$y, type => SQL_VARCHAR)],
  #    [1, sql_var([1, 2], type => SQL_INTEGER)],
  #    [2, sql_var([1, 2], type => SQL_INTEGER)]);

If the interpolation list contains at least one sql_var object, then
all the variable references are transparently converted into sql_var
objects, and the elements of @bind take a special form: an arrayref
consisting of the bind value and the sql_var object that generated the
bind value.  Note that a single sql_var holding an aggregate (arrayref
or hashref) may generate multiple bind values.  See L</ADDITIONAL
EXAMPLES> for example usage.

=head2 C<new>

 my $interp = SQL::Interpolate->new([$dbh|$filter]...);
 @result = $interp->sql_interp([$dbh|$filter]...);

Creates a new SQL::Interpolate object, which can configure the
interpolation process.

The arguments can be

- $dbh - zero or one DBI database handle.

- $filter - zero or more SQL filters (derived from
L<SQL::Interpolate::SQLFilter|SQL::Interpolate::Macro>).

The OO interface often is not needed, but it is useful if you need to
configure the behavior of many calls to sql_interp, such as when using
some macros.

=head2 C<make_sql_interp>

  my $sql_interp = make_sql_interp(@params);          # functional
  my $sql_interp = $interp->make_sql_interp(@params); # OO

Creates a closure that wraps the sql_interp function such that the
parameters passed to the sql_interp consist of @params following by
the parameters passed to the closure.  This function is typically used
to eliminate a need to always pass in a database handle into
sql_interp:

  my $interp = make_sql_interp($dbh);

  my ($sql, @bind) = $interp->(...);


=head2 Exports and use parameters

=over 4

=item TRACE_SQL

To enable tracing on C<sql_interp>, do

 use SQL::Interpolate TRACE_SQL => 1;

The generated SQL statements and bind values of all
C<sql_interp> calls will be sent to STDERR.

 DEBUG:interp[sql=INSERT INTO mytable VALUES(?),bind=5]

=item EXPORTS

 use SQL::Interpolate qw(:all);

':all' exports these functions: make_sql_interp,
sql_interp, sql_var, and sql.

=back

=head1 DEPENDENCIES

This module has no major dependencies.  If using the optional
modules, see their DEPENDENCIES sections.

=head1 ADDITIONAL EXAMPLES

These are more advanced examples.

=head2 Preparing and reusing a statement handle

  my $sth;
  for my $href (@array_of_hashrefs) {
     my @list = ("SELECT * FROM mytable WHERE", $href);
     my ($sql, @bind) = sql_interp @list;
     die 'ASSERT' if $sth && $sth->{Statement} ne $sql;
     $sth = $dbh->prepare($sql) unless $sth;
     $sth->execute(@list);
     $sth->fetchall_arrayref();
  }

The above code requires that $sql never changes.  If $sql does change,
you would have to prepare a new statement handle.  DBIx::Interpolate
implements a streamlined solution that caches statement
handles.

=head2 Binding variables types (DBI bind_param)

  my ($sql, @bind) = sql_interp "SELECT * FROM mytable WHERE",
      "x=", \$x, "AND y=", sql_var(\$y, SQL_VARCHAR), "AND z IN",
      sql_var([1, 2], SQL_INTEGER);
  # RESULT:
  #   @bind = ([$x, sql_var(\$x)], [$y, sql_var(\$y, type => SQL_VARCHAR)],
  #            [1, sql_var([1, 2], type => SQL_INTEGER)],
  #            [2, sql_var([1, 2], type => SQL_INTEGER)]);
  die 'ASSERT' if ref $bind[0] ne 'ARRAY';
  my $sth = $dbh->prepare($sql);
  my $idx = 1;
  for my $var (@bind) {
      $sth->bind_param($idx++, $var->[0], $var->[1]->{type});
  }
  $sth->execute();
  my $ret = $sth->selectall_arrayref();

This kludge is similar to the approach in L<SQL::Abstract's
bindtype|SQL::Abstract/bind_type>.
DBIx::Interpolate provides a simpler way of handling bind_type.

=head1 DESIGN NOTES

The section covers the design choices used in this module.

=head2 Philosophy and requirements

These principles have guided the design of SQL-Interpolate.

B<The core module (SQL::Interpolate) should be simple and not try to
do too much>.  (Mark Stosberg) SQL-Interpolate has one central
function, sql_interp, which is relatively simple and reusable in
itself such that all other functionality is built upon it.
Complicated (macro) and less robust (source filtering) capabilities
have been extracted out of the core module and into optional modules.
Source filtering, for example, is optional and off by default since
many distrust source filtering and fear it will cause bugs that are
especially difficult to debug because "it's not Perl anymore."

B<The bottleneck is the database rather than Perl>.  This module
necessarily imposes I<some> overhead, largely due to the added string
and regex processing.  The author has not quantified this overhead but
expects it to be low compared to database concerns such as disk access
and query processing and network concerns such as latency.  It may be
possible to avoid rerunning C<sql_interp> when only the binding
variables change (e.g. my ($sql, $bindobj) = sql_interp(...); @bind =
$bindobj->(x => 1); @bind = $bindobj->(x => 2)), but this is probably
does not provide much benefit.

B<The query language is SQL>.  There are other modules (such as
SQL::Abstract) that abstract the SQL language behind either
object-oriented (OO) method calls and/or Perl data structures (hashes
and arrays).  The former may be undesirable in some cases since it
replaces one language with another and hides the full capabilities and
expressiveness of your database's native SQL language.  The latter may
load too much meaning into the syntax of "{, "[" and "\" thereby
rendering the meaning less clear:

  SQL::Abstract example:
  %where = (lname => {like => '%son%'},
            age   => [-and => {'>=', 10}, {'<=', 20}])
  Plain SQL:
  "lname LIKE '%son' AND (age >= 10 AND age <= 20)"

In contrast, SQL::Interpolate does not abstract away your SQL but
rather makes it easier to interpolate Perl variables into your SQL.
Now, SQL::Interpolate I<does> load some meaning into "{, "[" and "\",
but we try to limit its use to obvious cases as justified below.
Since your raw SQL is exposed, you can use your particular dialect of
SQL, assuming the variable interpolation rules are relatively normal.
Database independence is a worthy goal, but it can be quite difficult
to achieve and is beyond the scope of SQL::Interpolate (though you
might wish to build such features on-top-of SQL::Interpolate).

B<Do-what-I-mean (DWIM) and satisfy the most common case.>  The syntax is
intended to be natural and terse for the most common cases.  This is
demonstrated in the examples.

Now, it may be a bit inconsistent that a hashref has two meanings. The
hashref in ("WHERE", \%hash) represents a logical AND-equal
construction, whereas the hashref in ("INSERT INTO mytable", \%hash)
and ("UPDATE mytable SET", \%hash) represents a tuple or portion of
it.  However, there is little ambiguity since a swap of the two
meanings results in illogical statements.  There is a limited number
of plausible meanings and these constructions, and these two are the
most common and useful ones in practice.  Admittedly, the former case
might alternately be understood as an logical OR (rather than AND)
construction, but it the AND construction is more common in a WHERE
clause and a natural "Do What I Mean." (Similarly, a query "Perl
MySQL" posed to a search engine usually implies "Perl AND MySQL" not
"Perl OR MySQL.)  In the latter interpretation of \%hash, the hashref
very well models a tuple that is more named rather than ordered.

Using an arrayref [x => $x, y => $y] rather than a hashref for the
AND'ed construction could work just as well, and it allows duplicate
keys and non-scalar keys.  However, SQL::Interpolate reserves [...]
for future use.  SQL::Interpolate interprets an arrayref
inside a hashref such as {x => \@y, ...} as an "x IN y" construction.
This was independently suggested by a number of people and unlikely
to be confused with the "x = y" since and x and y have different
dimensions (one is scalar and the other is a vector).

It may be a bit inconsistent that scalars inside hashrefs and
arrayrefs are interpreted as binding variables rather than SQL
as is the case outside.

  "WHERE", "x = ", \$x  # variables outside must be referenced
  "WHERE", {x => $x}    # variables inside should not be referenced
  "WHERE", [$x,$y]      # variables inside should not be referenced

However, this not too much a stretch of logicality, and the
alternatives are not pretty and do not satisfy the commonest case.
Consider:

  "WHERE", {x => \$x, y => \$y, z => 'CURRENT_TIMESTAMP'}
  "WHERE x IN", [\1, \2, \3]
  "WHERE x IN", \\@colors ("double referencing")

Exceptions from the commonest case require C<sql()>.

=head2 Limitations /  characteristics

This module is still a bit under development, so interfaces could
change some, particularly in the more esoteric features.  Still, it
is expected you will find this module quite stable, robust, tested,
simple, flexible, and well documented.

If you're new to this module, it's a good idea to examine the generated
SQL (e.g. the TRACE_SQL option) to ensure you're getting what you
think you're getting.  Be careful to reference the variables you
interpolate to prevent SQL injection (see discussion in
L</sql_interp>).

This module does not parse your SQL fragments except to the extent
required for variable interpolation, so it does not guarantee that the
generated SQL is valid but leaves that responsibility to your
database.  This is intentional so that it will works well even with
non-standard SQL dialects.  Some types of interpolation are
context-sensitive and involve examination of your SQL fragments.  The
examination could fail on obscure syntax, but it is often simple and
robust.  Look at the examples to see the types of interpolation that
are accepted, and if doubt, examine the SQL output yourself (use
Data::Dumper to examine the output of sql_interp or enable the
TRACE_SQL option) or look at the source code of sql_interp.  If
needed, you can disable context sensitivity by inserting a null-string
before a variable.

A few things are just not possible with the ("WHERE, \%hashref)
syntax, so in such case, use a more direct syntax:

  # ok--direct syntax
  sql_interp "...WHERE", {x => $x, y => $y}, 'AND y = z';
  # bad--trying to impose a hashref but keys must be scalars and be unique
  sql_interp "...WHERE",
      {sql_var(\$x) => sql('x'), y => $y, y => sql('z')};

=head2 Proposed enhancements

The following enhancements to SQL::Interpolate have been proposed.
The most important suggestions are listed at top, and some
suggestions could be rejected.

  # sample data for the below examples
  my $vv = [$v, $v];
  my $vh = [$h, $h];
  my $hh = {1 => $h, 5 => {m => 5, n => 6}};

A tutorial could be useful. (Wojciech)

Undef should be supported as such (slaven).
http://rt.cpan.org/NoAuth/Bug.html?id=11810

  IN:  "WHERE", {bla => undef}
  OUT: "WHERE bla IS NULL"

Similarly, this would be useful:

  IN:  "bla IN", [undef, 2]  (including {bla => [undef, 2]} syntax)
  OUT: "(blah IS NULL OR bla IN (?))", 2

B<Result sets>

In certain contexts, variable references should be interpreted as
result sets (of any number of tuples):

  # Examples where $x and $y are result sets
  - $x
  - $x, "UNION [ALL|DISTINCT]", $y
  - "INSERT INTO mytable", $x
  - "SELECT * FROM mytable WHERE x IN", $x

General behavior:

  INPUT:  $x
  OUTPUT: "SELECT ?", $s                        # $x = \$s
  OUTPUT: "SELECT ?, ?", @$v                    # $x = $v
  OUTPUT: "SELECT ? as m, ? as n",              # $x = $h
          $h->{m}, $h->{n}
  OUTPUT: "SELECT ?, ? UNION ALL SELECT ?, ?",  # $x = $vv
          map {@$_} @$v
  OUTPUT: "SELECT ? as m, ? as n UNION ALL      # $x = $vh
           SELECT ?, ?",
          $vh->[0]->{m}, $vh->[0]->{n},
          $vh->[1]->{m}, $vh->[1]->{n}
  OUTPUT: "SELECT ? as m, ? as n UNION ALL      # $x = $hh
           SELECT ?, ?",
          $hh->{1}->{m}, $hh->{1}->{n},
          $hh->{5}->{m}, $hh->{5}->{n}

INSERT and IN are special cases since MySQL supports an alternate
conventional syntax in addition to the subquery syntax above.  When
both syntaxes are valid, this modules should probably generate the
conventional syntax.

  # conventional
  SELECT * FROM mytable WHERE x IN (1,2,3)
  # subselect
  SELECT * FROM mytable WHERE x IN (SELECT 1,2,3)

  # conventional
  INSERT INTO mytable VALUES (1,2,3)
  INSERT INTO mytable (a,b,c) VALUES (1,2,3)
  # subselect
  INSERT INTO mytable SELECT 1,2,3
  INSERT INTO mytable (a,b,c) SELECT 1,2,3
  INSERT INTO mytable (a,b,c) (SELECT 1,2,3)  # equivalent

MySQL and DB2 (any other databases?) also support a special
multi-row INSERT syntax:

  # MySQL
  INSERT INTO table (a,b,c) VALUES (1,2,3),(4,5,6)
  # subselect
  INSERT INTO table SELECT 1,2,3 UNION SELECT 4,5,6

This mechanism allows passing DBI results back into the interpolation
list:

  # DBIx::Interpolate example ($vv2 is identical to $vv)
  my $vv2 = $dbx->selectall_arrayref(
    $dbx->selectall_arrayref($vv));

B<Table references>

In certain contexts, variable references should be interpreted as
table references (to temporary tables).

  # Example where $x and $y are table references
  "SELECT * FROM", $x, "JOIN", $y

General behavior:

  IN:  "SELECT * FROM", $x
  OUT: "SELECT * FROM (SELECT ?) as t001", $s            # $x = \$s
  OUT: "SELECT * FROM (SELECT ?, ?) as t001", @$v        # $x = $v
  OUT: "SELECT * FROM (SELECT ? as m, ? as n) as t001",  # $x = $h
       $h->{m}, $h->{n}
  OUT: "SELECT * FROM
       (SELECT ?, ? UNION ALL SELECT ?, ?) as t001",
       map {@$_} @$v                                     # $x = $vv
  OUT: "SELECT * FROM
       (SELECT ? as m, ? as n UNION ALL SELECT ?, ?) as temp001",
       $vh->[0]->{m}, $vh->[0]->{n},
       $vh->[1]->{m}, $vh->[1]->{n}                      # $x = $vh
  OUT: "SELECT * FROM
       (SELECT ? as x, ? as y UNION ALL SELECT ?, ?) as temp001",
       $hh->{1}->{m}, $hh->{1}->{n},
       $hh->{5}->{m}, $hh->{5}->{n}                      # $x = $hh

Complex example:

  IN:  "SELECT * FROM", [[1,2],[3,4]], "JOIN", [5,6], "
       UNION
       SELECT * FROM", [7,8,9,10];
  OUT: SELECT * FROM
         (SELECT 1,2 UNION ALL SELECT 3,4) as t001 JOIN
         (SELECT 5,6) as t002
       UNION
       SELECT * FROM (SELECT 7,8,9,10) as t003;

Temporary tables created by subselects often require a name in MySQL,
so one is generated (e.g. t001).  At times, you may want to specify
your own name with an explicit AS clause:

  IN:  "SELECT * FROM", $vv, "AS t"
  OUT: "SELECT * FROM
       (SELECT ?, ? UNION ALL SELECT ?, ?) AS t",
       map {@$_} @$v

B<More proposals>

The following additional type of INSERT might be supported (markt):

  IN:  "INSERT INTO temp (id,val) VALUES", [1,2]
or
  IN:  "INSERT INTO temp (id,val)", [1,2]

Support for placeholders might be added for cases when placing the
variable references in-line is inconvenient or not desired:

  IN:  "SELECT * FROM mytable WHERE x = ? and y = ?", \$x, \$y
  OUT: "SELECT * FROM mytable WHERE x = ? and y = ?", $x, $y

  IN:  "SELECT * FROM mytable WHERE x = :x and y = :y",
       {x => $x, y => $y}
  OUT: "SELECT * FROM mytable WHERE x = ? and y = ?", $x, $y

Similarly, named placeholders might be supported (possibly via
sql_var()):

  "SELECT * FROM mytable WHERE",
    "x=", sql_var("color"), "and", {val => sql_var("weight")},
    sql_val(weight => 100), sql_val(color => 'blue')

Placeholders might be allowed in the interpolation list:

  "SELECT * FROM mytable WHERE x = ? and y = ?", \$x, \$y

"AND"s might be made implicit such that the following statements
become equivalent.  This may not be necessary.

  sql_interp "...WHERE", {x => 5}, 'AND', sql_or(...)
  sql_interp "...WHERE", {x => 5}, sql_or(...)  # equivalent

sql_and and sql_or macros might support hashrefs as well (the former
for clarity and the latter for terseness):

  "SELECT * FROM mytable WHERE", {x => 2, y => 5}
  "SELECT * FROM mytable WHERE", sql_and {x => 2, y => 5} # same as above
  "SELECT * FROM mytable WHERE", sql_or {x => 2, y => 5}

Logical operations might be supported as follows (e.g. junctions).
This might be rejected due to unintuitive syntax.

  "SELECT * FROM mytable WHERE", {
    x => sql_not(2),   # x <> 2
    y => 5
  }
 "SELECT * FROM mytable WHERE", sql_or { # might be difficult to read
   x => sql_or(2, 3, sql_and(4, 5)),
   y => 5
 }

Support for tuples (e.g. MySQL) might be added, but this is probably too
uncommon to be worthwhile to implement:

  SELECT * FROM edge WHERE", {"(sid, did)" => [5, 1]}  # equals
  SELECT * FROM edge WHERE", {"(sid, did)" => [[5, 1], [2, 3]]} # IN

=head2 Implementation notes

Oracle (unlike MySQL) does not allow 'WHERE id = 5 and 1' nor
'WHERE id = 5 or 0'.  SQL::Interpolate therefore generates the more
portable 'WHERE id = 5 and 1=1' and 'WHERE id = 5 or 1=0'.

=head1 CONTRIBUTORS

David Manura (L<http://math2.org/david/contact>) (author).
Feedback incorporated from Mark Stosberg
(L<http://mark.stosberg.com/>) (recommended simplifying the code
module, simplified the docs, and provided a bunch of other highly
useful feedback), Mark Tiefenbruck, Wojciech Pietron (Oracle compat),
Jim Chromie (DBIx::Interpolate idea), Juerd Waalboer, Terrence Brannon
(early feedback), and others.

=head1 FEEDBACK

Bug reports and comments on the design are most welcome.  rt.cpan.org
can be used for specific bug reporting, but you may also use the
discussion list (L<http://www.cpanforum.com/dist/SQL-Interpolate>) or
contact me directly (L<http://math2.org/david/contact>).  See also the
project page at L<http://math2.org/sql_interpolate>.

=head1 LEGAL

Copyright (c) 2003-2005, David Manura.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 SEE ALSO

=head2 Other modules in this distribution

L<DBIx::Interpolate|DBIx::Interpolate> extends this module slightly,
allowing certain DBI methods to accept an C<sql_interp>-like
interpolation list rather than the traditional ($statement, \%attr,
@bind_values)-like parameter list.

L<SQL::Interpolate::Filter|SQL::Interpolate::Filter> streamlines the
the SQL::Interpolate syntax with direct SQL interpolation analogous to
Perl string interpolation.

L<SQL::Interpolate::Macro|SQL::Interpolate::Macro> provides an
assortment of macros and SQL filters, which allow you to write
simpler, more robust, and possibly more portable queries.

=head2 Related modules

L<SQL::Abstract|SQL::Abstract> shares with C<SQL::Interpolate> the
purpose of making SQL generation easier. SQL::Abstract differs in that
it expresses queries in terms of OO method calls. It's syntax may
impair readability because it uses the subtle difference between a
brace and bracket to denote the difference between AND and OR in a
query (the user can change whether a bracket implies "AND" or
"OR"). Some complex where clauses are difficult or impossible with
L<SQL::Abstract|SQL::Abstract>.  SQL::Interpolate gives the author
more direct access to the underlying SQL.  This permits using the full
expressivity of the database query language.

L<DBIx::Simple|DBIx::Simple> strives to simplify SQL generation as
well as the data structures returned from
L<DBI|DBI>. C<SQL::Interpolate> and the related modules don't try to
handle C<DBI>'s results at all. C<DBIx::Simple> currently can use
L<SQL::Abstract|SQL::Abstract> to help generate SQL, and it may be
possible in the future for the same to be done with
C<SQL::Interpolate>.

L<Class::DBI|Class::DBI> is a popular "complete" solution for abstract
database access through an OO interface. It currently has a plugin
called L<Class::DBI::AbstractSearch|Class::DBI::AbstractSearch> that
allows it to use C<SQL::Abstract> to generate SQL. It's possible that
C<SQL::Interpolate> could be integrated with it as well.

L<SQL::Preproc|SQL::Preproc> provides an "embedded SQL" approach where
the Perl and SQL languages are extended (via source filtering) to
support interwoven Perl and SQL.  The syntax supports interpolating
Perl variables into SQL and passing query results back into Perl
variables.  In contrast, SQL::Interpolate extends neither SQL nor Perl
(except with the optional source filtering module), and it deals only
with interpolating Perl variables into queries, whereas returning
variables from queries is the job of something like DBI,
DBIx::Interpolate, or DBIx::Simple.

L<SQL::String|SQL::String> shares a number of similiarities to
SQL::Interpolate but it is more rudimentary.  Both let you combine
"chunks" of SQL that have their parameters attached to them and then
transform it into an SQL string and list of bind parameters suitable
for passing to DBI.

=head2 Related resources

SQL Interpolate Project Page: L<http://math2.org/sql_interpolate> .

Full example code - Meset::MessageBoard in Meset
(L<http://math2.org/meset>).

=cut

