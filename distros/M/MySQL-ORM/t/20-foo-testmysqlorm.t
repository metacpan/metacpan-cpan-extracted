#!perl

BEGIN {

#	$ENV{PERL5LIB} = "tmp:" . $ENV{PERL5LIB};	
};

use Modern::Perl;
use String::Util ':all';
use Test::More;
use Data::Printer alias => 'pdump';
use MySQL::ORM::Generate;
use Module::Load;

use lib '.', './t', 'tmp';
require 'testlib.pl';

use vars qw($Orm);

########################

if ( !mysql_binary_exists() ) {
	plan skip_all => 'mysql not found';
}
elsif ( !check_connection() ) {
	plan skip_all => 'unable to connect to mysql';
}
else {
	drop_db();
	remove_tmp();
	load_db();
	generate();
	check();
	done_testing();
	drop_db();
	remove_tmp();
}

##################################

sub check {

	use_ok("Foo::Testmysqlorm") || BAIL_OUT("failed to use module");
	
	my $dbh = get_dbh();
	my $orm;
	eval {
		$orm = Foo::Testmysqlorm->new(dbh => $dbh);
	};
	ok(!$@) or BAIL_OUT($@);
	ok($orm);	
	
	my $sport = $orm->Sport;
	ok($sport);

	my $sport_id = $sport->insert(sport_name => 'football');
	ok($sport_id);	

	my $league = $orm->League;	
	my $league_id = $league->insert(league_name => 'nfl', sport_id => $sport_id);
	ok($league_id); 
	
	my $league_id2 = $league->insert(league_name => 'c f l', sport_id => $sport_id);
	ok($league_id2);

	my $rows_affected = $league->update(league_id => $league_id2, set => Foo::Testmysqlorm::League::ResultClass->new(league_name => 'cfl'));
	ok($rows_affected == 1);

	my $one = $league->select_one(league_id => $league_id2);
	ok($one->league_name eq 'cfl');
		
	my $team = $orm->Team;
	ok($team);

	my $vikings_id = $team->insert(team_name => 'vikings', league_id => $league_id, city => 'minneapolis');	
	ok($vikings_id);
		
	my $steelers_id = $team->insert(team_name => 'steelers', league_id => $league_id, city => 'pittsburg');
	ok($steelers_id);
	
	my $steelers_id2 = $team->upsert(	team_name => 'steelers', league_id => $league_id, city => 'pittsburgh');
	ok($steelers_id2 == $steelers_id);
	
	my $bears_id = $team->upsert(team_name => 'bears', league_id => $league_id, city => 'chicago', owner_id => get_random_owner_id($orm));
	ok($bears_id > $steelers_id);
	
	my @rows = $team->select;
	ok(@rows == 3);	
	ok(ref($rows[0]) eq 'Foo::Testmysqlorm::Team::ResultClass');
		
	@rows = $team->selectx(order_by => ['team_id']);
	ok(@rows == 3);
	my $row = $rows[0];
	ok(ref($row) eq 'Foo::Testmysqlorm::Team::ResultClassX');
	ok($row->team_name eq 'vikings');
	ok($row->league_name eq 'nfl');
	ok($row->sport_id == $sport_id);
	
	my $cnt = $team->delete(team_id => $steelers_id);
	ok($cnt == 1);
	
	$cnt = $team->delete;
	ok($cnt == 2);
	
	@rows = $team->select;
	ok(!@rows);
}

sub get_random_owner_id {

	my $orm = shift;
		
	my $owner = $orm->Owner;
	my $row = $owner->select_one;
	
	return $row->owner_id;
}

sub constructor {

	my %new;
	$new{dbh}       = get_dbh();
	$new{dir}       = 'tmp';
	$new{namespace} = 'Foo';

	my $orm = MySQL::ORM::Generate->new(%new);
	ok($orm);
}

sub generate {

	return if $ENV{SKIP_GENERATE};
	
	my %new;
	$new{dbh}       = get_dbh();
	$new{dir}       = 'tmp';
	$new{namespace} = 'Foo';

	my $orm = MySQL::ORM::Generate->new(%new);
	$orm->generate;
}
