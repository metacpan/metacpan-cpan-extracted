package RPC::Lite::Serializer::Null;

use strict;
use base qw( RPC::Lite::Serializer );

use RPC::Lite::Request;
use RPC::Lite::Response;
use RPC::Lite::Notification;
use RPC::Lite::Error;

our $VERSION = '0.1';

our $DEBUG = $ENV{DEBUG_SERIALIZER};

=pod

=head1 NAME

RPC::Lite::Serializer::Null -- The 'null' serializer.

=head1 SYNOPSIS

B<WARNING>: The null serializer will not currently work
with any of the suppoted transport layers.  The null serializer
requires an "in-memory" transport layer between processes,
which is not currently available.  This module is provided purely
as reference at this point.

=head1 DESCRIPTION

RPC::Lite::Serializer::Null is meant for clients and servers
operating on the I<same machine> that are both implemented in
I<perl>.  It does not actually serialize the object.

=cut

sub VersionSupported
{
  return 1;
}

sub GetVersion
{
  return $VERSION;
}

sub Serialize
{
  return $_[1];
}

sub Deserialize
{
  return $_[1];
}

1;
