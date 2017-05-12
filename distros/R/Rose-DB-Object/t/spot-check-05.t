#!/usr/bin/perl -w

use strict;

use Test::More tests => 3;

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

foreach my $db_type (qw(mysql))
{
  SKIP:
  {
    skip("$db_type tests", 2)  unless($Have{$db_type});
  }

  next  unless($Have{$db_type});

  Rose::DB->default_type($db_type);

  my $class_prefix = ucfirst($db_type);

  my $loader = 
    Rose::DB::Object::Loader->new(
      db           => Rose::DB->new,
      class_prefix => $class_prefix);

  my @classes = $loader->make_classes(include_tables => 'rdbo_company_vote');

  is(scalar @classes, 2, "uppercase keys - $db_type");

  my $o = Mysql::RdboCompanyVote->new;

  if($db_type eq 'mysql')
  {
    is($o->meta->column('canmeet')->perl_hash_definition,
       q(canmeet => { type => 'enum', check_in => [ 'YES', 'NO' ], default => 'YES', not_null => 1 }),
       "enum column defintion - $db_type");
  }
  else { ok(1, "non-mysql - $db_type") }
}

BEGIN
{
  #
  # MySQL
  #

  my $dbh;

  eval 
  {
    my $db = Rose::DB->new('mysql_admin');
    $dbh = $db->retain_dbh or die Rose::DB->error;

    # Drop existing tables, ignoring errors
    {
      local $dbh->{'RaiseError'} = 0;
      local $dbh->{'PrintError'} = 0;
      $dbh->do('DROP TABLE rdbo_company_vote CASCADE');
    }
  };

  if(!$@ && $dbh)
  {
    $Have{'mysql'} = 1;

    $dbh->do(<<"EOF");
CREATE TABLE rdbo_company_vote 
(
  vote_id      INT(10) UNSIGNED NOT NULL AUTO_INCREMENT ,
  company_id   INT(10) UNSIGNED NOT NULL DEFAULT '0',
  question_id  INT(10) UNSIGNED NOT NULL DEFAULT '0',
  rating_num   TINYINT(3) UNSIGNED DEFAULT NULL ,
  comment      VARCHAR(255) DEFAULT NULL,
  canmeet      ENUM('YES','NO') NOT NULL DEFAULT 'YES',
  PRIMARY KEY (vote_id, company_id, question_id),
  UNIQUE KEY IDX_company_rating1 (company_id, question_id),
  KEY IDX_company_vote2 (company_id) ,
  KEY IDX_company_vote3 (question_id) 
)
EOF

    $dbh->disconnect;
  }

}

END
{
  if($Have{'mysql'})
  {
    my $dbh = Rose::DB->new('mysql_admin')->retain_dbh()
      or die Rose::DB->error;

    $dbh->do('DROP TABLE rdbo_company_vote CASCADE');

    $dbh->disconnect;
  }
}
