#!/usr/bin/perl -w
#
# tinyurl.pl listens on a channel for URLs longer than a certain length,
# and then makes a tinyurl shortcut to them for the convenience of the
# poor bastards using terminal-based IRC clients.
#
# -- dennis taylor, <dennis@funkplanet.com>

use strict;
use POE;
use POE::Component::IRC;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request::Common;
use URI::Find;     # but... but... who'd want to?
use constant MIN_URL_LENGTH => 60;

my @urls;
my $finder = URI::Find->new( sub { push @urls, $_[1]; } );
my $ua = LWP::UserAgent->new();
my $chan = '#tempura';
my $nick = 'ebi';
my %services = ( tinyurl => \&_get_tinyurl,
		 shorl   => \&_get_shorl,
		 masl    => \&_get_masl,
		 shorter => \&_get_shorter, );
my $current = 'tinyurl';


sub _start {
  my ($kernel) = $_[KERNEL];

  $ua->agent( 'Mozilla/5.0 (X11; U; Linux i386; en-US; rv:1.0.0) Gecko/20020529' );
  $kernel->post( 'urlbot', 'register', 'all');
  $kernel->post( 'urlbot', 'connect', { Debug    => 1,
					 Nick     => $nick,
					 Server   => $ARGV[0] ||
					             'scissorman.phreeow.net',
					 Port     => $ARGV[1] || 6667,
					 Username => 'neenio',
					 Ircname  => "tinyurl.pl", }
	       );
}

sub irc_001 {
  my ($kernel) = $_[KERNEL];

  $kernel->post( 'urlbot', 'mode', $nick, '+i' );
  $kernel->post( 'urlbot', 'join', $chan );
}

sub irc_disconnected {
  my ($server) = $_[ARG0];
  print "Lost connection to server $server.\n";
}

sub irc_error {
  my $err = $_[ARG0];
  print "Server error occurred! $err\n";
}

sub irc_socketerr {
  my $err = $_[ARG0];
  print "Couldn't connect to server: $err\n";
}

sub _stop {
  my ($kernel) = $_[KERNEL];

  print "Control session stopped.\n";
  $kernel->call( 'urlbot', 'quit', 'Neenios on ice!' );
}

sub irc_public {
  my ($kernel, $who, $chan, $msg) = @_[KERNEL, ARG0 .. ARG2];
  make_tiny( $kernel, $who, $chan, $msg, 0 );
}

sub irc_msg {
  my ($kernel, $who, $chan, $msg) = @_[KERNEL, ARG0 .. ARG2];
  make_tiny( $kernel, $who, $chan, $msg, 1 );
}

sub make_tiny {
  my ($kernel, $who, $chan, $msg, $private) = @_;
  $who =~ s/^(.*)!.*$/$1/ or die "Weird-ass who: $who";

  # IGNORE INFOBOTS. ALL MUST DIE.
  return if $who eq "pea";

  if ($msg =~ /^\s*$nick[:,\-!](?:\s*please)?\s*switch to (\w+)/i
	and not $private) {
    my $new_service = $1;
    if (exists $services{$new_service}) {
      $current = $new_service;
      $kernel->post( 'urlbot', 'privmsg', $chan, 'Done.' );
    } else {
      my $known = join ', ', keys %services;
      $kernel->post( 'urlbot', 'privmsg', $chan,
		     "Sorry, $who, I don't know that service. Here are the ones I do know about: $known." );
    }

  } else {
    $finder->find( \$msg );
    while (@urls) {
      my $url = shift @urls;
      next if length $url < MIN_URL_LENGTH;
      $kernel->post( 'urlbot', 'privmsg', $private ? $who : $chan,
		     $services{$current}->( $who, $url ) );
    }
  }
}



sub _get_tinyurl {
  my ($who, $url) = @_;
  my $re = '<blockquote>(http://tinyurl\.com/.*?)</blockquote>';
  my $response = $ua->request( POST 'http://tinyurl.com/create.php',
			       [ url => $url ] );
  if ($response->is_success and $response->content =~ /$re/) {
    return "$who\'s url is at $1";
  } else {
    return 'tinyurl.com sucks.';
  }
}

sub _get_shorl {
  my ($who, $url) = @_;
  my $re = 'Shorl: <a href=".*?">(http://shorl\.com/.*?)</a><br>';
  my $response = $ua->request( POST 'http://shorl.com/create.php',
			       [ url => $url ] );
  if ($response->is_success and $response->content =~ /$re/) {
    return "$who\'s url is at $1";
  } else {
    return 'shorl.com sucks.';
  }
}

sub _get_masl {
  my ($who, $url) = @_;
  my $re = 'Your shorter link is: <a href="(http://makeashorterlink\.com/.*?)">';
  my $response = $ua->request( POST 'http://makeashorterlink.com/index.php',
			       [ url => $url ] );
  if ($response->is_success and $response->content =~ /$re/) {
    return "$who\'s url is at $1";
  } else {
    return 'makeashorterlink.com sucks.';
  }
}

sub _get_shorter {
  my ($who, $url) = @_;
  my $re = 'is:<br><br><a href="(http://shorterlink\.com/.*?)">';
  my $response = $ua->request( GET 'http://shorterlink.com/add_url.html',
			       [ url => $url ] );
  if ($response->is_success and $response->content =~ /$re/) {
    return "$who\'s url is at $1";
  } else {
    return 'makeashorterlink.com sucks.';
  }
}



POE::Component::IRC->new( 'urlbot' ) or
  die "Can't instantiate new IRC component!\n";
POE::Session->create( package_states => [ 'main' => [qw(_start _stop irc_001 irc_disconnected
                                 irc_socketerr irc_error irc_public irc_msg)],], );
$poe_kernel->run();

exit 0;
