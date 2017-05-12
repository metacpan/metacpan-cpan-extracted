package Worker;

use Moose;
use Test::More;

with 'Role::Pg::Notify';

has 'dbh' => (
	is => 'ro',
	isa => 'DBI::db',
);

sub process {
	my $self = shift;
	ok($self->listen( queue => 'test'), 'Listen to test');
	is($self->get_notification, undef, 'Nothing received');
	ok($self->notify(queue => 'test'), 'Notify test');
	ok(my $note = $self->get_notification, 'Notfication works');
	isa_ok($note, 'ARRAY', '- and we received something');
	ok($self->unlisten( queue => 'test'), 'Stop listening to test');
	ok($self->notify(queue => 'test'), 'Notify test');
	is($self->get_notification, undef, 'Nothing received');
	return;
};

package Test::Role::Pg::Notify;

use base qw(Test::Class);
use Test::More;

sub db_name {'__rpn:test__'};

sub startup : Test(startup => 2) {
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

sub _worker : Test(12) {
	my $self = shift;
	return if $self->{skip};

	ok(my $worker = Worker->new(dbh => $self->{dbh}), 'New Worker');
	isa_ok($worker,'Worker','Worker class');
	is($worker->process,undef,'Work');
};

package main;

Test::Role::Pg::Notify->runtests;
