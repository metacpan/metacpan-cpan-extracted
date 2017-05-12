use POE;

ElizaBot->new(
    Nick => 'doctor',
    Server => 'grou.ch',
    Port => 6667,
    );

$poe_kernel->run();
exit(0);

package ElizaBot;
use Chatbot::Eliza;
use POE;
use POE::Component::IRC::Object;
use base qw(POE::Component::IRC::Object);

BEGIN { $chatbot = Chatbot::Eliza->new(); }

sub irc_001 {
    $_[OBJECT]->join( "#elizabot" );
    print "Joined channel #elizabot\n";
}

sub irc_public {
    my ($self, $kernel, $who, $where, $msg) = 
      @_[OBJECT, ARG0, ARG1, ARG2];
    
    $msg =~ s/^doctor[:,]?\s+//;
    
    my ($nick, undef) = split(/!/, $who, 2);
    my $channel = $where->[0];
    
    my $response = $chatbot->transform($msg);
    $self->privmsg( $channel, "$nick: $response" );
}

sub irc_join {
    my ($self, $who, $channel) = 
      @_[OBJECT, ARG0, ARG1];
    
    my ($nick, undef) = split(/!/, $who, 2);
    $self->privmsg( $channel, "$nick: How can I help you?" );
}

1;