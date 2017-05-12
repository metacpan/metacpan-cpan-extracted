package RPC::Lite::Serializer::XML;

use strict;
use base qw( RPC::Lite::Serializer );

use RPC::Lite::Request;
use RPC::Lite::Response;
use RPC::Lite::Notification;
use RPC::Lite::Error;
use RPC::Lite::Signature;

use XML::Simple;

use Data::Dumper;

our $DEBUG = $ENV{DEBUG_SERIALIZER};

sub VersionSupported
{
  my $self = shift;
  my $version = shift;

  # FIXME make sure we support this version of serialization
  return 1;
}

sub GetVersion
{
  my $self = shift;
  return $XML::Simple::VERSION; # FIXME should be *this* module's version, not XML::Simple's.  we may require a minimum version of XML::Simple in the use() of course.
}

sub Serialize
{
  my $self = shift;
  my $object = shift;
  
  my $type = ref($object);
  
  # plain perl data structures...
  if(!defined($type))
  {
    # no-op
  }
  elsif($type eq 'HASH')
  {
    # no-op
  }
  elsif($type eq 'ARRAY')
  {
    # no-op
  }
  elsif($type eq 'RPC::Lite::Request')
  {
    # effectively 'unbless' this thing
    $object =
      {
        class     => $type,
        method    => $object->{method},
        params    => $object->{params}, # assume simple types, could recurse to attempt to throw real objects over the wire
        id        => $object->{id},
      };
  }
  elsif($type eq 'RPC::Lite::Response')
  {
    $object =
      {
        class     => $type,
        result    => $object->{result}, # assume simple types
        error     => $object->{error},
        id        => $object->{id},
      };
  }
  elsif($type eq 'RPC::Lite::Notification')
  {
    $object =
      {
        class     => $type,
        params    => $object->{params}, # assume simple types
        method    => $object->{method},
        id        => $object->{id},     # will be undef
      };
  }
  elsif($type eq 'RPC::Lite::Error')
  {
    $object =
      {
        class     => $type,
        result    => $object->{result}, # undef
        error     => $object->{error},
        id        => $object->{id},
      };
  }
  elsif($type eq 'RPC::Lite::Signature')
  {
    $object =
      {
        class            => $type,
        signature        => $object->AsString(),
      };
  }
  else # try our best
  {
    # unbless shit? 
  }

  my $data;
  {
    # work around uninitialized value warning in XML::Simple (keeps test output clean)
    local $^W = 0;
    $data = XMLout( $object, RootName => 'rpc-lite' );
  }

  $self->_Debug('Serializing', Dumper($object), $data) if($DEBUG);

  return $data;
}

sub Deserialize
{
  my $self = shift;
  my $data = shift;

  length($data) or return undef;
  
  my $object = XMLin( $data, ForceArray => ['params'] );

  my $result = $object;

  if(defined($object->{class}))
  {
    my $type = delete $object->{class};
    
    if($type eq 'RPC::Lite::Request')
    {
      my $params = $object->{params} || [];
      $result = $type->new($object->{method}, $params);
      $result->Id($object->{id});
    }
    elsif($type eq 'RPC::Lite::Response')
    {
      $result = $type->new($object->{result});
      $result->Id($object->{id});
    }
    elsif($type eq 'RPC::Lite::Notification')
    {
      my $params = $object->{params} || [];
      $result = $type->new($object->{method}, $params);
    }
    elsif($type eq 'RPC::Lite::Error')
    {
      $result = $type->new($object->{error});
      $result->Id($object->{id});
    }
    elsif($type eq 'RPC::Lite::Signature')
    {
      $result = $type->new($object->{signature});
    }
  }

  $self->_Debug('Deserializing', $data, Dumper($result)) if($DEBUG);
    
  return $result;
}

sub _Debug
{
  my $self = shift;
  my $action = shift;
  my $input = shift;
  my $output = shift;

  print qq{
    $action
    ===================================================================

      input:
         
        $input
         
      output:
       
        $output
      
    ===================================================================
    
  };
}

1;
