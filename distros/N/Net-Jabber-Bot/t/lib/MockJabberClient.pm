package Net::Jabber::Client;

use strict;
use warnings;
use Net::Jabber;
use Log::Log4perl qw(:easy);

# NOTE: Need to inherit from Jabber bot object so we don't have to re-do message code, etc.

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

    return $self;
}

# Read from array of messages and pass them to the message functions.
sub Process {
    my $self = shift;
    my $timeout = shift or 0;

    return if(!$self->{is_connected}); # Return undef if we're not connected.

    foreach my $message (@{$self->{message_queue}}) {
        $timeout = 0; # zero out sleep timer;
        next if(!defined $self->{message_callback});
        $self->{message_callback}->($self->{SESSION}->{id}, $message);
    }
    
    
    @{$self->{message_queue}} = ();

    sleep $timeout;
    return 1; # undef means we lost connection.
}

sub PresenceSend {;}


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
    return 1; # Always confirm we're connected.
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
    my $message = new Net::Jabber::Message();
    
    my $sent_to = $arg_hash{'to'};
    
    my ($forum, $server) = split(/\@/, $sent_to, 2);
    $server =~ s{\/.*$}{}; # Remove the /resource if it came from an individual, not a groupchat
    
    my $from = "$forum\@$server/$self->{resource}";
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

sub MUCJoin {; }

sub Disconnect {
    my $self = shift;
    $self->{is_connected} = 1;
}

sub Send {;} # Used for IQ. need to see if we need to put something here.

sub Subscription {;} # Used to process JabberPresenceMessages we don't really use this data at the moment.
sub RosterGet {;}
sub PresenceDB {;}
sub PresenceDBParse{;}

1;
