#!/usr/bin/perl -w

use Getopt::Long;
use POE qw(Component::IRC::State Wheel::ReadLine);
use Data::Dumper;

$Data::Dumper::Indent = 1;

my $nick;
my $user;
my $server;
my $port;
my $ircname;
my $password;
my $current_channel;
my $socks_proxy;
my $socks_port;
my $socks_id;
my $no_dns;

GetOptions(
"nick=s" => \$nick,
"server=s" => \$server,
"user=s" => \$user,
"port=s" => \$port,
"pass=s" => \$password,
"socksproxy=s" => \$socks_proxy,
"socksport=s" => \$socks_port,
"socksuser=s" => \$socks_id,
"ircname=s" => \$ircname,
"nodns" => \$no_dns,
);

die unless $nick and $server;
print "$nick $server\n";

my $irc = POE::Component::IRC::State->spawn( Nick => $nick, Server => $server, Port => $port, Ircname => $ircname, Username => $user, Password => $password, socks_proxy => $socks_proxy, socks_port => $socks_port, socks_id => $socks_id, NoDNS => $no_dns );

print STDOUT $irc->version(), "\n";

POE::Session->create(
	package_states => [
		'main' => [ qw(_start _stop got_input parse_input _default irc_public) ],
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
    undef;
}

sub _stop {
  delete $_[HEAP]->{readline_wheel};
  $irc->yield( unregister => 'all' );
  $irc->yield( 'shutdown' );
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
	if ( $cmd eq 'dump_state' ) {
	  unless (@args) {
    	    $heap->{readline_wheel}->put($_) for split /\n/, Dumper($irc->{STATE});
	  } else {
	    open my $fh, ">", $args[0] or return;
	    print $fh Dumper($irc->{STATE});
	  }
	  last SWITCH;
	}
	if ( $cmd eq 'sl' or $cmd eq 'quote' ) {
	  $irc->yield( $cmd => join ( ' ', @args ) );
	} else {
	  $irc->yield( $cmd => @args );
	}
        $heap->{readline_wheel}->put($cmd . " " . join(' ',@args) );
    }
  }
  undef;
}

sub _default {
    my ( $event, $args ) = @_[ ARG0 .. $#_ ];
    my (@output);

    my $arg_number = 0;
    foreach (@$args) {
	SWITCH: {
        if ( ref($_) eq 'ARRAY' ) {
            push ( @output, "[", join ( ", ", @$_ ), "]" );
	    last SWITCH;
        }
	if ( ref($_) eq 'HASH' ) {
	    push ( @output, "{", join ( ", ", %$_ ), "}" );
	    last SWITCH;
	}
        push ( @output, "'$_'" );
	}
        $arg_number++;
    }
    $_[HEAP]->{readline_wheel}->put("$event " . join(' ',@output) ) if ( defined ( $_[HEAP]->{readline_wheel} ) );
    return 0;    # Don't handle signals.
}

sub irc_public {
  my ($kernel,$heap,$who,$where,$what) = @_[KERNEL,HEAP,ARG0,ARG1,ARG2];
  my ($nick) = ( split /!/, $who )[0];
  my ($chan) = $where->[0];

  $heap->{readline_wheel}->put($chan . ':<' . $nick . '> ' . $what);
  undef;
}
