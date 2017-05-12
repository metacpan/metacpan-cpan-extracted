package RPC::Simple::AnyRemote;

use strict;
use vars qw(@ISA $VERSION);
use RPC::Simple::AnyWhere ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

( $VERSION ) = '$Revision: 1.6 $ ' =~ /\$Revision:\s+([^\s]+)/;

@ISA = qw(RPC::Simple::AnyWhere) ;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# see loadspecs for other names
sub new 
  {
    my $type = shift ;
    my $self = {} ;

    print "creating new $type\n";
    $self->{_twinHandle} = shift ;
    $self->{origDir} = $ENV{'PWD'} ;

    bless $self,$type ;

    # construct an array of existing remote functions and store it in the
    # child class name space (rude but necessary behavior)
    unless (defined $SUPER::_RPC_SUBS{ref($self)})
      {
        $self->_searchSubs(ref($self)) ;
      }

    return $self ;
  }


1;

__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::AnyRemote - Perl base class for a remote object accessible by RPC

=head1 SYNOPSIS

  package myClass ;
  use vars qw(@ISA @RPC_SUB);
  use RPC::Simple::AnyRemote;

  @ISA=('RPC::Simple::AnyRemote') ;
  @RPC_SUB = qw(localMethod);


=head1 DESCRIPTION

This class must be inherited by the user's class actually performing the 
remote functions.

Note that any user defined method which can be called by the local object must 
be able to handle the following optionnal parameters :

'callback' => code_reference

Usually, the methods will be like :

 sub remoteMethod
 {
   my $self = shift ;
   my $param = shift ;
   my $callback ;

   if ($param eq 'callback')
     {
       # callback required
       $callback = shift          
     }

   # user code

   # can call a method from local object
   $self->localMethod("Hey, remoteMethod was called !!");

   # when the user code is over
   return unless defined $callback ;

   &$callback("Hello local object" ) ;
 }

=head1 Methods

=head2 new('controller_ref')

controller_ref is the RPC::Simple::ObjectHandler object actually controlling 
this instance.

If you overload 'new', don't forget to call also the inherited 'new' method.

=head2 AUTOLOAD()

When this method is called (generally through perl mechanism), the call will
be forwarded with all parameter to the local object. 
Note that if the remote method name is not declated in the @RPC_SUB array, 
AnyLocal will try to autoload this mehtod.

Note that this method is not able to handle sub_reference and call back 
mechanism is not possible fromthis side.

returns self.

=head1 instance variable

AnyRemote will create the following instance variables:

=head2 _twinHandle

RPC::Simple::ObjectHandler object reference

=head2 origDir

Store the pwd of the object during its creation.

=head1 AUTHORS

    Current Maintainer
    Clint Edwards <cedwards@mcclatchyinteractive.com>

    Original
    Dominique Dumont, <Dominique_Dumont@grenoble.hp.com>

=head1 SEE ALSO

perl(1), RPC::Simple::AnyLocal(3)

=cut

