#!/usr/bin/perl -w

use strict;

use Test::More tests => 1 + (5 * 1);

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

#
# Tests
#

#$Rose::DB::Object::Manager::Debug = 1;

foreach my $db_type (qw(sqlite))
{
  SKIP:
  {
    skip("$db_type tests", 5)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB::Object::Metadata->unregister_all_classes;
  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => '^(foos|bars)$');

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition if($class->can('meta'));
  #}

  my $foo_class = $class_prefix . '::Foo';
  my $bar_class = $class_prefix . '::Bar';

  is($foo_class->meta->relationship('bar')->type, 'one to one', "check rel type - $db_type");

  my $bar = $bar_class->new;
  my $foo = $foo_class->new(foo => 'xyz');

  #$Rose::DB::Object::Debug = 1;

  $foo->bar($bar);
  $foo->bar->bar('some text');
  $foo->save;

  my $check_foo = $foo_class->new(id => $foo->id)->load;
  my $check_bar = $bar_class->new(foo_id => $bar->foo_id)->load;

  is($check_foo->foo, 'xyz', "check foo - $db_type");
  is($check_bar->bar, 'some text', "check bar - $db_type");

  is($bar_class->meta->relationship('foo')->type, 'one to one', "check foo one to one - $db_type");
  is($bar_class->meta->relationship('foo')->foreign_key, 
     $bar_class->meta->foreign_key('foo'), "check foo fk rel - $db_type");

  #foreach my $rel ($bar_class->meta->relationships)
  #{
  #  print $rel->name, ' ', $rel->type, "\n";
  #}
}

BEGIN
{
  our %Have;

  my $dbh;

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
    $Have{'sqlite'} = 1;

    # Drop existing tables and create schema, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;

      $dbh->do('DROP TABLE bars');
      $dbh->do('DROP TABLE foos');
    }

    $dbh->do(<<"EOF");
CREATE TABLE foos
(
  id   INTEGER PRIMARY KEY AUTOINCREMENT, 
  foo  VARCHAR(255)
)
EOF

    $dbh->do(<<"EOF");
CREATE TABLE "bars"
(
  "foo_id"  INTEGER PRIMARY KEY AUTOINCREMENT REFERENCES foos (id),
  bar     VARCHAR(255)
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables

  if($Have{'sqlite'})
  {
    my $dbh = Rose::DB->new('sqlite_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE bars');
    $dbh->do('DROP TABLE foos');

    $dbh->disconnect;
  }
}
