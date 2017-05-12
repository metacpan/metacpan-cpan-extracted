package Net::Google::Calendar::Server::Backend::ICalendar;

use strict;
use base qw(Net::Google::Calendar::Server::Backend);
use Digest::MD5 qw(md5_hex);

use Data::ICal::DateTime;

=head1 NAME

Net::Google::Calendar::Server::Backend::ICalendar - an ICalendar backend for Net::Google::Calendar::Server

=cut

=head1 METHODS

=cut

=head2 fetch 

Fetch entries from a ICalendar file.

=cut

sub fetch {
    my $self = shift;
    my %opts = @_;
	# TODO actually filter them
	my $cal =  $self->from_file;
	return $cal->events;
}

=head2 add

Add a new entry.

=cut

sub add {
    my $self  = shift;
    my $event = shift;

    $event->uid(md5_hex(time().$$.rand()));

    # read in whole of file
    my $cal = $self->from_file;
    # add event
    $cal->add_event($event);
    # write it back out again
    $self->_to_file($cal);
}

=head2 update

Update an entry

=cut

sub update {
    my $self  = shift;
    my $event = shift;


    # read in whole of file
    my $cal = $self->from_file;
    my @entries;
    # grep through looking for this id 
    foreach my $entry ($cal->entries) {
        # update it
        $entry = $event if ($entry->uid eq $event->uid);
        push @entries, $entry;
    }
    $cal->{entries} = [ @entries ];
    # write it back out again
    $self->_to_file($cal);



}

=head2 delete

Delete an entry

=cut

sub delete {
    my $self  = shift;
    my $event = shift;

    # read in whole of file
    my $cal = $self->from_file;
    my @entries;
    # grep through looking for this id 
    foreach my $entry ($cal->entries) {
        # delete it
        next if $entry->uid eq $event->uid;
        push @entries, $entry;
    }
    $cal->{entries} = [ @entries ];
    # write it back out again
    $self->_to_file($cal);
}


sub _from_file {
    my $self = shift;
    return Data::ICal->new(filename => $self->{filename});
}

sub _to_file {
    my $self = shift;
    my $cal  = shift;

    my $file = $self->{filename};
    open(CAL,">$file")|| die "Couldn't open $file for writing: $!\n";
    print CAL $cal->as_string;
    close(CAL);
}

1;
