#!/usr/bin/perl -w

use strict;

use Test::More tests => 55;

use Scalar::Util qw(isweak refaddr);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
}

eval { require Test::Memory::Cycle };

our $HAVE_TMC = $@ ? 0 : 1;

our %HAVE;

my $db_type = $HAVE{'sqlite'} ? 'sqlite' : (sort keys %HAVE)[0];

SKIP:
{
  skip("No db available", 54)  unless($db_type);

  package MyObject;
  use base 'Rose::DB::Object';
  __PACKAGE__->meta->table('objects');
  __PACKAGE__->meta->columns
  (
    id    => { type => 'int', primary_key => 1 },
    start => { type => 'scalar' },
  );
  __PACKAGE__->meta->initialize;
  sub init_db { Rose::DB->new($db_type) }

  package MySubObject;
  use base 'MyObject';
  __PACKAGE__->meta->column('id')->default(123);
  __PACKAGE__->meta->delete_column('start');
  __PACKAGE__->meta->add_column(start => { type => 'datetime' });
  __PACKAGE__->meta->initialize(replace_existing => 1);

  package MySubObject2;
  use base 'MyObject';
  __PACKAGE__->meta->table('s2objs');
  __PACKAGE__->meta->initialize(preserve_existing => 1);
  sub id 
  {
    my($self) = shift;
    return $self->{'id'} = shift  if(@_);
    return defined $self->{'id'} ? $self->{'id'} : 456;
  }

  package MySubObject3;
  use base 'MySubObject';
  __PACKAGE__->meta->initialize(preserve_existing => 1);

  package main;

  if($HAVE_TMC)
  {
    Test::Memory::Cycle::memory_cycle_ok(MyObject->meta, "meta memory cycle ok MyObject - $db_type");
    Test::Memory::Cycle::memory_cycle_ok(MySubObject->meta, "meta memory cycle ok MySubObject - $db_type");
    Test::Memory::Cycle::memory_cycle_ok(MySubObject2->meta, "meta memory cycle ok MySubObject2 - $db_type");
  }
  else
  {
    ok(1, 'Test::Memory::Cycle not installed');
    ok(1, 'Test::Memory::Cycle not installed');
    ok(1, 'Test::Memory::Cycle not installed');
  }

  ok(MyObject->meta ne MySubObject->meta, "meta 1 - $db_type");
  ok(MyObject->meta ne MySubObject2->meta, "meta 2 - $db_type");
  ok(MySubObject->meta ne MySubObject2->meta, "meta 3 - $db_type");

  ok(refaddr(MyObject->meta->column('id')) ne refaddr(MySubObject->meta->column('id')), "meta column 1 - $db_type");
  ok(refaddr(MyObject->meta->column('id')) ne refaddr(MySubObject2->meta->column('id')), "meta column 2 - $db_type");
  ok(refaddr(MySubObject->meta->column('id')) ne refaddr(MySubObject2->meta->column('id')), "meta column 3 - $db_type");

  ok(isweak(MyObject->meta->column('id')->{'parent'}), "meta weakened 1 - $db_type");
  ok(isweak(MySubObject->meta->column('id')->{'parent'}), "meta weakened 2 - $db_type");
  ok(isweak(MySubObject2->meta->column('id')->{'parent'}), "meta weakened 3 - $db_type");

  is(refaddr(MyObject->meta->column('id')->parent), refaddr(MyObject->meta), "meta parent 1 - $db_type");
  is(refaddr(MySubObject->meta->column('id')->parent), refaddr(MySubObject->meta), "meta parent 2 - $db_type");
  is(refaddr(MySubObject2->meta->column('id')->parent), refaddr(MySubObject2->meta), "meta parent 3 - $db_type");

  my $o = MyObject->new;
  is(MyObject->meta->table, 'objects', "base class 1 - $db_type");
  ok(!defined $o->id, "base class 2 - $db_type");
  $o->start('1/2/2003');
  is($o->start, '1/2/2003', "base class 3 - $db_type");

  my $s = MySubObject->new;
  is(MyObject->meta->table, 'objects', "subclass 1.1 - $db_type");
  is($s->id, 123, "subclass 1.2 - $db_type");
  $s->start('1/2/2003');
  is($s->start->strftime('%B'), 'January', "subclass 1.3 - $db_type");

  my $t = MySubObject2->new;
  is(MySubObject2->meta->table, 's2objs', "subclass 2.1 - $db_type");
  is($t->id, 456, "subclass 2.2 - $db_type");
  $t->start('1/2/2003');
  is($t->start, '1/2/2003', "subclass 2.3 - $db_type");

  my $f = MySubObject3->new;
  is(MySubObject3->meta->table, 'objects', "subclass 3.1 - $db_type");
  is($f->id, 123, "subclass 3.2 - $db_type");
  $f->start('1/2/2003');
  is($f->start->strftime('%B'), 'January', "subclass 3.3 - $db_type");

  # Test again, but without this module
  $Scalar::Util::Clone::VERSION = undef;

  package My2Object;
  use base 'Rose::DB::Object';
  __PACKAGE__->meta->table('objects');
  __PACKAGE__->meta->columns
  (
    id    => { type => 'int', primary_key => 1 },
    start => { type => 'scalar' },
  );
  __PACKAGE__->meta->initialize;
  sub init_db { Rose::DB->new($db_type) }

  package My2SubObject;
  use base 'My2Object';
  __PACKAGE__->meta->column('id')->default(123);
  __PACKAGE__->meta->delete_column('start');
  __PACKAGE__->meta->add_column(start => { type => 'datetime' });
  __PACKAGE__->meta->initialize(replace_existing => 1);

  package My2SubObject2;
  use base 'My2Object';
  __PACKAGE__->meta->table('s2objs');
  __PACKAGE__->meta->initialize(preserve_existing => 1);
  sub id 
  {
    my($self) = shift;
    return $self->{'id'} = shift  if(@_);
    return defined $self->{'id'} ? $self->{'id'} : 456;
  }

  package My2SubObject3;
  use base 'My2SubObject';
  __PACKAGE__->meta->initialize(preserve_existing => 1);

  package main;

  if($HAVE_TMC)
  {
    Test::Memory::Cycle::memory_cycle_ok(My2Object->meta, "meta memory cycle ok My2Object - $db_type");
    Test::Memory::Cycle::memory_cycle_ok(My2SubObject->meta, "meta memory cycle ok My2SubObject - $db_type");
    Test::Memory::Cycle::memory_cycle_ok(My2SubObject2->meta, "meta memory cycle ok My2SubObject2 - $db_type");
  }
  else
  {
    ok(1, 'Test::Memory::Cycle not installed');
    ok(1, 'Test::Memory::Cycle not installed');
    ok(1, 'Test::Memory::Cycle not installed');
  }

  ok(My2Object->meta ne My2SubObject->meta, "meta 1 - $db_type");
  ok(My2Object->meta ne My2SubObject2->meta, "meta 2 - $db_type");
  ok(My2SubObject->meta ne My2SubObject2->meta, "meta 3 - $db_type");

  ok(refaddr(My2Object->meta->column('id')) ne refaddr(My2SubObject->meta->column('id')), "meta column 1 - $db_type");
  ok(refaddr(My2Object->meta->column('id')) ne refaddr(My2SubObject2->meta->column('id')), "meta column 2 - $db_type");
  ok(refaddr(My2SubObject->meta->column('id')) ne refaddr(My2SubObject2->meta->column('id')), "meta column 3 - $db_type");

  ok(isweak(My2Object->meta->column('id')->{'parent'}), "meta weakened 1 - $db_type");
  ok(isweak(My2SubObject->meta->column('id')->{'parent'}), "meta weakened 2 - $db_type");
  ok(isweak(My2SubObject2->meta->column('id')->{'parent'}), "meta weakened 3 - $db_type");

  is(refaddr(My2Object->meta->column('id')->parent), refaddr(My2Object->meta), "meta parent 1 - $db_type");
  is(refaddr(My2SubObject->meta->column('id')->parent), refaddr(My2SubObject->meta), "meta parent 2 - $db_type");
  is(refaddr(My2SubObject2->meta->column('id')->parent), refaddr(My2SubObject2->meta), "meta parent 3 - $db_type");

  $o = My2Object->new;
  is(My2Object->meta->table, 'objects', "base class 1 - $db_type");
  ok(!defined $o->id, "base class 2 - $db_type");
  $o->start('1/2/2003');
  is($o->start, '1/2/2003', "base class 3 - $db_type");

  $s = My2SubObject->new;
  is(My2Object->meta->table, 'objects', "subclass 1.1 - $db_type");
  is($s->id, 123, "subclass 1.2 - $db_type");
  $s->start('1/2/2003');
  is($s->start->strftime('%B'), 'January', "subclass 1.3 - $db_type");

  $t = My2SubObject2->new;
  is(My2SubObject2->meta->table, 's2objs', "subclass 2.1 - $db_type");
  is($t->id, 456, "subclass 2.2 - $db_type");
  $t->start('1/2/2003');
  is($t->start, '1/2/2003', "subclass 2.3 - $db_type");

  $f = My2SubObject3->new;
  is(My2SubObject3->meta->table, 'objects', "subclass 3.1 - $db_type");
  is($f->id, 123, "subclass 3.2 - $db_type");
  $f->start('1/2/2003');
  is($f->start->strftime('%B'), 'January', "subclass 3.3 - $db_type");
}

BEGIN
{
  our %HAVE;

  #
  # PostgreSQL
  #

  my $dbh;

  eval 
  {
    $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $HAVE{'pg'} = 1;
  }

  #
  # MySQL
  #

  eval 
  {
    $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $HAVE{'mysql'} = 1;
  }

  #
  # SQLite
  #

  eval 
  {
    $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;
  };

  if(!$@ && $dbh)
  {
    $HAVE{'sqlite'} = 1;
  }
}
