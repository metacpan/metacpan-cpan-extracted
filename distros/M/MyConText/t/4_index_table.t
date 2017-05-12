
use strict;
use vars qw! $dbh !;

$^W = 1;

require 't/test.lib';

print "1..14\n";

use MyConText;
use Benchmark;

print "ok 1\n";


print "We will drop all the tables first\n";
for (qw! _ctx_test _ctx_test_data _ctx_test_words _ctx_test_docid 
		_ctx_test_the_table !) {
	local $dbh->{'PrintError'} = 0;
	$dbh->do("drop table $_");
	}

print "ok 2\n";


print "We will create the _ctx_test_the_table table\n";
$dbh->do('create table _ctx_test_the_table (id tinyint not null,
			data varchar(255),
			primary key(id))');

print "ok 3\n";

$dbh->do(q!insert into _ctx_test_the_table values (2, 'jezek ma bodliny')!);
$dbh->do(q!insert into _ctx_test_the_table values (3, 'krtek bodliny nema')!);

my $ctx;

print "Creating MyConText index with table frontend\n";
$ctx = MyConText->create($dbh, '_ctx_test',
	'frontend' => 'table', 'table_name' => '_ctx_test_the_table',
	'column_name' => 'data')
					or print "$MyConText::errstr\nnot ";
print "ok 4\n";

$ctx = MyConText->open($dbh, '_ctx_test') or print "$MyConText::errstr\nnot ";
print "ok 5\n";

my (@docs, $expected, @param, $words);

$words = $ctx->index_document(2);
print "Indexed 2, got $words words\n";
$words = $ctx->index_document(3);
print "Indexed 3, got $words words\n";

@param = 'bodl%';
print "Calling contains(@param)\n";
@docs = sort($ctx->contains(@param));
$expected = '2 3';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 6\n";


@param = 'nema';
print "Calling contains(@param)\n";
@docs = sort($ctx->contains(@param));
$expected = '3';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 7\n";

$words = $ctx->index_document(5);
print "Indexed 5, got $words words\n";

$dbh->do(q!insert into _ctx_test_the_table values (5, 'zirafa taky nema bodliny')!);

$words = $ctx->index_document(5);
print "Indexed 5, got $words words\n";

@param = 'nema';
print "Calling contains(@param)\n";
@docs = sort($ctx->contains(@param));
$expected = '3 5';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 8\n";

print "Drop the MyConText index\n";
$ctx->drop or print $ctx->errstr, "\nnot ";
print "ok 9\n";

print "Drop the _ctx_test_the_table table\n";
$dbh->do('drop table _ctx_test_the_table');


# Now the section with TableString

print "We will create the _ctx_test_the_table table\n";
$dbh->do('create table _ctx_test_the_table (name varchar(14) not null,
			data varchar(255),
			primary key(name))');

print "ok 10\n";

$dbh->do(q!insert into _ctx_test_the_table values ('jezek', 'jezek ma bodliny')!);
$dbh->do(q!insert into _ctx_test_the_table values ('krtek', 'krtek bodliny nema')!);

print "Creating MyConText index with table frontend against stringed table\n";
$ctx = MyConText->create($dbh, '_ctx_test',
	'frontend' => 'table', 'table_name' => '_ctx_test_the_table',
	'column_name' => 'data')
					or print "$MyConText::errstr\nnot ";
print "ok 11\n";

$ctx = MyConText->open($dbh, '_ctx_test') or print "$MyConText::errstr\nnot ";
print "ok 12\n";


$words = $ctx->index_document('jezek');
print "Indexed jezek, got $words words\n";
$words = $ctx->index_document('krtek');
print "Indexed krtek, got $words words\n";

@param = 'bodl%';
print "Calling contains(@param)\n";
@docs = sort($ctx->contains(@param));
$expected = 'jezek krtek';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 13\n";


@param = 'nema';
print "Calling contains(@param)\n";
@docs = sort($ctx->contains(@param));
$expected = 'krtek';
print "Documents containing `@param': @docs\n";
print "Expected $expected\nnot " unless "@docs" eq $expected;
print "ok 14\n";

$ctx->drop;


