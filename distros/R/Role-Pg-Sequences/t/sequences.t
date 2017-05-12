package Test;

use Moose;
use Test::More;

with 'Role::Pg::Sequences';

has 'dbh' => (
	is => 'ro',
	isa => 'DBI::db',
);

package Test::Role::Pg::Sequences;

use base qw(Test::Class);
use Test::More;

sub db_name {'__rps:test__'};

sub startup : Test(startup => 1) {
	my $self = shift;
	my $command = 'createdb -e '.db_name;
	qx{$command} || return $self->{skip} = 1;

	ok($self->{dbh} = DBI->connect('dbi:Pg:dbname='.db_name), 'Connect to test database') or return;
};

sub cleanup : Test(shutdown) {
	my $self = shift;
	return if $self->{skip};

	$self->{dbh}->disconnect;
	my $command = 'dropdb '.db_name;
	qx{$command};
};

sub _test : Test(25) {
	my $self = shift;
	return if $self->{skip};

	ok(my $test = Test->new(dbh => $self->{dbh}), 'New Test');
	isa_ok($test,'Test','Test class');
	is($test->sequence_exists(sequence => 'a'), 0,'Sequence does NOT exist');
	ok($test->create_sequence(sequence => 'a'),'Create a');
	ok($test->sequence_exists(sequence => 'a'),'Sequence exists');
	is($test->nextval(sequence => 'a'), 1,'Get first nextval for a');
	is($test->lastval, 1,'Get first lastval');
	is($test->setval(sequence => 'a', value => 1000), 1000,'Set sequence to 1000');
	is($test->lastval, 1000,'Lastval is 1000');
	is($test->nextval(sequence => 'a'), 1001,'Get nextval');
	is($test->lastval, 1001,'Lastval is now 1001');
	is($test->setval(sequence => 'a', value => 2000, is_called => 0), 2000,'Set sequence to 2000');
	is($test->lastval, 1001,'Lastval is still 1001');
	is($test->nextval(sequence => 'a'), 2000,'Get nextval');
	is($test->lastval, 2000,'Lastval is still 2000');
	ok($test->drop_sequence(sequence => 'a'),'Drop a');

	ok($test->create_sequence(sequence => 'b', minvalue => 100, temporary => 1),'Create b');
	is($test->nextval(sequence => 'b'), 100,'Get first nextval for b');

	ok($test->create_sequence(sequence => 'c', minvalue => 'onezerozero', temporary => 1),'Create c with nonsense param');
	is($test->nextval(sequence => 'c'), 1,'Get first nextval for c');

	my $schema_name = 'sequencetest';
	my $sql = qq{
		CREATE SCHEMA $schema_name
	};
	$test->sequences_dbh->do($sql);
	$test->sequences_schema($schema_name);
	is($test->sequence_exists(sequence => 'a'), 0,'Sequence does NOT exist in new schema');
	ok($test->create_sequence(sequence => 'a'),'Create a in new schema');
	ok($test->sequence_exists(sequence => 'a'),'Sequence exists in new schema');
	is($test->nextval(sequence => 'a'), 1,'Get first nextval for a in new schema');
	is($test->lastval, 1,'Get lastval');
};

package main;

Test::Role::Pg::Sequences->runtests;
