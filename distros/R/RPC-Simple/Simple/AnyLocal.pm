package RPC::Simple::AnyLocal;

use strict;

use vars qw(@ISA $VERSION %_RPC_SUBS);

use RPC::Simple::Agent ;
use RPC::Simple::AnyWhere ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

( $VERSION ) = '$Revision: 1.8 $ ' =~ /\$Revision:\s+([^\s]+)/;

@ISA = qw(RPC::Simple::AnyWhere) ;
*_RPC_SUBS=*RPC::Simple::AnyWhere::_RPC_SUBS;
# Preloaded methods go here.

# We may need a mechanism to declare the functions vailable on the remote
# side

sub createRemote
  {
    my $self = shift ;
    my $factory = shift ;
    my $remoteClass = shift ;

    die "No factory object given to ",ref($self),"->createRemote\n"
      unless defined $factory ;

    # construct an array of existing remote functions and store it in the
    # child class name space (rude but necessary behavior)
    unless (defined $_RPC_SUBS{ref($self)})
      {
        $self->_searchSubs(ref($self)) ;
      }

    # create real process object
    $self->{_twinHandle} = 
      $factory->newRemoteObject($self, $remoteClass, @_ ) ;
    
    $self->{remoteHostName} = $self->{_twinHandle}->getRemoteHostName() ;

    return $self ;
  }

sub destroy
  {
    my $self = shift ;
    print "AnyLocal object destroyed\n" ;
    $self->{_twinHandle}->destroy;
    undef $self->{_twinHandle} ;
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::AnyLocal - Perl extension defining a virtual SRPC client class

=head1 SYNOPSIS

 package MyLocal ;

 use RPC::Simple::AnyLocal;
 use vars qw($VERSION @ISA @RPC_SUB) ;
 @ISA = qw(RPC::Simple::AnyLocal [other_class] );
 @RPC_SUB = qw(remoteHello remoteAsk);

 sub new
  {
    my $type = shift ;

    my $self = {} ;
    my $remote =  shift ;
    bless $self,$type ;

    $self->createRemote($remote,'your_class_name') ;
    return $self ;
  }

 # Note that the 'remoteHello' method is not part of MyLocal

 package main;

 use Tk ;
 use RPC::Simple::Server ;
 use RPC::Simple::Factory ;

 my $pid = &spawn ; # spawn server if needed
 
 # client part
 my $mw = MainWindow-> new ;
 my $verbose = 1 ;

 # create factory
 my $factory = new RPC::Simple::Factory($mw,\$verbose) ;
 my $local = new MyLocal($factory) ;
 $mw -> Button (-text => 'quit', -command => sub {exit;} ) -> pack ;
 $mw -> Button (-text => 'remoteAct',
   -command => sub {$local->remoteHello();} ) -> pack ;

 MainLoop ; # Tk's


=head1 DESCRIPTION

This class must be inherited by a sub-class so this one can use the RPC 
facility.

Note that this class (and the Factory class) was designed to use Tk's 
fileevent facilities.

The child object must declare in the @RPC_SUB array the name of the methods
available on the remote side.


=head1 Methods

=head2 createRemote(factory_object_ref, [remote_class_name], ... )

This method should be called by the child object during start-up. It will
ask the SRPC factory to create a ClientAgent class dedicated to this new 
object.

The server on the other side of the socket will load the code necessary
for the remote class. By default the remote class name will be 
...::Real<LocalClass>. I.e if your local class is Test::Foo the remote
class name will be Test::RealFoo. 

If the remote class name has no prefix, '.pm' will be appended to get the
file name to load

The remaining parameters will passed to the remote object's new method
during its creation.

returns self.

=head2 destroy()

Objects derived from AnyLocal must be explicitely destroy. If you just undef
the object reference, you will not release the memory and the remote object
will not be destroyed.

=head2 AUTOLOAD()

When this method is called (generally through perl mechanism), the call will
be forwarded with all parameter to the remote object. If the first parameters
is  : \&one_callback 

the function &one_callback will be called when the remote side has finished
its function. 

If you want to call-back an object method, use a closure. Such as

 $self->remote_method(sub {$self-> finished(@_)})

Note that if the remote method name is not declared in the @RPC_SUB array, 
AnyLocal will try to autoload this method.

returns self.

=head1 instance variable

AnyLocal will create the following instance variables:

=head2 _twinHandle

Will contains the ref of the RPC::Simple::Agent object.

=head2 remoteHostName

Will contains the name of the remote host.

=head1 Inheritance and Autoload

Since RPC::Simple uses the AUTOLOAD subroutine to delegate unknown calls to 
the remote class, you must pay attention if you use or inherit classes 
which use the AutoLoader mechanism.

The AUTOLOAD defined in this class will first check if the called function
is declared in the @RPC_SUB arrays of all inherited classes. If yes it 
will call the remote function. If not it will forward the call to the 
AutoLoader::AUTOLOAD routine. In this case you fall back on the usual
AutoLoad mechanism.

For this scheme to work, it is important that RPC::Simple::AUTOLOAD is run
BEFORE the AutoLoader::AUTOLOAD routine.

So when inheriting from RPC::Simple and another class (say Foo::Bar), you must
put RPC::Simple::AnyLocal BEFORE your class in the @ISA array.

For instance, you must declare :
@ISA = qw(RPC::Simple::AnyLocal Foo::Bar);

BTW, if you are mixing autoloading, remote calls and inheritance, which is 
a recipe for a good headache, you really (I mean it) should use subroutine
stubs for the auloaded functions. (It does really work better).
See AutoLoad(3).

=head1 AUTHORS

    Current Maintainer
    Clint Edwards <cedwards@mcclatchyinteractive.com>

    Original
    Dominique Dumont, <Dominique_Dumont@grenoble.hp.com>

=head1 SEE ALSO

perl(1), RPC::Simple::Factory(3), RPC::Simple::AnyRemote(3)

=cut


