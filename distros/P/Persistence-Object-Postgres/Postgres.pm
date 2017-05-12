# -*-cperl-*-
#
# Persistence::Object::Postgres - Object Persistence with PostgreSQL.
# Copyright (C) 2000-2001, Ashish Gulhati <hash@netropolis.org>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: Postgres.pm,v 1.24 2001/07/07 00:37:13 cvs Exp $

package Persistence::Object::Postgres;

use DBI;
use Carp;
use IO::Wrap;
use IO::Handle;
use Data::Dumper;
use vars qw( $VERSION );

( $VERSION ) = '$Revision: 1.24 $' =~ /\s+([\d\.]+)/;

sub dbconnect {
  my ($class, $dbobj) = @_;
  my %options = (host     => $dbobj->{Host} || '',
		 port     => $dbobj->{Port} || '5432',
		);
  my $username = $dbobj->{Host} || (''.getpwuid $<);
  my $password = $dbobj->{Host} || '';
  my $options = join (';',"dbname=$dbobj->{Database}",
		      grep { /=.+$/ } map { "$_=$options{$_}" } keys %options);
  return undef unless $dbh = DBI->connect("dbi:Pg:$options", $username, $password);
} 

sub new {
  my ($class, %args) = @_; my $self=undef;
  return undef unless my $dope = $args{__Dope};
  $self = $class->load (__Dope => $dope, __Oid => $args{__Oid} )
    if my $oid = $args{__Oid};
  $self->{__Oid} = $oid if $self; $self = {} unless $self; 
  $self->{__Dope} = $dope; 
  delete $args{__Dope}; delete $args{__Oid};
  foreach (keys %args) { $self->{$_} = $args{$_} }
  bless $self, $class;
}

package Tie::PgBLOB;

sub IO::Handle::open {
  shift;
}

sub TIEHANDLE { 
  bless {
	 dbh   => $_[1], 
	 blob  => $_[2] 
	}, shift;
}

sub WRITE {
  my $r = shift;
  my ($buf, $len, $offset) = @_;
  $buf = substr ($buf, $offset, $len);
  my $nbytes = $r->{dbh}->func($r->{blob}, $buf, length ($buf), 'lo_write');    
}

sub PRINT { 
  my $r = shift; 
  my $buf = join($,,@_,$\); my $nbytes;
  $r->{dbh}->{AutoCommit} = 0;
  $r->{dbh}->{RaiseError} = 1;
  eval {
    my $blob = $r->{dbh}->func($r->{blob}, $r->{dbh}->{pg_INV_WRITE}, 'lo_open');
    $r->{dbh}->func($blob, $r->{loc}, 0, 'lo_lseek');
    $nbytes = $r->{dbh}->func($blob, $buf, length ($buf), 'lo_write');
    $r->{loc} = $r->{dbh}->func($blob, 'lo_tell');
    $r->{dbh}->func($blob, 'lo_close');
    $r->{dbh}->commit();
  };
  if ($@) {
    warn "Transaction aborted because $@";
    $r->{dbh}->rollback();
  }
  $r->{dbh}->{AutoCommit} = 1;
  return $nbytes;
}

sub PRINTF {
  my $r = shift; 
  my $buf = sprintf(@_);
  my $nbytes = $r->{dbh}->func($r->{blob}, $buf, length ($buf), 'lo_write');
}

sub READ {
  my $r = shift; my $nbytes;
  my(undef,$len,$offset) = @_;
  $r->{dbh}->{AutoCommit} = 0;
  $r->{dbh}->{RaiseError} = 1;
  eval {
    my $blob = $r->{dbh}->func($r->{blob}, $r->{dbh}->{pg_INV_READ}, 'lo_open');
    $r->{dbh}->func($blob, $r->{loc}, 0, 'lo_lseek');
    $nbytes = $r->{dbh}->func($blob, $_[0], $len, 'lo_read');
    $r->{loc} = $r->{dbh}->func($blob, 'lo_tell');
    $r->{dbh}->func($blob, 'lo_close');
    $r->{dbh}->commit();
  };
  if ($@) {
    warn "Transaction aborted because $@";
    $r->{dbh}->rollback();
    $r->{dbh}->{AutoCommit} = 1;
    return;
  }
  $r->{dbh}->{AutoCommit} = 1;
  return $nbytes;
}

sub READLINE { 
  my $r = shift; my $buf; my $l; my $fix; my $nbytes;
  while ($nbytes = $r->{dbh}->func($r->{blob}, $buf, 1024, 'lo_read')) {
    $buf = $fix . $buf;
    if (my $x = index($buf,$\)) { # bug: need to handle $\ = '' case.
      $l .= substr($buf, 0, $x+length($\));
      # rewind stream
      last;
    }
    $l .= substr($buf,0,-(length($\))); 
    $fix = substr($buf,-(length($\)));
  }
  return $l;
}
    
sub GETC { 
  print "Don't GETC, Get Perl"; return "a"; 
}
      
sub CLOSE { 
  my $r = shift;
  $r->{dbh}->func($r->{blob}, 'lo_close');
}
	
sub DESTROY { 
  my $r = shift;
  $r->{dbh}->func($r->{blob}, 'lo_close');
}

package Persistence::Object::Postgres;

sub load { 
  my ( $class, %args ) = @_; 
  return undef unless my $oid = $args{__Oid} and my $dope = $args{__Dope}; 
  return undef unless my $table = $dope->{Table}; 
  my @keys = keys %{$dope->{Template}};
  my $selfields = join ',', '"__dump"', map { "\"$_\"" } @keys; 
  my $s = $dope->{__DBHandle}->prepare("select $selfields from $table where oid=$oid");
  $s->execute(); return undef unless $s->rows(); my @row = $s->fetchrow_array();
  $object = eval $row[0]; $object->{__Dope} = $dope; $object->{__Oid} = $oid;
  my $i = 0; 
  foreach (@keys) { 
    if ($object->{$_} eq 'ref') {
      $object->{$_} = eval $row[++$i];
    }
    elsif ($object->{$_} eq 'blob') {
      my $x = IO::Handle->new();
      tie($$x, 'Tie::PgBLOB', $dope->{__DBHandle}, $row[++$i]);
      $object->{$_} = $x;
    }
    else {
      $object->{$_} = $row[++$i];
    }
  }
  return $object; 
}

sub commit {
  my ($self, %args) = @_; return undef unless ref $self;
  return undef unless my $dope = $self->{__Dope}; 
  return undef unless my $table = $dope->{Table};
  my $r; my %tablecols; my @tablecols = (); my $query; my $oid = $self->{__Oid} || 0; 
  for ( keys %$self ) { delete $self->{ $_ } if /^__(?:Dope|Oid)/ }; 

  $s = $dope->{__DBHandle}->prepare("select * from $table where oid=$oid");
  $s->execute(); my @fields = @{$s->{NAME}};
  unless (grep { $_ eq '__dump' } @fields) {
    my $s = $dope->{__DBHandle}->prepare
      ("alter table $table add column \"__dump\" text");
    $s->execute(); return undef unless $s->rows();
  }
  
  my %dd = %$self; $Data::Dumper::Indent = 0; 
  foreach $key (keys %{$dope->{Template}}) {
    unless (grep { $_ eq $key } @fields) {
      if ($dope->{Createfields}) {
	my $s = $dope->{__DBHandle}->prepare
	  ("alter table $table add column \"$key\" \"$dope->{Template}->{$key}\"");
	$s->execute(); return undef unless $s->rows();
      }
      else {
	next;
      }
    }
    my $stringified = '';
    if (defined $self->{$key}) {
      $stringified = defined &Data::Dumper::Dumpxs?
	Data::Dumper::DumperX($self->{$key}):
	  Data::Dumper::Dumper($self->{$key});
      $stringified =~ s/^\$VAR1 = (.*);$/$1/s;
      $stringified =~ s/(?<=[^\\])\'/\\\'/sg; $stringified =~ s/^'/\\'/s;
      $stringified =~ s/^(\\\')?/\'/s; $stringified =~ s/(\\\')?$/\'/s; 
    }
    if (my $t = ref $dd{$key}) { 
      if ($t =~ /^(GLOB|IO::(Handle|File|Wrap)|FileHandle)/) {
	if (ref (my $b = tied $$dd{$key}) eq 'Tie::PgBLOB') {
	  $tablecols{$key} = $b->{blob};
	}
	else {
	  my $x = wraphandle(IO::Handle->new());
	  my $y = wraphandle($dd{$key});
	  my $newblob = $dope->dbhandle->func($dope->dbhandle->{pg_INV_WRITE}, 
					      'lo_creat');
	  tie($$x, 'Tie::PgBLOB', $dope->dbhandle, $newblob); 
	  my $buffer; print $x $buffer while $y->read($buffer, 128);
	  $x->close();
	  $tablecols{$key} = $newblob;
	}
	$dd{$key} = 'blob';
      }
      else {
	$dd{$key} = 'ref';
	$tablecols{$key} = $stringified;
      }
    } 
    else { 
      delete $dd{$key};
      $tablecols{$key} = $stringified;
    }
  }

  $Data::Dumper::Indent = 1;
  my $dd = bless \%dd, ref $self; $d = new Data::Dumper ([$dd]); 
  $dumper = defined &Data::Dumper::Dumpxs?$d->Dumpxs():$d->Dump(); 
  $dumper =~ s/\'/\\\'/sg; $dumper = "'$dumper'"; 

  $s = $dope->{__DBHandle}->prepare("select * from $table where oid=$oid");
  my $n = $s->execute(); @fields = @{$s->{NAME}};
  
  if ($n and $oid!=0) {
    $query = "update $table set " . 
             join (',', (map { "\"$_\"=$tablecols{$_}" } keys %tablecols),
		   "__dump=$dumper" ) . " where oid=$oid";
  }
  else {
    my @insert = ();
    for (@fields) {
      push (@insert, $dumper), next if $_ eq '__dump';
      push @insert, $tablecols{$_};
    }
    $query = "insert into $table values (" . join (',',@insert) . ')';
  }
  
  $query =~ s/(?<=[=,(]),/'',/sg; $query =~ s/,(?=\))/,''/sg;
  $query =~ s/''/NULL/sg;
  $s = $dope->{__DBHandle}->prepare($query);
  $s->execute(); return undef unless $s->rows();
  $self->{__Dope} = $dope; 
  $self->{__Oid} = $oid || $s->{pg_oid_status};
}

sub expire { 
  my ($self, %args) = @_; return undef unless ref $self;
  return undef unless my $oid = $self->{__Oid} and my $dope = $self->{__Dope};
  return undef unless my $table = $dope->{Table};
  my $s = $dope->{__DBHandle}->prepare("select oid from $table where oid=$oid");
  $s->execute(); return undef unless $s->rows();
  $s = $dope->{__DBHandle}->prepare("delete from $table where oid=$oid");
  $s->execute();
} 

sub select {
  my ($class, $dope, $where) = @_;
  return undef unless $dope;
  return undef unless my $table = $dope->{Table};
  my $s = $dope->{__DBHandle}->prepare("select oid from $table $where"); $s->execute(); 
  return undef unless my $n = $s->rows(); 
  map { $s->fetchrow_array() } (1..$n);
}

sub lock {
  1;
}

sub unlock {
  1;
}

sub AUTOLOAD {
  my ($self, $val) = @_; (my $auto = $AUTOLOAD) =~ s/.*:://;
  if ($auto =~ /^(dope|oid)$/) {
    $self->{"__\u$auto"} = $val if defined $val;
    return $self->{"__\u$auto"};
  }
  else {
    croak "Could not AUTOLOAD method $auto.";
  }
}


'True Value';

__END__

=head1 NAME

Persistence::Object::Postgres - Object Persistence with PostgreSQL. 

=head1 SYNOPSIS

  use Persistence::Database::SQL;

  my $db = new Persistence::Database::SQL
    ( Engine => 'Postgres',
      Database => $database_name, 
      Table => $table_name,
      Template => $template_hashref );

  my $object1 = new Persistence::Object::Postgres
    ( __Dope => $db,
      $key => $value );

  my $object2 = new Persistence::Object::Postgres
    ( __Dope => $db, 
      __Oid => $object_id );

  $object1->{$key} = $object2->{$key};

  $object_id = $object1->commit();
  $object2->expire();

=head1 DESCRIPTION

This module provides persistence (and optionally, replication)
facilities to its objects. Object definitions are stored in a
PostgreSQL database as stringified perl data structures, generated
with Data::Dumper. Persistence is achieved with a blessed hash
container that holds the object data.

Using a template mapping object data to PostgreSQL fields, it is
possible to automatically generate PostgreSQL fields out of the object
data, which allows you to use poweful PostgreSQL indexing and querying
facilities on your database of persistent objects.

This module is intended for use in conjunction with the object
database class Persistence::Database::SQL, which provides persistent
object database handling functionality for multiple DBMS back-ends.
Persistence::Object::Postgres is the module that implements methods
for the PostgreSQL back-end.

=head1 CONSTRUCTOR 

=over 2

=item B<new()>

Creates a new Persistent Object.

  my $object = new Persistence::Object::Postgres 
    ( __Dope => $database );

Takes a hash argument with following possible keys:

B<__Dope> 

The Database of Persistent Entities. This attribute is required and
should have as its value a Persistence::Database::SQL object
corresponding to the database being used.

B<__Oid> 

An optional Object ID. If this attribute is specified, an attempt is
made to load the corresponding persistent object. If no corresponding
object exists, this attribute is silently ignored.

=back 

=head1 OBJECT METHODS

=over 2

=item B<commit()> 

Commits the object to the database.

  $object->commit(); 

=item B<expire()> 

Irrevocably destroys the object. Removes the persistent entry from the
DOPE.

  $object->expire(); 

If you want to keep a backup of the object before destroying it, use
commit() to store it in a different table or database.

  $db->table('expired');
  $object->commit;
  $db->table('active');
  $object->expire(); 

=head1 Inheriting Persistence::Object::Postgres

In most cases you would want to inherit this module to provide
persistence for your own classes. If you use your objects to store
refs to class data, you'd need to bind and detach these refs at load()
and commit(). Otherwise, you'll end up with a separate copy of class
data for every object which will eventually break your code. See
perlobj(1), perlbot(1), and perltoot(1), on why you should use objects
to access class data.

=head1 BUGS

=over 2

=item * 

Error checking needs work. 

=item * 

__Oid is ignored by new() if an object of this ID doesn't already
exist. That's because Postgres generates an oid for us at commit()
time. This is a potential compatibility issue as many other database
engines don't work like postgres in this regard. 

A more generic solution would be to ignore the Postgres oid field
and create a unique identifier of our own at commit(), or use the
user specified __Oid. This will probably be implemented in a future
version, but code written with the assumption that __Oid is ignored
should still work fine. __Oid just won't be ignored, is all.

=head1 SEE ALSO 

Persistence::Database::SQL(3), 
Data::Dumper(3), 
Persistence::Object::Simple(3), 
DBD::Recall(3),
Replication::Recall::DBServer(3),
perlobj(1), perlbot(1), perltoot(1).

=head1 AUTHOR

Persistence::Object::Postgres is Copyright (c) 2000-2001, Ashish
Gulhati <hash@netropolis.org>. All Rights Reserved.

=head1 ACKNOWLEDGEMENTS

Thanks to Barkha for inspiration, laughs and great times, and to Vipul
for Persistence::Object::Simple, the constant use and abuse of which
resulted in the writing of this module.

=head1 LICENSE

This code is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER

This is free software. If it breaks, you own both parts.

=cut
