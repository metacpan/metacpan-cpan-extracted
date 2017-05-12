package Net::GrowlClient;

use 5.006000;
use strict;
use warnings;
use IO::Socket;
use Digest::MD5 qw( md5_hex );
use Digest::SHA qw( sha256_hex );
use utf8;
use Carp;
require Exporter;
our @ISA = ("Exporter");
our @EXPORT = qw(notify $VERSION @ISA);
our $VERSION = '0.02';

##############################################
##    CONSTANTS
##############################################
use constant GROWL_UDP_PORT 					=> '9887';
use constant GROWL_PROTOCOL_VERSION 			=> '1';
use constant GROWL_PROTOCOL_VERSION_AES128 		=> '2';
use constant GROWL_TYPE_REGISTRATION 			=> '0';
use constant GROWL_TYPE_NOTIFICATION 			=> '1';
use constant GROWL_TYPE_REGISTRATION_SHA256 	=> '2';
use constant GROWL_TYPE_NOTIFICATION_SHA256 	=> '3';
use constant GROWL_TYPE_REGISTRATION_NOAUTH 	=> '4';
use constant GROWL_TYPE_NOTIFICATION_NOAUTH 	=> '5';

use constant CLIENT_DEFAULT_APPNAME				=> 'Net::GrowlClient';
use constant CLIENT_DEFAULT_NOTIFICATION_LIST	=> ['Net::GrowlClient Notification'];
use constant CLIENT_DEFAULT_NOTIFICATION		=> CLIENT_DEFAULT_NOTIFICATION_LIST->[0];
use constant CLIENT_DEFAULT_TITLE				=> 'Hello from Net::GrowlClient!';
use constant CLIENT_DEFAULT_MESSAGE				=> "Yeah! It Works!\nThis is the default message.";
use constant CLIENT_DEFAULT_PRIORITY			=> 0;
use constant FALSE								=> 0;
use constant TRUE								=> 1;

##############################################
##    CONSTRUCTOR
##############################################
sub init
{
	my $caller = shift;
	my $class = ref($caller) || $caller;
	my $self = 	{ 
			'CLIENT_PASSWORD'			=> FALSE,
			'CLIENT_PEER_HOST'			=> FALSE,	
			'CLIENT_PEER_PORT'			=> FALSE,
			'CLIENT_STICKY'				=> FALSE,
			'CLIENT_SKIP_REGISTER'		=> FALSE,
			'CLIENT_CRYPT'				=> FALSE,
			'CLIENT_APPLICATION_NAME'	=> CLIENT_DEFAULT_APPNAME,
			'CLIENT_NOTIFICATION_LIST'	=> CLIENT_DEFAULT_NOTIFICATION_LIST,
			'CLIENT_TYPE_REGISTRATION'	=> GROWL_TYPE_REGISTRATION_NOAUTH,
			'CLIENT_TYPE_NOTIFICATION'	=> GROWL_TYPE_NOTIFICATION_NOAUTH,
			'CLIENT_NOTIFICATION'		=> CLIENT_DEFAULT_NOTIFICATION,
			'CLIENT_TITLE'				=> CLIENT_DEFAULT_TITLE,
			'CLIENT_MESSAGE'			=> CLIENT_DEFAULT_MESSAGE,
			'CLIENT_PRIORITY'			=> CLIENT_DEFAULT_PRIORITY,
			@_
			};

	bless($self, $class);
	&_init($self);
	&_register($self) unless $self->{'CLIENT_SKIP_REGISTER'};
	return $self;
}

##############################################
##    INITIALIZE UDP SOCKET 
##############################################
sub _init
{
	my $self = shift;
	$self->{'CLIENT_SOCKET'} = IO::Socket::INET->new	
										(
										PeerPort	=> $self->{'CLIENT_PEER_PORT'} || GROWL_UDP_PORT,
										PeerHost  	=> $self->{'CLIENT_PEER_HOST'} || 'localhost',
										Proto     	=> 'udp',
										Type		=> SOCK_DGRAM,
										ReuseAddr	=> 1
										) or croak __PACKAGE__." --> $@";
}

##############################################
##    REGISTER
##############################################
sub _register
{
	use bytes;
	my $self = shift;
	my ($data, $ckecksum, $notification_pack, $default_pack, $packet, $checksum);
	my $notification_list_ptr = $self->{'CLIENT_NOTIFICATION_LIST'};
	my $application_name = $self->{'CLIENT_APPLICATION_NAME'};
	my $password = $self->{'CLIENT_PASSWORD'};
	utf8::encode($password);
	utf8::encode($application_name);

	foreach my $notification ( @$notification_list_ptr )
	{
		utf8::encode($notification);
		$notification_pack .= pack 	(
									'na*', 
									bytes::length($notification), 
									$notification
									);
	}
	foreach my $default_notification (0..scalar @$notification_list_ptr - 1)
	{
		$default_pack .= pack('C', $default_notification);
	}

	$data = pack 	(
					'CCnCC', 
					GROWL_PROTOCOL_VERSION, 
					$self->{'CLIENT_TYPE_REGISTRATION'}, 
					bytes::length($application_name), 
					(scalar @$notification_list_ptr), 
					(scalar @$notification_list_ptr)
					);
	$data .= pack ('a*', $application_name);
	$data .= $notification_pack . $default_pack;

	if ($self->{'CLIENT_TYPE_REGISTRATION'} eq GROWL_TYPE_REGISTRATION)
	{
		$checksum = pack ('H32', md5_hex($data . $password));
		$packet = $data . $checksum;
	}
	elsif ($self->{'CLIENT_TYPE_REGISTRATION'} eq GROWL_TYPE_REGISTRATION_SHA256)
	{
		$checksum = pack ('H64', sha256_hex($data . $password));
		$packet = $data . $checksum;
	}
	else
	{
		$packet = $data;
	}

	&_sender($self, $packet);
}

##############################################
##    NOTIFY
##############################################
sub notify
{
	use bytes;
	my $self = shift;
	my %notify_args = @_;
	my ($notification_name, $title, $message, $application_name, $checksum, $data, $packet, $priority, $flags, $sticky, $password);
	my %priority = 	(
						"-2" 		=> "011",
						"Low" 		=> "011",
						"Very Low"	=> "011",
						"-1" 		=> "111",
						"Moderate"	=> "111",
						"0"			=> "000",
						"Normal"	=> "000",
						"1"			=> "100",
						"High"		=> "100",
						"2"			=> "010",
						"Emergency"	=> "010"
	);
						
	$password = $self->{'CLIENT_PASSWORD'};utf8::encode($password);
	$application_name = $notify_args{'application'} || $self->{'CLIENT_APPLICATION_NAME'};utf8::encode($application_name);
	$notification_name = $notify_args{'notification'} || $self->{'CLIENT_NOTIFICATION'};utf8::encode($notification_name);
	$title = $notify_args{'title'} || $self->{'CLIENT_TITLE'};utf8::encode($title);
	$message = $notify_args{'message'} || $self->{'CLIENT_MESSAGE'};utf8::encode($message);
	$sticky = $notify_args{'sticky'} || $self->{'CLIENT_STICKY'};
	
	if (($notify_args{'priority'}) and (grep (/^$notify_args{'priority'}$/, keys %priority)))
	{
		$priority = $priority{$notify_args{'priority'}};
	}
	else
	{
		$priority = $self->{'CLIENT_PRIORITY'};
		carp __PACKAGE__." --> Unknown Priority \'$notify_args{'priority'}\'" if ($notify_args{'priority'});
	}
	
	$flags = '0'x12 .$priority.$sticky;
	
	$data = pack (		'CCb[16]nnnna*', 
						GROWL_PROTOCOL_VERSION, 
						$self->{'CLIENT_TYPE_NOTIFICATION'}, 
						$flags, 
						bytes::length($notification_name), 
						bytes::length($title), 
						bytes::length($message), 
						bytes::length($application_name), 
						"$notification_name$title$message$application_name"
						);

	if ($self->{'CLIENT_TYPE_NOTIFICATION'} eq GROWL_TYPE_NOTIFICATION)
	{
		$checksum = pack ('H32', md5_hex($data . $password));
		$packet = $data . $checksum;
	}
	elsif ($self->{'CLIENT_TYPE_NOTIFICATION'} eq GROWL_TYPE_NOTIFICATION_SHA256)
		{
		$checksum = pack ('H64', sha256_hex($data . $password));
		$packet = $data . $checksum;
	}
	else
	{
		$packet = $data;
	}

	&_sender($self, $packet);
}
##############################################
##    DATA CRYPT (AES128)
##############################################
sub _aescrypt
{
	my $self=shift;
	my $packet;
	return $packet;
}
##############################################
##    SOCKET PRINTER
##############################################
sub _sender
{
	my $self = shift;
	my $packet = shift;
	$self->{'CLIENT_SOCKET'}->send($packet) or carp __PACKAGE__." --> $@";
}

##############################################
##    DESTRUCTOR
###############################################
sub DESTROY
{
	#Still thinking about what I could insert here;
}
1;

__END__

=head1 NAME

Net::GrowlClient - Perl implementation of Growl Network Notification Protocol (Client Part)

=head1 SYNOPSIS

	use Net::GrowlClient;

=head1 DESCRIPTION

C<Net::GrowlClient> provides an object interface to register applications and/or send notifications to Growl Servers using udp protocol. 

=head1 CONSTRUCTOR

=over 4

=item init ( [ARGS] )

Initialize a C<Net::GrowlClient> Application with a Growl Server target.
The constructor takes arguments, these arguments are in key-value pairs.

There is two groups of parameters, protocol parameters and registration parameters.

Protocols parameters are:

 CLIENT_PEER_HOST	Remote server address or name
 CLIENT_PEER_PORT	Remote UDP port to use
 CLIENT_PASSWORD 	Server password (if needed)
 CLIENT_CRYPT 		Determine if we AES128 encrypt (boolean) (NOT IMPLEMENTED IN v < 0.10)
 CLIENT_TYPE_REGISTRATION Determine if we authenticate and how (0 md5 2 sha 4 noauth)
 CLIENT_TYPE_NOTIFICATION Determine if we authenticate and how (1 md5 3 sha 5 noauth)

Registering an application within a Growl Server consist to tell the Server who we are, 
ie the name of the application, and what kind of message we will use.
As an example, the application "NetMonitor.pl" would register as "Perl NetMonitor" and tell the server
that it will use "Standard Message" and "Alert Message" as kind of notifications.

Registering the application is implicit (Constructor does it) but may be avoided if 
the application has already been registered within the Growl Server.

Registering parameters are:

 CLIENT_APPLICATION_NAME	Name to register
 CLIENT_NOTIFICATION_LIST	List of notification type (A Reference to an array) 
 CLIENT_SKIP_REGISTER		Do or Do not Register flag (boolean)

You can also define some global notify() options wich could be override with the notify() method

 CLIENT_TITLE		Notification title
 CLIENT_STICKY		Sticky flag (boolean)
 CLIENT_NOTIFICATION	Default Notification to use
 CLIENT_MESSAGE		Message
 CLIENT_PRIORITY 	Priority flag 

=back

=head1 METHOD

=over 4

=item notify(args)

Once the object initialized, you can start sending notifications to the server with this method.
A Notification has a title and a message witch is related to one of the different kind of messages defined in 
the constructor. It also has a priority and a sticky flag. Priority is a value from -2 to 2, 0 is a normal priority.
Sticky notifications does not desappear themselves on the server screen and needs a user interaction, this could be
useful for important messages. But take care about not all notification display styles support sticky notification.
As an example the default Bezel style doesn't.

Parameters:

 application	Application name #Be careful and see below
 title		The title 
 message	The message
 priority	Priority flag
 sticky		Sticky flag
 notification	Kind of notification to use

=back

=head1 DEFAULT VALUES

Default values should be overwritten but some exists:

 CLIENT_TYPE_REGISTRATION	=> 4 #noauth
 CLIENT_TYPE_NOTIFICATION	=> 5 #noauth
 CLIENT_CRYPT			=> FALSE #Do not crypt ( AES128 is NOT IMPLEMENTED IN v < 0.10)
 CLIENT_PASSWORD		=> '' #nullstring <=> nopassword
 CLIENT_PEER_HOST 		=> 'localhost'
 CLIENT_PEER_PORT		=> 9887
 CLIENT_APPLICATION_NAME	=> 'Net::GrowlClient'
 CLIENT_NOTIFICATION_LIST	=> ['Net::GrowlClient Notification']
 CLIENT_NOTIFICATION		=> First element of CLIENT_NOTIFICATION_LIST 
 CLIENT_DEFAULT_TITLE		=> 'Hello from Net::GrowlClient!'
 CLIENT_DEFAULT_MESSAGE		=> "Yeah! It Works!\nThis is the default message."
 CLIENT_STICKY			=> FALSE
 CLIENT_SKIP_REGISTER		=> FALSE
 CLIENT_PRIORITY		=> 0 #Normal 

Notify Method use object parameters. They could be overwritten but keep in mind that application name 
and the notification list needs to be registered in order to be used with the notify() method.

=head1 COMMON USAGE

Usually, you just want to see your message on the server screen and don't care about wich application 
is sending the message. In this case You just have to set a GrowlClient object which use the default values.
The identity will be 'Net::GrowlClient' and the notification 'Net::GrowlClient Notification'.
This is the minimal but sufficient usage.

 use Net::GrowlClient;

 my $growl = Net::GrowlClient->init(
	'CLIENT_PEER_HOST'	=> 'server.example.com'
	) or die "$!\n";

 $growl->notify(
	'title'	=> 'Notification title',
	'message'	=> "first line\nsecond line"
	);

=head1 ADVANCED USAGE

Using advanced features alow your application to have its own identity and notification list.
This make possible to set specific preferences for this application in the Growl Control Panel on the server.

This example create a GrowlClient object for the application "Foo" with the server "server.example.com" using md5 auth.
Register this application 'Foo' with its notification list.
Send a sticky notification to with tho highest priority.

 use Net::GrowlClient;

 my $growl = Net::GrowlClient->init(
	'CLIENT_TYPE_REGISTRATION'	=> 0, #md5 auth
	'CLIENT_TYPE_NOTIFICATION'	=> 1, #md5 auth
	'CLIENT_CRYPT'			=> 0, #Do not crypt 
	'CLIENT_PASSWORD'		=> 'secret',
	'CLIENT_PEER_HOST' 		=> 'server.example.com',
	'CLIENT_APPLICATION_NAME'	=> 'Foo',
	'CLIENT_NOTIFICATION_LIST'	=> ['Foo Normal', 'Foo Alert'] #The default is the first 'Foo Normal'.
	) or die "$!\n";

 $growl->notify(
	'title' 	=> 'Notification title',
	'message' 	=> "first line\nsecond line",
	'notification'	=> 'Foo Alert', #Specify we do not use the default notification.
	'priority' 	=> 2,
	'sticky' 	=> 1
	);

This example create a GrowlClient object for one or more application with are already registered and send
messages to the server from Application 1 and Application 2.
This use sha256 auth method.

use Net::GrowlClient;

 my $growl = Net::GrowlClient->init(
	'CLIENT_TYPE_REGISTRATION'	=> 2, #sha auth
	'CLIENT_TYPE_NOTIFICATION'	=> 3, #sha auth
	'CLIENT_PASSWORD'		=> 'secret',
	'CLIENT_PEER_HOST' 		=> 'server.example.com',
	) or die "$!\n";
	
 $growl->notify(
	'title' 	=> 'Notification title',
	'message' 	=> "first line\nsecond line",
	'notification'	=> 'An Application 1 Notification',
	'application'	=> 'Application 1 wich is registered'
	);

 $growl->notify(
	'title' 	=> 'Notification title',
	'message' 	=> "first line\nsecond line",
	'notification'	=> 'An Application 2 Notification', 
	'application'	=> 'Application 2 wich is registered'
	);

=head1 MISSING THINGS

There is still some capabilities missing in this growl network client protocol implementation.

=over 4

=item

 Enabling fine registering of default notification list instead of all as default.( expect v 0.05 )

=item

 Implementation of AES128 Crypting ( expect v 0.10 )

=back

=head1 AUTHOR

Raphael Roulet. 
Please report all bugs to <modules@perl-auvergne.com> or <castor@cpan.org>.