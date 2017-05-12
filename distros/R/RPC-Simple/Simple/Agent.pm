package RPC::Simple::Agent;

use strict;
use vars qw($VERSION);

use RPC::Simple::Factory ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

( $VERSION ) = '$Revision: 1.7 $ ' =~ /\$Revision:\s+([^\s]+)/;

# Preloaded methods go here.

# connection is opened, ask for a remote object
sub new
  {
    my $type = shift ;
    my $factoryObj = shift ;       # factory
    my $clientRef = shift;
    my $index  = shift ;
    my $remoteClass = shift ; # may be undef

    my $self={} ;
    $self->{'idx'} = $index ;
    
    $self->{requestId} = 0 ;
    
    $self->{'factory'} = $factoryObj ;
    $self->{remoteHostName} = $factoryObj->getRemoteHostName() ;

    unless (defined $remoteClass)
      {
        $remoteClass = ref($clientRef) ;
        $remoteClass =~ s/(\w+)$/Real$1/ ;
      } 
    
    print "Creating $type for $remoteClass\n";
    
    $self->{'clientObj'}= $clientRef ;

    # store call-back info
    $self->{callback}{$self->{requestId}} = sub{ $self->remoteCreated(@_)} ; 
    my $id = $self->{requestId}++ ;
    
    $factoryObj->writeSockBuffer($index, 'new', $id , [ @_ ], $remoteClass ) ;
    
    $self->{remoteClass} = $remoteClass ;
    bless $self, $type ;
  }

sub destroy
  {
    my $self = shift ;
    print "RPC::Simple::Agent destroyed\n";
    $self->{factory}->destroyRemoteObject($self->{'idx'});    

    # We need to undef the factory and clientObj references
    # because they create a circular reference and we can not
    # destroy the factory or the clientObj
    undef $self->{factory};
    undef $self->{clientObj};
  }

sub delegate
  {
    # delegate to remote
    my $self = shift ;
    my $method = shift ;
    my $id ;
    
    if (ref($_[0]) eq 'CODE')
      {
        # callback required
        $self->{callback}{$self->{requestId}} = shift ; # store call-back info
        $id = $self->{requestId}++ ;
      }
    
    $self->{'factory'}->writeSockBuffer($self->{'idx'},$method, $id,[ @_]) ;
  }

sub remoteCreated
  {
    my $self = shift ;
    my $result = shift ;
    my $failStr = shift ;

    if ($result)
      {
        print "Remote class $self->{remoteClass} created\n";
        return ;
      }
    
    print "Failed to create remote class $self->{remoteClass}\n",$failStr;
    undef $self->{clientObj} ;
  }

sub callMethod
  {
    my $self = shift ;
    my $method = shift ;
    my $args = shift ;
    $self->{clientObj} -> $method (@$args) ;
  }

sub getRemoteHostName
  {
    my $self = shift ;
    return $self->{'remoteHostName'} ;
  }

sub treatCallBack
  {
    my $self = shift ;
    my $reqId = shift ;
    my $args = shift ;

    my $cbRef = $self->{callback}{$reqId} ;

    &$cbRef(@$args);
    
    delete $self->{callback}{$reqId} ;
  }


# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::Agent - Perl extension for an agent object for RPC

=head1 SYNOPSIS

  use RPC::Simple::Agent ;

=head1 DESCRIPTION

This class is an agent for client class inheriting PRC::AnyLocal. This
class will handle all the boring stuff to create, access store call-back 
when dealing with the remote object.

Casual user should not worry about this class. RPC::Simple::AnyLocal 
will deal with it.

=head1 Methods

=head2 new( $factory_ref, client_ref, index, remote_class, ... .)

Create the agent. 

factory_ref is the SPRC::Factory object.

client_ref is the client object itself.

index is an index handled by the Factory.

remote_class if the name of the class created on the remote side. By default,
it is set to the client's class name with a 'Real' prepended to the name.

I.e if the client is Foo::Bar, the remote will be Foo::RealBar.

The remaining parameters will forwarded to the constructor of the remote
class.

=head2 getRemoteHostName

returns the remote host name

=head2 delegate( method_name , [code_ref ],
                parameters ,... )

Call a method of the remote object. If code_ref is specified, the code
 will be executed with whatever parameters the remote functions passed
in its reply.

The remaining optionnal parameters are passed as is to the remote method.

Note that ref are copied. You can't expect the remote to be able to modify
a client's variable because you passed it's ref to the remote. 

=head2 callMethod( method_name, argument_array_ref )

Function used to call the owner of the agent. All arguments of the 
function to be called back are passed in the array ref.

=head1 CALLBACKS

=head2 remoteCreated(result, string)

Called when the remote object is created. 'result' will be true or false 
depending on whether the remote object was created or not.

'string' contains the error message in case of a failure.

=head2 treatCallBack ( request_id, argument_array_ref)

Function used to call-back the owner of the agent. All arguments of the 
function to be called back are passed in the array ref.

'request_id' is used to know what object and methos are to be called back. 
These info were stored by the delegate function.

=head1 AUTHORS

    Current Maintainer
    Clint Edwards <cedwards@mcclatchyinteractive.com>
    
    Original
    Dominique Dumont, <Dominique_Dumont@grenoble.hp.com>

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3).

=cut
