package RPC::Simple::ObjectHandler;

use strict;
use vars qw($VERSION);

use RPC::Simple::CallHandler ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

( $VERSION ) = '$Revision: 1.7 $ ' =~ /\$Revision:\s+([^\s]+)/;

sub new
  {
    my $type = shift ;
    my $self = {} ;
    bless $self,$type ;
    
    $self->{server} = shift ;
    my $objName = shift ;
    $self->{handle} = shift ;
    my $args = shift ;
    my $reqId = shift ;
    
    my $result = 1 ;
    
    #We can remove the .pm off the object name if
    #it exists.  This will allow us to be called
    #as an object name and even a fully qualified
    #object name ie.(Object.pm, Ojbect, Some::Object)
    $objName =~ s/\.\w*$// ;
    eval "require $objName; $objName->import()" ;

    if ($@)
      {
        print "Can't load $objName: $@\n" ;
        $result = 0 ;
      } 
    else
      {
        print "Creating object controller for $objName\n" if $main::verbose ;
        eval { $self->{objRef} = $objName -> new ($self, @$args) };

        if ($@)
          {
            print "Can't create $objName: $@\n" ;
            $result = 0 ;
          } 
      }

    $self->{slaveClass} = $objName ;

    $self->callbackDone($reqId,$result,$@) ;
    return $self ;
  }

sub destroy
  {
    my $self=shift;
    delete $self->{objRef} ;

    if (defined $self->{requestTab})
      {
        foreach (values %{$self->{requestTab}})
          {
            $_->destroy ;
          }
      }
    print "ObjectHandler for $self->{slaveClass} destroyed\n";
  }

sub remoteCall
  {
    my $self = shift ;
    my $reqId = shift ; # optionnal
    my $method = shift ;
    my $args = shift ;
    
    if (defined $reqId)
      {
        # call back required
        $self->{requestTab}{$reqId} = 
          RPC::Simple::CallHandler -> 
            new ($self,$self->{objRef}, $reqId, $method, $args) ;
      }
    else
      {
        $self->{objRef} -> $method (@$args);
      }
  }

sub close 
  {
    my $self = shift ;
    
    print "Closing ",ref($self),"\n" ;
    
    map( undef $self->{requestTab}{$_}  , keys %{$self->{requestTab}}) ;
    $self->{objRef} -> close ;
    undef $self ;
  }

sub delegate 
  {
    my $self = shift ;
    my $method = shift ;
    my $args = \@_ ;
    
    print "delegate called by real object for $method\n" if $main::verbose ;
    $self->{server}-> writeSock($self->{handle},$method,undef,$args) ;
  }

sub callbackDone 
  {
    my $self = shift ;
    my $reqId = shift ;
    
    print "callbackDone called\n" if $main::verbose ;
    $self->{server}->writeSock($self->{handle},undef,$reqId,[@_]) ;
  }

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::ObjectHandler - Perl class to handle a remote object 

=head1 SYNOPSIS

  use RPC::Simple::ObjectHandler;


=head1 DESCRIPTION

This class is instanciated by RPS::Simple::Server each time a remote
object is created. All is handled by the server, the user need not to
worry about it.

=head1 new (server_ref, object_name, agent_id, argument_array_ref, req_id)

Creates a new object controller. Also creates a new object_name which
is remotely controlled by the agent referenced by agent_id. If object name 
has no suffix, new will 'require' object_name.pm

The new method of the slave object will be passed the argument stored
in argument_array_ref.

req_id is used for calling back the agent once the object is created 
(either with success ot not)

The connection server is passed with server_ref

=head1 METHODS

=head2 remoteCall( request_id | undef , method_name, arguments )

Will call the slave object with method method_name and the arguments.

If request_id is defined, it means that a call-back is expected. In this case,
the argument passed should contains a sub reference.

=head2 close

Cancel all pending requests and delete itself.

=head2 delegate(method_name, ... )

Used to call the local object with passed method and arguments.

=head2 callbackDone($reqId,$result)

Called by the callHandler when a function performed by the remote object
is over. $result being the result of this function.

=head1 AUTHORS

    Current Maintainer
    Clint Edwards <cedwards@mcclatchyinteractive.com>

    Original
    Dominique Dumont, <Dominique_Dumont@grenoble.hp.com>

=head1 SEE ALSO

perl(1)

=cut
