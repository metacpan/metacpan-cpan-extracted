package SomeIrcBot::Plugins::megaHAL;
use strict;
use warnings;
use POE;
use POE::Component::AI::MegaHAL;
our $name     = "SomeIrcBot::Plugins::megaHAL";
our $longname = "megaHAL plugin for jamesd";
our $license  = "GPL";
our $VERSION  = "0.1";
our $author   = 'whoppix <elektronenvolt@quantentunnel.de>';

my $pluginmanager;
my $shutdown_reason;
my $spam_channel = "#orakel"; # in this channel we will answer on every message.
my $irc; # the PoCo::IRC object, that the application gave us as plugin_data
sub new {
    my $type = shift;
    $pluginmanager = shift;
    $irc = shift;
    POE::Session->create(
        'inline_states' => {
            '_start'     => \&start,
            '_stop'      => \&stop,
            'sig_DIE'    => \&handle_die,
            'shutdown'   => \&plugin_shutdown,
            'irc_public' => \&irc_public,
            '_got_reply' => \&got_reply,
        },
    ) or die '[$name] Failed to spawn a new session.';
}

sub start {
    $_[KERNEL]->sig( DIE => 'sig_DIE' );
    $_[KERNEL]->alias_set($name);
    $irc->yield( register => 'public' );
    my $poco = POE::Component::AI::MegaHAL->spawn(
        autosave => 1,
        debug    => 0,
        path     => '.',
        alias    => 'megaHAL',
        options  => { trace => 0 }
    );

    return [ $name, $longname, $license, $VERSION, $author ];
}

sub stop {
    print "[$name] is unloaded.\n";
    return $shutdown_reason;
}

sub handle_die {
    print "[$name] plugin died\n";
    my ( $sig, $ex ) = @_[ ARG0, ARG1 ];
    $pluginmanager->error($ex);
    $_[KERNEL]->sig_handled();
}

sub plugin_shutdown {
    my $timing  = $_[ARG0];
    my $message = $_[ARG1];
    print "[$name] received shutdown signal: $timing because of: $message\n";
    $shutdown_reason = $message;
    $_[KERNEL]->alias_remove($name);
    $_[KERNEL]->post( 'megaHAL' => 'shutdown' );
    $irc->yield( unregister => 'public' );
}

sub irc_public {
    my ( $kernel, $sender, $who, $where, $what ) = @_[ KERNEL, SENDER, ARG0, ARG1, ARG2 ];
    my $nick = ( split( /!/, $who ) )[0];
    my $channel = $where->[0];
    if ( $what =~ m/^!orakel/ || $channel eq $spam_channel ) {
        my @tokens = split( / /, $what );
        shift @tokens;    #removing command
        my $request = join( " ", @tokens );
        $_[KERNEL]->post(
            'megaHAL' => do_reply => {
                text    => $request,
                event   => '_got_reply',
                nick    => $nick,
                channel => $channel,
            }
        );
    }
    else {                # feed the bot channel input
        $_[KERNEL]->post(
            'megaHAL' => do_reply => {
                text  => $what,
                event => 'no_reply',
            }
        );
    }

}

sub got_reply {
    my $reply   = $_[ARG0];
    my $answer  = $reply->{reply};
    my $who     = $reply->{nick};
    my $channel = $reply->{channel};
    $irc->yield( 'privmsg' => $channel => $who . ": " . $answer );

}
return 1;
