
package Notify::NoticePool;

require 5.00503;
use strict;
use Carp;
use Notify::Notice;
use Tie::Persistent;

require Exporter;

our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'all' => [ qw( DEFAULT_RESEND_INTERVAL DEFAULT_MAX_RETRIES ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );
#our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $VERSION = '0.0.1';

# Set our notification constants
use constant DEFAULT_RESEND_INTERVAL => 300;
use constant DEFAULT_MAX_RETRIES     => 5;
our $resend_interval = DEFAULT_RESEND_INTERVAL;
our $max_retries     = DEFAULT_MAX_RETRIES;

sub new {

	my ($self, $options) = @_;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

	confess "Error creating Notice Pool: No file store given."
		unless exists $options->{'file_store'};

	$this->{'__NOTICE_FILE'} = $options->{'file_store'};
	$this->{'__TRANSPORT'} = (exists $options->{'transport'})
		? $options->{'transport'} : { };

	$this->updateOutstanding ()
		unless exists $options->{'no_implicit_update'};

	return $this;

} #end sub new

sub setResendInterval {

	my ($self, $interval) = @_;

	confess "Error setting resend interval: No interval given."
		unless $interval;

	$resend_interval = $interval;

} #end sub setResendInterval

sub getResendInterval {

	my ($self) = @_;
	return $resend_interval;

} #end getResendInterval

sub setMaxRetries {

	my ($self, $retries) = @_;

	confess "Error setting number of max retries: No maximum given."
		unless $retries;

	$max_retries = $retries;

} #end sub setMaxRetries

sub getMaxRetries {

	my ($self) = @_;
	return $max_retries;

} #end sub getMaxRetries

sub addTransport {

	my ($self, $entries) = @_;

	foreach (keys %$entries) {

		confess "Error adding transport entry for type $_. Invalid transport object."
			unless defined $entries->{$_}->send and defined $entries->{$_}->receive;

		$self->{'__TRANSPORT'}->{$_} = $entries->{$_};

	}

} #end sub addTransport

sub getUniqueID {

	my ($self) = @_;
	my %tied;

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';
	my $lastid = $tied{'__LAST_ID'} + 1;
	while (exists $tied{ $lastid }) { $lastid++; }
	untie %tied;

	return $lastid;

} #end sub getUniqueID

sub exists {

	my ($self, $id) = @_;
	my %tied;

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';
	my $result = exists $tied{$id};
	untie %tied;

	return $result;

} #end sub exists

sub addNotice {

	my ($self, $notice) = @_;
	my %tied;

	confess "Error adding notice: No notice given."
		unless $notice;

	my $notice_attribs = $notice->getNotice ();

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';

	unless (exists $tied{ $notice_attribs->{'id'} }) {

		$notice_attribs->{'time_created'} = $notice_attribs->{'time_updated'} = time ();
		$tied{ $notice_attribs->{'id'} } = $notice_attribs;

		# Update the last used ID
		$tied{'__LAST_ID'} = $notice_attribs->{'id'};

	}
	else {
		return undef;
	}

	untie %tied;

	my $new_notice = new Notify::Notice ($notice_attribs);
	my $updated = $self->sendIfAppropriate ($new_notice);

	return ($updated) ? $updated : $new_notice;

} #end sub addNotice

sub sendIfAppropriate {

	my ($self, $notice) = @_;
	my $attribs = $notice->getNotice ();
	my %tied;

	# Try to send the notice immediate with an updated object
	# and update the persistent object on disk. Note that we
	# had to untie before trying the send in order to have
	# guaranteed messaging.

	if ($attribs->{'status'} == OUTGOING_PENDING) {

		if ($self->sendNotice ($notice)) {
			$attribs->{'status'} = WAITING_RESPONSE;
		}
		else {
			$attribs->{'attempts'}++;
		}

		tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';
		$tied{ $attribs->{'id'} } = $attribs;
		untie %tied;

		return new Notify::Notice ($attribs);

	}
	else {
		return undef;
	}

} #end sub sendIfAppropriate

sub resolveNotice {

	my ($self, $notice) = @_;
	my %tied;

	confess "Error resolving notice: No notice given."
		unless $notice;

	my $notice_attribs = $notice->getNotice ();

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';
	return undef unless exists $tied{ $notice_attribs->{'id'} };
	delete $tied{ $notice_attribs->{'id'} };
	untie %tied;

	return 1;

} #end sub resolveNotice

sub retrieveNotice {

	my ($self, $notice) = @_;
	my %tied;
	my ($notice_attribs, $db_attribs);

	$notice_attribs = $notice->getNotice ();

	confess "Error retrieving notice: No notice given."
		unless $notice;

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'r';
	if (exists $tied{ $notice_attribs->{'id'} }) {
		$db_attribs = $tied{ $notice_attribs->{'id'} };
	}
	else {
		return undef;
	}
	untie %tied;

	if ($db_attribs->{'status'} == WAITING_PROCESSING) {

		# Mark that the notification is transaction is considered
		# done unless the application updated the notification
		# back to OUTGOING_PENDING
		$db_attribs->{'status'} = DONE;
		tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';
		$tied{ $db_attribs->{'id'} } = $db_attribs;
		untie %tied;

	}

	return new Notify::Notice ($db_attribs);

} #end sub retreiveNotice

sub updateNotice {

	my ($self, $notice) = @_;
	my %tied;
	my ($new_attribs, $old_attribs);

	confess "Error updating notice: No notice given."
		unless $notice;

	$new_attribs = $notice->getNotice ();

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';

	return undef unless exists $tied{ $new_attribs->{'id'} };
	$old_attribs = $tied{$new_attribs->{'id'}};
	push @{ $new_attribs->{'history'} }, $old_attribs->{'message'};
	$new_attribs->{'time_updated'} = time ();
	$tied{ $new_attribs->{'id'} } = $new_attribs;

	untie %tied;

	my $new_notice = new Notify::Notice ($new_attribs);
	my $updated = $self->sendIfAppropriate ($new_notice);

	return ($updated) ? $updated : $new_notice;

} #end sub updateNotice

sub updateOutstanding {

	my ($self) = @_;
	my %tied;

	tie %tied, 'Tie::Persistent', $self->{'__NOTICE_FILE'}, 'rw';

	foreach my $key (keys %tied) {

		# Skip the special LASTID key
		next if $key =~ /^__LAST_ID$/;

		my $notice_attribs = $tied{$key};

		if ($notice_attribs->{'status'} == OUTGOING_PENDING) {

			# Check to see if we are within the send interval
			next unless $notice_attribs->{'attempts'} and
			            (time () - $notice_attribs->{'time_updated'} > $resend_interval);

			my $outgoing = new Notify::Notice ($notice_attribs);

			if ($self->sendNotice ($outgoing)) {

				$notice_attribs->{'status'} = WAITING_RESPONSE;
				$notice_attribs->{'time_updated'} = time ();

			}
			else {

				$notice_attribs->{'attempts'}++;

				if ($notice_attribs->{'attempts'} > $max_retries) {
					$notice_attribs->{'status'} = FAILURE;
				}

			}

		}
		elsif ($notice_attribs->{'status'} == WAITING_RESPONSE) {

			my $incoming = new Notify::Notice ($notice_attribs);
			my $response = $self->getNoticeResponse ($incoming);

			if ($response) {

				push @{ $notice_attribs->{'history'} }, $notice_attribs->{'message'};
				$notice_attribs->{'message'} = $response;
				$notice_attribs->{'status'} = WAITING_PROCESSING;
				$notice_attribs->{'time_updated'} = time ();

			}

		}

		# Assign the copy to the persistent DB
		$tied{$key} = $notice_attribs;

	}

	untie %tied;

	return 1;

} #end sub updateOutstanding

sub sendNotice {

	my ($self, $notice) = @_;
	my $attribs = $notice->getNotice ();

	confess "Error: Attempted to send notice to undefined transport type."
		unless exists $self->{'__TRANSPORT'}->{ $attribs->{'transport'} };

	return $self->{'__TRANSPORT'}->{ $attribs->{'transport'} }->send ($notice);

} #end sub sendNotice

sub getNoticeResponse {

	my ($self, $notice) = @_;
	my $attribs = $notice->getNotice ();

	confess "Error: Attempted to retrieve notice from undefined transport type."
		unless exists $self->{'__TRANSPORT'}->{ $attribs->{'transport'} };

	return $self->{'__TRANSPORT'}->{ $attribs->{'transport'} }->receive ($notice);

} #end sub getNoticeResponse

1;

__END__


=head1 NAME

Notify::NoticePool - Framework for managing persistent user
                     notifications.

=head1 SYNOPSIS

    use Notify::NoticePool;
    use Notify::Notice;
    use Notify::Email;

    my $email_transport = new Notify::Email ({
        'app'   => "Application Name",
        'mbox'  => "/var/spool/mail/mailbox",
        'smtp'  => "smtp.domain.net",
    });

    my $notice_pool = new Notify::NoticePool ({
        'file_store'  => "/usr/lib/persistent_db",
        'transport'   => { 'email' => $email_transport },
    });

    # Add a notification
    my $id = $notice_pool->getUniqueID ();
    my $notice = new Notify::Notice ({
        'id' => $id,
    });
    # ... set attributes
    $notice_pool->addNotice ($notice);

   # Retreive a notification if one is waiting
    my $notice = new Notify::Notice ({
        'id' => $id,
        'transport' => 'email',
    });
    $notice_pool->retrieveNotice ($notice);

    # Advance each transaction if possible
    $notice_pool->updateOutstanding ();

=head1 DESCRIPTION

Notify::NoticePool provides methods for managing
persistent user notifications that might be sent through a variety
of medium such as via email or pager. This module is meant to
facilitate communication through medium where the programmer can
expect a significant delay and where reliability is important.

NoticePool allows for management of various Notification objects
(see Notify::Notice), each with possibly
different destinations. The NoticePool offers guaranteed
reliability as all changes to the Notification object are written
out to disk in the notification database prior to update.

The notification pool allows the addition, updating, and retrieval
of notification objects within the pool. Notification transactions
are advanced through the 'updateOutstanding' method, which
attempts to resend notifications whose delivery previously failed
and indicate that notices are awaiting processing when a response
has arrived.

Transports are registered as transport types (keywords) and
associated instantiated transport objects. Transport objects
must adhere to the interface outlined in the transport section
below.

A history of the notification transactions is also maintained
within the notification object during sending and retrieval.
The status of the notification object is also updated as the
application interacts with the notice pool.

Finally, notification objects continue to exist within the
persistent notification database until they are resolved by the
application.

=head2 EXPORT

None by default.

=head2 CLASS ATTRIBUTES

  $Notify::NoticePool:resend_interval
      - The interval at which to retry a failed attempt to
        send a notification

  $Notify::NoticePool:max_retries
      - The maximum number of retries before a notification
        is deemed a failure.

  $Notify::NoticePool:VERSION
      - The CVS revision of this module.

The following class constants are optional:

  DEFAULT_MAX_RESEND_INTERVAL - The default interval in
                                seconds at which to retry a
                                failed attempt.

  DEFAULT_MAX_RETRIES - The default number of retries before
                        deeming a notification a failure.

=head2 PUBLIC METHODS

  new ($hashref)

     The constructor takes a hashref that support the following
     keys:

       Required:

         'file_store' - The persistent database to use.
         'transport'  - A hashref whose keys are the names of
                        transport types and whose values are
                        instantiated transport objects.

       Optional:

         'no_implicit_update' - When this key is set,
                                updateOutstanding will not be
                                called during object
                                instantiation.

  setResendInterval ($integer)

     Sets the miniumum interval that must elapse in seconds
     between failed notifications. Note that the notifications
     will only be resent with a call to updateOutstanding ().

  getResentInterval ()

     Returns the interval value.

  setMaxRetries ($integer)

     Sets the number of retries to attempt before marking a
     notification a failure.

  getMaxRetries

     Returns the maximum number of retries.

  addTransport ($hashref)

     Takes a hashref whose keys are transport types and whose
     values are instantiated transport objects. These are used
     when routing the notification objects based on the 'type'
     field.

  getUniqueID ()

     Returns a unique ID (currently unused in the persistent
     database) for the creation of a new notification object.

  exits ($id)

     Retruns 1 if an ID exists within the persistent
     database and 0 otherwise.

  addNotice ($notice)

     Adds a notice object into the pool. Returns undef if the
     add failed (i.e, a notification object with the same id
     already exists) or an updated notification object if
     successful. An attempt to send the notification is
     immediately made as well.

  resolveNotice ($notice)

     Resolves a notification by removing it from the persistent
     database. Returns 1 if successful, otherwise returns
     undef.

  retrieveNotice ($object)

     Attempts to receive the response associated with a
     notification object. Returns a new notification object
     that includes the new response message and the updated
     history.

  updateNotice ($notice)

     Updates the attributes of an existing notice within the
     persistent database. Returns an updated notification
     object if successful and undef otherwise.

  updateOutstanding ()

     Checks all notifications in the persistent database and
     attempts to advance each transaction by one step, i.e,
     resending failed attempts or checking if a response is
     waiting for a notification. This method changes the
     status of the notification in the persistent database
     accordingly.

=head2 PRIVATE METHODS

  sendIfAppropriate ($notice)

     Attempts to send the notice if the notice is marked
     OUTGOING_PENDING. Updates the data store and returns
     an updated notification object upon success and undef
     on failure.

  sendNotice ($notice)

     Attempts to send a notice using the appropriate transport
     found in the transport attribute of the notification object.

  getNoticeResponse ($notice)

     Attempts to receive a response to a notification over
     the transport found in the transport attribute of the
     notification object.

=head2 TRANSPORT INTERFACE

    All transport modules must implement the following methods:

      send ($notice)

         Attempts to send a notification object through the
         implemented transport. Returns 1 if successful and
         undef otherwise.

      receive ($notice)

         Attempts to obtain a response for a given
         notification through the implemented transport.
         Returns the message string is successful or undef
         otherwise.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu>
Copyright (C) 2001

=head1 SEE ALSO

perl(1), Notify::Notice, Notify::Email

=head1 VERSION

  This software is currently alpha, version 0.0.1.

=cut
