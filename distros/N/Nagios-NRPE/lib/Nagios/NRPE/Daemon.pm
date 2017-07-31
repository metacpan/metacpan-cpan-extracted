#!/usr/bin/perl

=head1 NAME

Nagios::NRPE::Daemon - A Nagios NRPE Daemon

=head1 SYNOPSIS

 use Nagios::NRPE::Daemon;
 use IPC::Cmd qw(can_run run run_forked);

 # create the commandlist we accept
 my $commandlist = 
 };
 my $callback = sub {
   my ($self,$check,@options) = @_;
   my $commandlist = $self->commandlist();
   if ($commandlist->{$check}) {
     my $args = $commandlist->{$check}->{args};
     my $i = 0;
     foreach (@options) {
       $i++;
       $args =~ "s/\$ARG$i\$/$_/";
     }
     my $buffer;
     if (scalar run(command => $commandlist->{$check}->{bin} . " " . $args,
                    verbose => 0,
                    buffer => \$buffer,
                    timeout => 20)) {
       return $buffer;
     }
   }
 };

 my $daemon = Nagios::NRPE::Daemon->new(
   listen => "127.0.0.1",
   port => "5666",
   pid_dir => '/var/run',
   ssl => 0,
   commandlist => {
     "check_cpu" => { bin => "/usr/lib/nagios/plugin/check_cpu",
                      args => "-w 50 -c 80" }
   },
   callback => $callback
 );

=head1 DESCRIPTION

A simple daemon implementation with the capabillity to add your own callbacks 
and hooks in case you want to build your own NRPE Server.

=cut

package Nagios::NRPE::Daemon;

our $VERSION = '1.0.2';

use 5.010_000;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use IO::Socket;
use IO::Socket::INET6;
use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_3
  NRPE_PACKET_VERSION_2
  NRPE_PACKET_RESPONSE
  MAX_PACKETBUFFER_LENGTH
  STATE_UNKNOWN
  STATE_CRITICAL
  STATE_WARNING
  STATE_OK);

=pod

=head1 SUBROUTINES

=over

=item new()

Takes the following options as a hashref:

 * listen:

Listen on this IP Address

 * port:

Port to listen on

 * pid_dir

The pidfile for this daemon

 * ssl

Use ssl (1|0)

 * commandlist

A hashref of the allowed commands on the daemon

 * callback

A sub executed everytime a check should be run. Giving the daemon full control what should happen.

 my $callback = sub {
   my ($self,$check,@options) = @_;
   my $commandlist = $self->commandlist();
   if ($commandlist->{$check}) {
     my $args = $commandlist->{$check}->{args};
     my $i = 0;
     foreach (@options) {
       $i++;
       $args =~ "s/\$ARG$i\$/$_/";
     }
     my $buffer;
     if (scalar run(command => $commandlist->{$check}->{bin} . " " . $args,
                    verbose => 0,
                    buffer => \$buffer,
                    timeout => 20)) {
       return $buffer;
     }
   }
 };


=back

=cut

sub new {
    my ( $class, %hash ) = @_;
    my $self = {};

    $self->{listen}      = delete $hash{listen}      || "0.0.0.0";
    $self->{port}        = delete $hash{port}        || "5666";
    $self->{pid_dir}     = delete $hash{pid_dir}     || "/var/run";
    $self->{ssl}         = delete $hash{ssl}         || 0;
    $self->{commandlist} = delete $hash{commandlist} || {};
    $self->{callback}    = delete $hash{callback}    || sub { };

    bless $self, $class;
}

=pod

=over

=item start()

Starts the server and enters the Loop listening for packets

=back

=cut

sub start {
    my $self     = shift;
    my $packet   = Nagios::NRPE::Packet->new();
    my $callback = $self->{callback};
    my ( $socket, $s );

    $socket = $self->create_socket();

    while (1) {
        while ( ( $s = $socket->accept() ) ) {
            my $request;
            $s->recv( $request, 1036 );
            my $unpacked_request = $packet->deassemble($request);
            my $buffer           = $unpacked_request->{buffer};
            my $version          = $unpacked_request->{packet_version};
            my ( $command, @options ) = split /!/, $buffer;

            my $return = $self->{callback}( $self, $command, @options );
            eval {
                print $s $packet->assemble(
                    version => $version,
                    type    => NRPE_PACKET_RESPONSE,
                    check   => $return
                );
            };

            close($s);
        }
    }
}

=pod

=over

=item commandlist()

A hashref of elements that are valid commands.
An example for it is:

 "check_cpu" => { bin => "/usr/lib/nagios/plugin/check_cpu",
                  args => "-w 50 -c 80" }

C<args> can contain $ARG1$ elements like normal nrpe.cfg command elements.

=back

=cut

sub commandlist {
    my $self = shift;
    return $self->{commandlist};
}

=pod

=over

=item create_socket()

A shorthand function returning either an encrypted or unencrypted socket
depending on wether ssl is set to 1 or 0.

=back

=cut

sub create_socket {
    my $self = shift;
    my $socket;

    if ( $self->{ssl} ) {
        eval {
            # required for new IO::Socket::SSL versions
            require IO::Socket::SSL;
            IO::Socket::SSL->import();
            IO::Socket::SSL::set_ctx_defaults( SSL_verify_mode => 0 );
        };
        $socket = IO::Socket::SSL->new(
            Listen          => 5,
            LocalAddr       => $self->{host},
            LocalPort       => $self->{port},
            Proto           => 'tcp',
            Reuse           => 1,
            SSL_verify_mode => 0x01,
            Type            => SOCK_STREAM
        ) or die( IO::Socket::SSL::errstr() );
    }
    else {
        $socket = IO::Socket::INET6->new(
            Listen    => 5,
            LocalAddr => $self->{host},
            LocalPort => $self->{port},
            Reuse     => 1,
            Proto     => 'tcp',
            Type      => SOCK_STREAM
        ) or die "ERROR: $@ \n";
    }
    return $socket;
}

=pod

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the authors (see AUTHORS file).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
