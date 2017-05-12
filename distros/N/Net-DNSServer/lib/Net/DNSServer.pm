package Net::DNSServer;

use strict;
use Exporter;
use Net::DNS;
use Net::Server::MultiType;
use Getopt::Long qw(GetOptions);
use Carp qw(croak);
use vars qw(@ISA $VERSION);
@ISA = qw(Exporter Net::Server::MultiType);

$VERSION = '0.11';

sub run {
  my $class = shift;
  $class = ref $class || $class;
  my $prop  = shift;
  unless ($prop &&
          (ref $prop) &&
          (ref $prop eq "HASH") &&
          ($prop->{priority}) &&
          (ref $prop->{priority} eq "ARRAY")) {
    croak "Usage> $class->run({priority => \\\@resolvers})";
  }
  foreach (@{ $prop->{priority} }) {
    my $type = ref $_;
    if (!$type) {
      croak "Not a Net::DNSServer::Base object [$_]";
    } elsif (!$_->isa('Net::DNSServer::Base')) {
      croak "Resolver object must isa Net::DNSServer::Base (Type [$type] is not?)";
    }
  }
  my $self = bless $prop, $class;

  $self->{server}->{commandline} ||= [ $0, @ARGV ];
  # Fix up process title on a "ps"
  $0 = join(" ",$0,@ARGV);

  my ($help,$conf_file,$nodaemon,$user,$group,$server_port,$pidfile);
  GetOptions     # arguments compatible with bind8
    ("help"       => \$help,
     "config-file|boot-file=s" => \$conf_file,
     "foreground" => \$nodaemon,
     "user=s"     => \$user,
     "group=s"    => \$group,
     "port=s"     => \$server_port,
     "Pidfile=s"  => \$pidfile,
     ) or $self -> help();
  $self -> help() if $help;

  # Load general configuration settings
  $conf_file ||= "/etc/named.conf";
  ### XXX - FIXME: not working yet...
  # $self -> load_configuration($conf_file);

  # Daemonize into the background
  $self -> {server} -> {setsid} = 1 unless $nodaemon;

  # Effective uid
  $self -> {server} -> {user} = $user if defined $user;

  # Effective gid
  $self -> {server} -> {group} = $group if defined $group;

  # Which port to bind
  $server_port ||= getservbyname("domain", "udp") || 53;
  $self -> {server} -> {port} = ["$server_port/tcp", "$server_port/udp"];

  # Where to store process ID for parent process
  $self -> {server} -> {pid_file} ||= $pidfile || "/tmp/named.pid";

  # Listen queue length
  $self -> {server} -> {listen} ||= 12;

  # Default IP to bind to
  $self -> {server} -> {host} ||= "0.0.0.0";

  # Show warnings until configuration has been initialized
  $self -> {server} -> {log_level} ||= 1;

  # Where to send errors
  $self -> {server} -> {log_file} ||= "/tmp/rob-named.error_log";

  return $self->SUPER::run(@_);
}

sub help {
  my ($p)=$0=~m%([^/]+)$%;
  print "Usage> $p [ -u <user> ] [ -f ] [ -(b|c) config_file ] [ -p port# ] [ -P pidfile ]\n";
  exit 1;
}

sub post_configure_hook {
  my $self = shift;
  open (STDERR, ">>$self->{server}->{log_file}");
  local $_;
  foreach (@{$self -> {priority}}) {
    $_->init($self);
  }
}

sub pre_server_close_hook {
  my $self = shift;
  local $_;
  # Call cleanup() routines
  foreach (@{$self -> {priority}}) {
    $_->cleanup($self);
  }
}

sub restart_close_hook {
  my $self = shift;
  local $_;
  # Call cleanup() routines
  foreach (@{$self -> {priority}}) {
    $_->cleanup($self);
  }
  # Make sure everything is taint clean ready before exec
  foreach (@{ $self->{server}->{commandline} }) {
    # Taintify commandline
    $_ = $1 if /^(.*)$/;
  }
  foreach (keys %ENV) {
    # Taintify %ENV
    $ENV{$_} = $1 if $ENV{$_} =~ /^(.*)$/;
  }
}

sub process_request {
  my $self = shift;
  my $peeraddr = $self -> {server} -> {peeraddr};
  my $peerport = $self -> {server} -> {peerport};
  my $sockaddr = $self -> {server} -> {sockaddr};
  my $sockport = $self -> {server} -> {sockport};
  my $proto    = $self -> {server} -> {udp_true} ? "udp" : "tcp";
  print STDERR "DEBUG: process_request from [$peeraddr:$peerport] for [$sockaddr:$sockport] on [$proto] ...\n";
  local $0 = "named: $peeraddr:$peerport";
  if( $self -> {server} -> {udp_true} ){
    print STDERR "DEBUG: udp packet received!\n";
    my $dns_packet = new Net::DNS::Packet (\$self -> {server} -> {udp_data});
    print STDERR "DEBUG: Question Packet:\n",$dns_packet->string;
    # Call pre() routine for each module
    foreach (@{$self -> {priority}}) {
      $_->pre($dns_packet);
    }

    # Keep calling resolve() routine until one module resolves it
    my $answer_packet = undef;
    print STDERR "DEBUG: Preparing for resolvers...\n";
    foreach (@{$self -> {priority}}) {
      print STDERR "DEBUG: Executing ",(ref $_),"->resolve() ...\n";
      $answer_packet = $_->resolve();
      last if $answer_packet;
    }
    # For DEBUGGING purposes, use the question as the answer
    # if no module could figure out the real answer (echo)
    $self -> {answer_packet} = $answer_packet || $dns_packet;

    print STDERR "DEBUG: Answer Packet After Resolve:\n",$self->{answer_packet}->string;

    # Before the answer is sent to the client
    # Run it through the post() routine for each module
    foreach (@{$self -> {priority}}) {
      $_->post( $self -> {answer_packet} );
    }

    # Send the answer back to the client
    print STDERR "DEBUG: Answer Packet After Post:\n",$self->{answer_packet}->string;
    $self -> {server} -> {client} -> send($self->{answer_packet}->data);
  } else {
    print STDERR "DEBUG: Incoming TCP packet? Not implemented\n";
  }
}


1;
__END__

=head1 NAME

Net::DNSServer - Perl module to be used as a name server

=head1 SYNOPSIS

  use Net::DNSServer;

  run Net::DNSServer {
    priority => [ list of resolver objects ],
  };
  # never returns

=head1 DESCRIPTION

Net::DNSServer will run a name server based on the
Net::DNSServer::Base resolver objects passed to it.
Usually the first resolver is some sort of caching
resolver.  The rest depend on what kind of name
server you are trying to run.  The run() method
never returns.

=head1 AUTHOR

Rob Brown, rob@roobik.com

=head1 SEE ALSO

L<Net::DNSServer::Base>,
L<Net::DNS>,
L<Net::Server>

named(8).

=head1 COPYRIGHT

Copyright (c) 2001, Rob Brown.  All rights reserved.
Net::DNSServer is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

$Id: DNSServer.pm,v 1.25 2002/11/13 19:47:01 rob Exp $

=cut
