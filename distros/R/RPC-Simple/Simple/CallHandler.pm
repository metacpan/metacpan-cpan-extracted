package RPC::Simple::CallHandler;

use strict;
use vars qw($VERSION);

( $VERSION ) = '$Revision: 1.6 $ ' =~ /\$Revision:\s+([^\s]+)/;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
sub new
  {
    my $type = shift ;
    my $self = {} ;
    
    $self->{controlRef} = shift ;
    $self->{objRef} = shift ;
    $self->{reqId} = shift ;
    my $method = shift ;
    my $args = shift ;
    
    print "Creating call handler\n" if $main::verbose ;
    bless $self,$type ;
    
    $self->{objRef} -> $method (sub {$self->done(@_);} , @$args) ;
    return $self ;
  }

sub done 
  {
    my $self = shift ;
    
    print "done called\n" if $main::verbose ;
    $self->{controlRef} -> callbackDone ($self->{reqId}, @_ ) ;
    $self->destroy ;
  }

sub destroy
  {
    my $self = shift ;
    print "CallHandler destroyed\n" if $main::verbose ;
    delete $self->{controlRef} ;
    delete $self->{objRef} ;
    delete $self->{reqId} ;
  }

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

RPC::Simple::CallHandler - Perl class to handle RPC calls with call-back

=head1 SYNOPSIS

  use RPC::Simple::CallHandler;


=head1 DESCRIPTION

This class is intanciated on the remote side each time a function is called 
with a call-back ref. This class will hold the relevant information so that
the call-back will be passed to the local object which issued the call.

Used only for asynchronous functions calls. I.e the called function cannot
pass a result immediately, it will have to call-back this handler.

=head1 new (handler_ref, remote_object, request_id, method, argument_ref)

Call the remote_object methods with a call-back parameter and the passed 
arguments, store the handler ref.

Note that the called method must be able to handle a sub ref  parameter.
This sub must be called when the function is over.

Usually the call-back function will be a closure.

=head1 methods

=head2 done ($result, ...)

call-back method.

=head1 AUTHORS

    Current Maintainer
    Clint Edwards <cedwards@mcclatchyinteractive.com>

    Original
    Dominique Dumont, <Dominique_Dumont@grenoble.hp.com>

=head1 SEE ALSO

perl(1).

=cut
