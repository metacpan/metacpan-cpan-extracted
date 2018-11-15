=head1 NAME

Nagios::NRPE::Client - A Nagios NRPE client

=head1 SYNOPSIS

 use Nagios::NRPE::Client;

 my $client = Nagios::NRPE::Client->new( host => "localhost", check => 'check_cpu');
 my $response = $client->run();
 if(defined $response->{error}) {
   print "ERROR: Couldn't run check " . $client->{check} . " because of: " . $response->{reason} . "\n";
 } else {
   print $response->{buffer}."\n";
 }

=head1 DESCRIPTION

This Perl Module implements Version 2 and 3 of the NRPE-Protocol. With this module you can execute 
checks on a remote server.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the authors (see AUTHORS file).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Nagios::NRPE::Client;

our $VERSION = '2.0.2';

use 5.010_000;

use strict;
use warnings;

use Data::Dumper;
use Carp;
use IO::Socket;
use IO::Socket::INET6;
use Nagios::NRPE::Utils qw(return_error);
use Nagios::NRPE::Packet qw(NRPE_PACKET_VERSION_3
  NRPE_PACKET_VERSION_2
  NRPE_PACKET_QUERY
  MAX_PACKETBUFFER_LENGTH
  STATE_UNKNOWN
  STATE_CRITICAL
  STATE_WARNING
  STATE_OK);

=pod

=head1 SUBROUTINES

=over 2

=item new()

Constructor for the Nagios::NRPE::Client Object

 example

 my $client = Nagios::NRPE::Client->new( host => "localhost", check => 'check_cpu');

Takes a hash of options:

 *  host => <hostname or IP>

The hostname or IP on which the NRPE-Server is running

 * port => <Portnumber>

The port number at which the NRPE-Server is listening

 * timeout => <number in seconds>

Timeout for TCP/IP communication

 * arglist => ["arg","uments"]

List of arguments attached to the check

 * check => "check_command"

Command defined in the nrpe.cfg on the NRPE-Server

 * ssl => 0,1

Use or don't use SSL

=back

=cut

sub new
{
    my ($class, %hash) = @_;
    my $self = {};
    $self->{arglist}  = delete $hash{arglist}  || [];
    $self->{bindaddr} = delete $hash{bindaddr} || 0;
    $self->{check}    = delete $hash{check}    || "";
    $self->{host}     = delete $hash{host}     || "localhost";
    $self->{ipv4}     = delete $hash{ipv4}     || 0;
    $self->{ipv6}     = delete $hash{ipv6}     || 0;
    $self->{port}     = delete $hash{port}     || 5666;
    $self->{ssl}      = delete $hash{ssl}      || 0;
    $self->{timeout}  = delete $hash{timeout}  || 30;
    bless $self, $class;
}

=pod

=over 2

=item create_socket()

Helper function that can create either an INET socket or a SSL socket

=back

=cut 

sub create_socket
{
    my ($self) = @_;
    my $reason;
    my $socket;

    my %socket_opts = (

        # where to connect
        PeerHost => $self->{host},
        PeerPort => $self->{port},
        Timeout  => $self->{timeout}
    );
    if ($self->{bindaddr})
    {
        $socket_opts{LocalAddr} = $self->{bindaddr};
    }
    if ($self->{ipv4})
    {
        $socket_opts{Domain} = AF_INET;
    }
    if ($self->{ipv6})
    {
        $socket_opts{Domain} = AF_INET6;
    }
    if ($self->{ssl})
    {
        eval {
            # required for new IO::Socket::SSL versions
            use IO::Socket::SSL;
        };

        $socket_opts{SSL_cipher_list} = $self->{SSL_cipher_list}
          || 'ALL:!MD5:@STRENGTH:@SECLEVEL=0';
        $socket_opts{SSL_verify_mode} = SSL_VERIFY_NONE;
        $socket_opts{SSL_version}     = 'TLSv1';

        $socket = IO::Socket::SSL->new(%socket_opts);
        if ($SSL_ERROR)
        {
            $reason = "$!,$SSL_ERROR";
            return return_error($reason);
        }

    }
    else
    {
        $socket_opts{Proto} = 'tcp';
        $socket_opts{Type}  = SOCK_STREAM;
        $socket             = IO::Socket::INET6->new(%socket_opts);
        $reason             = $@;
    }

    if (!$socket)
    {
        return return_error($reason);
    }

    return $socket;

}

=pod

=over 2

=item run()

Runs the communication to the server and returns a hash of the form:

  my $response = $client->run();

The output should be a hashref of this form for NRPE V3:

  {
    version => NRPE_VERSION,
    type => RESPONSE_TYPE,
    crc32 => CRC32_CHECKSUM,
    code => RESPONSE_CODE,
    alignment => PACKET_ALIGNMENT,
    buffer_length => OUTPUT_LENGTH,
    buffer => CHECK_OUTPUT
  }
  
and this for for NRPE V2:

  {
    version => NRPE_VERSION,
    type => RESPONSE_TYPE,
    crc32 => CRC32_CHECKSUM,
    code => RESPONSE_CODE,
    buffer => CHECK_OUTPUT
  }

=back

=cut

sub run
{
    my ($self) = @_;
    my $check;
    if (scalar @{$self->{arglist}} == 0)
    {
        $check = $self->{check};
    }
    else
    {
        $check = join '!', $self->{check}, @{$self->{arglist}};
    }

    my $socket = $self->create_socket();
    if (ref $socket eq "HASH")
    {
        return ($socket);
    }
    my $packet = Nagios::NRPE::Packet->new();
    my $response;
    my $assembled = $packet->assemble(
                                      type    => NRPE_PACKET_QUERY,
                                      check   => $check,
                                      version => NRPE_PACKET_VERSION_3
                                     );
    print $socket $assembled;
    while (<$socket>)
    {
        $response .= $_;
    }
    close($socket);

    if (!$response)
    {
        $socket = $self->create_socket();
        if (ref $socket eq "REF")
        {
            return ($socket);
        }
        $packet   = Nagios::NRPE::Packet->new();
        $response = undef;
        $assembled = $packet->assemble(
                                       type    => NRPE_PACKET_QUERY,
                                       check   => $check,
                                       version => NRPE_PACKET_VERSION_2
                                      );

        print $socket $assembled;
        while (<$socket>)
        {
            $response .= $_;
        }
        close($socket);

        if (!$response)
        {
            my $reason = "No output from remote host";
            return return_error($reason);
        }
    }
    return $packet->disassemble($response);
}

=pod

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the authors (see AUTHORS file).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
