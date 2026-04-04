package Net::Jabber::Client;

use strict;
use warnings;
use Net::Jabber;
use Log::Log4perl qw(:easy);

# NOTE: Need to inherit from Jabber bot object so we don't have to re-do message code, etc.

# Package variables for simulating connection/process failures in tests
our $connect_fail_remaining = 0;
our $process_die_remaining = 0;
our $process_return_undef_remaining = 0;

sub new {
    my $proto = shift;
    my $self = { };

    bless($self, $proto);
    $self->init(@_);

    $self->{SESSION}->{id} = int(rand(9999)); # Gen a random session ID.
    
    my @empty_array;
    $self->{message_queue} = \@empty_array;
    $self->{is_connected} = 1;
    $self->{presence_callback} = undef;
    $self->{iq_callback}       = undef;
    $self->{message_callback}  = undef;

    $self->{server} = undef;
    $self->{username} = undef;
    $self->{password} = undef;
    $self->{resource} = undef;
    $self->{muc_nicks} = {};

    $self->{subscription_log} = [];
    $self->{muc_join_log} = [];
    $self->{presence_send_log} = [];
    $self->{sent_messages_log} = [];
    $self->{roster_jids} = [];
    $self->{presence_db} = {};

    return $self;
}

# Read from array of messages and pass them to the message functions.
sub Process {
    my $self = shift;
    my $timeout = shift or 0;

    # Simulate Process() dying (e.g., XML parse error, socket exception)
    if ($process_die_remaining > 0) {
        $process_die_remaining--;
        die "Simulated connection error\n";
    }

    # Simulate Process() returning undef (silent connection loss)
    if ($process_return_undef_remaining > 0) {
        $process_return_undef_remaining--;
        return undef;
    }

    return if(!$self->{is_connected}); # Return undef if we're not connected.

    foreach my $message (@{$self->{message_queue}}) {
        next if(!defined $self->{message_callback});
        $self->{message_callback}->($self->{SESSION}->{id}, $message);
    }

    @{$self->{message_queue}} = ();

    return 1; # undef means we lost connection.
}

sub PresenceSend {
    my $self = shift;
    my %args = @_;
    push @{$self->{presence_send_log}}, \%args;
}


sub SetCallBacks {
    my $self = shift;
    my %callbacks = @_;

    $self->{presence_callback} = $callbacks{'presence'};
    $self->{iq_callback}       = $callbacks{'iq'};
    $self->{message_callback}  = $callbacks{'message'};
}

sub Connect {
    my $self = shift;

    $self->{server} = shift;

    if ($connect_fail_remaining > 0) {
        $connect_fail_remaining--;
        return undef; # Simulate connection failure.
    }

    return 1; # Confirm we're connected.
}

sub AuthSend {
    my $self = shift;

    my %arg_hash = @_;
    $self->{'username'} = $arg_hash{'username'};
    $self->{'password'} = $arg_hash{'password'};
    $self->{'resource'} = $arg_hash{'resource'};
    
    return ("ok", "connected"); # Always confirm auth succeeds.
}

sub MessageSend { #Loop the messages into the in queue so we can see the server send em back. Needs peer review
    my $self = shift;
    my %arg_hash = @_;

    # Log the raw send arguments for test inspection
    push @{$self->{sent_messages_log}}, { %arg_hash };
    my $message = new Net::Jabber::Message();

    my $sent_to = $arg_hash{'to'};

    my ($forum, $server) = split(/\@/, $sent_to, 2);
    $server =~ s{\/.*$}{}; # Remove the /resource if it came from an individual, not a groupchat

    # In MUC (groupchat), real XMPP servers use the room nickname as the
    # resource in the from JID, not the XMPP resource. Use the stored MUC
    # nick when available for groupchat messages to match real behavior.
    my $from_resource = $self->{resource};
    if ( ($arg_hash{'type'} || '') eq 'groupchat' ) {
        my $room_jid = "$forum\@$server";
        $from_resource = $self->{muc_nicks}{$room_jid} || $from_resource;
    }

    my $from = "$forum\@$server/$from_resource";
    my $to   = "$self->{username}\@$self->{server}/$self->{resource}";
    DEBUG("$sent_to --- $from --- $to");
    
    $message->SetFrom($from);
    $message->SetTo($to);
    $message->SetType($arg_hash{'type'});
    $message->SetSubject($arg_hash{'subject'});
    $message->SetBody($arg_hash{'body'});
    
#    ERROR($message->GetXML()); exit;

    push @{$self->{message_queue}}, $message;
}

sub MUCJoin {
    my $self = shift;
    my %args = @_;
    push @{$self->{muc_join_log}}, \%args;
    # Track the MUC nickname for each room so MessageSend can use it
    # in the from JID, matching real XMPP MUC server behavior.
    my $room   = $args{room}   || '';
    my $server = $args{server} || '';
    my $nick   = $args{nick}   || $self->{resource};
    $self->{muc_nicks}{"$room\@$server"} = $nick;
}

sub Disconnect {
    my $self = shift;
    $self->{is_connected} = 0;
}

sub Send {;} # Used for IQ. need to see if we need to put something here.

sub Subscription {
    my $self = shift;
    my %args = @_;
    push @{$self->{subscription_log}}, \%args;
}
sub RosterGet {;}
sub RosterDB {;}
sub RosterRequest {;}
sub RosterDBJIDs {
    my $self = shift;
    return @{$self->{roster_jids}};
}
sub PresenceDB {;}

sub PresenceDBParse {
    my $self = shift;
    my $presence = shift;
    # Store presence by from JID for later query
    my $from = $presence->GetFrom();
    $self->{presence_db}{$from} = $presence if defined $from;
}

sub PresenceDBQuery {
    my $self = shift;
    my $jid = shift;
    return $self->{presence_db}{$jid};
}

sub VersionSend {
    my $self = shift;
    my %args = @_;
    $self->{last_version_send} = \%args;
}

1;
