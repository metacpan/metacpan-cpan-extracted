package Net::ICQ;


use strict;
use vars qw(
  $VERSION
  @_table
  %cmd_codes %srv_codes
  %status_codes %privacy_codes
  %meta_codes %sex_codes %occupations %languages
  %_parsers %_msg_parsers %_meta_parsers
  %_builders %_msg_builders
);
use Carp;
use IO::Socket;
use IO::Select;
use Time::Local;
use Math::BigInt;

$VERSION = '0.16';


# "encryption" table (grumble grumble...)
@_table = (
 0x59, 0x60, 0x37, 0x6B, 0x65, 0x62, 0x46, 0x48,
 0x53, 0x61, 0x4C, 0x59, 0x60, 0x57, 0x5B, 0x3D,
 0x5E, 0x34, 0x6D, 0x36, 0x50, 0x3F, 0x6F, 0x67,
 0x53, 0x61, 0x4C, 0x59, 0x40, 0x47, 0x63, 0x39,
 0x50, 0x5F, 0x5F, 0x3F, 0x6F, 0x47, 0x43, 0x69,
 0x48, 0x33, 0x31, 0x64, 0x35, 0x5A, 0x4A, 0x42,
 0x56, 0x40, 0x67, 0x53, 0x41, 0x07, 0x6C, 0x49,
 0x58, 0x3B, 0x4D, 0x46, 0x68, 0x43, 0x69, 0x48,
 0x33, 0x31, 0x44, 0x65, 0x62, 0x46, 0x48, 0x53,
 0x41, 0x07, 0x6C, 0x69, 0x48, 0x33, 0x51, 0x54,
 0x5D, 0x4E, 0x6C, 0x49, 0x38, 0x4B, 0x55, 0x4A,
 0x62, 0x46, 0x48, 0x33, 0x51, 0x34, 0x6D, 0x36,
 0x50, 0x5F, 0x5F, 0x5F, 0x3F, 0x6F, 0x47, 0x63,
 0x59, 0x40, 0x67, 0x33, 0x31, 0x64, 0x35, 0x5A,
 0x6A, 0x52, 0x6E, 0x3C, 0x51, 0x34, 0x6D, 0x36,
 0x50, 0x5F, 0x5F, 0x3F, 0x4F, 0x37, 0x4B, 0x35,
 0x5A, 0x4A, 0x62, 0x66, 0x58, 0x3B, 0x4D, 0x66,
 0x58, 0x5B, 0x5D, 0x4E, 0x6C, 0x49, 0x58, 0x3B,
 0x4D, 0x66, 0x58, 0x3B, 0x4D, 0x46, 0x48, 0x53,
 0x61, 0x4C, 0x59, 0x40, 0x67, 0x33, 0x31, 0x64,
 0x55, 0x6A, 0x32, 0x3E, 0x44, 0x45, 0x52, 0x6E,
 0x3C, 0x31, 0x64, 0x55, 0x6A, 0x52, 0x4E, 0x6C,
 0x69, 0x48, 0x53, 0x61, 0x4C, 0x39, 0x30, 0x6F,
 0x47, 0x63, 0x59, 0x60, 0x57, 0x5B, 0x3D, 0x3E,
 0x64, 0x35, 0x3A, 0x3A, 0x5A, 0x6A, 0x52, 0x4E,
 0x6C, 0x69, 0x48, 0x53, 0x61, 0x6C, 0x49, 0x58,
 0x3B, 0x4D, 0x46, 0x68, 0x63, 0x39, 0x50, 0x5F,
 0x5F, 0x3F, 0x6F, 0x67, 0x53, 0x41, 0x25, 0x41,
 0x3C, 0x51, 0x54, 0x3D, 0x5E, 0x54, 0x5D, 0x4E,
 0x4C, 0x39, 0x50, 0x5F, 0x5F, 0x5F, 0x3F, 0x6F,
 0x47, 0x43, 0x69, 0x48, 0x33, 0x51, 0x54, 0x5D,
 0x6E, 0x3C, 0x31, 0x64, 0x35, 0x5A, 0x00, 0x00,
);


%cmd_codes = (
  CMD_ACK                 => 10,
  CMD_SEND_MESSAGE        => 270,
  CMD_LOGIN               => 1000,
  CMD_REG_NEW_USER        => 1020,
  CMD_CONTACT_LIST        => 1030,
  CMD_SEARCH_UIN          => 1050,
  CMD_SEARCH_USER         => 1060,
  CMD_KEEP_ALIVE          => 1070,
  CMD_SEND_TEXT_CODE      => 1080,
  CMD_ACK_MESSAGES        => 1090,
  CMD_LOGIN_1             => 1100,
  CMD_MSG_TO_NEW_USER     => 1110,
  CMD_INFO_REQ            => 1120,
  CMD_EXT_INFO_REQ        => 1130,
  CMD_CHANGE_PW           => 1180,
  CMD_NEW_USER_INFO       => 1190,
  CMD_UPDATE_EXT_INFO     => 1200,
  CMD_QUERY_SERVERS       => 1210,
  CMD_QUERY_ADDONS        => 1220,
  CMD_STATUS_CHANGE       => 1240,
  CMD_NEW_USER_1          => 1260,
  CMD_UPDATE_INFO         => 1290,
  CMD_AUTH_UPDATE         => 1300,
  CMD_KEEP_ALIVE2         => 1310,
  CMD_LOGIN_2             => 1320,
  CMD_ADD_TO_LIST         => 1340,
  CMD_RAND_SET            => 1380,
  CMD_RAND_SEARCH         => 1390,
  CMD_META_USER           => 1610,
  CMD_INVIS_LIST          => 1700,
  CMD_VIS_LIST            => 1710,
  CMD_UPDATE_LIST         => 1720
);


%srv_codes = (
  SRV_ACK                 => 10,
  SRV_GO_AWAY             => 40,
  SRV_NEW_UIN             => 70,
  SRV_LOGIN_REPLY         => 90,
  SRV_BAD_PASS            => 100,
  SRV_USER_ONLINE         => 110,
  SRV_USER_OFFLINE        => 120,
  SRV_QUERY               => 130,
  SRV_USER_FOUND          => 140,
  SRV_END_OF_SEARCH       => 160,
  SRV_NEW_USER            => 180,
  SRV_UPDATE_EXT          => 200,
  SRV_RECV_MESSAGE        => 220,
  SRV_X2                  => 230,
  SRV_NOT_CONNECTED       => 240,
  SRV_TRY_AGAIN           => 250,
  SRV_SYS_DELIVERED_MESS  => 260,
  SRV_INFO_REPLY          => 280,
  SRV_INFO_FAIL           => 300,
  SRV_EXT_INFO_REPLY      => 290,
  SRV_STATUS_UPDATE       => 420,
  SRV_SYSTEM_MESSAGE      => 450,
  SRV_UPDATE_SUCCESS      => 480,
  SRV_UPDATE_FAIL         => 490,
  SRV_AUTH_UPDATE         => 500,
  SRV_MULTI_PACKET        => 530,
  SRV_X1                  => 540,
  SRV_RAND_USER           => 590,
  SRV_META_USER           => 990
);



%status_codes = (
  ONLINE                  => 0x0000,
  AWAY                    => 0x0001,
  DO_NOT_DISTURB_2        => 0x0002,
  NOT_AVAILABLE           => 0x0004,
  NOT_AVAILABLE_2         => 0x0005,
  OCCUPIED                => 0x0010,
  DO_NOT_DISTURB          => 0x0013,
  FREE_FOR_CHAT           => 0x0020,
  INVISIBLE               => 0x0100
);

%privacy_codes = (
  WEB_AWARE               => 0x0001,
  SHOW_IP                 => 0x0002,
  TCP_MUST_AUTH           => 0x1000,
  TCP_IF_ON_CONNECTLIST   => 0x2000
);

%meta_codes = (
  GENERAL_INFO        => 0x03E9,
  WORK_INFO           => 0x03F3,
  MORE_INFO           => 0x03FD,
  ABOUT_INFO          => 0x0406,
);

%sex_codes = (
  "UNSPECIFIED"           => 0,
  "FEMALE"                => 1,
  "MALE"                  => 2
);

%occupations = (
  "Academic"                     => 1,
  "Administrative"               => 2,
  "Art/Entertainment"            => 3,
  "College Student"              => 4,
  "Computers"                    => 5,
  "Community & Social"           => 6,
  "Education"                    => 7,
  "Engineering"                  => 8,
  "Financial Services"           => 9,
  "Government"                   => 10,
  "High School Student"          => 11,
  "Home"                         => 12,
  "ICQ - Providing Help"         => 13,
  "Law"                          => 14,
  "Managerial"                   => 15,
  "Manufacturing"                => 16,
  "Medical/Health"               => 17,
  "Military"                     => 18,
  "Non-Government Organization"  => 19,
  "Professional"                 => 20,
  "Retail"                       => 21,
  "Retired"                      => 22,
  "Science & Research"           => 23,
  "Sports"                       => 24,
  "Technical"                    => 25,
  "University Student"           => 26,
  "Web Building"                 => 27,
  "Other Services"               => 99,
);

%languages = (
  1   => 'Arabic',
  2   => 'Bhojpuri',
  3   => 'Bulgarian',
  4   => 'Burmese',
  5   => 'Cantonese',
  6   => 'Catalan',
  7   => 'Chinese',
  8   => 'Croatian',
  9   => 'Czech',
  10  => 'Danish',
  11  => 'Dutch',
  12  => 'English',
  13  => 'Esperanto',
  14  => 'Estonian',
  15  => 'Farsi',
  16  => 'Finnish',
  17  => 'French',
  18  => 'Gaelic',
  19  => 'German',
  20  => 'Greek',
  21  => 'Hebrew',
  22  => 'Hindi',
  23  => 'Hungarian',
  24  => 'Icelandic',
  25  => 'Indonesian',
  26  => 'Italian',
  27  => 'Japanese',
  28  => 'Khmer',
  29  => 'Korean',
  30  => 'Lao',
  31  => 'Latvian',
  32  => 'Lithuanian',
  33  => 'Malay',
  34  => 'Norwegian',
  35  => 'Polish',
  36  => 'Portuguese',
  37  => 'Romanian',
  38  => 'Russian',
  39  => 'Serbian',
  40  => 'Slovak',
  41  => 'Slovenian',
  42  => 'Somali',
  43  => 'Spanish',
  44  => 'Swahili',
  45  => 'Swedish',
  46  => 'Tagalog',
  47  => 'Tatar',
  48  => 'Thai',
  49  => 'Turkish',
  50  => 'Ukrainian',
  51  => 'Urdu',
  52  => 'Vietnamese',
  53  => 'Yiddish',
  54  => 'Yoruba',
  55  => 'Afrikaans',
  56  => 'Bosnian',
  57  => 'Persian',
  58  => 'Albanian',
  59  => 'Armenian',
  60  => 'Punjabi',
  61  => 'Chamorro',
  62  => 'Mongolian',
  63  => 'Mandarin',
  64  => 'Taiwaness',
  65  => 'Macedonian',
  66  => 'Sindhi',
  67  => 'Welsh',
  68  => 'Azerbaijani',
  69  => 'Kurdish',
  70  => 'Gujarati',
  71  => 'Tamil',
  72  => 'Belorussian',
  73  => 'Unknown',
);

=head1 NAME

Net::ICQ - Pure Perl interface to an ICQ server

=head1 SYNOPSIS

  use Net::ICQ;

  $icq = Net::ICQ->new($uin, $password);
  $icq->connect();

  $icq->add_handler('SRV_SYS_DELIVERED_MESS', \&on_msg);

  $params = {
    'type'         => 1,
    'text'         => 'Hello world',
    'receiver_uin' => 1234
  };
  $icq->send_event('CMD_SEND_MESSAGE', $params);

  $icq->start();

=head1 DESCRIPTION

C<Net::ICQ> is a class implementing an ICQ client interface
in pure Perl.

=cut

=head1 CONSTRUCTOR

=over 4

=item *

new (uin, password [, server [, port]])

Creates a new Net::ICQ object.  A Net::ICQ object represents
a single user logged into a specific ICQ server.  The UIN and
password to use are specified as the first two parameters.
Server and port are optional, and default to
'icq.mirabilis.com' and '4000', respectively.

Also, environment variables will be checked as follows:

  uin      - ICQ_UIN
  password - ICQ_PASS
  server   - ICQ_SERVER
  port     - ICQ_PORT

Constructor parameters have the highest priority, then environment
variables.  The built-in defaults (for server and port only) have
the lowest priority.

If either a UIN or password is not provided either directly or
through environment variables, new() will return undef.

Note that after calling new() you must next call connect() before
you can send and receive ICQ events.

=back

=cut

sub new {
  my ($class, $uin, $password, $server, $port) = @_;
  my ($params);

  $uin or $uin = $ENV{ICQ_UIN} or return;
  $password or $password = $ENV{ICQ_PASS} or return;
  $server or $server = $ENV{ICQ_SERVER} or $server = 'icq.mirabilis.com';
  $port or $port = $ENV{ICQ_PORT} or $port = 4000;

  my $self = {
    _uin => $uin,
    _password => $password,
    _server => $server,
    _port => $port,
    _socket => undef,
    _select => undef,
    _events_incoming => [], # array
    _events_outgoing => [],
    _acks_incoming   => [], # acks are processed immediately, so they get their own array
    _acks_outgoing   => [],
    _handlers => {},
    _last_keepalive => undef,
    _seen_seq => [],
    _debug => 0
  };

  $self->{_socket} = IO::Socket::INET->new(
    Proto => 'udp',
    PeerAddr => $self->{_server},
    PeerPort => $self->{_port},
  )
    or croak("socket error: $@");

  $self->{_select} = IO::Select->new($self->{_socket});
  $self->{_last_keepalive} = time();

  bless($self, $class);

  return $self;
}


=head1 METHODS

All of the following methods are instance methods;
you must call them on a Net::ICQ object (for example, $icq->start).

=over 4

=item *

connect

Connects the Net::ICQ object to the server.

=cut

sub connect {
  my ($self) = @_;

  $self->{_session_id} = int(rand(0xFFFFFFFF));
  $self->{_seq_num_1}  = int(rand(0xFFFF));
  $self->{_seq_num_2}  = 0x1;
  $self->{_connected}  = 1;

  # send a login event
  my $params = {
    password => $self->{_password},
    client_ip => $self->{_socket}->sockaddr(),
    # FIX: deal with client_port correctly when TCP communication is implemented
    client_port => 0
  };
  $self->send_event('CMD_LOGIN', $params, 1);

}


=item *

disconnect

Disconnects the Net::ICQ object from the server.

=cut

sub disconnect {
  my ($self) = @_;

  $self->send_event('CMD_SEND_TEXT_CODE', {text_code => 'B_USER_DISCONNECTED'}, 1);
  $self->_do_outgoing();
  $self->{_connected} = 0;
}


=item *

connected

Returns true if the Net::ICQ object is connected to the server,
and false if it is not.

=cut

sub connected {
  my ($self) = @_;

  return $self->{_connected};
}


=item *

start

If you're writing a fairly simple application that doesn't need to
interface with other event-loop-based libraries, you can just call
start() to begin communicating with the server.

Note that start() will not return until the Net::ICQ object is
disconnected from the server, either by the server itself or by
your event-handler code calling disconnect().

=cut

sub start {
  my ($self) = @_;

  while ($self->connected) {
    $self->do_one_loop();
  }
}


=item *

do_one_loop

If you don't want to (or can't) call the start() method, you must
continuously call do_one_loop when your Net::ICQ object
is connected to the server.  It uses select() to wait for
data from the server and other ICQ clients, so it won't use
CPU power even if you call it in a tight loop.  If you need
to do other processing, you could call do_one_loop as
infrequently as once every few seconds.

This method does one processing loop, which involves looking
for incoming data from the network, calling registered event
handlers, sending acknowledgements for received packets,
transmitting outgoing data over the network, and sending
keepalives to the server to tell it that we are still online.
If it is not called often enough, you will not be notified of
incoming events in a timely fashion, or the server might even
think you have disconnected and start to ignore you.


=cut

sub do_one_loop {
  my ($self) = @_;

  $self->_do_incoming();
  $self->_do_acks();
  $self->_do_multis();
  $self->_do_keepalives();
  $self->_do_timeouts();
  $self->_do_handlers();
  $self->_do_outgoing();
}


=item *

add_handler(command_number, handler_ref)

Sets the handler function for a specific ICQ server event.
command_number specifies the event to handle.  You may use
either the numeric code or the corresponding string code.
See the SERVER EVENTS section below for the numeric and
string codes for all the events, along with descriptions
of each event's function and purpose.
handler_ref is a code ref for the sub that you want to handle
the event.  See the HANDLERS section for how a handler works
and what it needs to do.

=cut

sub add_handler {
  my ($self, $command, $sub) = @_;
  my ($command_num);

  $command_num = exists $srv_codes{$command} ?
    $srv_codes{$command} :
    $command;

  print "=== add handler <", sprintf("%04X", $command_num), "> = $sub\n"
      if $self->{_debug};

  $self->{_handlers}{$command_num} = $sub;
}


=item *

send_event(command_number, params)

Sends an event to the server.
command_number specifies the event to be sent.  You may use
either the numeric code or the corresponding string code.
See the CLIENT EVENTS section below for the numeric and
string codes for all the events, along with descriptions
of each event's function and purpose.
params is a reference to a hash containing the parameters
for the event.  See the CLIENT EVENTS section for an
explanation of the correct parameters for each event.

=cut

sub send_event {
  my ($self, $command, $params, $priority) = @_;

  $command = $cmd_codes{$command}
    if exists ($cmd_codes{$command});

  $self->_queue_event(
    {
     params  => &{$_builders{$command}}($params),
     command => $command
    },
    $priority
  );
}


=head1 CLIENT EVENTS

Client events are the messages an ICQ client, i.e. your code,
sends to the server.  They represent things such as a logon
request, a message to another user, or a user search request.
They are sometimes called 'commands' because they represent
the 'commands' that an ICQ client can execute.

When you ask Net::ICQ to send an event with send_event()
(described above), you need to provide 2 things:
the event name, and the parameters.

=head2 Event name

The event name is the first parameter to send_event(),
and it specifies which event you are sending.  You may either
specify the string code or the numeric code.  The section
CLIENT EVENT LIST below describes all the events and
gives the codes for each.  For example: when sending a
text message to a user, you may give the event name as
either the string 'CMD_SEND_MESSAGE' or the number 270.

The hash C<%Net::ICQ::cmd_codes> maps string codes to numeric
codes.  C<keys(%Net::ICQ::cmd_codes)> will produce a list of
all the string codes.

=head2 Parameters

The parameters list is the second parameter to send_event(),
and it specifies the data for the event.  Every event has
its own parameter list, but the general idea is the same.
The parameters list is stored as a hashref, where the hash
contains a key for each parameter.  Almost all the events
utilize a regular 1-level hash where the values are plain
scalars, but a few events do require 2-level hash.  The
CLIENT EVENT LIST section lists the parameters for every
client event.

For example: to send a normal text message with the text
'Hello world' to UIN 1234, the parameters would
look like this:

  {
    'type'         => 1,
    'text'         => 'Hello world',
    'receiver_uin' => 1234
  }

=head2 A complete example

Here is the complete code using send_event() to send the
message 'Hello world' to UIN 1234:

  $params = {
    'type'         => 1,
    'text'         => 'Hello world',
    'receiver_uin' => 1234
  };
  $icq->send_event('CMD_SEND_MESSAGE', $params);

=cut


%_parsers = (
  # SRV_ACK
  10 => sub {
    my ($event) = @_;
    delete $event->{params};
  },
  # SRV_GO_AWAY
  40 => sub {
    my ($event) = @_;
    delete $event->{params};
  },
  # SRV_NEW_UIN
  70 => sub {
    my ($event) = @_;
    delete $event->{params};
  },
  # SRV_LOGIN_REPLY
  90 => sub {
    my ($event) = @_;
    my ($parsedevent);

    $parsedevent->{your_ip} = _bytes_to_int($event->{params}, 12, 4);
    $event->{params}        = $parsedevent;
  },
  # SRV_BAD_PASS
  100 => sub {
    my ($event) = @_;
    delete $event->{params};
  },
  # SRV_USER_ONLINE
  110 => sub {
    my ($event) = @_;
    my ($parsedevent);

    $parsedevent->{uin}     = _bytes_to_int($event->{params}, 0, 4);
    $parsedevent->{ip}      = _bytes_to_int($event->{params}, 4, 4);
    $parsedevent->{port}    = _bytes_to_int($event->{params}, 8, 4);
    $parsedevent->{real_ip} = _bytes_to_int($event->{params}, 12, 4);
    $parsedevent->{status}  = _bytes_to_int($event->{params}, 17, 2);
    $parsedevent->{privacy} = _bytes_to_int($event->{params}, 19, 2);
    $event->{params}        = $parsedevent;
  },
  # SRV_USER_OFFLINE
  120 => sub {
    my ($event) = @_;
    my ($parsedevent);

    $parsedevent->{uin} = _bytes_to_int($event->{params}, 0, 4);
    $event->{params}    = $parsedevent;
  },
  # SRV_QUERY
  130 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_USER_FOUND
  140 => sub {
    my ($event) = @_;
    my ($parsedevent, $offset, $length);

    $parsedevent->{uin}       = _bytes_to_int($event->{params}, 0, 4);
    $offset = 4;
    foreach ('nickname', 'firstname', 'lastname', 'email') {
      $length                 = _bytes_to_int($event->{params}, $offset, 2);
      $offset += 2; # Fixed: NN 06 jan 01
      $parsedevent->{$_}      = _bytes_to_str($event->{params}, $offset, $length - 1);
      $offset += $length;
    }
    $parsedevent->{authorize} = _bytes_to_str($event->{params}, $offset, 1);
    $event->{params} = $parsedevent;

    # AUTHORIZE can contain either 00 or 01:
    #   00 means that your client should request authorization before
    #      adding this user to the contact list.
    #   01 means that authorization is not required to add him/her to
    #      your contact list.
  },
  # SRV_END_OF_SEARCH
  160 => sub {
    my ($event) = @_;
    my ($parsedevent);

    $parsedevent->{too_many} = _bytes_to_int($event->{params}, 0, 1);
    $event->{params}         = $parsedevent;
  },
  # SRV_NEW_USER
  180 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_UPDATE_EXT
  200 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_RECV_MESSAGE
  220 => sub {
    my ($event) = @_;
    my ($parsedevent, @time);

    # Remove the bytes storing the time of the message, which makes the
    # params look just like a regular online message (SRV_SYS_DELIVERED_MESS).
    # Then, we can use that handler directly instead of copying its code here.
    # Mirabilis really dropped the ball on this one, defining two separate
    # events where it should really just be one...
    @time = splice(@{$event->{params}}, 4, 6, ());
    &{$_parsers{260}}($event);

    # we still need to insert the time
    $event->{params}->{time} = timelocal(0, # sec
      _bytes_to_int(\@time, 5, 1),          # min
      _bytes_to_int(\@time, 4, 1),          # hour
      _bytes_to_int(\@time, 3, 1),          # day
      _bytes_to_int(\@time, 2, 1)-1,        # mon (thanks Bek Oberin for the -1)
      _bytes_to_int(\@time, 0, 2)           # year
    );
  },
  # SRV_X2
  230 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_NOT_CONNECTED
  240 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_TRY_AGAIN
  250 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_SYS_DELIVERED_MESS
  260 => sub {
    my ($event) = @_;
    my ($parsedevent, @strings, @tmp);

    $parsedevent->{uin}    = _bytes_to_int($event->{params}, 0, 4);
    $parsedevent->{type}   = _bytes_to_int($event->{params}, 4, 2);
    $parsedevent->{length} = _bytes_to_int($event->{params}, 6, 2);
    @strings = _bytes_to_strlist([@{$event->{params}}[8..@{$event->{params}}-1]]);
    if      ($parsedevent->{type} == 1) {
      $parsedevent->{text}        = $strings[0];
    } elsif ($parsedevent->{type} == 4) {
      $parsedevent->{description} = $strings[0];
      $parsedevent->{url}         = $strings[1];
    } elsif ($parsedevent->{type} == 6) {
      $parsedevent->{nickname}    = $strings[0];
      $parsedevent->{firstname}   = $strings[1];
      $parsedevent->{lastname}    = $strings[2];
      $parsedevent->{email}       = $strings[3];
      $parsedevent->{reason}      = $strings[4];
    } elsif ($parsedevent->{type} == 8) {
    } elsif ($parsedevent->{type} == 12) {
      $parsedevent->{nickname}    = $strings[0];
      $parsedevent->{firstname}   = $strings[1];
      $parsedevent->{lastname}    = $strings[2];
      $parsedevent->{email}       = $strings[3];
    } elsif ($parsedevent->{type} == 13) {
      $parsedevent->{name}        = $strings[0];
      $parsedevent->{unknown1}    = $strings[1];
      $parsedevent->{unknown2}    = $strings[2];
      $parsedevent->{email}       = $strings[3];
      $parsedevent->{unknown3}    = $strings[4]; #always has value: 3
      $parsedevent->{message}     = $strings[5];
    } elsif ($parsedevent->{type} == 14){
      $parsedevent->{name}        = $strings[0];
      $parsedevent->{unknown1}    = $strings[1];
      $parsedevent->{unknown2}    = $strings[2];
      $parsedevent->{email}       = $strings[3];
      $parsedevent->{unknown3}    = $strings[4]; #always has value: 3
      $parsedevent->{message}     = $strings[5];
    } elsif ($parsedevent->{type} == 19) {
      $parsedevent->{contacts} = {};
      shift @strings; # remove first element - number of contacts
      for (my $i=0; $i<@strings-1; $i+=2) {
	$parsedevent->{contacts}{$strings[$i]} = $strings[$i+1];
      }
    }

    $event->{params} = $parsedevent;
  },
  # SRV_INFO_REPLY
  280 => sub {
    # (same as SRV_USER_FOUND, above)
    my ($event) = @_;
    my ($parsedevent, $offset, $length);

    $parsedevent->{uin}       = _bytes_to_int($event->{params}, 0, 4);
    $offset = 4;
    foreach ('nickname', 'firstname', 'lastname', 'email') {
      $length                 = _bytes_to_int($event->{params}, $offset, 2);
      $offset += 2; # Fixed: NN 06 jan 01
      $parsedevent->{$_}      = _bytes_to_str($event->{params}, $offset, $length - 1);
      $offset += $length;
    }
    $parsedevent->{authorize} = _bytes_to_str($event->{params}, $offset, 1);
    $event->{params} = $parsedevent;
  },
  # SRV_EXT_INFO_REPLY
  290 => sub {
    # Thanks to Nezar Nielsen for this bit.
    my ($event) = @_;
    my ($parsedevent, $offset, $length);

    $parsedevent->{uin}            = _bytes_to_int($event->{params}, 0, 4);
    my $citylength                 = _bytes_to_int($event->{params}, 4, 2);
    $parsedevent->{city}           = _bytes_to_str($event->{params}, 6, $citylength - 1);
    $offset = 6 + $citylength;
    $parsedevent->{country_code}   = _bytes_to_int($event->{params}, $offset, 2);
    $offset += 2;
    $parsedevent->{country_status} = _bytes_to_int($event->{params}, $offset,1);
    $offset += 1;
    my $statelength                = _bytes_to_int($event->{params}, $offset,2);
    $offset += 2;
    $parsedevent->{state}          = _bytes_to_str($event->{params}, $offset,$statelength - 1);
    $offset += $statelength;
    $parsedevent->{age}            = _bytes_to_int($event->{params}, $offset, 2);
    $offset += 2;
    $parsedevent->{sex}            = _bytes_to_int($event->{params}, $offset, 1);
    $offset += 1;
    for('phone', 'home_page', 'about'){
       my $length                  = _bytes_to_int($event->{params}, $offset, 2);
       $offset += 2;
       $parsedevent->{$_}          = _bytes_to_str($event->{params}, $offset, $length - 1);
       $offset += $length;
    }
    # done parsing
    $event->{params} = $parsedevent;

    # And from the specification (pretty much), here is some extra info:
    #
    # The code used in COUNTRY_CODE is the international telephone prefix, e.g.
    #   01 00 (1) for the USA, 2C 00 (44) for the UK, 2E 00 (46) for Sweden, etc.
    #   COUNTRY_STATUS is normally FE, unless the remote user has not entered a
    #   country, in which case COUNTRY_CODE will be FF FF, and COUNTRY_STATUS
    #   will be 9C.
    # The field AGE has the value FF FF if the user has not entered his/her age.
    # Values for SEX:
    #   00 = Not specified
    #   01 = Female
    #   02 = Male
  },
  #SRV_INFO_FAIL
  300 => sub {
    # thanks to Robin Fisher
    my ($event) = @_;
    my $parsedevent;

    $parsedevent->{uin}       = _bytes_to_int($event->{params}, 0, 4);
    $event->{params} = $parsedevent;
  },
  # SRV_STATUS_UPDATE
  420 => sub {
    # RTG 8/26/2000
    my ($event) = @_;
    my $parsedevent;
    $parsedevent->{uin}    = _bytes_to_int($event->{params}, 0, 4);
    $parsedevent->{status} = _bytes_to_int($event->{params}, 4, 2);
    $parsedevent->{privacy} = _bytes_to_int($event->{params}, 6, 2);
    $event->{params} = $parsedevent;
  },
  # SRV_SYSTEM_MESSAGE
  450 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_UPDATE_SUCCESS
  480 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_UPDATE_FAIL
  490 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_AUTH_UPDATE
  500 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_X1
  540 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_RAND_USER
  590 => sub {
    #FIX : don't know what to do here ..
  },
  # SRV_META_USER
  990 => sub {
    my ($event) = @_;
    my ($parsedevent, $params);

    $parsedevent->{subcmd}  = _bytes_to_int($event->{params}, 0, 2);
    $parsedevent->{success} = (_bytes_to_int($event->{params}, 2, 1) == 10);
    @$params                = @{$event->{params}}[3..@{$event->{params}}-1];
    if (defined($_meta_parsers{$parsedevent->{subcmd}})){
      $parsedevent->{body}  = &{$_meta_parsers{$parsedevent->{subcmd}}}($params);
    } else {
      $parsedevent->{body}  = {};
    }
    $event->{params} = $parsedevent;
  }
);

%_meta_parsers = (
  #GENERAL_INFO
  100    => sub {
    return {}
  },
  #WORK_INFO
  110    => sub {
    return {}
  },
  #MORE_INFO
  120    => sub {
    return {}
  },
  #ABOUT_INFO
  130    => sub {
    return {}
  },
  200    => sub {
    my ($params) = @_;
    my ($ret, $offset, $length);

    $ret->{uin}       = _bytes_to_int($params, 0, 4);
    $offset = 4;
    foreach ('nickname', 'firstname', 'lastname',
	     'primary_email', 'secondary_email', 'old_email',
	     'city', 'state', 'phone', 'fax',
	     'street', 'cellular') {
      $length         = _bytes_to_int($params, $offset, 2);
      $ret->{$_}      = _bytes_to_str($params, $offset + 2, $length - 1);
      $offset        += $length;
    }
    $ret->{zipcode}   = _bytes_to_str($params, $offset, 4);
    $ret->{country}   = _bytes_to_str($params, $offset+4, 2);
    $ret->{authorize} = _bytes_to_str($params, $offset+6, 1);
    $ret->{webaware}  = _bytes_to_str($params, $offset+7, 1);
    $ret->{hideip}    = _bytes_to_str($params, $offset+8, 1);

    return $ret;
  },
  230    => sub {
    my ($params) = @_;
    return _bytes_to_str($params, 2, _byte_to_int($params, 0, 2) - 1);
  },
  410    => sub {
    my ($params) = @_;
    my ($ret, $offset, $length);

    $ret->{uin}       = _bytes_to_int($params, 0, 4);
    $offset = 4;
    foreach ('nickname', 'firstname', 'lastname', 'email') {
      $length         = _bytes_to_int($params, $offset, 2);
      $ret->{$_}      = _bytes_to_str($params, $offset + 2, $length - 1);
      $offset        += $length;
    }
    $ret->{authorize} = _bytes_to_str($params, $offset, 1);

    return $ret;
  }
);


%_builders = (
  #CMD_ACK
  10 => sub {
  },
  #CMD_SEND_MESSAGE
  270 => sub {
    my ($params) = @_;
    my ($ret, $body2);

    $ret = [];
    push @$ret, _int_to_bytes(4, $params->{receiver_uin});
    push @$ret, _int_to_bytes(2, $params->{type});

    $body2 = &{$_msg_builders{$params->{type}}}($params);
    push @$ret, _int_to_bytes(2, @$body2+1);
    push @$ret, @$body2;
    push @$ret, (0x0);
    return $ret;
  },
  #CMD_LOGIN
  1000 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(4, time()),
      _int_to_bytes(4, $params->{client_port}),
      _int_to_bytes(2, length($params->{password})+1),
      _str_to_bytes($params->{password}, 1),
      _int_to_bytes(4, 0xD5),
      _str_to_bytes($params->{client_ip}),
      _int_to_bytes(1, 4),
      _int_to_bytes(4, $status_codes{ONLINE}),
      _int_to_bytes(2, 6),
      _int_to_bytes(2, 0),
      _int_to_bytes(4, 0),
      _int_to_bytes(4, 0x013F0002),
      _int_to_bytes(4, 0x50),
      _int_to_bytes(4, 3),
      _int_to_bytes(4, 0)
    ];
  },
  #CMD_REG_NEW_USER
  1020 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(2, length($params->{password})+1),
      _str_to_bytes($params->{password}, 1),
      _int_to_bytes(4, 0xA0),
      _int_to_bytes(4, 0x2461),
      _int_to_bytes(4, 0xA00000),
      _int_to_bytes(4, 0x0)
    ];
  },
  #CMD_CONTACT_LIST
  1030 => sub {
    my ($params) = @_;
    my ($ret, $num);

    $num = $params->{num_contacts};
    # FIX: this shouldn't croak!  handle it gracefully..
    croak ("120 contact limit, send more than one packet")
      if ($num > 120);

    $ret = [];
    push @$ret, _int_to_bytes(1, $num);
    for (my $i = 0; $i < $num; $i++){
      push @$ret, _int_to_bytes(4, $params->{uins}[$i]);
    }
    return $ret;
  },
  #CMD_SEARCH_UIN
  1050 => sub {
    # thanks to Germain Malenfant for the fix
    my ($params) = @_;
    return [
      _int_to_bytes(4, $params->{uin})
    ];
  },
  #CMD_SEARCH_USER
  1060 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(2, length($params->{nick})+1),
      _str_to_bytes($params->{nick}, 1),
      _int_to_bytes(2, length($params->{first})+1),
      _str_to_bytes($params->{first}, 1),
      _int_to_bytes(2, length($params->{last})+1),
      _str_to_bytes($params->{last}, 1),
      _int_to_bytes(2, length($params->{email})+1),
      _str_to_bytes($params->{email}, 1),
    ];
  },
  #CMD_KEEP_ALIVE
  1070 => sub {
    return [_int_to_bytes(4, int(rand(0xFFFFFFFF)))];
  },
  #CMD_SEND_TEXT_CODE
  1080 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(2, length($params->{text_code})+1),
      _str_to_bytes($params->{text_code}, 1),
      _int_to_bytes(2, 0x05)
    ];
  },
  #CMD_ACK_MESSAGES
  1090 => sub {
    return [_int_to_bytes(4, int(rand(0xFFFFFFFF)))];
  },
  #CMD_LOGIN_1
  1100 => sub {
    return [_int_to_bytes(4, int(rand(0xFFFFFFFF)))];
  },
  #CMD_MSG_TO_NEW_USER
  1110 => sub {
  },
  #CMD_INFO_REQ
  1120 => sub {
    my ($params) = @_;
    return [_int_to_bytes(4, $params->{uin})];
  },
  #CMD_EXT_INFO_REQ
  1130 => sub {
    my ($params) = @_;
    return [_int_to_bytes(4, $params->{uin})];
  },
  #CMD_CHANGE_PW
  1180 => sub {
  },
  #CMD_NEW_USER_INFO
  1190 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(2, length($params->{nick})+1),
      _str_to_bytes($params->{nick}, 1),
      _int_to_bytes(2, length($params->{first})+1),
      _str_to_bytes($params->{first}, 1),
      _int_to_bytes(2, length($params->{last})+1),
      _str_to_bytes($params->{last}, 1),
      _int_to_bytes(2, length($params->{email})+1),
      _str_to_bytes($params->{email}, 1),
      _int_to_bytes(1, 0x01),
      _int_to_bytes(1, 0x01),
      _int_to_bytes(1, 0x01)
    ];
  },
  #CMD_UPDATE_EXT_INFO
  1200 => sub {
  },
  #CMD_QUERY_SERVERS
  1210 => sub {
  },
  #CMD_QUERY_ADDONS
  1220 => sub {
  },
  #CMD_STATUS_CHANGE
  1240 => sub {
    my ($params) = @_;
    return [_int_to_bytes(4, $params->{status})];
  },
  #CMD_NEW_USER_1
  1260 => sub {
  },
  #CMD_UPDATE_INFO
  1290 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(2, length($params->{nick})+1),
      _str_to_bytes($params->{nick}, 1),
      _int_to_bytes(2, length($params->{first})+1),
      _str_to_bytes($params->{first}, 1),
      _int_to_bytes(2, length($params->{last})+1),
      _str_to_bytes($params->{last}, 1),
      _int_to_bytes(2, length($params->{email})+1),
      _str_to_bytes($params->{email}, 1)
    ];
  },
  #CMD_AUTH_UPDATE
  1300 => sub {
  },
  #CMD_KEEP_ALIVE2
  1310 => sub {
    return [_int_to_bytes(4, int(rand(0xFFFFFFFF)))];
  },
  #CMD_LOGIN_2
  1320 => sub {
  },
  #CMD_ADD_TO_LIST
  1340 => sub {
    my ($params) = @_;
    return [_int_to_bytes(4, $params->{uin})];
  },
  #CMD_RAND_SET
  1380 => sub {
    my ($params) = @_;
    return [_int_to_bytes(4, $params->{rand_group})];
  },
  #CMD_RAND_SEARCH
  1390 => sub {
    my ($params) = @_;
    return [_int_to_bytes(2, $params->{rand_group})];
  },
  #CMD_META_USER
  1610 => sub {
    my ($params) = @_;

    # Thanks to Nezar Nielsen for this handler (wow!)
    # (cleaned up and modified slightly by JLM 2/25/2001)

    # convert string to numeric code if necessary
    $params->{subcmd} = $meta_codes{$params->{subcmd}}
      if exists($meta_codes{$params->{subcmd}});

    my $return=[];
    push @$return, _int_to_bytes(2, $params->{subcmd});

    if ($params->{subcmd} == $meta_codes{GENERAL_INFO}) {
      #1001 - serverresponse: 100
      foreach ('nick', 'first', 'last',
	       'primary_email', 'secondary_email', 'old_email',
	       'city', 'state', 'phone', 'fax', 'street', 'cellular') {
	push @$return, _int_to_bytes(2, length($params->{$_}     || '')+1);
	push @$return, _str_to_bytes($params->{$_}               || '', 1);
      }
      # observe: this has changed since the spec was written,
      # zipcode is also sent as text with null-termination.
      push @$return, _int_to_bytes(2, length($params->{zipcode}  || '')+1);
      push @$return, _str_to_bytes($params->{zipcode}            || '',1);
      push @$return, _int_to_bytes(2, $params->{country}         || 0);
      # timezone - don't know the spec for this
      push @$return, _int_to_bytes(1, $params->{timezone}        || 0);
      push @$return, _int_to_bytes(1, $params->{authorize}       || 0);
      push @$return, _int_to_bytes(1, $params->{webaware}        || 0);
      push @$return, _int_to_bytes(1, $params->{hideip}          || 0);

    } elsif ($params->{subcmd} == $meta_codes{WORK_INFO}) {
      #1011 - serverresponse: 110
      # FIX: Does not work, allthough it sends the info exactly like ICQ 2000b
      # (which sends it through TCP).
      foreach ('city', 'state', 'phone', 'fax', 'addr') {
	push @$return, _int_to_bytes(2, length($params->{$_}     || '')+1);
	push @$return, _str_to_bytes($params->{$_}               || '', 1);
      }
      # i sniffed my client (ICQ 2000b), and i can see that it sends the zipcode
      # like the other null-terminated strings
      push @$return, _int_to_bytes(2, length($params->{zipcode}  || '')+1);
      push @$return, _str_to_bytes($params->{zipcode}            || '', 1);
      push @$return, _int_to_bytes(2, $params->{country}         || 0);
      foreach ('company', 'dept', 'pos') {
	push @$return, _int_to_bytes(2, length($params->{$_}     || '')+1);
	push @$return, _str_to_bytes($params->{$_}               || '', 1);
      }
      # got occupation codes from the Icqlib source, and sniffed my way to see that
      # my icq client sends two bytes here with the number according to what i chose.
      push @$return, _int_to_bytes(2, $params->{occupation});
      push @$return, _int_to_bytes(2, length($params->{url}      || '') + 1);
      push @$return, _str_to_bytes($params->{url}                || '', 1);

    } elsif ($params->{subcmd} == $meta_codes{MORE_INFO}) {
      #metauser code: 1021 - serverresponse: 120
      push @$return, _int_to_bytes(2, $params->{age}             || 0xFFFF);
      push @$return, _int_to_bytes(1, $sex_codes{uc($params->{sex})} || $sex_codes{UNSPECIFIED});
      push @$return, _int_to_bytes(2, length($params->{url}      || '')+1);
      push @$return, _str_to_bytes($params->{url}                || '', 1);
      push @$return, _int_to_bytes(2, $params->{year});
      push @$return, _int_to_bytes(1, $params->{month}           || 1);
      push @$return, _int_to_bytes(1, $params->{day}             || 1);
      # three spoken languages (or set to 0)
      push @$return, _int_to_bytes(1, $params->{lang1}           || 0);
      push @$return, _int_to_bytes(1, $params->{lang2}           || 0);
      push @$return, _int_to_bytes(1, $params->{lang3}           || 0);

    } elsif ($params->{subcmd} == $meta_codes{ABOUT_INFO}) {
      #1030 - serverresponse: 130
      push @$return, _int_to_bytes(2, length($params->{about}    || '')+1);
      push @$return, _str_to_bytes($params->{about}              || '',1);
    }

    return $return;
  },
  #CMD_INVIS_LIST
  1700 => sub {
    my ($params) = @_;
    my ($ret, $num);

    $num = $params->{num_contacts};
    croak ("120 contact limit, send more than one packet")
      if ($num > 120);

    $ret = [];
    push @$ret, _int_to_bytes(1, $num);
    for (my $i = 0; $i < $num; $i++){
      push @$ret, _int_to_bytes(4, $params->{uins}[$i]);
    }
    return $ret;
  },
  #CMD_VIS_LIST
  1710 => sub {
    my ($params) = @_;
    my ($ret, $num);

    $num = $params->{num_contacts};
    croak ("120 contact limit, send more than one packet")
      if ($num > 120);

    $ret = [];
    push @$ret, _int_to_bytes(1, $num);
    for (my $i = 0; $i < $num; $i++){
      push @$ret, _int_to_bytes(4, $params->{uins}[$i]);
    }
    return $ret;
  },
  #CMD_UPDATE_LIST
  1720 => sub {
    my ($params) = @_;
    return [
      _int_to_bytes(4, $params->{uin}),
      _int_to_bytes(1, $params->{list}),
      _int_to_bytes(1, $params->{remadd})
    ];
  },
);

%_msg_builders = (
  #MSG_TEXT
  1 => sub {
    my ($params) = @_;
    return [_str_to_bytes($params->{text})];
  },
  #MSG_URL
  4 => sub {
    my ($params) = @_;
    my (@ret, $first);
    $first = 1;
    foreach ('description', 'url'){
      push @ret, (0xFE) if !$first;
      $first = 0 if $first;
      push @ret, _str_to_bytes($params->{$_});
    }
    return \@ret;
  },
  #MSG_AUTH_REQ
  6 => sub {
    my ($params) = @_;
    my (@ret, $first);
    $first = 1;
    foreach ('nickname', 'firstname', 'lastname', 'email', 'reason'){
      push @ret, (0xFE) if !$first;
      $first = 0 if $first;
      push @ret, _str_to_bytes($params->{$_});
    }
    return \@ret;
  },
  #MSG_AUTH
  8 => sub {
    my ($params) = @_;
    my @ret = undef;
    return \@ret;
  },
  #MSG_USER_ADDED message
  12 => sub {
    my ($params) = @_;
    my (@ret, $first);
    $first = 1;
    foreach ('nickname', 'firstname', 'lastname', 'email'){
      push @ret, (0xFE) if !$first;
      $first = 0 if $first;
      push @ret, _str_to_bytes($params->{$_});
    }
    return \@ret;
  },
  #MSG_CONTACTS message
  19 => sub {
    my ($params) = @_;
    my (@ret, $num_uins);
    $num_uins = keys(%{$params->{contacts}});
    push @ret, _str_to_bytes($num_uins);
    foreach (%{$params->{contacts}}) {
      push @ret, (0xFE);
      push @ret, _str_to_bytes($_);
    }
    return \@ret;
  }
);

# == DEVELOPERS' NOTE ==
# (should this be in pod???)
#
# An event is stored as a hash ref (note: not a full blessed object).
# Here are the fields (keys) in the hash and their descriptions:
#
# command    - The numeric command code
# seq_num_1  - Sequence number 1, which is incremented in every packet
# seq_num_2  - Sequence number 2, which is incremented in most (?) packets
# params     - The raw array of bytes that make up the parameters
# is_ack     - Set to 1 if this is an ACK event, otherwise not present
# is_multi   - Set to 1 if this is a multi packet, otherwise not present
#
# The following fields exist only in outgoing events:
#
# send_last  - time of the last resend, as time() (seconds since the epoch)
# send_count - number of times the event has been sent to the server
# send_now   - set to 1 when the event is due to be resent

# ====
# private methods
# ====

# look for data coming from the server and build events out of it
sub _do_incoming {
  my ($self) = @_;
  my ($raw, @packet, $event);

  while (IO::Select->select($self->{_select}, undef, undef, .00001)) {
    $self->{_socket}->recv($raw, 10000);
    @packet = split('', $raw);

    foreach (@packet) {
      $_ = ord($_);
    }

    # build the event
    $event = $self->_parse_packet(\@packet);

    # DEBUG: print out incoming packets
    if ($self->{_debug}) {
      print '<-- event #', $event->{seq_num_1}, ' ';
      _print_packet(\@packet);
      print " <", $event->{command},">\n";
    }

    # put acks in separate array because they will be handled immediately.
    if ( $event->{is_ack} ) {
        push @{$self->{_acks_incoming}}, $event;
    }
    # stick everything that hasn't already been seen in the incoming events list
    else {
      my $not_in_array = 1;
      foreach my $seq ( @{$self->{_seen_seq}} ) { 
	if ($seq == $event->{seq_num_1}) {
	  $not_in_array = 0;
	  last;
	}
      }
      if ($not_in_array) {
	  push @{$self->{_events_incoming}}, $event;
	  push @{$self->{_seen_seq}}, $event->{seq_num_1};

	  if (@{$self->{_seen_seq}} > 20) {
	    shift @{$self->{_seen_seq}};
	  }
      } 
      
    } # end else
  } # end while
} # end sub _do_incoming


# for each incoming ack, remove corresponding outgoing event from queue,
# and send out acks for every non-ack event we received
sub _do_acks {
  my ($self) = @_;
  my (@params);

  # incoming ACKs are received, delete corrosponding outgoing events
  foreach ( @{$self->{_acks_incoming}} ) {

    #DEBUG: print out incoming ACKS
    print "    (ACK  #", $_->{seq_num_1}, ")\n" 
      if $self->{_debug};

    # remove the matching outgoing event that got ACK from server
    if ( defined $self->{_events_outgoing}[0] &&
         $_->{seq_num_1} == $self->{_events_outgoing}[0]{seq_num_1} ) {

        shift @{$self->{_events_outgoing}}; 
        $self->{_seq_num_1}++; # increment seq_num_1 because event was sucessfully received
        $self->{_seq_num_2}++; # increment seq_num_1 because event was sucessfully received
    }
  } # end foreach

  # remove all incoming acks because they're all processed
  $self->{_acks_incoming} = [];

  # got some incoming events, send some loving ACKs home
  # to tell them events are successfully received.
  foreach ( @{$self->{_events_incoming}} ) {

    push @{$self->{_acks_outgoing}}, { command   => 10,
                                       is_ack    => 1,
                                       seq_num_1 => $_->{seq_num_1},
                                       seq_num_2 => $_->{seq_num_2},
                                       params    => [_int_to_bytes(4, int(rand(0xFFFFFFFF)))]
                                     };
  } # end foreach
} # end sub _do_acks


# split the sub-events out of all the multi events on the incoming
# queue, put the sub-events on the queue, and remove the multi
sub _do_multis {
  my ($self) = @_;
  my ($event, $i);

  $i = 0;
  # for every incoming packet
  foreach (@{$self->{_events_incoming}}) {
    # if it's not a multi, skip it
    if (!$_->{is_multi}) {
      $i++;
      next;
    }

    my (@newevents, $offset);
    #for each packet in the multi packet..
    $offset = 1;
    for (my $i = 0; $i < _bytes_to_int($_->{params}, 0, 1); $i++) {
      # build the event
      my $packet_length = _bytes_to_int($_->{params}, $offset, 2);
      $offset += 2;
      my @packet = @{$_->{params}}[$offset..($offset + $packet_length)-1];
      $offset += $packet_length;

      # build the event and queue it
      $event = $self->_parse_packet(\@packet);
      push @{$self->{_events_incoming}}, $event;

      # DEBUG: print out incoming packets
      if ($self->{_debug}) {
	print ' <+ multi #', $event->{seq_num_1}, ' ';
	_print_packet(\@packet);
	print " <", $event->{command},">\n";
      }

    } # end for

    # remove the multi from the queue
    splice(@{$self->{_events_incoming}}, $i, 1);

  } # end foreach
} # end sub _do_multis


# if it's time, queue a keepalive packet as close to the head of the queue
# as possible
sub _do_keepalives {
  my ($self) = @_;
  my ($now);

  # grab current time
  $now = time();

  # FIX: make the time configgable
  # Keepalive every 2 minutes, as recommanded by ICQ V5.
  if ($self->{_last_keepalive} + 2*60 < $now) {

    #DEBUG: print out keepalive
    print "=== queueing keepalive\n"
      if $self->{_debug};

    $self->{_last_keepalive} = $now;
    $self->send_event('CMD_KEEP_ALIVE', undef, 1);

  } # end if
} #end _do_keepalives


# see if the top event needs to be resent, and remove it from the
# outgoing queue if it's been resent too many times
sub _do_timeouts {
  my ($self) = @_;

  # FIX: make the time configgable
  if ( defined $self->{_events_outgoing}[0] &&
       $self->{_events_outgoing}[0]{send_last} + 10 <= time() ) {

    if ( $self->{_events_outgoing}[0]{send_count} >= 6 )  {

      # FIX: it would probably be wise to inform the programmer that
      # their event couldn't be sent.

      #DEBUG: print out timeout
      print "=== too many resends for ", $self->{_events_outgoing}[0]{seq_num_1}, "\n"
	if $self->{_debug};

      # out of tries, you loose, next!
      shift @{$self->{_events_outgoing}};
    }
    else {
      $self->{_events_outgoing}[0]{send_now} = 1;
    }
  }
} # end sub _do_timeouts


# call the handler for each event on the incoming queue
sub _do_handlers {
  my ($self) = @_;

  foreach ( @{$self->{_events_incoming}} ) {

    # if a handler for this event has been registered
    if (exists $self->{_handlers}{$_->{command}} ) {
      # parse the raw event params
      &{$_parsers{$_->{command}}}($_)
	if ( exists $_parsers{$_->{command}} );

      #call the handler
      &{$self->{_handlers}{$_->{command}}}($self, $_);

    } # end if
  } # end foreach

  # empty incoming queue
  $self->{_events_incoming} = [];
}


# send all outgoing acks, send the top event on the regular
# outgoing queue if it's marked as ready to go
sub _do_outgoing {
  my ($self) = @_;

  foreach (@{$self->{_acks_outgoing}}) {

    #DEBUG: print out sending acks
    print "--> ACK   #", $_->{seq_num_1}, "\n" 
      if $self->{_debug};

    $self->_deliver_event($_);

  } # end foreach

  # clear outgoing ack array
  $self->{_acks_outgoing} = []; 

  if ( $self->{_events_outgoing}[0] and
       $self->{_events_outgoing}[0]{send_now} ) {

    $self->{_events_outgoing}[0]{send_now} = 0;
    $self->{_events_outgoing}[0]{send_last} = time();
    $self->{_events_outgoing}[0]{send_count}++;
    $self->{_events_outgoing}[0]{seq_num_1} = $self->{_seq_num_1};
    $self->{_events_outgoing}[0]{seq_num_2} = $self->{_seq_num_2};

    #DEBUG: print out outgoing event
    print "--> event #", $self->{_events_outgoing}[0]{seq_num_1},
      " <" , $self->{_events_outgoing}[0]{command}, ">\n"
	if $self->{_debug};

    $self->_deliver_event($self->{_events_outgoing}[0]);

  } # end if
} # end sub _do_outgoing


# adds an event to the queue, with an optional priority flag
# (priority means the event is put as close to the head as
# possible without interrupting a "live" event)
sub _queue_event {
  my ($self, $event, $priority) = @_;

  $event->{send_count} = 0; # not resent at all yet
  $event->{send_last} = 0;  # a time as far in the past as possible
  $event->{send_now} = 1;   # send me right away when I get to the head of the queue

  if (!$priority) {
    # regular event; just slap it on the tail of the queue

    push @{$self->{_events_outgoing}}, $event;

  } else {
    # priority event; stick it on top, or just after that if top event is "live"

    if (
	# top event not defined (queue empty)
	!defined $self->{_events_outgoing}[0] or
	# top event is defined but has not been sent out yet (not live)
	(defined $self->{_events_outgoing}[0] and
	 $self->{_events_outgoing}[0]{send_count} == 0)
       ) {
      # then stick event on the head of the queue
      unshift @{$self->{_events_outgoing}}, $event;
    } else {
      # there is a live event on the top of the queue (we're waiting for it to be ACKed);
      # queue this event AFTER the live event so as not to interrupt it
      splice @{$self->{_events_outgoing}}, 1, 0, $event;
    }

  }
}


# takes an event, builds a UDP packet, and sends it to the server
sub _deliver_event {
  my ($self, $event) = @_;
  my ($packet, $checkcode, $raw, $length);

  $packet = $self->_make_header($event);
  push @$packet, @{$event->{params}};

  $checkcode = $self->_calc_checkcode($packet);

  $length = @$packet;
  $raw = $self->_encrypt($packet, $checkcode); # now $raw might have extra 0-bytes
  substr($raw, $length) = '';                  # truncate data to correct length

  $self->{_socket}->send($raw);
}


# ICQ Packet Header (client side)
# ===============================
# Length       Content (if fixed)  Designation      Description
# ------       ------------------  -----------      -----------
# 2 bytes      05 00               VERSION          Protocol version
# 4 bytes      00 00 00 00         ZERO             Just zeros, purpouse unknown
# 4 bytes      xx xx xx xx         UIN              Your (the client's) UIN
# 4 bytes      xx xx xx xx         SESSION_ID       Used to prevent 'spoofing'. See below.
# 2 bytes      xx xx               COMMAND
# 2 bytes      xx xx               SEQ_NUM1         Starts at a random number
# 2 bytes      xx xx               SEQ_NUM2         Starts at 1
# 4 bytes      xx xx xx xx         CHECKCODE
# variable     xx ...              PARAMETERS       Parameters for the command being sent

sub _make_header {
  my ($self, $event) = @_;
  my ($header);

  $header = [];
  push @$header, _int_to_bytes(2, 5);
  push @$header, _int_to_bytes(4, 0);
  push @$header, _int_to_bytes(4, $self->{_uin});
  push @$header, _int_to_bytes(4, $self->{_session_id});
  push @$header, _int_to_bytes(2, $event->{command});
  push @$header, _int_to_bytes(2, $event->{seq_num_1});
  push @$header, _int_to_bytes(2, $event->{seq_num_2});
  push @$header, _int_to_bytes(4, 0); # checkcode gets set later

  return $header;
}


sub _calc_checkcode {
  my ($self, $packet) = @_;
  my ($number1, $number2, $r1, $r2, @checkcode);

  # NUMBER1 = B8 B4 B2 B6
  $number1 = $packet->[8];
  $number1 <<= 8;
  $number1 |= $packet->[4];
  $number1 <<= 8;
  $number1 |= $packet->[2];
  $number1 <<= 8;
  $number1 |= $packet->[6];

  # PL = Packet length
  # R1 = A random number beetween 0x18 and PL
  # R2 = Another random number beetween 0 and 0xFF
  # (the max here may end up 1 too small.. who cares)

  $r1 = int(rand(@$packet - 0x18)) + 0x18;
  $r2 = int(rand(0xFF));

  $number2 = $r1;
  $number2 <<= 8;
  $number2 |= $packet->[$r1];
  $number2 <<= 8;
  $number2 |= $r2;
  $number2 <<=8;
  $number2 |= $_table[$r2];
  $number2 ^= 0x00FF00FF;

  @checkcode = _int_to_bytes(4, $number1 ^ $number2);
  splice(@$packet, 0x14, 0x04, @checkcode);

  return _bytes_to_int(\@checkcode, 0, 4);
}


sub _encrypt {
  my ($self, $packet, $cc) = @_;
  my ($code, @plain, @dwords, $i, $raw, $cc_raw);

  $code = Math::BigInt->new(@$packet * 0x68656C6C + $cc);
  $code = $code->band(Math::BigInt->new(0xFFFFFFFF));

  @plain = splice(@$packet, 0, 0xA, ());
  $i = 0;
  while ($i < @$packet) {
    push @dwords, _bytes_to_int($packet, $i, 4);
    $i += 4;
  }

  $i = 0xA;
  foreach (@dwords) {
    $_ = Math::BigInt->new($_);
    $_ = $_->bxor(Math::BigInt->new($code + $_table[$i & 0xFF]));
    $i += 4;
  }

  $cc =
    (($cc & 0x0000001F) << 0x0C) |
    (($cc & 0x03E003E0) << 0x01) |
    (($cc & 0xF8000400) >> 0x0A) |
    (($cc & 0x0000F800) << 0x10) |
    (($cc & 0x041F0000) >> 0x0F);
  for ($i = 0; $i < 4; $i++) {
    $cc_raw .= chr($cc & 0xFF);
    $cc >>= 8;
  }

  $raw = '';
  foreach (@plain) {
    $raw .= chr($_);
  }
  foreach (@dwords) {
    for ($i = 0; $i < 4; $i++) {
      $raw .= chr($_ & 0xFF);
      $_ >>= 8;
    }
  }
  substr($raw, 0x14, 4, $cc_raw);

  return $raw;
}


# ICQ Packet Header (server side)
# ===============================
# Length       Content (if fixed)  Designation          Description
# 2 bytes      05 00               VERSION              Protocol version
# 1 byte       00                  ZERO                 Unknown
# 4 bytes      xx xx xx xx         SESSION_ID           Same as in your login packet.
# 2 bytes      xx xx               COMMAND
# 2 bytes      xx xx               SEQ_NUM1             Sequence 1
# 2 bytes      xx xx               SEQ_NUM2             Sequence 2
# 4 bytes      xx xx xx xx         UIN                  Your (the client's) UIN
# 4 bytes      xx xx xx xx         CHECKCODE
# variable     xx ...              PARAMETERS           Parameters for the command being sent

sub _parse_packet {
  my ($self, $packet) = @_;
  my ($event, @params);

  # Thanks to Robin Fisher for this fix for V3 packets.
  # if it's a version 3 packet, change the header to match a version 5 packet.
  # (apparently, the only difference in V5 is the addition of the session id)
  if (_bytes_to_int($packet, 0, 2) == 3) {
    print("OOPS: Server sent a V3 packet.  Converting to V5.\n");
    splice @$packet, 0, 2, (5, 0, 0, _int_to_bytes(4, $self->{_session_id}));
  }

  # sanity checks
  if (_bytes_to_int($packet, 3, 4) != $self->{_session_id}) {
    print("OOPS: Server told us the wrong session ID!\n") if $self->{_debug};
    $self->disconnect;
  }
  if (_bytes_to_int($packet, 13, 4) != $self->{_uin}) {
    print("OOPS: Server told us the wrong UIN!\n") if $self->{_debug};
    $self->disconnect;
  }

  # fill in the event's fields
  $event = {};
  $event->{command}    = _bytes_to_int($packet, 7, 2);
  $event->{seq_num_1}  = _bytes_to_int($packet, 9, 2);
  $event->{seq_num_2}  = _bytes_to_int($packet, 11, 2);
  $event->{is_ack}     = 1 if $event->{command} == 10;
  $event->{is_multi}   = 1 if $event->{command} == 530;
  @params = @$packet[21..@$packet-1];
  $event->{params} =  \@params;

  return $event;
}


# ====
# private functions
# (they're not methods, so don't call them on a Net::ICQ object!)
# ====


# _int_to_bytes(bytes, val)
#
# Converts <val> into an array of <bytes> bytes and returns it.
# If <val> is too big, only the <bytes> least significant bytes are
# returned.  The array is in little-endian order.
#
# _int_to_bytes(2, 0x1234)  == (0x34, 0x12)
# _int_to_bytes(2, 0x12345) == (0x45, 0x23)

sub _int_to_bytes {
  my ($bytes, $val) = @_;
  my (@ret);

  for (my $i=0; $i<$bytes; $i++) {
    push @ret, ($val >> ($i*8) & 0xFF);
  }

  return @ret;
}


# _str_to_bytes(str, add_zero)
#
# Converts <str> into an array of bytes and returns it.  If <add_zero>
# is true, makes the array null-terminated (adds a 0 as a the last byte).
#
# _str_to_bytes('foo')     == ('f', 'o', 'o')
# _str_to_bytes('foo', 1)  == ('f', 'o', 'o', 0)

sub _str_to_bytes {
  my ($string, $add_zero) = @_;
  my (@ret);

  # the ?: keeps split() from complaining about undefined values
  foreach (split('', defined($string) ? $string : '')) {
    push @ret, ord($_);
  }
  push @ret, 0 if $add_zero;

  return @ret;
}


# _bytes_to_int(array_ref, start, bytes)
#
# Converts the byte array referenced by <array_ref>, starting at offset
# <start> and running for <bytes> values, into an integer, and returns it.
# The bytes in the array must be in little-endian order.
#
# _bytes_to_int([0x34, 0x12, 0xAA, 0xBB], 0, 2) == 0x1234
# _bytes_to_int([0x34, 0x12, 0xAA, 0xBB], 2, 1) == 0xAA

sub _bytes_to_int {
  my ($array, $start, $bytes) = @_;
  my ($ret);

  $ret = 0;
  for (my $i = $start+$bytes-1; $i >= $start; $i--) {
    $ret <<= 8;
    $ret |= ($array->[$i] or 0);
  }

  return $ret;
}


# _bytes_to_str(array_ref, start, bytes)
#
# Converts the byte array referenced by <array_ref>, starting at offset
# <start> and running for <bytes> values, into a string, and returns it.
#
# _bytes_to_str([0x12, 'f', 'o', 'o', '!'], 1, 3) == 'foo'

sub _bytes_to_str {
  # thanks to Dimitar Peikov for the fix
  my ($array, $start, $bytes) = @_;
  my ($ret);

  $ret = '';
  for (my $i = $start; $i < $start+$bytes; $i++) {
    $ret .= $array->[$i] ? chr($array->[$i]) : '';
  }

  return $ret;
}

# _bytes_to_strlist(array_ref)
#
# Converts the byte array referenced by <array_ref> into an array of
# strings, and returns a reference to the array.
# The strings in the byte array must be separated by the byte 0xFE, and the
# end of the last string to be converted must be followed by the byte 0x00.
#
# _bytes_to_strlist(['a', 'b', 0xFE, 'x', 'y', 'z', 0x00]) == ['ab', 'xyz']

sub _bytes_to_strlist {
  my ($array) = @_;
  my (@ret, $str);

  $str = '';
  foreach (@$array) {
    if ($_ == 0xFE) {
      push @ret, $str;
      $str = '';
    }
    else {
      $str .= chr($_);
    }
  }

  # remove last 0 from the last string
  substr($str, -1, 1, '');
  push @ret, $str;
  return @ret;
}


# print_packet(packet_ref)
#
# Dumps the ICQ packet contained in the byte array referenced by
# <packet_ref> to STDOUT.  The format is '[byte0 byte1 ...]'
# where byte0 byte1 ... are all the actual bytes
# that make up the packet, in 2-character 0-padded hex format.
# For instance, a dump might begin like this:
# [02 BD 14 4A ...

sub _print_packet {
  my ($packet) = @_;

  print "[";
  foreach (@$packet) {
    print sprintf("%02X ", $_);
  }
  print "]";

}

1;

