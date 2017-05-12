#!/usr/bin/perl
use strict;
use warnings;
use Socket;
use Getopt::Long;

use POE qw(Component::IRC::State Component::IRC::Plugin::Proxy);

my $nick;
my $user;
my $server;
my $port;
my $ircname;
my $bindaddr;
my $bindport;
my $password;
my $channels;

GetOptions(
"address=s" => \$bindaddr,
"bindport=s" => \$bindport,
"password=s" => \$password,
"nick=s" => \$nick,
"server=s" => \$server,
"user=s" => \$user,
"port=s" => \$port,
"ircname=s" => \$ircname,
"channels=s" => \$channels,
);

die "Please specify a nickname and a servername\n" unless ( $nick and $server );

my @channels = split /\,/, $channels;

my $poco = POE::Component::IRC::State->spawn(Nick => $nick, Server => $server, Port => $port, Ircname => $ircname, Username => $user);

POE::Session->create(
  package_states => [
	'main' => [ qw(_start _default irc_proxy_service irc_proxy_authed irc_proxy_close irc_001) ],
  ],
  heap => { irc => $poco, channels => \@channels },
  options => { trace => 0 },
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  my $irc = $heap->{irc};
  $irc->yield( register => 'all' );
  $heap->{proxy} = POE::Component::IRC::Plugin::Proxy->new( bindaddress => $bindaddr, bindport => $bindport, password => $password );
  $irc->plugin_add( 'Proxy' => $heap->{proxy} );
  $irc->yield( connect => { } );
  undef;
}

sub irc_001 {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{irc}->yield( join => $_ ) for @{ $heap->{channels} };
  return;
}

sub _default {
  my ($event) = $_[ARG0];
  my (@args) = @{ $_[ARG1] };
  my (@output) = ( "$event: " );

  foreach my $arg ( @args ) {
        if ( ref($arg) eq 'ARRAY' ) {
                push( @output, "[" . join(" ,", @$arg ) . "]" );
        } else {
                push ( @output, "'$arg'" );
        }
  }
  print STDOUT join(', ', @output, "\n" );
  undef;
}

sub irc_proxy_service {
  my ($kernel,$heap,$mysockaddr) = @_[KERNEL,HEAP,ARG0];

  my ($port, $myaddr) = sockaddr_in($mysockaddr);
                   printf "Connect to %s [%s]:[%s]\n",
                      scalar gethostbyaddr($myaddr, AF_INET),
                      inet_ntoa($myaddr), $port;
  undef;
}

sub irc_proxy_authed {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{irc}->yield( ctcp => $_ => 'ACTION has attached' )
    for keys %{ $heap->{irc}->channels() };
  undef;
}

sub irc_proxy_close {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{irc}->yield( ctcp => $_ => 'ACTION has detached' )
    for keys %{ $heap->{irc}->channels() };
  undef;
}
