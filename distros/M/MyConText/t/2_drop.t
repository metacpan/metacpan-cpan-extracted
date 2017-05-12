
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..9\n";

use MyConText;

print "ok 1\n";


sub get_tables_list {
	return grep /^_ctx_test(?!_the_table$)/,
		map { $_->[0] } @{ $dbh->selectall_arrayref('show tables') };
	}

print "We will drop all the tables first\n";
for (qw! _ctx_test _ctx_test_data _ctx_test_words _ctx_test_docid !) {
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}
my $ctx;
my @tables;

print "Now check that everything was dropped\n";

@tables = get_tables_list();
if (@tables) {
	print "The following tables were not dropped: @tables\nnot ";
	}
print "ok 2\n";


print "Creating default MyConText index\n";
$ctx = MyConText->create($dbh, '_ctx_test') or print "$MyConText::errstr\nnot ";
print "ok 3\n";


@tables = get_tables_list();
if ("@tables" ne '_ctx_test _ctx_test_data') {
	print "After the index was created, @tables were found\nnot ";
	}
print "ok 4\n";


print "Now we will drop the index\n";
$ctx->drop or print $ctx->errstr, "\nnot ";
print "ok 5\n";

@tables = get_tables_list();
if (@tables) {
	print "The following tables were not dropped: @tables\nnot ";
	}
print "ok 6\n";


print "Creating MyConText index with blob backend and file frontend\n";
$ctx = MyConText->create($dbh, '_ctx_test', 'backend' => 'blob',
		'frontend' => 'file') or print "$MyConText::errstr\nnot ";
print "ok 7\n";


print "Now we will drop the index\n";
$ctx->drop or print $ctx->errstr, "\nnot ";
print "ok 8\n";

@tables = get_tables_list();
if (@tables) {
	print "The following tables were not dropped: @tables\nnot ";
	}
print "ok 9\n";

