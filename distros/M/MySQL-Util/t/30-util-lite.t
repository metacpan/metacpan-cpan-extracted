#!perl

use Modern::Perl;
use String::Util ':all';
use Data::Dumper;
use Test::More;
use feature 'state';
use File::Which;
use MySQL::Util::Lite;
use Data::Printer alias => 'pdump';

use lib '.', './t';
require 'testlib.pl';

use vars qw($Lite);

########################

if ( !which('mysql') ) {
	plan skip_all => 'mysql not found';
}
elsif ( !check_connection() ) {
	plan skip_all => 'unable to connect to mysql';
}
else {
	drop_db();
	load_db();
	constructor();
	get_schema();
	drop_db();
	done_testing();
}

##################################

sub get_schema {

	my $schema = $Lite->get_schema;
	ok($schema);
	ok( ref($schema) eq 'MySQL::Util::Lite::Schema' );

	get_tables($schema);
}

sub get_tables {
	my $schema = shift;

	my $tables = $schema->tables;
	ok(@$tables);
	foreach my $t (@$tables) {
		ok( ref($t) eq 'MySQL::Util::Lite::Table' );
		get_foreign_keys($t);
		get_parent_tables($t);
		get_columns($t);
	}
}

sub get_columns {
	my $t = shift;

	my $cols;
	eval {	$cols = $t->columns; };
	ok(!$@);
	
	foreach my $c (@$cols) {
		ok(ref($c) eq 'MySQL::Util::Lite::Column');	
	}
}

sub get_parent_tables {
	my $t = shift;

	my @tables;
	eval {	@tables = $t->get_parent_tables;};
	ok(!$@) or pdump $@;
	
	foreach my $table (@tables) {
		ok(ref($table) eq 'MySQL::Util::Lite::Table');		
	}
}

sub get_foreign_keys {
	my $t = shift;

	my @fks = $t->get_foreign_keys;
	foreach my $fk (@fks) {
		eval { my @cols = $fk->column_constraints; };
		ok(!$@) or pdump $@;;
	}
}

sub check_connection {

	my $mysql_cmd = get_mysql_cmdline();
	$mysql_cmd .= " -e 'show databases'";
	$mysql_cmd .= " 1>/dev/null 2>/dev/null";

	eval { system($mysql_cmd); };
	if ( $@ or $? ) {
		return 0;
	}

	return 1;
}

sub constructor {
	my $func = ( caller(0) )[3];
	my %conf = parse_conf();

	eval { MySQL::Util->new };
	ok( $@, "$func - no args " );

	$Lite = MySQL::Util->new(
		dsn  => $conf{DBI_DSN},
		user => $conf{DBI_USER},
		pass => $conf{DBI_PASS},
		span => 0
	);
	ok( $Lite, "$func - with valid args " );

	my $dbh = $Lite->clone_dbh;
	$Lite = MySQL::Util::Lite->new( dbh => $dbh, );
	ok( $Lite, "$func - with dbh" );
}
