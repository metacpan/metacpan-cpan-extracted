package Notify::Notice;

require 5.00503;
use strict;
use Carp;

require Exporter;

our @ISA = qw( Exporter );
our %EXPORT_TAGS = (
	'all' => [qw( EMPTY OUTGOING_PENDING WAITING_RESPONSE WAITING_PROCESSING FAILURE DONE )]
);
our @EXPORT_OK = qw( );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );
#our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $VERSION = '0.0.1';

# Constants that indicate notification status
use constant EMPTY              => 0;
use constant OUTGOING_PENDING   => 1;
use constant WAITING_RESPONSE   => 2;
use constant WAITING_PROCESSING => 3;
use constant FAILURE            => 4;
use constant DONE               => 5;

our @attribs = qw( status attempts id src dest message transport time_created time_updated history );

sub new {

	my ($self, $hash_vals) = @_;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

	# Set our notification attribs to a blank hash
	$this->{'__ATTRIBS'} = { };

	# Copy in preset values
	foreach (@attribs) {

		$this->{'__ATTRIBS'}->{$_} = $hash_vals->{$_}
			if exists $hash_vals->{$_};

	}

	return $this;

} #end sub new

sub attribs {

	my ($self) = @_;
	return @attribs;

} #end sub attribs

sub getNotice {

	my ($self) = @_;
	# Return a copy of the hash
	return \%{ $self->{'__ATTRIBS'} };

} #end sub getNotice

sub setNotice {

	my ($self, $attribs) = @_;

	confess "Error: Must receive hash reference to set Notice attributes."
		unless $attribs and ref ($attribs) eq 'HASH';

	# Change the internal to reflect the changes
	foreach (keys %$attribs) {

		$self->{'__ATTRIBS'}->{$_} = $attribs->{$_}
			if grep /^$_$/, @attribs;

	}

} #end sub setNotice

1;

__END__

=head1 NAME

Notify::Notice - Notification object for use with the NoticePool
                 object.

=head1 SYNOPSIS

    use Notify::Notice;

    my $init = { 'id' => 23, 'status' = EMPTY };
    my $notice = new Notify::Notice ($init);

    my $attribs = $notice->getNotice ();
    foreach ($notice->attribs () ) { ... }
    $notice->setNotice ($attribs);

=head1 DESCRIPTION

Notify::Notice encapsulates notification data.
The object provides methods for retreiving and settings
the attributes as well as listing the currently supported
attribs.

The notification object also export the following constants
and can be in the following states:

    EMPTY  - The notice object is currently in the empty state.

    OUTGOING_PENDING - The notice object is waiting to be sent.

    WAITING_REPONSE - The notice has been sent and is in a wait
                      state.

    WAITING_PROCESSING - A response has been received for the
                         notice and awaits retrieval.

    FAILURE - The notice could not be successfully sent.

    DONE - The transaction is completed and is halted until the
           state is futher changed or the notification object
           destroyed.

=head2 EXPORT

    This module exports the constants listed in the description:

       ( EMPTY, OUTGOING_PENDING, WAITING_RESPONSE,
         WAITING_PROCESSING, FAILURE, DONE )

=head2 CLASS ATTRIBUTES

    This class defines the following attributes in its external
    function which can be retrieved through a hash ref via
    the getNotice () method:

       status - The current status of the notification object.
                Takes on the value of the value of one of the
                above constants.

       attempts - The number of attempts made to send this
                  notification.

       id - The unique id of the notification.

       src - The sender of the notification.

       dest - The intended receiver of the notification.

       message - The message to deliver to the receiver.

       transport - The transport type to use to deliver this
                   object. A transport object of some sort
                   needs to be associated with this type and
                   must know how to deliver the notification
                   accordingly.

       time_created - The time the notification was created.

       time_updated - The time the notificationw as last
                      updated.

       history - An array containing the history of
                 notifications and responses.

=head2 PUBLIC METHODS

    new ($hashref)

      The constructor builds a new notification object and
      copies over any attribute values found in the $hashref
      into the internal attribute structure.

    attribs ()

      Returns an array of keys to the notification attribute
      hash.

    getNotice ()

      Returns a reference to a *copy* of the internal
      attribute hash. To iterate through the keys, use
      attribs ().

   setNotice ($attribs)

      Copies the new attributes into the internal copy. All
      non-supported keys are dropped.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu>
Copyright (C) 2001

=head1 SEE ALSO

perl (1), Notify::NoticePool, Notify::Email

=head1 VERSION

  This software is currently alpha, version 0.0.1.

=cut
