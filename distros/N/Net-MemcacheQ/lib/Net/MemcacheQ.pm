#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# Source:        $Source$
# $HeadURL$
#
package Net::MemcacheQ;
use strict;
use warnings;
use IO::Socket::INET;
use Readonly;
use Carp;
use English qw(-no_match_vars);

Readonly::Scalar our $DEFAULT_HOST    => '127.0.0.1';
Readonly::Scalar our $DEFAULT_PORT    => 22_201;

our $DEBUG      = 0;
our $DEBUG_INFO = 1;
our $VERSION    = '1.04';

sub new {
  my ($class, $ref) = @_;

  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;
  return $ref;
}

sub _host {
  my ($self) = @_;
  if($self->{host}) {
    return $self->{host};
  }
  return $DEFAULT_HOST;
}

sub _port {
  my ($self) = @_;
  if($self->{port}) {
    return $self->{port};
  }
  return $DEFAULT_PORT;
}

sub _sock {
  my ($self) = @_;

  if($self->{_sock}) {
    return $self->{_sock};
  }

  $self->{_sock} = IO::Socket::INET->new(
					 PeerAddr  => $self->_host,
					 PeerPort  => $self->_port,
					 Proto     => 'tcp',
					) or croak $EVAL_ERROR;
  return $self->{_sock};
}

sub _request {
  my ($self, $txt) = @_;

  my $sock = $self->_sock;
  ($DEBUG == $DEBUG_INFO) and carp q[Socket connected];

  print {$sock} $txt or croak $EVAL_ERROR;
  ($DEBUG == $DEBUG_INFO) and carp qq[Sent '$txt'];

  my $response = q[];

  ($DEBUG == $DEBUG_INFO) and carp q[Going to read response];
  while(my $buf = <$sock>) {
    ($DEBUG == $DEBUG_INFO) and carp qq[Read '$buf'];
    $buf =~ s/[\r\n]+$//smx;
    ($DEBUG == $DEBUG_INFO) and carp qq[Processed '$buf'];

    if($buf =~ /^STAT/smx) {
      #########
      # retain the rest of the line
      #
      $buf      =~ s/^.*?\s//smx;
      if(!ref $response) {
	$response = [];
      }
      push @{$response}, $buf;

    } elsif($buf =~ /^VALUE/smx) {
      #########
      # retain the expected number of bytes from the next line onwwards
      #
      my ($size) = $buf =~ /(\d+)$/smx;
      my $tmp = q[];

      while(my $buf2 = <$sock>) {
	($DEBUG == $DEBUG_INFO) and carp qq[Read '$buf2'];
	if($buf2 =~ /^END/smx) {
	  last;
	}

	$tmp .= $buf2;
      }
      $response = substr $tmp, 0, $size;
      $buf      = 'END';
    }

    if($buf eq 'END' ||
       $buf eq 'STORED') {
      last;
    }
  }

  ($DEBUG == $DEBUG_INFO) and carp q[Finished request];

  return $response;
}

sub queues {
  my ($self)   = @_;
  my $response = $self->_request("stats queue\r\n");
  if(!$response) {
    $response = [];
  }
  return $response;
}

sub delete_queue {
  my ($self, $queuename) = @_;
  my $response = $self->_request("delete $queuename\r\n");
  return $response;
}

sub push { ## no critic (Homonym)
  my ($self, $queuename, $message) = @_;
  my $len = length $message;
  return $self->_request("set $queuename 0 0 $len\r\n$message\r\n");
}

sub shift { ## no critic (Homonym)
  my ($self, $queuename) = @_;
  return $self->_request("get $queuename\r\n");
}

sub DESTROY {
  my ($self) = @_;
  if($self->{_sock}) {
    $self->{_sock}->close;
    delete $self->{_sock};
  }
  return 1;
}

1;
__END__

=head1 NAME

Net::MemcacheQ

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

  my $oNMQ = Net::MemcacheQ->new({
    host => '192.168.0.1',
    port => 22202,
  });

  $oNMQ->push('myqueue', '{"some data":"abcdefg"}');

  my $message = $oNMQ->shift('myqueue');

=head1 DESCRIPTION

MemcacheQ implements a BerkeleyDB-backed FIFO message queue service
serviced using the Memcache protocol. Net::MemcacheQ provides a simple
interface against a single memcacheq instance.

For more information about MemcacheQ, please see:
  http://memcachedb.org/memcacheq/

=head1 SUBROUTINES/METHODS

=head2 new - constructor

  my $oNMQ = Net::MemcacheQ->new({...});

  Optional arguments:
  host => 'localhost'  # memcacheq server hostname
  port => 22201        # memcacheq server port

=head2 queues - arrayref of queue names

  my $arQueueNames = $oNMQ->queues();

=head2 delete_queue - delete a queue, messages and all

  $oNMQ->delete_queue($sQueueName);

=head2 push - push a message onto a given queue

  $oNMQ->push($sQueueName, $sQueueMessage);

=head2 shift - pull a message from a given queue

  my $sMessage = $oNMQ->shift($sQueueName);

=head2 DESTROY - disconnect socket on destruction

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Debugging messages are available by setting:

  $Net::MemcacheQ::DEBUG = $Net::MemcacheQ::DEBUG_INFO;

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item IO::Socket::INET

=item Readonly

=item Carp

=item English -no_match_vars

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

See those of memcacheq, in particular about message size.

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
