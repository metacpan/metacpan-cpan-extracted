use strict;
use warnings;

use Module::Load;
use Test::BDD::Cucumber::StepFile;
use Test::More;

my $statement_re = qr/[\w\d_]+/;

Given qr/a valid database connection/, sub {
	my $c = shift;
	require DBI;
	my $dbh = DBI->connect("dbi:Mock:", "", "");
	isa_ok($dbh, 'DBI::db');
	$c->stash->{'scenario'}->{'dbh'} = $dbh;
};

Given qr/a new (SQL::Stash) instance using the database connection/, sub {
	my $c = shift;
	require_ok("SQL::Stash");
	my $stash = SQL::Stash->new('dbh' => $c->stash->{'scenario'}->{'dbh'});
	isa_ok($stash, 'SQL::Stash');
	$c->stash->{'scenario'}->{'stash'} = $stash;
	diag(explain($c->stash));
};

Given qr/stash the statement "([^"]+)" named ($statement_re)(?:in the (class|instance))?/, sub {
	my $c = shift;
	if(defined($3) && $3 eq 'class') {
		# TODO: Make this local to a scenario.
		SQL::Stash->stash($2, $1);
	} else {
		$c->stash->{'scenario'}->{'stash'}->stash($2, $1);
	}
};

When qr/retrieve the statement ($statement_re)(?: with "([^"]+)" as an argument)?/, sub {
	my $c = shift;
	my $sth = $c->stash->{'scenario'}->{'stash'}->retrieve($1, $2);
	$c->stash->{'scenario'}->{'sth'} = $sth;
};

Then qr/I should have a statement handle/, sub {
	my $c = shift;
	isa_ok($c->stash->{'scenario'}->{'sth'}, 'DBI::st');
};

Then qr/the statement should be "([^"]+)"/, sub {
	my $sth = shift->stash->{'scenario'}->{'sth'};
	is($sth->FETCH('mock_my_history')->statement, $1);
};

Then qr/the statement handle should be undefined/, sub {
	my $c = shift;
	is($c->stash->{'scenario'}->{'sth'}, undef);
};

