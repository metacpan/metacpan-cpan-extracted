package SomeIrcBot::Plugins::bmi_calc;
use strict;
use warnings;
use POE;
our $name     = "SomeIrcBot::Plugins::bmi_calc";
our $longname = "Body Mass index calculation plugin";
our $license  = "GPL";
our $VERSION  = "0.5";
our $author   = 'whoppix <elektronenvolt@quantentunnel.de>, paul <paul@computer-talk.de>';

my $pluginmanager;
my $shutdown_reason;
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
        },
    ) or die '[$name] Failed to spawn a new session.';
}

sub start {
    $_[KERNEL]->sig( DIE => 'sig_DIE' );
    $_[KERNEL]->alias_set($name);
    $irc->yield( register => 'public' );
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
    $_[KERNEL]->yield( 'shutdown', 'immediate', 'exception ocurred: plugin has to terminate.' );
    $_[KERNEL]->sig_handled();
}

sub plugin_shutdown {
    my $timing  = $_[ARG0];
    my $message = $_[ARG1];
    print "[$name] received shutdown signal: $timing because of: $message\n";
    $shutdown_reason = $message;
    $irc->yield( unregister => 'public' );
    $_[KERNEL]->alias_remove($name);
}

sub irc_public {
    my ( $kernel, $sender, $who, $where, $what ) = @_[ KERNEL, SENDER, ARG0, ARG1, ARG2 ];
    my $nick = ( split( /!/, $who ) )[0];
    my $channel = $where->[0];

    if ( $what =~ /^!bmi .*/i ) {
        if ( my (@in) = $what =~ /^!bmi\W+(.+),\W*(.+)/ ) {
            my $in = eval { $in[0] / ( ( $in[1] / 100 ) * ( $in[1] / 100 ) ) };
            if ($@) {
                $irc->yield( 'privmsg' => $channel => "Invalid Parameters! Usage: !bmi \x02wheight\x0F, \x02Size in cm\x0F" );
            }
            else {
                $irc->yield( 'privmsg' => $channel => sprintf( "%s has a BMI of \x02%.2f\x0F", $nick, $in ) );
            }
        }
        else {
            $irc->yield( 'privmsg' => $channel => "Usage: !bmi \x02wheight\x0F, \x02Size in cm\x0F" );
        }
    }
}

return 1;