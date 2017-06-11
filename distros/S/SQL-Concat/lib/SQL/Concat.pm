package SQL::Concat;
use 5.010;
use strict;
use warnings;
use Carp;

our $VERSION = "0.002";

use MOP4Import::Base::Configure -as_base
  , [fields => qw/sql bind/
     , [sep => default => ' ']]
  ;
use MOP4Import::Util qw/lexpand terse_dump/;

sub SQL {
  MY->new(sep => ' ')->concat(@_);
}

sub PAR {
  SQL(@_)->paren;
}

# Useful for OPT("limit ?", $limit, OPT("offset ?", $offset))
sub OPT {
  my ($expr, $value, @rest) = @_;
  return unless defined $value;
  SQL([$expr, $value], @rest);
}

sub PFX {
  my ($prefix, @items) = @_;
  return unless @items;
  my @non_empty = _nonempty(@items)
    or return;
  SQL($prefix => @non_empty);
}

sub _nonempty {
  grep {
    my MY $item = $_;
    if (not defined $item
        or not ref $item and $item !~ /\S/) {
      ();
    } elsif (ref $item eq 'ARRAY') {
      $item;
    } elsif (ref $item and UNIVERSAL::can($item, 'is_empty')
	     and $item->is_empty) {
      ();
    } else {
      $item;
    }
  } @_;
}

# sub SELECT {
#   MY->new(sep => ' ')->concat(SELECT => @_);
# }

sub CAT {
  MY->concat_by(_wrap_ws($_[0]), @_[1..$#_]);
}

sub CSV {
  MY->concat_by(', ', @_);
}

sub _wrap_ws {
  my ($str) = @_;
  $str =~ s/^(\S)/ $1/;
  $str =~ s/(\S)\z/$1 /;
  $str;
}

# XXX: Do you want deep copy?
sub clone {
  (my MY $item) = @_;
  MY->new(%$item)
}

sub is_empty {
  (my MY $item) = @_;
  $item->{sql} !~ /\S/
}

sub paren {
  (my MY $item) = @_;
  if (_nonempty($item)) {
    $item->format_by('(%s)')
  } else {
    return;
  }
}

sub paren_nl_indent {
  (my MY $item, my $indent) = @_;
  if (_nonempty($item)) {
    $item->format_by("(\n%s\n)", $indent || 2)
  } else {
    return;
  }
}

sub format_by {
  (my MY $item, my ($fmt, $indent)) = @_;
  my MY $clone = $item->clone;
  my $sql = $item->{sql};
  $sql =~ s/^/" " x $indent/emg if $indent;
  $clone->{sql} = sprintf($fmt, $sql);
  $clone;
}

sub concat_by {
  my MY $self = ref $_[0]
    ? shift->configure(sep => shift)
    : shift->new(sep => shift);
  $self->concat(_nonempty(@_));
}

#
# XXX: Could have more extension hook, hmm...
#
sub concat {
  my MY $self = ref $_[0] ? shift : shift->new;
  if (defined $self->{sql}) {
    croak "concat() called after concat!";
  }
  my @sql;
  $self->{bind} = [];
  foreach my MY $item (@_) {
    next unless defined $item;
    if (not ref $item) {
      push @sql, $item;
    } else {

      $item = $self->of_bind_array($item)
        if ref $item eq 'ARRAY';

      $item->validate_placeholders;

      push @sql, $item->{sql};
      push @{$self->{bind}}, @{$item->{bind}};
    }
  }
  $self->{sql} = join($self->{sep}, @sql);
  $self
}

sub of_bind_array {
  (my MY $self, my $bind_array) = @_;
  my ($s, @b) = @$bind_array;
  $self->new(sql => $s, bind => \@b);
}

sub validate_placeholders {
  (my MY $self) = @_;

  my $nbinds = $self->{bind} ? @{$self->{bind}} : 0;

  unless ($self->count_placeholders == $nbinds) {
    croak "SQL Placeholder mismatch! sql='$self->{sql}' bind="
      .terse_dump($self->{bind});
  }

  $self;
}

sub count_placeholders {
  (my MY $self) = @_;

  unless (defined $self->{sql}) {
    croak "Undefined SQL Fragment!";
  }

  $self->{sql} =~ tr,?,?,;
}

sub as_sql_bind {
  (my MY $self) = @_;
  if (wantarray) {
    ($self->{sql}, lexpand($self->{bind}));
  } else {
    [$self->{sql}, lexpand($self->{bind})];
  }
}

sub sql_bind_pair {
  (my MY $self) = @_;
  if (wantarray) {
    ($self->{sql}, $self->{bind} // [])
  } else {
    [$self->{sql}, $self->{bind} // []];
  }
}


#========================================

sub BQ {
  if (ref $_[0]) {
    croak "Meaningless backtick for reference! ".terse_dump($_[0]);
  }
  if ($_[0] =~ /\`/) {
    croak "Can't quote by backtick: text contains backtick! $_[0]";
  }
  q{`}.$_[0].q{`}
}

1;


__END__
=encoding utf-8

=head1 NAME

SQL::Concat - SQL concatenator, only cares about bind-vars, to write SQL generator

=head1 SYNOPSIS

    #
    # Functional interface
    #
    use SQL::Concat qw/SQL/;

    $q = SQL("SELECT uid FROM authors"); # Just single fixed SQL

    $q = SQL("SELECT uid FROM authors"   # Fixed SQL fragment
    
            , ["WHERE name = ?", 'foo']  # Pair of placeholder(s) and value(s)
    
            , "ORDER BY uid"             # Fixed SQL fragment (again)
    
            , ($reverse ? "desc" : ())   # Conditional Fixed SQL fragment
          );

    $q = SQL($q                          # SQL(SQL(SQL(...), SQL(..))) is ok
             , "LIMIT 10"
             , ["OFFSET ?", 30]
          );

    # Extract concatenated SQL and bind vars.
    #
    ($sql, @binds) = $q->as_sql_bind;
    # ==>
    # SQL: SELECT uid FROM authors WHERE name = ? ORDER BY uid LIMIT 10 OFFSET ?
    # BIND: ('foo', 30)

    #
    # SQL() doesn't care about composed SQL syntax. It just concat given args.
    #
    $q = SQL("SELECT uid", "FROM authors");
    $q = SQL("SELECT uid FROM", "authors");
    $q = SQL(SELECT => uid => FROM => 'authors');

    #
    # OO Interface
    #
    my $comp = SQL::Concat->new(sep => ' ')
      ->concat(SELECT => foo => FROM => 'bar');


=head1 DESCRIPTION

SQL::Concat is B<NOT> a I<SQL generator>, but a minimalistic B<SQL
fragments concatenator> with B<safe bind-variable handling>.  SQL::Concat
doesn't care anything about SQL syntax but I<placeholder> and
I<bind-variables>. Other important topics to generate correct SQL
such as SQL syntaxes, SQL keywords, quotes, or even parens are
all remained your-side.

This module only focuses on correctly concatenating SQL fragments
with keeping their corresponding bind variables.

=head2 Motivation

To run complex queries on RDBs, you must compose complex SQLs.
There are many feature-rich SQL generators on CPAN to help these tasks
(e.g. L<SQL::Abstract>, L<SQL::Maker>, L<SQL::QueryMaker>, ...).
Unfortunately, they themselves come with their own syntax and semantics
and have significant learning cost.
And anyway, when you want to generate complex SQL at some level,
you can't avoid learning target SQL anymore.
Eventually, you may realize you doubled complexity and learning cost.

So, this module is written not for SQL refusers
but for dynamic SQL programmers who really want to write precisely controlled SQL,
who already know SQL enough and just want to handle I<placeholders>
and I<bind-variables> safely.

=head2 Concatenate STRING, BIND_ARRAY and SQL::Concat

SQL::Concat can concatenate following four kind of values
into single SQL::Concat object.

    SQL("SELECT uid FROM authors"   # STRING

      , ["WHERE name = ?", 'foo']   # BIND_ARRAY

      , SQL("ORDER BY uid")         # SQL::Concat object

      , undef                       # undef is ok and silently disappears.
    );

In other words, SQL::Concat is C<join($SEP, @ITEMS)> with special handling for pairs of B<placeholders> and B<bind variables>.

Default $SEP is a space character C<' '> but you can give it as L<sep =E<gt> $sep|/sep> option
for L<new()|/new>
or constructor argument like L<SQL::Concat-E<gt>concat_by($SEP)|/concat_by>.

=over 4

=item STRING

Non-reference values are used just as resulting SQL as-is.
This means each given strings are treated as B<RAW> SQL fragment.
If you want to use foreign values, you must use next L</BIND_ARRAY>.

  use SQL::Concat qw/SQL/;

  SQL("SELECT 1")->as_sql_bind;
  # SQL: "SELECT 1"
  # BIND: ()

  SQL("SELECT foo, bar" => FROM => 'baz', "\nORDER BY bar")->as_sql_bind;
  # SQL: "SELECT foo, bar FROM baz
  #       ORDER BY bar"
  # BIND: ()

Note: C<SQL()> is just a shorthand of C<< SQL::Concat->new(sep => ' ')->concat( @ITEMS... ) >>.


=item BIND_ARRAY [$RAW_SQL, @BIND]
X<BIND_ARRAY>

If item is ARRAY reference, it is treated as BIND_ARRAY.
The first element of BIND_ARRAY is treated as RAW SQL.
The rest of the elements are pushed into C<< ->bind >> array.
This SQL fragment must contain B<same number of SQL-placeholders>(C<?>)
with corresponding @BIND variables.

  SQL(["city = ?", 'tokyo'])->as_sql_bind
  # SQL: "city = ?"
  # BIND: ('tokyo')

  SQL(["age BETWEEN ? AND ?", 20, 65])->as_sql_bind
  # SQL: "age BETWEEN ? AND ?"
  # BIND: (20, 65)

=item SQL::Concat
X<compose>

Finally, concat() can accept SQL::Concat instances. In this case, C<< ->sql >> and C<< ->bind >> are extracted and treated just like L</BIND_ARRAY>

  SQL("SELECT * FROM members WHERE" =>
      SQL(["city = ?", "tokyo"]),
      AND =>
      SQL(["age BETWEEN ? AND ?", 20, 65])
  )->as_sql_bind;
  # SQL: "SELECT * FROM members WHERE city = ? AND age BETWEEN ? AND ?"
  # BIND: ('tokyo', 20, 65)

=back

=head1 TUTORIAL

=head2 Hide WHERE clause if $name is empty

Suppose you have a sql statement
C<select * from artists where name = ? order by age>
and you want to make C<where name = ?> part conditional.
It can be achieved via L<SQL()|/SQL>.

  use SQL::Concat qw/SQL/;

  $q = SQL("select * from artists"
          , ($name ? ["where name = ?", $name] : ())
          , "order by age"
       );
  ($sql, @bind) = $q->as_sql_bind;

=head2 Add more conditions with parens

Then, you want to add C<age = ?> to where clause.
So you may want to put "WHERE" only if $name or $age is present.
You can achieve it via L<PFX($STR, @OTHER)|/PFX>.
PFX() prefixes C<@OTHER> with C<$STR>.
If C<@OTHER> is empty, whole PFX() is also empty.

  use SQL::Concat qw/PFX/;

  $q = SQL("select * from artists"
          , PFX("WHERE"
               , ($name ? ["name = ?", $name] : ())
               , ($age  ? ["age = ?", $age] : ())
            )
          , "order by age"
       );
  # (Wrong)
  # select * from artists WHERE name = ? age = ? order by age

Unfortunately, this doesn't work if B<both> $name and $age is given.
You must decide conjunction or disjunction.
Suppose this time you want to put C<OR> between them (oh, really?;-).
You can achieve it via L<CAT()|/CAT>. CAT() behaves like
L<Perl's join($SEP, @ITEM)|perlfunc/join> but keeps bind-variables safely.

  use SQL::Concat qw/CAT/;

  $q = SQL("select * from artists"
          , PFX("WHERE" =>
               CAT("OR"
                  , ($name ? ["name = ?", $name] : ())
                  , ($age  ? ["age = ?", $age] : ())
               )
            )
          , "order by age"
       );
  # select * from artists WHERE name = ? OR age = ? order by age

Then, you may feel above is bit complicated and factorize it out.

  $c = CAT("OR"
          , ($name ? ["name = ?", $name] : ())
          , ($age  ? ["age = ?", $age] : ())
       );
  $q = SQL("select * from artists"
          , PFX(WHERE => $c)
          , "order by age"
       );

Then, you want to add another condtion C<AND address = ?>.
You will nest CAT().

  $c = CAT("AND"
          , CAT("OR"
               , ($name ? ["name = ?", $name] : ())
               , ($age  ? ["age = ?", $age] : ())
            )
          , ($address ? ["address = ?", $address] : ())
       );
  #..
  # (Wrong)
  # select * from artists WHERE name = ? OR age = ? AND address = ? order by age

Unfortunately, this doesn't work as expected because of the lack of paren.
To put paren around "OR" clause, you can use L<-E<gt>paren()|/paren> method.

  $c = CAT("AND"
          , CAT("OR"
               , ($name ? ["name = ?", $name] : ())
               , ($age  ? ["age = ?", $age] : ())
            )->paren                                   # <<----- THIS
          , ($address ? ["address = ?", $address] : ())
       );
  # select * from artists WHERE (name = ? OR age = ?) AND address = ? order by age

=head1 FUNCTIONS

=head2 C<< SQL( @ITEMS... ) >>
X<SQL>

Equiv. of

=over 4

=item * C<< SQL::Concat->concat( @ITEMS... ) >>

=item * C<< SQL::Concat->concat_by(' ', @ITEMS... ) >>

=item * C<< SQL::Concat->new(sep => ' ')->concat( @ITEMS... ) >>

=back

=head2 C<< CAT($SEP, @ITEMS... ) >>
X<CAT>

Equiv. of C<< SQL::Concat->concat_by($SEP, @ITEMS... ) >>, except
C<$SEP> is wrapped by whitespace when necessary.

  CAT(UNION =>
      , SQL("select * from foo")
      , SQL("select * from bar")
  )

If C<@ITEMS> are empty, this returns empty result:

  CAT(AND =>
      , ($name ? ["name = ?", $name] : ())
      , ($age  ? ["age = ?", $age]   : ())
  )

=head2 C<< PFX($ITEM, @OTHER_ITEMS...) >>
X<PFX>

Prefix C<$ITEM> only when C<@OTHER_ITEMS> are not empty.

  PFX(WHERE =>
      ($name ? ["name = ?", $name] : ())
  )

Usually used with C<CAT()> like following:

  PFX(WHERE =>
      CAT('AND'
          , ($name ? ["name = ?", $name] : ())
          , ($age  ? ["age = ?", $age]   : ())
      )
  )


=head2 C<< OPT(RAW_SQL, VALUE, @OTHER...) >>
X<OPT>

If VALUE is defined, C<< (SQL([$RAW_SQL, $VALUE]), @OTHER_ITEMS) >> are returned. Otherwise empty list is returned.

This is designed to help generating C<"LIMIT ? OFFSET ?">.

  OPT("limit ?", $limit, OPT("offset ?", $offset));

is shorthand version of:

  SQL(defined $limit
     ? (["limit ?", $limit]
       , SQL(defined $offset
            ? ["offset ?", $offset]
            : ()
         )
       )
     : ()
  )

=head2 C<< PAR( @ITEMS... ) >>
X<PAR>

Equiv. of C<< SQL( ITEMS...)->paren >>

=head2 C<< CSV( @ITEMS... ) >>
X<CSV>

Equiv. of C<< CAT(', ', @ITEMS... ) >>

Note: you can use "," anywhere in concat() items. For example,
you can write C<< SQL(SELECT => "x, y, z") >> instead of C<< SQL(SELECT => CSV(qw/x y z/)) >>.

=head1 METHODS

=head2 C<< SQL::Concat->new(%args) >>
X<new>

Constructor, inherited from L<MOP4Import::Base::Configure>.

=head3 Options

Following options has their getter.
To set these options after new,
use L<MOP4Import::Base::Configure/configure> method.

=over 4

=item sep
X<sep>

Separator, used in L<concat()|/concat>.

=item sql
X<sql>

SQL, constructed when L<concat()|/concat> is called.
Once set, you are not allowed to call L</concat> again.

=item bind
X<bind>

Bind variables, constructed when L</BIND_ARRAY> is given to L<concat()|/concat>.

=back


=head2 C<< SQL::Concat->concat( @ITEMS... ) >>
X<concat>

Central operation of SQL::Concat. It basically does:

  $self->{bind} = [];
  foreach my MY $item (@_) {
    next unless defined $item;
    if (not ref $item) {
      push @sql, $item;
    } else {
      $item = SQL::Concat->of_bind_array($item)
        if ref $item eq 'ARRAY';

      $item->validate_placeholders;

      push @sql, $item->{sql};
      push @{$self->{bind}}, @{$item->{bind}};
    }
  }
  $self->{sql} = join($self->{sep}, @sql);


=head2 C<< SQL::Concat->concat_by($SEP, @I..) >>
X<concat_by>

Equiv. of C<< SQL::Concat->new(sep => $SEP)->concat( @ITEMS... ) >>

=head2 C<< ->is_empty() >>
X<is_empty>

Test whether C<< $obj->sql >> doesn't contain C<< /\S/ >> or not.

=head2 C<< ->paren() >>
X<paren>

Equiv. of C<< $obj->is_empty ? () : $obj->format_by('(%s)') >>.

=head2 C<< ->paren_nl_indent() >>
X<paren_nl_indent>

Indenting version of L<-E<gt>paren()|/paren> method.

  $q = SQL("select * from artists where aid in"
           => SQL(["select aid from records where release_year = ?", $year])
              ->paren_nl_indent
       );

Above generates following:

=for code sql

  select * from artists where aid in (
    select aid from records where release_year = ?
  )

=for code perl


=head2 C<< ->format_by($FMT, ?$INDENT?) >>
X<format_by>

Apply C<< sprintf($FMT, $self->sql) >>.
This will create a clone of $self.

If optional integer argument C<$INDENT> is given, C<sql> is indented
before formatting.

=head2 C<< ->as_sql_bind() >>
X<as_sql_bind>

  my ($sql, @bind) = SQL(...)->as_sql_bind;

Extract C<< $self->sql >> and C<< @{$self->bind} >>.
If caller is scalar context, wrap them with C<[]>.

=head2 C<< ->sql_bind_pair() >>
X<sql_bind_pair>

  my ($sql, $bind) = SQL(...)->sql_bind_pair;

Extract C<< [$self->sql, $self->bind] >>.
If caller is scalar context, wrap them with C<[]>.


=head1 MISC

=head2 Complex example

  use SQL::Concat qw/SQL CAT OPT/;

  my ($tags, $limit, $offset, $reverse) = @_;

  my $pager = OPT("limit ?", $limit, OPT("offset ?", $offset));

  my ($sql, @bind)
    = SQL("SELECT datetime(ts, 'unixepoch', 'localtime') as dt, eid, path"
	  , "FROM entrytext"
	  , ($tags
	     ? SQL("WHERE eid IN"
                   , SQL("SELECT eid FROM"
                         => CAT("\nINTERSECT\n"
                                => map {
                                  SQL("SELECT DISTINCT eid, ts FROM entry_tag"
                                      , "WHERE tid IN"
                                      => SQL("SELECT tid FROM tag WHERE"
                                             , ["tag glob ?", lc($_)])
                                      ->paren_nl_indent
                                    )
                                } @$tags
                              )->paren_nl_indent
                         , "\nORDER BY"
                         , "ts desc, eid desc"
                         , $pager)->paren_nl_indent
                 )
             : ())
	  , "\nORDER BY"
	  , "fid desc, feno desc"
	  , ($tags ? () : $pager)
	)->as_sql_bind;

Generated SQL example:

=for code sql

  SELECT datetime(ts, 'unixepoch', 'localtime') as dt, eid, path FROM entrytext WHERE eid IN (
    SELECT eid FROM (
      SELECT DISTINCT eid, ts FROM entry_tag WHERE tid IN (
        SELECT tid FROM tag WHERE tag glob ?
      )
      INTERSECT
      SELECT DISTINCT eid, ts FROM entry_tag WHERE tid IN (
        SELECT tid FROM tag WHERE tag glob ?
      )
    )
    ORDER BY ts desc, eid desc limit ? offset ?
  )
  ORDER BY fid desc, feno desc


=head1 SEE ALSO

L<SQL::Object>, L<SQL::Maker>, L<SQL::QueryMaker>

=head1 LICENSE

Copyright (C) Kobayasi, Hiroaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kobayasi, Hiroaki E<lt>hkoba @ cpan.orgE<gt>

=cut
