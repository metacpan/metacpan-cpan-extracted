package Net::Tor;

use 5.026001;
use strict;
use warnings;

use diagnostics;
use Data::Dumper;

use Carp;
use IO::Socket;

=head1 NAME

Net::Tor - Perl extension to control running tor

=head1 SYNOPSIS

  use Net::Tor;

=head1 DESCRIPTION

This is the first implementation to allow control of tor.

Currently working: set/getconf and new_circuit

=head2 METHODS

=over

=cut

our $VERSION = 'v0.1';

=item new

Constructor for the class. if password is specified as parameter, connect will be transparently called.

=cut

sub new
{
   my $param = shift;
   my $class = ref($param) || $param;
   my %opts = @_;

   my $self = {
      connected => undef,
      server => 'localhost',
      port => 9051,
   };

   bless $self, $class;

   foreach (qw(server port))
   {
      $self->{$_} = $opts{$_} if exists($opts{$_});
   }

   if (exists $opts{password})
   {
      $self->connect($opts{password})
   }

   return $self;
}

=item connect

Connect to the server.

First parameter is the password.

=cut

sub connect
{
   my $self = shift;
   my $pw = shift || '';
   my %opts = @_;

   if ($self->{connected} and not $opts{force})
   {
      carp('Already connected and no force reconnect');
      return 1;
   }

   my $conn = IO::Socket::INET->new(
      Proto => 'tcp',
      PeerAddr => $self->{server},
      PeerPort => $self->{port},
   ) or croak('Error connecting to the server');

   $conn->send(sprintf("authenticate \"%s\"\r\n", $pw));

   my $msg;
   $conn->recv($msg, 1024);
   croak('No answer from server') unless $msg;

   unless ($msg =~ /^(\d+) (.*)\r\n/)
   {
      croak ("Unknown answer from server '$msg'");
   }
   my $status = $1;
   $msg = $2;

   if ($status != 250)
   {
      croak("Error $status while authentication '$msg'");
   }

   $self->{conn} = $conn;
   $self->{connected} = 1;
   return 1;
} ## end connect

=item conf

Get or set a configuration parameter

=cut

sub conf
{
   my $self = shift;
   my $name = shift;
   my $value = shift;

   if (defined $value)
   {
      $self->{conn}->send(sprintf("setconf %s=%s\r\n", $name, $value));
      my $msg;
      $self->{conn}->recv($msg, 1024);
      unless ($msg =~ /^250 OK\r\n/)
      {
	 $msg =~ s/^(?:\d+ )?(.*)\r\n.*/$1/;
	 croak("Received '$msg' instead of OK");
      }
   }

   my @value;
   $self->{conn}->send(sprintf("getconf %s\r\n", $name));
   my $msg;
   $self->{conn}->recv($msg, 1024);
   if ($msg =~ /^(\d+)\+(.*)\r\n(.*\r\n)\.\r\n/s)
   {
      croak("Does not understand data reply");
   }
   else
   {
      while ($msg =~ /^(\d+)[ -](.*)\r\n/gm)
      {
	 my $status = $1;
	 my $msg = $2;

	 croak($msg) if $status != 250 and $status != 650;

	 $msg =~ /^([a-zA-Z_]+)(?:=(.*))?$/;
	 push @value, $2;
      }
   }

   return wantarray ? @value : $value[0];
} ## end conf

=item new_circuit

Request a new circuit

=cut

sub new_circuit
{
   my $self = shift;

   $self->{conn}->send("signal newnym\r\n");
   my $msg;
   $self->{conn}->recv($msg, 1024);
   unless ($msg =~ /^250 OK\r\n/)
   {
      $msg =~ s/^(?:\d+ )?(.*)\r\n.*/$1/;
      croak("Received '$msg' instead of OK");
   }

   return 1;
} ## end new_circuit

1;

__END__

=back

=head1 SEE ALSO

man tor

=head1 AUTHOR

Klaus Ethgen, E<lt>Klaus@Ethgen.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Klaus Ethgen. All rights reserved.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not,
see <http://www.gnu.org/licenses/>.

=cut
