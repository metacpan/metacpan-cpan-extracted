#!perl

use Modern::Perl;
use String::Util ':all';
use Test::More;
use Data::Printer alias => 'pdump';
use MySQL::ORM::Generate;
use File::stat;
use Module::Refresh;

use lib '.', './t';
require 'testlib.pl';

use vars qw($Orm);

my @CheckFiles = (
	'tmp/Foo/Testmysqlorm/Sport.pm',
	'tmp/Foo/Testmysqlorm/Sport/CustomRole.pm',
	'tmp/Foo/Testmysqlorm/Sport/ResultClass.pm',
	'tmp/Foo/Testmysqlorm/Sport/ResultClassX.pm',
	'tmp/Foo/Testmysqlorm/League.pm',
	'tmp/Foo/Testmysqlorm/League/CustomRole.pm',
	'tmp/Foo/Testmysqlorm/League/ResultClass.pm',
	'tmp/Foo/Testmysqlorm/League/ResultClassX.pm',
	'tmp/Foo/Testmysqlorm/Team.pm',
	'tmp/Foo/Testmysqlorm/Team/CustomRole.pm',
	'tmp/Foo/Testmysqlorm/Team/ResultClass.pm',
	'tmp/Foo/Testmysqlorm/Team/ResultClassX.pm',
);

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
	constructor();
	generate();
	mod_refresh();
	generate2();
	done_testing();
}

##################################

END {
	drop_db();
}

sub mod_refresh {

	# for some reason Perl::Tidy hangs on the second run
	my $r = Module::Refresh->new;
	$r->refresh_module('Perl/Tidy.pm');
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

	my %new;
	$new{dbh}       = get_dbh();
	$new{dir}       = 'tmp';
	$new{namespace} = 'Foo';

	eval {
		my $orm = MySQL::ORM::Generate->new(%new);
		$orm->generate;
	};
	ok( !$@ ) or print STDERR "$@\n";

	foreach my $f (@CheckFiles) {
		ok( -e $f );
	}
}

sub generate2 {

	my %stat;

	foreach my $f (@CheckFiles) {
		$stat{$f} = stat($f);
	}

	my %new;
	$new{dbh}       = get_dbh();
	$new{dir}       = 'tmp';
	$new{namespace} = 'Foo';

	eval {
		my $orm = MySQL::ORM::Generate->new(%new);
		$orm->generate;
	};
	ok( !$@ );

	foreach my $f (@CheckFiles) {
		my $stat = stat($f);
		if ( $f =~ /CustomRole.pm$/ ) {
			ok( $stat->mtime eq $stat{$f}->mtime );
		}
		else {
			ok( $stat->mtime ne $stat{$f}->mtime );
		}
	}
}

