#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use POE qw(Component::IRC Component::IRC::Plugin::Blowfish);

my $nickname  = 'BlowFish' . $$;
my $ircname   = 'Blowing fish';
my $ircserver = 'irc.perl.org';
my $port      = 6667;
my $channel   = '#POE-Component-IRC-Plugin-Blowfish';
my $bfkey     = 'secret';

my $irc = POE::Component::IRC->spawn(
    nick         => $nickname,
    server       => $ircserver,
    port         => $port,
    ircname      => $ircname,
    debug        => 0,
    plugin_debug => 1,
    options      => { trace => 0 },
) or die "Oh noooo! $!";

POE::Session->create(
    package_states => [ 'main' => [qw(_start irc_public irc_001 irc_join)], ],
);

$poe_kernel->run();
exit 0;

sub _start {

    # Create and load our plugin
    $irc->plugin_add( 'BlowFish' =>
          POE::Component::IRC::Plugin::Blowfish->new( $channel => $bfkey ) );

    $irc->yield( register => 'all' );
    $irc->yield( connect  => {} );
    undef;
}

sub irc_001 {
    $irc->yield( join => $channel );
    undef;
}

sub irc_join {
    my ( $kernel, $sender, $channel ) = @_[ KERNEL, SENDER, ARG1 ];
    $kernel->post(
        $irc => privmsg => $channel => 'hello this is an encrypted message' );
    undef;
}

sub irc_public {
    my ( $kernel, $sender, $who, $where, $msg ) =
      @_[ KERNEL, SENDER, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $chan = $where->[0];

    my @args = split /\s+/, $msg;
    my $cmd = shift @args;

    if ( $cmd eq '!setkey' ) {
        $kernel->yield( set_blowfish_key => (@args)[ 0, 1 ] );
    }

    elsif ( $cmd eq '!delkey' ) {
        $kernel->yield( del_blowfish_key => $args[0] );
    }

    elsif ( $cmd eq '!test' ) {
        $kernel->post(
            $irc => privmsg => $chan => 'this is a test message...' );
    }
}
