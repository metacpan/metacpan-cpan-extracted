package MyLibrary::Message;

use MyLibrary::DB;
use Carp qw(croak);
use strict;

=head1 NAME

MyLibrary::Message

=head1 SYNOPSIS

use MyLibrary::Message;

=head1 DESCRIPTION

Use this module to get and set messages from the librarians to a MyLibrary database.

=head1 METHODS

=head2 new()

=head2 message_id()

=head2 message_date()

=head2 message()

=head2 message_global()

message_global is a Boolean value. Set it to true ('1') to make this message intended for everybody. Set it to false ('2') to make it not. False is the default. Call message_global without any parameters to get it's value.

=head2 commit()

=head2 delete()

=head2 get_messages()

=head1 HISTORY

This module is legacy code. I sometimes wonder if it is even needed, and the message_global method feels like a hack.

=head1 AUTHOR

Eric Lease Morgan


=cut


sub new {

	# declare local variables
	my ($class, %opts) = @_;
	my $self           = {};

	# check for an id
	if ($opts{id}) {
	
		# get a handle
		my $dbh = MyLibrary::DB->dbh();
		
		# find this record
		my $rv = $dbh->selectrow_hashref('SELECT * FROM messages WHERE message_id = ?', undef, $opts{id});
		
		# check for success
		if (ref($rv) eq "HASH") { $self = $rv }
		else { return }
	
	}
	
	# return the object
	return bless $self, $class;
	
}


sub message_id {

	my $self = shift;
	return $self->{message_id};

}


sub message_date {

	# declare local variables
	my ($self, $message_date) = @_;
	
	# check for the existance of a date 
	if ($message_date) { $self->{message_date} = $message_date }
	
	# return it
	return $self->{message_date};
	
}


sub message {

	# declare local variables
	my ($self, $message) = @_;
	
	# check for the existance of a message 
	if ($message) { $self->{message} = $message }
	
	# return the date
	return $self->{message};
	
}


sub message_global {

	# declare local variables
	my ($self, $message_global) = @_;
	
	# check for the existance of a message
	if ( ! $message_global ) { }
	elsif ( lc( $message_global ) eq '1'  || lc( $message_global ) eq '2' ) { $self->{message_global} = $message_global }
	else { croak("Invalid value for message_global: $message_global. Valid values are 1 (true) or 2 (false).") }
	
	# return the global message flag
	return $self->{message_global};
	
}


sub commit {

	# get myself, :-)
	my $self = shift;
	
	# get a database handle
	my $dbh = MyLibrary::DB->dbh();	
	
	# see if the object has an id
	if ($self->message_id()) {
	
		# update the record with this id
		my $return = $dbh->do('UPDATE messages SET message = ?, message_date = ?, message_global = ? WHERE message_id = ?', undef, $self->message(), $self->message_date(), $self->message_global(), $self->message_id());
		if ($return > 1 || ! $return) { croak "Message update in commit() failed. $return records were updated." }
	
	}
	
	else {
	
		# get a new sequence
		my $id = MyLibrary::DB->nextID();		
		
		# create a new record
		my $return = $dbh->do('INSERT INTO messages (message_id, message, message_date, message_global) VALUES (?, ?, ?, ?)', undef, $id, $self->message(), $self->message_date(), $self->message_global());
		if ($return > 1 || ! $return) { croak 'Message commit() failed.'; }
		$self->{message_id} = $id;
		
	}
	
	# done
	return 1;
	
}


sub delete {

	my $self = shift;

	if ($self->{message_id}) {

		my $dbh = MyLibrary::DB->dbh();
		my $rv = $dbh->do('DELETE FROM messages WHERE message_id = ?', undef, $self->{message_id});
		if ($rv != 1) {croak ("Deleted $rv records. I'll bet this isn't what you wanted.");} 
		return 1;

	}

	return 0;

}


sub get_messages {

	my $self = shift;
	my @rv   = ();
	
	# create and execute a query
	my $dbh = MyLibrary::DB->dbh();
	my $rows = $dbh->prepare('SELECT * FROM messages ORDER BY message_date');
	$rows->execute;
	
	# process each found row
	while (my $row = $rows->fetchrow_hashref()) {
	
		push (@rv, bless ($row, 'MyLibrary::Message'));
				
	}
	
	return @rv;
	
}


# return true, or else
1;
