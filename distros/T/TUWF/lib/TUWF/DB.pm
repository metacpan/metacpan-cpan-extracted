
package TUWF::DB;

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Time::HiRes 'time';

our $VERSION = '1.2';
our @EXPORT = qw|
  dbInit dbh dbCheck dbDisconnect dbCommit dbRollBack
  dbExec dbVal dbRow dbAll dbPage
|;
our @EXPORT_OK = ('sqlprint');


sub dbInit {
  my $self = shift;
  require DBI;
  my $login = $self->{_TUWF}{db_login};
  my $sql;
  if(ref($login) eq 'CODE') {
    $sql = $login->($self);
    croak 'db_login subroutine did not return a DBI instance.' if !ref($sql) || !$sql->isa('DBI::db');
  } elsif(ref($login) eq 'ARRAY' && @$login == 3) {
    $sql = DBI->connect(@$login, {
      PrintError => 0, RaiseError => 1, AutoCommit => 0,
      mysql_enable_utf8 => 1, # DBD::mysql
      pg_enable_utf8    => 1, # DBD::Pg
      sqlite_unicode    => 1, # DBD::SQLite
    });
  } else {
    croak 'Invalid value for the db_login setting.';
  }
  $sql->{private_tuwf} = 1;
  inject_logging();

  $self->{_TUWF}{DB} = {
    sql => $sql,
    queries => [],
  };
}


sub dbh {
  return shift->{_TUWF}{DB}{sql};
}


sub dbCheck {
  my $self = shift;
  my $info = $self->{_TUWF}{DB};

  my $start = time;
  $info->{queries} = [];

  if(!$info->{sql}->ping) {
    warn "Ping failed, reconnecting";
    $self->dbInit;
  }
  $self->dbRollBack;
  push(@{$info->{queries}}, [ 'ping/rollback', {}, time-$start ]);
}


sub dbDisconnect {
  shift->{_TUWF}{DB}{sql}->disconnect();
}


sub dbCommit {
  my $self = shift;
  my $start = [Time::HiRes::gettimeofday()] if $self->debug || $self->{_TUWF}{log_slow_pages};
  $self->{_TUWF}{DB}{sql}->commit();
  push(@{$self->{_TUWF}{DB}{queries}}, [ 'commit', {}, Time::HiRes::tv_interval($start) ])
    if $self->debug || $self->{_TUWF}{log_slow_pages};
}


sub dbRollBack {
  shift->{_TUWF}{DB}{sql}->rollback();
}


# execute a query and return the number of rows affected
sub dbExec {
  return sqlhelper(shift, 0, @_);
}


# ..return the first column of the first row
sub dbVal {
  return sqlhelper(shift, 1, @_);
}


# ..return the first row as an hashref
sub dbRow {
  return sqlhelper(shift, 2, @_);
}


# ..return all rows as an arrayref of hashrefs
sub dbAll {
  return sqlhelper(shift, 3, @_);
}


# same as dbAll, but paginates results by adding
# an OFFSET and LIMIT to the query, the first argument
# should be a hashref with the keys page and results.
# Returns the usual value from dbAll and a value
# indicating whether there is a next page
sub dbPage {
  my($s, $o, $q, @a) = @_;
  $q .= ' LIMIT ? OFFSET ?';
  push @a, $o->{results}+1, $o->{results}*($o->{page}-1);
  my $r = $s->dbAll($q, @a);
  return ($r, 0) if $#$r != $o->{results};
  pop @$r;
  return ($r, 1);
}


sub sqlhelper { # type, query, @list
  my $self = shift;
  my $type = shift;
  my $sqlq = shift;

  $sqlq =~ s/\r?\n/ /g;
  $sqlq =~ s/  +/ /g;
  my(@q) = @_ ? sqlprint($sqlq, @_) : ($sqlq);

  my($q, $r);
  my $ret = eval {
    $q = $self->dbh->prepare($q[0]);
    $q->execute($#q ? @q[1..$#q] : ());
    $r = $type == 1 ? ($q->fetchrow_array)[0] :
         $type == 2 ? $q->fetchrow_hashref :
         $type == 3 ? $q->fetchall_arrayref({}) :
                      $q->rows;
    1;
  };

  # re-throw the error in the context of the calling code
  croak($self->dbh->errstr || $@) if !$ret;

  $r = 0  if $type == 0 && (!$r || $r == 0);
  $r = {} if $type == 2 && (!$r || ref($r) ne 'HASH');
  $r = [] if $type == 3 && (!$r || ref($r) ne 'ARRAY');

  return $r;
}


# sqlprint:
#   ?    normal placeholder
#   !l   list of placeholders, expects arrayref
#   !H   list of SET-items, expects hashref or arrayref: format => (bind_value || \@bind_values)
#   !W   same as !H, but for WHERE clauses (AND'ed together)
#   !s   the classic sprintf %s, use with care
# This isn't sprintf, so all other things won't work,
# Only the ? placeholder is supported, so no dollar sign numbers or named placeholders

sub sqlprint { # query, bind values. Returns new query + bind values
  my @a;
  my $q='';
  for my $p (split /(\?|![lHWs])/, shift) {
    next if !defined $p;
    if($p eq '?') {
      push @a, shift;
      $q .= $p;
    } elsif($p eq '!s') {
      $q .= shift;
    } elsif($p eq '!l') {
      my $l = shift;
      $q .= join ', ', map '?', 0..$#$l;
      push @a, @$l;
    } elsif($p eq '!H' || $p eq '!W') {
      my $h=shift;
      my @h=ref $h eq 'HASH' ? %$h : @$h;
      my @r;
      while(my($k,$v) = (shift(@h), shift(@h))) {
        last if !defined $k;
        my($n,@l) = sqlprint($k, ref $v eq 'ARRAY' ? @$v : $v);
        push @r, $n;
        push @a, @l;
      }
      $q .= ($p eq '!W' ? 'WHERE ' : 'SET ').join $p eq '!W' ? ' AND ' : ', ', @r
        if @r;
    } else {
      $q .= $p;
    }
  }
  return($q, @a);
}


# There are generally two approaches to adding logging to DBI: The common and
# clean approach is to subclass DBD::st and DBD::db (e.g. DBIx::LogAny). But
# subclassing doesn't stack nicely, and you may need to implement more methods
# because methods calling each other internally won't be caught.
#
# The other approach is to replace the methods of DBD::st and DBD::db directly,
# as done in DBI::Log. The downside is that it's hacky, unreliable when DBD::*
# modules come with their own implementation of something, and this approach
# affects *all* DBI interation and not just those of selected handlers. The
# latter issue is easily solved by setting a private flag in the DBI object
# ('private_tuwf' in this case).
sub inject_logging {
  require DBI;
  no warnings 'redefine';

  # The measured SQL timing only includes that of the execute() call, but it's
  # likely that some query processing also happens during fetching.
  # Unfortunately, I haven't found a reliable way to trigger on "Okay, I'm done
  # with executing and fetching this statement". The final() method is not
  # implicitely called, and adding an object destructor wouldn't work with
  # cached prepared statements.
  my $orig_execute = \&DBI::st::execute;
  *DBI::st::execute = sub {
    my($self) = @_;
    my $start = time;
    my $ret = $orig_execute->(@_);

    if($self->{Database}{private_tuwf}) {
      my $time = time - $start;
      my %params = %{$self->{ParamValues} || {}};

      $TUWF::OBJ->log(sprintf
        '[%7.2fms] %s | %s',
        $time*1000,
        $self->{Statement},
        join ', ',
          map "$_:".DBI::neat($params{$_}),
          sort { $a =~ /^[0-9]+$/ && $b =~ /^[0-9]+$/ ? $a <=> $b : $a cmp $b }
          keys %params
      ) if $TUWF::OBJ->{_TUWF}{log_queries};

      push @{$TUWF::OBJ->{_TUWF}{DB}{queries}}, [ $self->{Statement}, \%params , $time ];
    }

    return $ret;
  };
}


1;
