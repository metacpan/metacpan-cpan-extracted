#!/usr/bin/perl -w

use strict;
use CGI;
use DBI;
use MyConText;

use vars qw! $q $dbh !;

$q = new CGI;

print $q->header('text/html');

print $q->start_html;

print "<H1>MyConText Administration</H1>\n";
print $q->dump;

if (defined $q->param('dsn')) {
	my $dsn = $q->param('dsn');
	my $user = $q->param('user');
	my $password = $q->param('password');

	$dbh = DBI->connect($dsn, $user, $password, {
		'RaiseError' => 0, 'PrintError' => 1,
		});
	if (defined $dbh and defined $q->param('test_connect')) {
		print $q->pre("Connect was successfull."), "\n";
		}
	if (not defined $dbh) {
		print $q->pre("Connect failed:\n$DBI::errstr."), "\n";
		offer_dbi_connect();
		exit;
		}


	my $tables = $dbh->selectall_arrayref('show tables');
	my %possible_indexes = map { ( $_->[0] => 1 ) } @$tables
							if defined $tables;
	for my $table (keys %possible_indexes) {
		local $dbh->{'PrintError'} = 0;
		unless ($dbh->selectrow_array(
			"select 1 from $table where param = 'data_table'")) {
			delete $possible_indexes{$table};
			}
		}
	my @tables = sort keys %possible_indexes;

	if (@tables) {
		print "Select existing MyConText index to work with:\n",
			$q->start_form,
			$q->scrolling_list('index_name', \@tables),
			$q->br,
			$q->submit('test_index', 'Select index'),
			$q->hidden('dsn'), $q->hidden('user'),
				$q->hidden('password'),
			$q->end_form;
		}
	else {
		print "No existing MyConText index was found.\n";
		}

	my $myself = $q->url('-relative' => 1);
	print $q->hr, "\n",
		$q->a({'href' => $myself}, 'Change database connection'), "\n";
	}
else {
	offer_dbi_connect();
	}

if (defined $q->param('index_name')) {
	my $ctx_name = $q->param('index_name');
	my $ctx = MyConText->open($dbh, $ctx_name);
	if (defined $ctx and defined $q->param('test_index')) {
		print $q->pre("MyConText index $ctx_name loaded OK.\n");
		}
	if (not defined $ctx) {
		print $q->pre("Loading MyConText index $ctx_name failed: $MyConText::errstr.\n");
		exit;
		}
	
	use Data::Dumper;
	print '<PRE>', Dumper($ctx), "</PRE>\n";

	if (defined $q->param('search')) {
		my $search = $q->param('search');
		my @documents = $ctx->contains($search);
		print "Documents containing string `$search' are @documents.<P>\n";
		}
	elsif (defined $q->param('esearch')) {
		my $search = $q->param('esearch');
		my @documents = $ctx->econtains(split /\s+/, $search);
		print "Documents matching expression `$search' are @documents.<P>\n";
		}

	print $q->start_form,
		$q->hidden('dsn'), $q->hidden('user'),
		$q->hidden('password'), $q->hidden('index_name'),
		$q->textfield('search'), $q->submit('Search in index'),
		$q->end_form, "<P>\n";
	
	print $q->start_form,
		$q->hidden('dsn'), $q->hidden('user'),
		$q->hidden('password'), $q->hidden('index_name'),
		$q->textfield('esearch'), $q->submit('Search in index (extended)'),
		$q->end_form, "<P>\n";
	}

sub offer_dbi_connect {
	print "Please specify the DBI connect string, the user and
		password info for the database connection:\n";
	print $q->start_form,
		$q->table(
			$q->Tr( $q->td("DBI connect"),
				$q->td($q->textfield('dsn', 'dbi:mysql:test'))
				), "\n",
			$q->Tr( $q->td("Database user"),
				$q->td($q->textfield('user', 'test'))
				), "\n",
			$q->Tr( $q->td("Password"),
				$q->td($q->password_field('password', 'test'))
				), "\n",
			),
		$q->submit('test_connect', 'Test connection'),
		$q->end_form;
	}

END { print $q->end_html; }
END { $dbh->disconnect if defined $dbh; }

