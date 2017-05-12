=head1 NAME

Queue::Worker - Database based work queue abstraction.

=head1 SYNOPSIS

    package MyWorker;
    use base 'Queue::Worker';

    sub name { 'my_work'; }

    sub process {
            my ($self, $item) = @_;
            # do your work here
    }
    
    # create worker table in db
    MyWorker->create_table($dbh);

    # and somewhere else
    MyWorker->enqueue($dbh, 'some work order string');

    # and finally to run the queue
    MyWorker->run($dbh);

=head1 DESCRIPTION

This module provides simple, database queue based, worker abstraction. It
provides locking between worker instances using L<POSIX::RT::Semaphore>.

Strings representing work orders are enqueued with C<enqueue> function. Those
items are removed from the queue by C<run> function.

=cut
use strict;
use warnings FATAL => 'all';

package Queue::Worker;
our $VERSION = '0.01';
use POSIX::RT::Semaphore;
use Fcntl;            # O_CREAT, O_EXCL for named semaphore creation

=head1 METHODS

=head2 $class->create_table($dbh, $name)

Creates table C<queue_worker_$name> table in the database. C<$name> parameter
is optional: if undef C<name> accessor is used.

=cut
sub create_table {
	my ($class, $dbh, $name) = @_;
	$name ||= $class->name;
	$dbh->do(sprintf(<<'ENDS', $name));
create table queue_worker_%s (id serial primary key, msg text) without oids
ENDS
}

=head2 $class->enqueue($dbh, $msg)

Enqueues work order C<$msg> into the queue.

=cut
sub enqueue {
	my ($class, $dbh, $msg) = @_;
	$dbh->do(sprintf('insert into queue_worker_%s (msg) values (?)'
				, $class->name), undef, $msg);
}

=head2 $class->new

Creates new instance of the worker. Also creates underlying semaphore.

=cut
sub new { 
	my $class = shift;
	my $sem = POSIX::RT::Semaphore->open("/" . $class->name
		, O_CREAT, 0660, 1);
	return bless({ semaphore => $sem }, $class);
}

=head2 $class->run($dbh)

Runs the queue. Calls C<process> method on each work item.

=cut
sub run {
	my ($self, $dbh) = @_;
	my $t = 'queue_worker_' . $self->name;
	my $sql = <<ENDS;
delete from $t where id in (select id from $t order by id limit 1)
	returning msg;
ENDS
	my $cnt = 0;
AGAIN:
	(!$self->{semaphore}->trywait) and goto OUT; # has 0 but true
	eval { for (;;) {
		# delete should not be in transaction: we should always make
		# progress, even if we die. Otherwise, we'll be crashing again
		# and again.
		my $res = $dbh->selectcol_arrayref($sql);
		last unless @$res;
		$self->process($res->[0]);
		$cnt++;
	} };
	$self->{semaphore}->post;
	die "Retrowing: $@" if $@;

	my $more = $dbh->selectcol_arrayref("select id from $t limit 1");
	goto AGAIN if @$more;
OUT:
	return $cnt;
}

=head2 $class->unlink_semaphore

Unlinks semaphore.

=cut
sub unlink_semaphore { 
	my $class = shift;
	POSIX::RT::Semaphore->unlink('/' . $class->name);
}

=head2 $class->get_semaphore

Returns underlying semaphore.

=cut
sub get_semaphore {
	return shift()->new->{semaphore};
}

1;

=head1 ABSTRACT METHODS

The following methods should be implemented by inherited class.

=head2 $class->name

Should return the name of the worker.

=head2 $self->process($msg)

Callback to process the work order.

=head1 AUTHOR

	Boris Sukholitko
	CPAN ID: BOSU
	
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<POSIX::RT::Semaphore>

=cut
