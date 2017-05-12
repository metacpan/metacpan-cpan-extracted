package Notify::Email;

require 5.00503;
use strict;
use Carp;
use Mail::Box::Manager;
use Mail::Sender;

require Exporter;

our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'all' => [qw( )] );
our @EXPORT_OK = ( );
our @EXPORT = ( );
#our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
our $VERSION = '0.0.1';

use constant DEFAULT_SMTP_HOST => 'localhost';

sub new {

	my ($self, $options) = @_;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

	# Sanity checking on options
	confess "Attempted to create Email notification object without registering the application name."
		unless exists $options->{'app'};

	$this->{'__CONFIG'} = $options;
	$this->init ();

	return $this;

} #end sub new

sub init {

	my ($self, $options) = @_;

	$self->{'__MAILBOX'} = Mail::Box::Manager->new
		or confess "Error creating mail box manager object: $!";

	$self->{'__CONFIG'}->{'mbox'} = ($self->{'__CONFIG'}->{'mbox'})
		? $self->{'__CONFIG'}->{'mbox'} : $ENV{'MAIL'};

	# Note we don't check for success here but check before we are
	# about to receive. This is because it's inappropriate to bomb
	# during the init
	$self->{'__FOLDER'} = $self->{'__MAILBOX'}->open (
		'folder' => $self->{'__CONFIG'}->{'mbox'},
		'type' => 'mbox',
		'access' => "rw",
	);

} #end sub init

sub send {

	my ($self, $notice) = @_;
	my ($smtp, $sender);
	my $notice_attribs = $notice->getNotice ();

	$smtp = ($self->{'__CONFIG'}->{'smtp'})
		? $self->{'__CONFIG'}->{'smtp'} : DEFAULT_SMTP_HOST;

	ref ($sender = new Mail::Sender ({
		'smtp' => $smtp,
		'from' => $notice_attribs->{'src'},
	})) or confess "Error creating outgoing mail object: $!";

	my $subject = "[" . $self->{'__CONFIG'}->{'app'} . " Notification] #" . $notice_attribs->{'id'};

	$sender->MailMsg ({
		'from'    => $notice_attribs->{'src'},
		'to'      => $notice_attribs->{'dest'},
		'smtp'    => $smtp,
		'subject' => $subject,
		'msg'     => $notice_attribs->{'message'},
	}) or return undef;

	return 1;

} #end sub send

sub receive {

	my ($self, $notice) = @_;
	my $notice_attribs = $notice->getNotice ();

	# It's possible the mbox may be removed if its empty. So just
	# return undef.
	return undef unless $self->{'__FOLDER'};

	# If we end with a negative num, then we haven't found any msgs
	# with our notification number
	my $lastindex = -1;
	for (my $i = 0; $i < $self->{'__FOLDER'}->messages (); $i++ ) {

		my $msg = $self->{'__FOLDER'}->message ($i);

		my $subject = $msg->head->get('subject');
		chomp ($subject);

		# Check if the subject matches the notification string
		if ($subject =~ /^.*(Re:)?\s*[\s*$self->{'__CONFIG'}->{'app'}\s*Notification\s*]\s*#\s*$notice_attribs->{'id'}\s*$/i) {

			if ($lastindex < 0) {
				$lastindex = $i;
			}
			else {

				# We want the newer one and will delete the old one
				$msg = $self->{'__FOLDER'}->message ($lastindex);
				$msg->delete ();
				$lastindex = $i;

			}

		}

	}

	return undef if $lastindex < 0;
	my $msg = $self->{'__FOLDER'}->message ($lastindex);
	my $body = join ('', @{ $msg->body () });
	$msg->delete ();
	return $body;

} #end sub receive

sub DESTROY {

	my ($self) = @_;

	$self->{'__FOLDER'}->close ()
		if $self->{'__FOLDER'};

}

1;

__END__

=head1 NAME

Notify::Email - Implements a transport object in accordance with
                interface defined in Notify::NoticePool.

=head1 SYNOPSIS

    use Notify::Email

    my $transport = new Notify::Email ({
       'app'  => "Application name",
       'mbox' => "Path to unix mail box",
       'smtp' => "smtp@domain.com",
    });

    my $notice = new Notify::Notice;

    $transport->send ($notice);
    my $response = $transport->receive ($notice);

=head1 DESCRIPTION

This module implements the transport object interface as defined in
Notify::NoticePool for communication over email. Mail delivery is done
via SMTP and mail reception is done via unix-style mailbox.

=head2 EXPORT

None.

=head2 PUBLIC METHODS

  new ($hashref)

    The email transport object takes a hashref that supports the
    following keys:

      Required:

        'app' - The name of the calling application. Used in
                constructing the notification subject.

      Optional:

        'smtp' - The SMTP server to use for outgoing mail.
                 Defaults to localhost.

        'mbox' - The unix-style mailbox to use for receiving mail.
                 Defaults to /var/spool/mail/`whoami`.

  send ($notice)

    Attempts to send an email to the 'dest' attribute of the
    notification object. Returns 1 on success or undef.

  recieve ($notice)

    Attempts to receive a response for a notification object.
    Returns the body of the response email or undef if not
    successful.

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu>
Copyright (C) 2001

perl (1), Notify::Notice, Notify::NoticePool

=head1 VERSION

  This software is currently alpha, version 0.0.1.

=cut
