package Net::Jabber::Bot;

use Moose;
use MooseX::Types 
    -declare => [qw( JabberClientObject PosInt PosNum HundredInt )];

# import builtin types
use MooseX::Types::Moose qw/Int HashRef Str Maybe ArrayRef Bool CodeRef Object Num/;

use version;
use Net::Jabber;
use Time::HiRes;
use Sys::Hostname;
use Log::Log4perl qw(:easy);
#use Data::Dumper; #For testing only.


coerce Bool, from Str, 
    via {($_ =~ m/(^on$)|(^true$)/i) + 0}; # True if it's on or true. Otherwise false.

subtype JabberClientObject, as Object, where { $_->isa('Net::Jabber::Client') };

subtype PosInt,     as Int, where { $_ > 0 };
subtype PosNum,     as Num, where { $_ > 0 };
subtype HundredInt, as Num,  where { $_ > 100 };

has jabber_client               => (isa => Maybe[JabberClientObject],
                                    is => 'rw',
                                    default => sub {Net::Jabber::Client->new});
#my %connection_hash : ATTR; # Keep track of connection options fed to client.

has 'client_session_id'   => (isa => Str, is => 'rw');
has 'connect_time'        => (isa => PosInt, is => 'rw', default => 9_999_999_999);
has 'forum_join_grace'    => (isa => PosNum, is => 'rw', default => 10);
has 'server_host'         => (isa => Str, is => 'rw', lazy => 1, default => sub{shift->server });
has 'server'              => (isa => Str, is => 'rw');
has 'port'                => (isa => PosInt, is => 'rw', default => 5222);
has 'tls'                 => (isa => Bool, is => 'rw', default => '0');
has 'connection_type'     => (isa => Str, is => 'rw', default => 'tcpip');
has 'conference_server'   => (isa => Str, is => 'rw');
has 'username'            => (isa => Str, is => 'rw');
has 'password'            => (isa => Str, is => 'rw');
has 'alias'               => (isa => Str, is => 'rw', default => sub{'net_jabber_bot'});
# Resource defaults to alias_hostname_pid
has 'resource'            => (isa => Str, lazy => 1, is => 'rw', default => sub{shift->alias . "_" . hostname . "_" . $$});
#has 'resource'            => (isa => Str, lazy => 1, is => 'rw', default => sub{shift->alias});
has 'message_function'    => (isa => Maybe[CodeRef], is => 'rw', default => sub{undef});
has 'background_function' => (isa => Maybe[CodeRef], is => 'rw', default => sub{undef});
has 'loop_sleep_time'     => (isa => PosNum, is => 'rw', default => 5);
has 'process_timeout'     => (isa => PosNum, is => 'rw', default => 5);
has 'from_full'           => (isa => Str, is => 'rw', default => sub{my $self = shift;
                                                                       $self->username .
                                                                       '@' .
                                                                       $self->server .
                                                                       '/' .
                                                                       $self->alias});
                                                                       

has 'safety_mode'            => (isa => Bool, is => 'rw', default => 1, coerce => 1);
has 'ignore_server_messages' => (isa => Bool, is => 'rw', default => 1, coerce => 1);
has 'ignore_self_messages'   => (isa => Bool, is => 'rw', default => 1, coerce => 1);
has 'forums_and_responses'   => (isa => HashRef[ArrayRef[Str]], is => 'rw'); # List of forums we're in and the strings we monitor for.
has 'forum_join_time'        => (isa => HashRef[Int], is => 'rw', default => sub{{}}); # List of when we joined each forum
has 'out_messages_per_second' => (isa => PosNum, is => 'rw', default => sub{5});
has 'message_delay'           => (isa => PosNum, is => 'rw', default => sub {1/5});

has 'max_message_size'        => (isa => HundredInt, is => 'rw', default => 1000000);
has 'max_messages_per_hour'   => (isa => PosInt,     is => 'rw', default => 1000000);

# Initialize this hour's message count.
has 'messages_sent_today'     => (isa => 'HashRef', is => 'ro', default => sub{{(localtime)[7] => {(localtime)[2] => 0}}});


#my %message_function : ATTR; # What is called if we are fed a new message once we are logged in.
#my %bot_background_function : ATTR; # What is called if we are fed a new message once we are logged in.
#my %forum_join_time : ATTR;  # Tells us if we've parsed historical messages yet.
#my %client_start_time :ATTR; # Track when we came online. Also used to determine if we're online.
#my %process_timeout : ATTR;  # Time to take in process loop if no messages found
#my %loop_sleep_time : ATTR;  # Time to sleep each time we go through a Start() loop.
#my %ignore_messages : ATTR;  # Messages to ignore if we recieve them.
#my %forums_and_responses: ATTR; # List of forums we have joined and who we respond to in each forum
#my %message_delay: ATTR;    # Allows us to limit Messages per second
#my %max_message_size: ATTR; # Maximum allowed message size before we chunk them.
#my %forum_join_grace: ATTR; # Time before we start responding to forum messages.
#my %messages_sent_today: ATTR;   # Tracks messages sent in 2 dimentional hash by day/hour
#my %max_messages_per_hour: ATTR; # Limits the number of messages per hour.
#my %safety_mode: ATTR; # Tracks if we are in safety mode.

=head1 NAME

Net::Jabber::Bot - Automated Bot creation with safeties

=head1 VERSION

Version 2.1.5

=cut

our $VERSION = '2.1.5';

=head1 SYNOPSIS

Program design:
This is a Moose based Class.

The idea behind the module is that someone creating a bot should not really have to know a whole lot about how the Jabber protocol works in order to use it. It also allows us to abstract away all the things that can get a bot maker into trouble. Essentially the object helps protect the coders from their own mistakes.

All someone should have to know and define in the program away from the object is:

=over

=item 1. Config - Where to connect, how often to do things, timers, etc

=item 2. A subroutine to be called by the bot object when a new message comes in.

=item 3. A subroutine to be called by the bot object every so often that lets the user do background activities (check logs, monitor web pages, etc.),

=back

The object at present has the following enforced safeties as long as you do not override safety mode:

=over

=item 1. Limits messages per second, configurable at start up, (Max is 5 per second) by requiring a sleep timer in the message sending subroutine each time one is sent.

=item 2. Endless loops of responding to self prevented by now allowing the bot message processing subroutine to know about messages from self

=item 3. Forum join grace period to prevent bot from reacting to historical messages

=item 4. Configurable aliases the bot will respond to per forum

=item 5. Limits maximum message size, preventing messages that are too large from being sent (largest configurable message size limit is 1000).

=item 6. Automatic chunking of messages to split up large messages in message sending subroutine

=item 7. Limit on messages per hour. (max configurable limit of 125) Messages are visible via log4perl, but not ever be sent once the message limit is reached for that hour.

=back

=head1 FUNCTIONS

=over 4

=item B<new>

Minimal: 
    my $bot = Net::Jabber::Bot->new(
                                  server => 'host.domain.com' # Name of server when sending messages internally.
                                , conference_server => 'conference.host.domain.com'
                                , port => 522
                                , username => 'username'
                                , password => 'pasword'
                                , safety_mode => 1
                                , message_function => \&new_bot_message
                                , background_function => \&background_checks
                                , forums_and_responses => \%forum_list
                            );
    
All options:
    my $bot = Net::Jabber::Bot->new(
                                  server => 'host.domain.com' # Name of server when sending messages internally.
                                , conference_server => 'conference.host.domain.com'
                                , server_host => 'talk.domain.com' # used to specify what jabber server to connect to on connect?
                                , tls => 0 # set to 1 for google 
                                , connection_type => 'tcpip'
                                , port => 522
                                , username => 'username'
                                , password => 'pasword'
                                , alias => 'cpan_bot'
                                , message_function => \&new_bot_message
                                , background_function => \&background_checks
                                , loop_sleep_time => 15
                                , process_timeout => 5
                                , forums_and_responses => \%forum_list
                                , ignore_server_messages => 1
                                , ignore_self_messages => 1
                                , out_messages_per_second => 4
                                , max_message_size => 1000
                                , max_messages_per_hour => 100
                            );




Setup the object and connect to the server. Hash values are passed to new as a hash.

The following initialization variables can be passed. Only marked variables are required (TODO)

=over 5

=item B<safety_mode>

    safety_mode = (1,0)

Determines if the bot safety features are turned on and enforced. This mode is on by default. Many of the safety features are here to assure you do not crash your favorite jabber server with floods, etc. DO NOT turn it off unless you're sure you know what you're doing (not just Sledge Hammer ceratin)

=item B<server>

Jabber server name

=item B<server_host>

Defaults to the same value set for 'server' above.
This is where the bot initially connects. For google for instance, you should set this to 'gmail.com' 

=item B<conference_server>

conferencee server (usually conference.$server_name)

=item B<port>

Defaults to 5222

=item B<tls>
Boolean value. defaults to 0. for google, it is know that this value must be 1 to work.  

=item B<connection_type>
defaults to 'tcpip' also takes 'http' 

=item B<username>

The user you authenticate with to access the server. Not full name, just the stuff to the left of the @...

=item B<password>

password to get into the server

=item B<alias>

This will be your nickname in rooms, as well as the login resource (which can't have duplicates). I couldn't come up with any reason these should not be the same so hardcoded them to be the same.

=item B<forums_and_responses>

A hash ref which lists the forum names to join as the keys and the values are an array reference to a list of strings they are supposed to be responsive to.
The array is order sensitive and an empty string means it is going to respond to all messages in this forum. Make sure you list this last.

The found 'response string' is assumed to be at the beginning of the message. The message_funtion function will be called with the modified string.

alias = jbot:, attention:

    example1:

    message: 'jbot: help'

    passed to callback: 'help'

=item B<message_function>

The subroutine the bot will call when a new message is recieved by the bot. Only called if the bot's logic decides it's something you need to know about.

=item B<background_function>

The subroutine the bot will call when every so often (loop_sleep_time) to allow you to do background activities outside jabber stuff (check logs, web pages, etc.)

=item B<loop_sleep_time>

Frequency background function is called.

=item B<process_timeout>

Time Process() will wait if no new activity is received from the server

=item B<ignore_server_messages>

Boolean value as to whether we should ignore messages sent to us from the jabber server (addresses can be a little cryptic and hard to process)

=item B<ignore_self_messages>

Boolean value as to whether we should ignore messages sent by us.

BE CAREFUL if you turn this on!!! Turning this on risks potentially endless loops. If you're going to do this, please be sure safety is turned on at least initially.

=item B<out_messages_per_second>

Limits the number of messages per second. Number must be <gt> 0

default: 5

safety: 5

=item B<max_message_size>

Specify maximimum size a message can be before it's split and sent in pieces.

default: 1,000,000

safetey: 1,000

=item B<max_messages_per_hour>

Limits the number of messages per hour before we refuse to send them

default: 125

safetey: 166

=back

=cut

# Handle initialization of objects of this class...
sub BUILD {
    my ($self, $params) = @_;

    # Deal with legacy bug
    if($params->{background_activity} || $params->{message_callback}) {
        my $warn_message = "\n\n" 
                          . "*" x 70 . "\n"
                          . "WARNING!!! You're using old parameters for your bot initialization\n"
                          . "'message_callback' should be changed to 'message_function'\n"
                          . "'background_activity' should be changed to 'background_function'\n"
                          . "I'm correcting this, but you should fix your code\n"
                          . "*" x 70 . "\n"
                          . "\n\n";
        warn($warn_message);
        WARN($warn_message);

        $self->background_function($params->{background_activity})
            if(!$self->background_function && $params->{background_activity});
        $self->message_function($params->{message_callback})
            if(!$self->message_function && $params->{message_callback});
        sleep 30;
    } 
    
    # Message delay is inverse of out_messages_per_second
    $self->message_delay(1/$self->out_messages_per_second);

    # Enforce all our safety restrictions here.
    if($self->safety_mode) {
        # more than 5 messages per second risks server flooding.
        $self->message_delay(1/5) if($self->message_delay < 1/5);

        # Messages should be small to not overwhelm rooms/people/server
        $self->max_message_size(1000) if($self->max_message_size > 1000);

        # More than 4,000 messages a day is a little excessive.
        $self->max_messages_per_hour(125) if($self->max_messages_per_hour > 166);

        # Should not be responding to self messages to prevent loops.
        $self->ignore_self_messages(1);
    }

    #Initialize the connection.
    $self->_init_jabber;
}

# Return a code reference that will pass self in addition to arguements passed to callback code ref.
sub _callback_maker {
    my $self = shift;
    my $Function = shift;

#    return sub {return $code_ref->($self, @_);};
    return sub {return $Function->($self, @_);};
}

# Creates client object and manages connection. Called on new but also called by re-connect
sub _init_jabber {
    my $self = shift;

    # Determine if the object already exists and if not, create it.
    DEBUG("new client object.");
    if(!$self->jabber_client) {
        $self->jabber_client(Net::Jabber::Client->new);
    }
    my $connection = $self->jabber_client;

    DEBUG("Set the call backs.");
    $connection->PresenceDB(); # Init presence DB.
    $connection->RosterDB(); # Init Roster DB.
    $connection->SetCallBacks( 'message'  => $self->_callback_maker(\&_process_jabber_message)
                              ,'presence' => $self->_callback_maker(\&_jabber_presence_message)
                              ,'iq'       => $self->_callback_maker(\&_jabber_in_iq_message)
                              );

    DEBUG("Connect. hostname => " . $self->server . ", port => " . $self->port);
    my %client_connect_hash = (
        hostname => $self->server,
        port => $self->port,
        tls => $self->tls,
        connectiontype => $self->connection_type,
        componentname  => $self->server_host,
    );

    my $status = $connection->Connect(%client_connect_hash);

    if(!defined $status) {
       ERROR("ERROR:  Jabber server is down or connection was not allowed: $!");
       die("Jabber server is down or connection was not allowed: $!");
    }

    DEBUG("Logging in... as user " . $self->username . " / " . $self->resource);
    DEBUG("PW: " . $self->password);

# Moved into connect hash via 'componentname'
#    my $sid = $connection->{SESSION}->{id};
#    $connection->{STREAM}->{SIDS}->{$sid}->{hostname} = $self->server_host;


    my @auth_result = $connection->AuthSend(username => $self->username,
                                            password => $self->password,
                                            resource => $self->resource,
                                            );

    if(!defined $auth_result[0] || $auth_result[0] ne "ok") {
        ERROR("Authorization failed: for " . $self->username . " / " . $self->resource);
        foreach my $result (@auth_result) {
            ERROR("$result");
        }
        die("Failed to re-connect: " . join("\n", @auth_result));
    }

    $connection->RosterRequest();

    $self->client_session_id($connection->{SESSION}->{id});

    DEBUG("Sending presence to tell world that we are logged in");
    $connection->PresenceSend();
    $self->Process(5);

    DEBUG("Getting Roster to tell server to send presence info");
    $connection->RosterGet();
    $self->Process(5);

    foreach my $forum (keys %{$self->forums_and_responses}) {
        $self->JoinForum($forum);
    }

    INFO("Connected to server '" . $self->server . "' successfully");
    $self->connect_time(time); # Track when we came online.
    return 1;
}

=item B<JoinForum>

Joins a jabber forum and sleeps safety time. Also prevents the object
from responding to messages for a grace period in efforts to get it to
not respond to historical messages. This has failed sometimes.

NOTE: No error detection for join failure is present at the moment. (TODO)

=cut

sub JoinForum {
    my $self = shift;
    my $forum_name = shift;

    DEBUG("Joining $forum_name on " . $self->conference_server . " as " . $self->alias);

    $self->jabber_client->MUCJoin(room    => $forum_name,
                                  server => $self->conference_server,
                                  nick   => $self->alias,
                                  );

    $self->forum_join_time->{$forum_name} = time;
    DEBUG("Sleeping " . $self->message_delay . " seconds");
    Time::HiRes::sleep $self->message_delay;
}

=item B<Process>

Mostly calls it's client connection's "Process" call.
Also assures a timeout is enforced if not fed to the subroutine
You really should not have to call this very often.
You should mostly be calling Start() and just let the Bot kernel handle all this.

=cut

sub Process { # Call connection process.
    my $self = shift;
    my $timeout_seconds = shift;

    #If not passed explicitly
    $timeout_seconds = $self->process_timeout if(!defined $timeout_seconds);

    my $process_return = $self->jabber_client->Process($timeout_seconds);
    return $process_return;
}

=item B<Start>

Primary subroutine save new called by the program. Does an endless loop of:
1. Process
2. If Process failed, Reconnect to server over larger and larger timeout
3. run background process fed from new, telling it who I am and how many loops we have been through.
4. Enforce a sleep to prevent server floods.

=cut

sub Start {
    my $self = shift;

    my $time_between_background_routines = $self->loop_sleep_time;
    my $process_timeout = $self->process_timeout;
    my $background_subroutine = $self->background_function;
    my $message_delay = $self->message_delay;

    my $last_background = time - $time_between_background_routines - 1; # Call background process every so often...
    my $counter = 0; # Keep track of how many times we've looped. Not sure if we'll use this long term.

    while(1) { # Loop for ever!
        # Process and re-connect if you have to.
        my $reconnect_timeout = 1;
        eval {$self->Process($process_timeout)};

        if($@) { #Assume the connection is down...
            my $message = "Disconnected from " . $self->server . ":" . $self->port
                        . " as " . $self->username;
            ERROR("$message Reconnecting...");
            sleep 5; # TODO: Make re-connect time flexible somehow
            $self->ReconnectToServer();
        }

        # Call background function
        if(defined $background_subroutine && $last_background + $time_between_background_routines < time) {
            &$background_subroutine($self, ++$counter);
            $last_background = time;
        }
        Time::HiRes::sleep $message_delay;
    }
}

=item B<ReconnectToServer>

You should not ever need to use this. the Start() kernel usually figures this out and calls it.

Internal process
1. Disconnects
3. Re-initializes

=cut

sub ReconnectToServer {
    my $self = shift;

    my $background_subroutine = $self->background_function;

    $self->Disconnect();

    my $sleep_time = 5;
    while (!$self->IsConnected()) { # jabber_client variable defines if we're connected.
        INFO("Sleeping $sleep_time before attempting re-connect");
        sleep $sleep_time;
        $sleep_time *= 2 if($sleep_time < 300);
        $self->InitJabber();
        INFO("Running background routine.");
        &$background_subroutine($self, 0); # call background proc so we can check for errors while down.
    }
}

=item B<Disconnect>

Disconnects from server if client object is defined. Assures the client object is deleted.

=cut


sub Disconnect {
    my $self = shift;

    $self->connect_time('9' x 10); # Way in the future

    INFO("Disconnecting from server");
    return if(!defined $self->jabber_client); # do not proceed, no object.

    $self->jabber_client->Disconnect();
    my $old_client = $self->jabber_client;
    $self->jabber_client(undef);

    DEBUG("Disconnected.");
    return 1;
}

=item B<IsConnected>

Reports connect state (true/false) based on the status of client_start_time.

=cut

sub IsConnected {
    my $self = shift;

    DEBUG("REF = " . ref($self->jabber_client));
    return $self->connect_time;
}

# TODO: ***NEED VERY GOOD DOCUMENTATION HERE*****
=item B<_process_jabber_message> - DO NOT CALL

Handles incoming messages.   

=cut

sub _process_jabber_message {
    my $self = shift;
    DEBUG("_process_jabber_message called");

    my $session_id = shift;
    my $message = shift;

    my $type = $message->GetType();
    my $fromJID = $message->GetFrom("jid");
    my $from_full = $message->GetFrom();

    my $from = $fromJID->GetUserID();
    my $resource = $fromJID->GetResource();
    my $subject = $message->GetSubject();
    my $body = $message->GetBody();

    my $reply_to = $from_full;
    $reply_to =~ s/\/.*$// if($type eq 'groupchat');

    # TODO: 
    # Don't know exactly why but when a message comes from gtalk-web-interface, it works well, but if the message comes from Gtalk client, bot dies
    #   my $message_date_text;  eval { $message_date_text = $message->GetTimeStamp(); } ; # Eval is a really bad idea. we need to understand why this is failing.

    #    my $message_date_text = $message->GetTimeStamp(); # Since we're not using the data, we'll turn this off since it crashes gtalk clients aparently?
    #    my $message_date = UnixDate($message_date_text, "%s") - 1*60*60; # Convert to EST from CST;

    # Ignore any messages within 10 seconds of start or join of that forum
    my $grace_period = $self->forum_join_grace;
    my $time_now = time;
    if($self->connect_time > $time_now - $grace_period
       || (defined $self->forum_join_time->{$from} && $self->forum_join_time->{$from} > $time_now - $grace_period)) {
        my $cond1 = $self->connect_time . " > $time_now - $grace_period";
        my $cond2 = $self->forum_join_time->{$from} || 'undef'
                    . " > $time_now - $grace_period";
        DEBUG("Ignoring messages cause I'm in startup for forum $from\n$cond1\n$cond2");
        return; # Ignore messages the first few seconds.
    }

    # Ignore Group messages with no resource on them. (Server Messages?)
    if($self->ignore_server_messages) {
        if($from_full !~ m/^([^\@]+)\@([^\/]+)\/(.+)$/) {
        DEBUG("Server message? ($from_full) - $message");
            return if($from_full !~ m/^([^\@]+)\@([^\/]+)\//);
            ERROR("Couldn't recognize from_full ($from_full). Ignoring message: $body");
            return;
        }
    }

    # Are these my own messages?
    if($self->ignore_self_messages ) { # TODO: || $self->safety_mode (this breaks tests in 06?)
        
        if(defined $resource && $resource eq $self->resource) { # Ignore my own messages.
            DEBUG("Ignoring message from self...\n");
            return;
        }
    }

    # Determine if this message was addressed to me. (groupchat only)
    my $bot_address_from;
    my @aliases_to_respond_to = $self->get_responses($from);

    if($#aliases_to_respond_to >= 0 and $type eq 'groupchat') {
        my $request;
        foreach my $address_type (@aliases_to_respond_to) {
            my $qm_address_type = quotemeta($address_type);
            next if($body !~ m/^\s*$qm_address_type\s*(\S.*)$/ms);
            $request = $1;
            $bot_address_from = $address_type;
            last; # do not need to loop any more.
        }
        DEBUG("Message not relevant to bot");
        return if(!defined $request);
        $body = $request;
    }

    # Call the message callback if it's defined.
    if( defined $self->message_function) {
        $self->message_function->(bot_object => $self,
                                  from_full => $from_full,
                                  body => $body,
                                  type => $type,
                                  reply_to => $reply_to,
                                  bot_address_from => $bot_address_from,
                                  message => $message
                                  );
        return;
    } else {
        WARN("No handler for messages!");
        INFO("New Message: $type from $from ($resource). sub=$subject -- $body");
    }
}

=item B<get_responses>

    $bot->get_ident($forum_name);

Returns the array of messages we are monitoring for in supplied forum or replies with undef.

=cut

sub get_responses {
    my $self = shift;

    my $forum = shift;

    if(!defined $forum) {
    WARN("No forum supplied for get_responses()");
    return;
    }

    my @aliases_to_respond_to;
    if(defined $self->forums_and_responses->{$forum}) {
        @aliases_to_respond_to = @{$self->forums_and_responses->{$forum}};
    }

    return @aliases_to_respond_to;
}


=item B<_jabber_in_iq_message> - DO NOT CALL

Called when the client receives new messages during Process of this type.

=cut

sub _jabber_in_iq_message {
    my $self = shift;

    my $session_id = shift;
    my $iq = shift;

    DEBUG("IQ Message:" . $iq->GetXML());
    my $from = $iq->GetFrom();
#    my $type = $iq->GetType();DEBUG("Type=$type");
    my $query = $iq->GetQuery();#DEBUG("query=" . Dumper($query));
    my $xmlns = $query->GetXMLNS();DEBUG("xmlns=$xmlns");
    my $iqReply;

    # Respond to version requests with information about myself.
    if($xmlns eq "jabber:iq:version") {
        # convert 5.010000 to 5.10.0
        my $perl_version = $];
        $perl_version =~ s/(\d{3})(?=\d)/$1./g; 
        $perl_version =~ s/\.0+(\d)/.$1/;
        
        $self->jabber_client
             ->VersionSend(to=> $from,
                           name=>__PACKAGE__,
                           ver=> $VERSION,
                           os=> "Perl v$perl_version");
    } else { # Unknown request. Just ignore it.
        return;
    }

    if($iqReply) {
        DEBUG("Reply: ", $iqReply->GetXML());
        $self->jabber_client->Send($iqReply);
    }

#    INFO("IQ from $from ($type). XMLNS: $xmlns");
}

=item B<_jabber_presence_message> - DO NOT CALL

Called when the client receives new presence messages during Process.
Mostly we are just pushing the data down into the client DB for later processing.

=cut

sub _jabber_presence_message {
    my $self = shift;

    my $session_id = shift;
    my $presence = shift;

    my $type = $presence->GetType();
    if($type eq 'subscribe') { # Always allow people to subscribe to us. Why wouldn't we?
        my $from = $presence->GetFrom();
        $self->jabber_client->Subscription(type=>"subscribe",
                                              to=>$from);
        $self->jabber_client->Subscription(type=>"subscribed",to=>$from);
        INFO("Processed subscription request from $from");
        return;
    } elsif($type eq 'unsubscribe') { # Always allow people to subscribe to us. Why wouldn't we?
        my $from = $presence->GetFrom();
        $self->jabber_client->Subscription(type=>"unsubscribed",
                                              to=>$from);
        INFO("Processed unsubscribe request from $from");
        return;
    }

    $self->jabber_client->PresenceDBParse($presence); # Since we are always an object just throw it into the db.

    my $from = $presence->GetFrom();
    $from = "." if(!defined $from);

    my $status = $presence->GetStatus();
    $status = "." if(!defined $status);

    DEBUG("Presence From $from t=$type s=$status");
    DEBUG("Presence XML: " . $presence->GetXML());
}

=item B<respond_to_self_messages>

    $bot->respond_to_self_messages($value = 1);


Tells the bot to start reacting to it\'s own messages if non-zero is passed. Default is 1.

=cut


sub respond_to_self_messages {
    my $self = shift;

    my $setting = shift;
    $setting = 1 if(!defined $setting);

    $self->ignore_self_messages(!$setting);
    return !!$setting;
}

=item B<get_messages_this_hour>

    $bot->get_messages_this_hour();

replys with number of messages sent so far this hour.

=cut


sub get_messages_this_hour {
    my $self = shift;

    my $yday = (localtime)[7];
    my $hour = (localtime)[2];
    my $messages_this_hour = $self->messages_sent_today->{$yday}->{$hour};
    return $messages_this_hour || 0; # Assure it's not undef to avoid math warnings
}

=item B<get_safety_mode>

Validates that we are in safety mode. Returns a bool as long as we are an object, otherwise returns undef

=cut

sub get_safety_mode {
    my $self = shift;

    # Must be in safety mode and all thresholds met.
    my $mode = $self->safety_mode
          && $self->message_delay >= 1/5
          && $self->max_message_size <= 1000
          && $self->max_messages_per_hour <= 166
          && $self->ignore_self_messages
         ;
         
    return $mode || 0;
}

=item B<SendGroupMessage>

    $bot->SendGroupMessage($name, $message);

Tells the bot to send a message to the recipient room name

=cut

sub SendGroupMessage {
    my $self = shift;
    my $recipient = shift;
    my $message = shift;

    $recipient .= '@' . $self->conference_server if($recipient !~ m{\@});

    return $self->SendJabberMessage($recipient, $message, 'groupchat');
}

=item B<SendPersonalMessage>

    $bot->SendPersonalMessage($recipient, $message);

How to send an individual message to someone.

$recipient must read as user@server/Resource or it will not send.

=cut

sub SendPersonalMessage {
    my $self = shift;
    my $recipient = shift;
    my $message = shift;

    return $self->SendJabberMessage($recipient, $message, 'chat');
}

=item B<SendJabberMessage>

    $bot->SendJabberMessage($recipient, $message, $message_type, $subject);

The master subroutine to send a message. Called either by the user, SendPersonalMessage, or SendGroupMessage. Sometimes there
is call to call it directly when you do not feel like figuring you messaged you.
Assures message size does not exceed a limit and chops it into pieces if need be.

NOTE: non-printable characters (unicode included) will be stripped before sending to the server via:
    s/[^[:print:]]+/./xmsg

=cut

sub SendJabberMessage {
    my $self = shift;

    my $recipient = shift;
    my $message = shift;
    my $message_type = shift;
    my $subject = shift;

    my $max_size = $self->max_message_size;

    # Split the message into no more than max_message_size so that we do not piss off jabber.
    # Split on new line. Space if you have to or just chop at max size.
    my @message_chunks = ( $message =~ /.{1,$max_size}$|.{1,$max_size}\n|.{1,$max_size}\s|.{1,$max_size}/gs );


    DEBUG("Max message = $max_size. Splitting...") if($#message_chunks > 0);
    my $return_value;
    foreach my $message_chunk (@message_chunks) {
        my $msg_return = $self->_send_individual_message($recipient, $message_chunk, $message_type, $subject);
        if(defined $msg_return) {
            $return_value .= $msg_return;
        }
    }
    return $return_value;
}

# $self->_send_individual_message($recipient, $message_chunk, $message_type, $subject);
# Private subroutine only called directly by SetForumSubject and SendJabberMessage.
# There are a bunch of fancy things this does, but the important things are:
# 1. sleep a minimum of .2 seconds every message
# 2. Make sure we have not sent too many messages this hour and block sends if they are attempted over a certain limit (max limit is 125)
# 3. Strip out special characters that will get us booted from the server.

sub _send_individual_message {
    my $self = shift;

    my $recipient = shift;
    my $message_chunk = shift;
    my $message_type = shift;
    my $subject = shift;

    if(!defined $message_type) {
        ERROR("Undefined \$message_type");
        return "No message type!\n";
    }

    if(!defined $recipient) {
        ERROR('$recipient not defined!');
        return "No recipient!\n";
    }

    my $yday = (localtime)[7];
    my $hour = (localtime)[2];
    my $messages_this_hour = $self->messages_sent_today->{$yday}->{$hour} += 1;

    if($messages_this_hour > $self->max_messages_per_hour) {
        $subject = "" if(!defined $subject); # Keep warning messages quiet.
        $message_chunk = "" if(!defined $message_chunk); # Keep warning messages quiet.

        ERROR("Can't Send message because we've already tried to send $messages_this_hour of $self->max_messages_per_hour messages this hour.\n"
              . "To: $recipient\n"
              . "Subject: $subject\n"
              . "Type: $message_type\n"
              . "Message sent:\n"
              . "$message_chunk"
              );

        # Send 1 panic message out to jabber if this is our last message before quieting down.
        return "Too many messages ($messages_this_hour)\n";
    }

    if(!$self->IsConnected) {
        $subject = "" if(!defined $subject); # Keep warning messages quiet.
        $message_chunk = "" if(!defined $message_chunk); # Keep warning messages quiet.

        ERROR("Can't Jabber server is down. Tried to send: \n"
              . "To: $recipient\n"
              . "Subject: $subject\n"
              . "Type: $message_type\n"
              . "Message sent:\n"
              . "$message_chunk"
              );

        # Send 1 panic message out to jabber if this is our last message before quieting down.
        return "Server is down.\n";
    }

    # Strip out anything that's not a printable character
    # Now with unicode support?
    $message_chunk =~ s/[^[:print:]]+/./xmsg; 

    my $message_length = length($message_chunk);
    DEBUG("Sending message $yday-$hour-$messages_this_hour $message_length bytes to $recipient");
    $self->jabber_client->MessageSend(to => $recipient
                     , body => $message_chunk
                     , type => $message_type
#                     , from => $connection_hash{$obj_ID}{'from_full'}
                     , subject => $subject
                     );

    DEBUG("Sleeping " . $self->message_delay . " after sending message.");
    Time::HiRes::sleep $self->message_delay; #Throttle messages.

    if($messages_this_hour == $self->max_messages_per_hour) {
        $self->jabber_client->MessageSend(to => $recipient
                         , body => "Cannot send more messages this hour. "
                         . "$messages_this_hour of " . $self->max_messages_per_hour . " already sent."
                         , type => $message_type
                         );
    }
    return; # Means we succeeded!
}

=item B<SetForumSubject>

    $bot->SetForumSubject($recipient, $subject);

Sets the subject of a forum

=cut

sub SetForumSubject {
    my $self = shift;

    my $recipient = shift;
    my $subject = shift;

    if(length $subject > $self->max_message_size) {
    my $subject_len = length($subject);
    ERROR("Someone tried to send a subject message $subject_len bytes long!");
    my $subject = substr($subject, 0, $self->max_message_size);
    DEBUG("Truncated subject: $subject");
    return "Subject is too long!";
    }
    $self->_send_individual_message($recipient, "Setting subject to $subject", 'groupchat', $subject);

    return;
}

=item B<ChangeStatus>

    $bot->ChangeStatus($presence_mode, $status_string);

Sets the Bot's presence status.
$presence mode could be something like: (Chat, Available, Away, Ext. Away, Do Not Disturb).
$status_string is an optional comment to go with your presence mode. It is not required.

=cut

sub ChangeStatus {
    my $self = shift;
    my $presence_mode = shift;
    my $status_string = shift; # (optional)

    $self->jabber_client->PresenceSend(show=>$presence_mode, status=>$status_string);

    return 1;
}

=item B<GetRoster>

    $bot->GetRoster();

Returns a list of the people logged into the server.
I suspect we really want to know who is in a paticular forum right?
In which case we need another sub for this.
=cut

sub GetRoster {
    my $self = shift;

    my @rosterlist;
    foreach my $jid ($self->jabber_client->RosterDBJIDs()) {
        my $username =$jid->GetJID();
        push(@rosterlist, $username) ;
    }
    return @rosterlist;
}

=item B<GetStatus>

Need documentation from Yago on this sub.

=cut

sub GetStatus {

    my $self = shift;
    my ($jid) = shift;

    my $Pres = $self->jabber_client->PresenceDBQuery($jid);

    if (!(defined($Pres))) {

        return "unavailable" ;
    }

    my $show = $Pres->GetShow();
    if ($show) {

        return $show;
    }

    return "available";

}

=item B<AddUser>

Need documentation from Yago on this sub.

=cut

sub AddUser {
    my $self = shift;
    my $user = shift;

    $self->jabber_client->Subscription(type=>"subscribe", to=>$user);
    $self->jabber_client->Subscription(type=>"subscribed",to=>$user);
}

=item B<RmUser>

Need documentation from Yago on this sub.

=cut

sub RmUser {
    my $self = shift;
    my $user = shift;

    $self->jabber_client->Subscription(type=>"unsubscribe", to=>$user);
    $self->jabber_client->Subscription(type=>"unsubscribed",to=>$user);
}
=back

=head1 AUTHOR

Todd Rinaldo C<< <perl-net-jabber-bot@googlegroups.com) > >>

=head1 BUGS

Please report any bugs or feature requests to
C<perl-net-jabber-bot@googlegroups.com>, or through the web interface at
L<http://code.google.com/p/perl-net-jabber-bot/issues/entry>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Jabber::Bot

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Jabber-Bot>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Jabber-Bot>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Jabber-Bot>

=item * Project homepage

L<http://code.google.com/p/perl-net-jabber-bot/>

=item * Google Issue Tracker (reporting bugs)

L<http://code.google.com/p/perl-net-jabber-bot/issues/entry>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Todd E Rinaldo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
no MooseX::Types;
1; # End of Net::Jabber::Bot
