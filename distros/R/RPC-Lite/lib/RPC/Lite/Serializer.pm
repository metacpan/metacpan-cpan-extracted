package RPC::Lite::Serializer;

use strict;

use RPC::Lite::Request;
use RPC::Lite::Response;
use RPC::Lite::Notification;
use RPC::Lite::Error;

=pod

=head1 NAME

RPC::Lite::Serializer -- Base class for RPC::Lite::Serializers.

=head1 DESCRIPTION

RPC::Lite::Serializer outlines the basic functionality any serializer
must implement.

=head1 METHODS

=over 4

=cut

=pod

=item C<new>

Creates a new serializer object.

=cut

sub new
{
  my $class = shift;
  my $self = {};
  bless $self, $class;
}

=pod

=item C<VersionSupported( $version )>

Returns a boolean indicating whether the given serialization version is
supported.

=cut

sub VersionSupported
{
  die( "Unimplemented virtual function!" );
}

=pod

=item C<GetVersion>

Returns the current version of the serializer.

=cut

sub GetVersion
{
  die( "Unimplemented virtual function!" );
}

=pod

=item C<Serialize( $data )>

Takes a reference to an object and serializes it, returning the result.

=cut

sub Serialize
{
  die( "Unimplemented virtual function!" );
}

=pod

=item C<Deserialize( $data )>

Takes serialized data and returns a deserialized object.

=cut

sub Deserialize
{
  die( "Unimplemented virtual function!" );
}

=pod

=back

=head1 NOTE

RPC::Lite::Servers automatically instantiate any of the supported serializers
as necessary to communicate with clients.

=head1 SUPPORTED SERIALIZERS

=over 4

=item JSON (client default)

"JSON (JavaScript Object Notation) is a lightweight data-interchange format.
It is easy for humans to read and write.  It is easy for machines to parse
and generate. It is based on a subset of the JavaScript Programming Language,
Standard ECMA-262 3rd Edition - December 1999."
  -- http://www.json.org/

=item XML

"Extensible Markup Language (XML) is a simple, very flexible text format
derived from SGML (ISO 8879). Originally designed to meet the challenges
of large-scale electronic publishing, XML is also playing an increasingly
important role in the exchange of a wide variety of data on the Web and elsewhere."
  -- http://www.w3.org/XML/

=item Null

The Null serializer is for communicating with native perl RPC::Lite servers
on the same machine.  It does nothing (and is largely untested, its use is
not currently recommended unless you are a developer wishing to improve it).

=back 

=cut

1;
