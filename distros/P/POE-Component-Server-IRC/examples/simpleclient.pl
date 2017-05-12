#!/usr/local/bin/perl -w

use Getopt::Long;
use POE qw(Component::IRC Wheel::ReadLine Component::IRC::Plugin::CTCP);

my $nick;
my $user;
my $server;
my $port;
my $pass;
my $ircname;
my $localaddr;
my $current_channel;

GetOptions(
"nick=s" => \$nick,
"server=s" => \$server,
"user=s" => \$user,
"port=s" => \$port,
"ircname=s" => \$ircname,
"password=s" => \$pass,
"localaddr=s" => \$localaddr
);

die unless $nick and $server;
print "$nick $server\n";

my $irc = POE::Component::IRC->spawn( password => $pass, Nick => $nick, Server => $server, Port => $port, Ircname => $ircname, Username => $user, Raw => 1, LocalAddr => $localaddr );

POE::Session->create(
	package_states => [
		'main' => [ qw(_start _stop got_input parse_input irc_raw) ],
		'main' => { 'irc_error' => '_error',
			    'irc_disconnected' => '_error',
			    'irc_socketerr' => '_error',
			  },
	],
);

$poe_kernel->run();
exit 0;

sub _start {
    my $heap = $_[HEAP];
    $heap->{readline_wheel} =
      POE::Wheel::ReadLine->new( InputEvent => 'got_input' );
    $heap->{readline_wheel}->get("> ");
    $irc->yield( register => 'all' );
    $irc->plugin_add( 'CTCP' => POE::Component::IRC::Plugin::CTCP->new() );
    undef;
}

sub _stop {
  delete $_[HEAP]->{readline_wheel};
  $irc->yield( unregister => 'all' );
  $irc->yield( 'shutdown' );
  undef;
}

sub _error {
  $_[HEAP]->{readline_wheel}->put(join ' ', "$_[STATE]:", @_[ARG0..$#_]);
  undef;
}

sub got_input {
    my ( $heap, $kernel, $input, $exception ) = @_[ HEAP, KERNEL, ARG0, ARG1 ];

    if ( defined $input ) {
        $heap->{readline_wheel}->addhistory($input);
        #$heap->{readline_wheel}->put("I heard $input");
	$kernel->yield( 'parse_input' => $input );
    }
    elsif ( $exception eq 'interrupt' ) {
        $heap->{readline_wheel}->put("Goodbye.");
        delete $heap->{readline_wheel};
	$irc->yield( unregister => 'all' );
	$irc->yield( 'shutdown' );
        return;
    }
    else {
        $heap->{readline_wheel}->put("\tException: $exception");
	if ( $exception eq 'eot' ) {
	   $irc->yield( unregister => 'all' );
	   $irc->yield( 'shutdown' );
	   delete ( $heap->{readline_wheel} );
	}
    }

    $heap->{readline_wheel}->get("> ") if ( $heap->{readline_wheel} );
    undef;
}

sub parse_input {
  my ($kernel, $heap, $input) = @_[KERNEL,HEAP,ARG0];

  # Parse input
  if ( $input =~ /^\//) {
    $input =~ s/^\///;
    my (@args) = split(/ /,$input);
    my ($cmd) = shift @args;
    SWITCH: {
	if ( $cmd eq 'connect' ) {
	  if ( $irc->connected() ) {
		$heap->{readline_wheel}->put("Already connected");
		last SWITCH;
	  }
    	  $heap->{readline_wheel}->put("Connecting");
	  $irc->yield( 'connect' );
	  last SWITCH;
	}
	$irc->yield( $cmd => @args ) unless $cmd eq 'sl';
	$irc->yield( $cmd => join ' ', @args ) if $cmd eq 'sl';
        $heap->{readline_wheel}->put($cmd . " " . join(' ',@args) );
    }
  }
  undef;
}

sub irc_raw {
  $_[HEAP]->{readline_wheel}->put($_[ARG0]);
  undef;
}
