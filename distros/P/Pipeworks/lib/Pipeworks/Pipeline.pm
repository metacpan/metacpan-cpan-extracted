package Pipeworks::Pipeline;

use Mojo::Base -base;
use Mojo::Loader;
use Pipeworks::Stage::Callback;
use Scalar::Util qw( blessed );

has stages => sub { [] };

# message class a pipeline can operate with
has "type";
has "namespace" => "Pipeworks";

sub new
{
	my $class = shift;
	my $type = @_ > 0 # when a type was given
	         ? shift  # ... use it
	         : $class =~ m!::([^:]+)\z! # otherwise take the last
	           ? $1                     # part of the class
	           : ""
	;
	my $self = $class->SUPER::new( @_ );
	my $namespace = $self->namespace;
	my $message = $type =~ m!\A[+](.*)!
		    ? $1
		    : "${namespace}::Message::$type"
	;

	if ( ref( my $e = Mojo::Loader::load_class( $message ) ) ) {
		warn( "FAIL: e=$e, \@=$@" );
		return undef;
	}

	$self->type( $message );

	return $self;
}

sub register
{
	my $self = shift;
	my $stage = shift;
	my $namespace = $self->namespace;
	my $stages = $self->stages;
	my $type = $self->type;
	my $object;

	# pipeline or stage object
	if ( blessed( $stage ) &&
	    ( $stage->isa( 'Pipeworks::Stage' ) ||
	      $stage->isa( 'Pipeworks::Pipeline' ) ) ) {
		$object = $stage;
	}
	# code reference
	elsif ( ref( $stage ) eq 'CODE' ) {
		$object = Pipeworks::Stage::Callback->new( $stage );
	}
	# class names
	else {
		my $class = $stage =~ m!\A[+](.*)!
		          ? $1
		          : "${namespace}::Stage::$stage"
		;

		my $e = Mojo::Loader::load_class( $class );

		if ( ref( $e ) || $@ ) {
			warn( "FAIL: e=$e, \@=$@" );
		}

		$object = $class->new( @_ );
	}

	push( @$stages, $object );

	return $self;
}

sub process
{
	my $self = shift;
	my $message = shift;
	my $stages = $self->stages;

	for my $stage ( @$stages ) {
		$stage->process( $message );
	}

	return $message;
}

sub message
{
	my $self = shift;
	my $type = $self->type;
	my $message = $type->new( @_ );

	return $message;
}

1;

__END__

=head1 NAME

Pipeworks::Pipeline - Pipeline base class with top-level functionality

=head1 SYNOPSIS

  my $pipeline = Pipeworks::Pipeline->new;
  $pipeline->register( sub { ... } );
  $pipeline->process( { ... } );

=cut

