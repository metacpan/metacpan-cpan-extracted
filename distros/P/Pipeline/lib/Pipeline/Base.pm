package Pipeline::Base;

use strict;
use warnings::register;

use Error;
use Pipeline::Error::Construction;

our $VERSION = "3.12";

sub new {
  my $class = shift;
  my $self  = {};
  if (bless($self, $class)->init( @_ )) {
    return $self;
  } else {
    Pipeline::Error::Construction->throw();
  }
}

sub init {
  my $self = shift;
  return 1;
}

sub debug {
  my $self = shift;

  return 1 if !ref($self);

  my $level = shift;
  if (defined( $level )) {
    $self->{ debug } = $level;
    return $self;
  } else {
    return $self->{ debug };
  }
}

sub emit {
  my $self = shift;
  my $mesg = shift;
  $self->log( $self->_format_message( $mesg ) ) if $self->debug;
}

sub log {
  my $self = shift;
  my $mesg = shift;
  print STDERR $mesg;
}

sub _format_message {
  my $self = shift;
  my $mesg = shift;
  my $class = ref( $self );
  return "[$class] $mesg\n";
}

1;


=head1 NAME

Pipeline::Base - base class for all classes in Pipeline distribution

=head1 SYNOPSIS

  use Pipeline::Base;

  $object = Pipeline::Base->new()
  $object->debug( 10 );
  $object->emit("message");

=head1 DESCRIPTION

C<Pipeline::Base> is a class that provides a basic level of functionality
for all classes in the Pipeline system.  Most importantly it provides the 
construction and initialization of new objects.

=head1 METHODS

=over 4

=item CLASS->new()

The C<new()> method is a constructor that returns an instance of receiving
class.

=item init( LIST );

C<init()> is called by the constructor, C<new()> and is passed all of its 
arguments in LIST.

=item debug( [ SCALAR ] )

The C<debug()> method gets and sets the debug state of the OBJECT.  Setting it
to a true value will cause messages sent to C<emit()> to be printed to the
terminal.  If debug() is called as a class method it always will return true.

=item emit( SCALAR )

C<emit()> is a debugging tool.  It will cause the the SCALAR to be formatted and
sent to the C<log()> method if the current debugging level is set to a true value.

=item log( SCALAR )

The C<log()> method will send SCALAR to STDERR by default.  It performs no processing
of SCALAR and merely sends its results to the error handle.  To change your logging
mechanism simply override this method in the class as you see fit.

=back

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=cut

