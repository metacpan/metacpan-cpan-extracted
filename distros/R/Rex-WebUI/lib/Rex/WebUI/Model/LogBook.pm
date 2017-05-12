
package Rex::WebUI::Model::LogBook;

use strict;

use Data::Dumper;
use DBIx::Foo qw(:all);

sub new
{
	my ($class, $dbh) = @_;

	my $self = {
		'_dbh'   => $dbh,
	};

	return bless $self, $class;
}

sub dbh
{
	return shift->{_dbh};
}

sub add
{
	my ($self, $data) = @_;

	die "Need a task_name" unless $data->{task_name};
	die "Need a server"    unless $data->{server};
	die "Need a userid"    unless $data->{userid};

	if (ref($data->{server}) eq 'ARRAY') {

		$data->{server} = join ", ", map { $_->{name} } @{$data->{server}};
	}

	my $check = $self->dbh->selectrow_hashref("select max(jobid) from logbook");

	$self->_create_logbook_table unless $check;

	my $jobid = $self->dbh_do("insert into logbook (userid, task_name, server, statusid, jobid) values (?, ?, ?, ?, ?)", $data->{userid}, $data->{task_name}, $data->{server}, 0, undef);

	$jobid = "TS" . time if !$jobid; # in case db not working, use timestamp as a jobid

	return $jobid;
}

sub update_status
{
	my ($self, $jobid, $statusid) = @_;

	return $self->dbh_do("update logbook set statusid = ? where jobid = ?", $statusid, $jobid);
}

sub set_pid
{
	my ($self, $jobid, $pid) = @_;

	$self->dbh_do("update logbook set pid = ? where jobid = ?", $pid, $jobid);
}

sub _create_logbook_table
{
	my $self = shift;

	$self->dbh_do("create table logbook (jobid INTEGER PRIMARY KEY AUTOINCREMENT, userid int not null, task_name varchar(100), server varchar(100), statusid int)");
}

sub running_tasks
{
	my $self = shift;

	my $rows = $self->selectall("select l.*, s.status, u.username from logbook l join status s on l.statusid = s.statusid join users u on u.userid = l.userid where l.statusid in (0, 1)");

	# check if the tasks are still alive
	foreach my $row (@$rows) {

		if ($row->{pid}) {
			unless (my $check = kill 0, $row->{pid}) {
				$row->{status} = 'DEAD' ;
				$self->update_status($row->{jobid}, 3);
			}
		}
		else {
			$row->{status} = 'MISSING PID';
		}
	}

	return $rows;
}

sub recent_tasks
{
	my $self = shift;

	my $rows = $self->selectall("select l.*, s.status, u.username from logbook l join status s on l.statusid = s.statusid join users u on u.userid = l.userid where l.statusid > 1 order by l.jobid desc limit 20");

	return $rows;
}

1;
