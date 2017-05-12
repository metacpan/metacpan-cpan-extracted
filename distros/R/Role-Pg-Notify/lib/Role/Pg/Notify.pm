package Role::Pg::Notify;
$Role::Pg::Notify::VERSION = '0.001';
use Moose::Role;
use DBI;

has 'notify_dbh' => (
	is => 'ro',
	isa => 'DBI::db',
	lazy_build => 1,
);

sub _build_notify_dbh {
	my $self = shift;
	return $self->dbh if $self->can('dbh');
	return $self->schema->storage->dbh if $self->can('schema');
}

sub listen {
	my ($self, %args) = @_;
	my $queue = $args{queue} || return undef;

	for my $q (ref $queue ? @$queue : ($queue)) {
		$self->notify_dbh->do(qq{listen "$q";});
	}
	return $queue;
}

sub unlisten {
	my ($self, %args) = @_;
	my $queue = $args{queue} || return undef;

	for my $q (ref $queue ? @$queue : ($queue)) {
		$self->notify_dbh->do(qq{unlisten "$q";});
	}
	return $queue;
}

sub notify {
	my ($self, %args) = @_;
	my $queue = $args{queue} || return undef;

	my $sql = qq{SELECT pg_notify(?,?)};
	my $sth = $self->notify_dbh->prepare($sql) || return;

	my $payload = $args{payload};
	$sth->execute( $queue, $payload );
}

sub get_notification {
	my ($self) = @_;
	my $dbh = $self->notify_dbh;
	my $notifies = $dbh->pg_notifies;
	return $notifies;
}

sub set_listen {
	my ($self,$timeout) = @_;
	my $dbh = $self->notify_dbh;
	my $notifies = $dbh->pg_notifies;
	if (!$notifies) {
		my $fd = $dbh->{pg_socket};
		vec(my $rfds='',$fd,1) = 1;
		my $n = select($rfds, undef, undef, $timeout);
		$notifies = $dbh->pg_notifies;
	}
	return $notifies;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Role::Pg::Notify - Client PostgreSQL notification Role

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This role adds easy notification to client programs connected to a PostgreSQL database.

=head1 NAME

Role::Pg::Notify

=head1 ATTRIBUTES

=head2 notify_dbh

Role::Pg::Notify tries to guess your dbh. If it isn't a standard DBI::db named dbh, or
constructed in a DBIx::Class schema called schema, you have to return the dbh from
_build_notify_dbh.

=head1 METHODS

=head2 listen

 $self->listen( queue => 'queue_name' );
 $self->listen( queue => \@queues );

Sets up the listener. Quit listening to the named queues.

Returns undef immediately if no queue is provided.

=head2 unlisten

 $self->unlisten( queue => 'queue_name' );
 $self->unlisten( queue => \@queues );

Quit listening to the named queues.

Returns undef immediately if no queue is provided.

=head2 notify

 $self->notify( queue => 'queue_name' );
 $self->notify( queue => 'queue_name', payload => $data  );

Sends an asynchronous notification to the named queue, with an optional
payload.

Returns undef immediately if no queue name is provided.

=head2 get_notification

 my $notifies = $self->get_notification();

Retrievies the pending notifications. The return value is an arrayref where
each row looks like this:

 my ($name, $pid, $payload) = @$notify;

Returns undef if no notification was found.

=head2 set_listen

 my $notifies = $self->set_listen($timeout);

Retrievies the pending notifications. The return value is an arrayref where
each row looks like this:

 my ($name, $pid, $payload) = @$notify;

If no notification is found, set_listen listens $timeout seconds. If any notification
to any queue we're listening on is received, it will be returned immediately.

Not passing $timeout (or passing undef) means that set_listen will wait forever (or until
a notification is received).

Returns undef if no notification was received within the requested time.

=head1 AUTHOR

Kaare Rasmussen <kaare@cpan.org>.

=head1 COPYRIGHT

Copyright (C) 2014, Kaare Rasmussen

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Kaare Rasmussen <kaare at cpan dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kaare Rasmussen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Client PostgreSQL notification Role

