#!/usr/bin/perl -w

use strict;

use Test::More tests => 2 + 6;

BEGIN 
{
  require 't/test-lib.pl';
  use_ok('Rose::DB::Object');
  use_ok('Rose::DB::Object::Loader');
}

our %Have;

foreach my $db_type (qw(pg))
{
  SKIP:
  {
    skip("$db_type tests", 6)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB::Object::Metadata->unregister_all_classes;
  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => [ qw(rdbo_users rdbo_comments) ]);

  #foreach my $class (@classes)
  #{
  #  print $class->meta->perl_class_definition if($class->can('meta'));
  #}

  my $user_class    = $class_prefix . '::RdboUser';
  my $comment_class = $class_prefix . '::RdboComment';

  ok($user_class->meta->relationship('user1s'), "user1s rel - $db_type");
  ok($user_class->meta->relationship('user2s'), "user2s rel - $db_type");

  ok($comment_class->meta->foreign_key('user1'), "user1 fk - $db_type");
  ok($comment_class->meta->foreign_key('user2'), "user2 fk - $db_type");

  is($comment_class->meta->column('type')->type, 'enum', "enum - $db_type");
  is($comment_class->meta->column('type')->db_type, 'my_type', "custom type - $db_type");
}

BEGIN
{
  our %Have;

  #
  # Pg
  #

  my $dbh;

  eval
  {
    my $db = Rose::DB->new('pg_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rdbo_comments');
      $dbh->do('DROP TABLE rdbo_users');
      $dbh->do('DROP TYPE my_type');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'pg'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_users
(
  id INT NOT NULL PRIMARY KEY
)
EOF

    $dbh->do(<<"EOF");
CREATE TYPE my_type AS ENUM ('foo', 'bar')
EOF

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_comments
(
  id        SERIAL NOT NULL PRIMARY KEY,
  user1_id  INTEGER NOT NULL REFERENCES rdbo_users (id),
  user2_id  INTEGER NOT NULL REFERENCES rdbo_users (id),
  type      MY_TYPE
)
EOF

    $dbh->disconnect;
  }
}

END
{
  # Delete test tables

  if($Have{'pg'})
  {
    my $dbh = Rose::DB->new('pg_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rdbo_comments');
    $dbh->do('DROP TABLE rdbo_users');
    $dbh->do('DROP TYPE my_type');

    $dbh->disconnect;
  }
}
