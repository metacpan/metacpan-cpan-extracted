package Norma::ORM::Test::DB;

use strict;
use Test::More;
use Data::Dumper;

use DBI;

our $dbh;
my $primary_key_column_def;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	$self->{db_driver} = $ENV{NORMA_UNIT_TEST_DB_DRIVER} || 'sqlite';

	print "DB DRIVER: " . $self->{db_driver} . "\n";

	if ($self->{db_driver} eq 'mysql') {
		$dbh = DBI->connect("dbi:mysql:database=unit_testing", 'tester', 'tester', { RaiseError => 1 });
		$primary_key_column_def = 'int not null primary key auto_increment';
	} else {
		$self->{sqlite_db_filename} = "/tmp/norma-unit_testing";
		$dbh = DBI->connect("dbi:SQLite:dbname=$self->{sqlite_db_filename}", '', '', { RaiseError => 1 });
		$primary_key_column_def = 'integer primary key';
	}

	return $self;
}

sub DESTROY {
	my ($self) = @_;
	if ($self->{db_driver} eq 'sqlite') {
		#unlink $self->{sqlite_db_filename};
	}
}

sub dbh { $dbh };

sub initialize {

	$dbh->do("drop table if exists recipes");
	$dbh->do("drop table if exists recipe_comments");
	$dbh->do("drop table if exists recipe_categories");
	$dbh->do("drop table if exists recipe_tags");
	$dbh->do("drop table if exists entity_likes");
	$dbh->do("drop table if exists recipe_entity_likes_map");

	$dbh->do(<<EOT);
	CREATE TABLE `recipes` (
	  `id` $primary_key_column_def,
	  `contributor_person_id` int(11) default NULL,
	  `added_date` date NOT NULL,
	  `title` varchar(255) NOT NULL,
	  `description` text,
	  `ingredients` text,
	  `instructions` text,
	  `contributor_name` varchar(255) default NULL,
	  `category_id` int(11)
	) 
EOT
	$dbh->do(<<EOT);
	 CREATE TABLE `recipe_comments` (
	  `id` $primary_key_column_def,
	  `recipe_id` int(11) default NULL,
	  `person_id` int(11) default NULL,
	  `date_time` datetime default NULL,
	  `text` text
	) 
EOT
	$dbh->do(<<EOT);
	 CREATE TABLE `recipe_categories` (
	  `id` $primary_key_column_def,
	  `name` varchar(255) NOT NULL
	) 
EOT
	$dbh->do(<<EOT);
	 CREATE TABLE `recipe_tags` (
	  `id` $primary_key_column_def,
	  `recipe_id` int not null,
	  `word` varchar(255) NOT NULL,
          unique(word)
	) 
EOT
	$dbh->do(<<EOT);
	 CREATE TABLE `entity_likes` (
	  `id` $primary_key_column_def,
	  `liked_date_time` timestamp DEFAULT CURRENT_TIMESTAMP
	) 
EOT
	$dbh->do(<<EOT);
	 CREATE TABLE `recipe_entity_likes_map` (
	  `id` $primary_key_column_def,
	  `entity_like_id` int NOT NULL,
	  `recipe_id` int NOT NULL,
	  unique(recipe_id, entity_like_id)
	) 
EOT
}


1;
