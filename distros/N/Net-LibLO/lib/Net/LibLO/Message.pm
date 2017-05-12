package Net::LibLO::Message;

################
#
# liblo: perl bindings
#
# Copyright 2005 Nicholas J. Humfrey <njh@aelius.com>
#

use Carp;
use Net::LibLO;
use strict;



sub new {
    my $class = shift;
    my $self = {};
    
    # Was an lo_message passed to us?
    if( ref($_[0]) eq "lo_message") {
    	$self->{message} = shift;
		# Don't free memory we didn't allocate
		$self->{dontfree} = 1;
    } else {
    	$self->{message} = Net::LibLO::lo_message_new();
    }
    
    # Was there an error ?
    if (!defined $self->{message}) {
    	carp("Error creating lo_message");
    	return undef;
    }

    # Bless the hash into an object
    bless $self, $class;
    
    
    # Types and parameters supplied ?
	my $types = shift;
	if (defined $types) {
		foreach my $type (split(//, $types)) {
		
			if    ($type eq 'i') {  $self->add_int32( shift ) }
			elsif ($type eq 'f') {  $self->add_float( shift ) }
			elsif ($type eq 's') {  $self->add_string( shift ) }
			elsif ($type eq 'd') {  $self->add_double( shift ) }
			elsif ($type eq 'S') {  $self->add_symbol( shift ) }
			elsif ($type eq 'c') {  $self->add_char( shift ) }
			elsif ($type eq 'T') {  $self->add_true() }
			elsif ($type eq 'F') {  $self->add_false() }
			elsif ($type eq 'N') {  $self->add_nil() }
			elsif ($type eq 'I') {  $self->add_infinitum() }
			else {
				croak("Unsupported character '$type' in type string.");
			}
		}
    }
    
   	return $self;
}

sub add_int32 {
	my $self=shift;
	my ($int) = @_;
	Net::LibLO::lo_message_add_int32( $self->{message}, $int );
}

sub add_float {
	my $self=shift;
	my ($float) = @_;
	Net::LibLO::lo_message_add_float( $self->{message}, $float );
}

sub add_string {
	my $self=shift;
	my ($string) = @_;
	Net::LibLO::lo_message_add_string( $self->{message}, $string );
}

sub add_double {
	my $self=shift;
	my ($double) = @_;
	Net::LibLO::lo_message_add_double( $self->{message}, $double );
}

sub add_symbol {
	my $self=shift;
	my ($symbol) = @_;
	Net::LibLO::lo_message_add_symbol( $self->{message}, $symbol );
}

sub add_char {
	my $self=shift;
	my ($char) = @_;
	Net::LibLO::lo_message_add_char( $self->{message}, $char );
}

sub add_true {
	my $self=shift;
	Net::LibLO::lo_message_add_true( $self->{message} );
}

sub add_false {
	my $self=shift;
	Net::LibLO::lo_message_add_false( $self->{message} );
}

sub add_nil {
	my $self=shift;
	Net::LibLO::lo_message_add_nil( $self->{message} );
}
sub add_infinitum {
	my $self=shift;
	Net::LibLO::lo_message_add_infinitum( $self->{message} );
}

sub length {
	my $self=shift;
	my ($path) = @_;
	croak('Usage: $msg->length( $path )') unless (defined $path);
	return Net::LibLO::lo_message_length( $self->{message}, $path );
}

sub get_source {
	my $self=shift;
	return new Net::LibLO::Address( 
		Net::LibLO::lo_message_get_source( $self->{message} )
	);
}

sub pretty_print {
	my $self=shift;
	Net::LibLO::lo_message_pp( $self->{message} );
}

sub DESTROY {
    my $self=shift;
    
    if (defined $self->{message}) {
    	# Don't free memory we didn't allocate
		unless ($self->{dontfree}) {
	    	Net::LibLO::lo_message_free( $self->{message} );
	    }
    	undef $self->{message};
    }
}


1;

__END__

=pod

=head1 NAME

Net::LibLO::Message

=head1 SYNOPSIS

  use Net::LibLO::Message;

  my $msg = new Net::LibLO::Message( );
  $msg->add_string( "Hello World!" );
  $msg->add_int32( 41287 );

=head1 DESCRIPTION

Net::LibLO::Message is a perl class which represents a single OSC message.

=over 4

=item B<new( )>

Create a new, empty message.

=item B<new( types, ... )>

C<types> The types of the data items in the message.

=over 4

=item B<i>  32 bit signed integer.

=item B<f>  32 bit IEEE-754 float.

=item B<s>  A string

=item B<d>  64 bit IEEE-754 double.

=item B<S>  A symbol - used in systems which distinguish strings and symbols.

=item B<c>  A single 8bit charater

=item B<T>  Symbol representing the value True.

=item B<F>  Symbol representing the value False.

=item B<N>  Symbol representing the value Nil.

=item B<I>  Symbol representing the value Infinitum.

=back

C<...> The data values to be transmitted.
The types of the arguments passed here must agree with the 
types specified in the type parameter.

=item B<add_int32( int )>

Adds a 32-bit integer to the message.

=item B<add_float( float )>

Adds a 32-bit floating point number to the message.

=item B<add_string( string )>

Adds a string to the message

=item B<add_double( double )>

Adds a 64 bit floating point number to the message.

=item B<add_symbol( symbol )>

Adds a symbol string to the message.
Used in systems which distinguish strings and symbols.

=item B<add_char( char )>

Adds a single 8-bit character to the message.

=item B<add_true()>

Adds a symbol representing the value True to the message.

=item B<add_false()>

Adds a symbol representing the value B<False> to the message.

=item B<add_nil()>

Adds a symbol representing the value B<Nil> to the message.

=item B<add_infinitum()>

Adds a symbol representing the value B<Infinitum> to the message.

=item B<length( path )>

Returns the length of the message in bytes - the path the message is 
going to be sent to is also required.

=item B<pretty_print()>

Prints the message to STDOUT - probably most useful for debugging.

=back


=head1 AUTHOR

Nicholas J. Humfrey, njh@aelius.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Nicholas J. Humfrey

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
