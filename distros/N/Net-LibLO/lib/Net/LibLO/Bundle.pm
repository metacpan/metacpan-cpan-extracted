package Net::LibLO::Bundle;

################
#
# liblo: perl bindings
#
# Copyright 2005 Nicholas J. Humfrey <njh@aelius.com>
#

use Carp;
use Net::LibLO;
use Net::LibLO::Message;
use strict;


sub new {
    my $class = shift;
    my $self = {
    	sec => 0,
    	frac => 0, 
    	bundle => undef
	};
    
    # Bless the hash into an object
    bless $self, $class;

    # 2 parameters = seconds and fraction
    if (scalar(@_)==2) {
		$self->{sec} = $_[0];
		$self->{frac} = $_[1];
    } elsif (scalar(@_)!=0) {
    	croak( "Invalid number of parameters" );
    }
    
    # Create bundle structure
    $self->{bundle} = Net::LibLO::lo_bundle_new( $self->{sec}, $self->{frac} );
    
    # Was there an error ?
    if (!defined $self->{bundle}) {
    	carp("Error creating lo_bundle");
    	undef $self;
    }
    
   	return $self;
}

sub add_message {
	my $self=shift;
	my ($path, $mesg) = @_;
	
	# Check parameters
    if (scalar(@_) != 2) {
    	croak( "Invalid number of parameters" );
    }

	# Check parameter is right type
	if (ref($mesg) ne 'Net::LibLO::Message') {
    	croak( "Second parameter should be a Net::LibLO::Message object." );
    }
	
	# Add the message to the bundle
	return Net::LibLO::lo_bundle_add_message(
		$self->{bundle}, $path, $mesg->{message});
}

sub length {
	my $self=shift;
	return Net::LibLO::lo_bundle_length( $self->{bundle} );
}

sub pretty_print {
	my $self=shift;
	Net::LibLO::lo_bundle_pp( $self->{bundle} );
}

sub DESTROY {
    my $self=shift;
   
    if (defined $self->{bundle}) {
    	# Don't free memory we didn't allocate
		unless ($self->{dontfree}) {
			Net::LibLO::lo_bundle_free( $self->{bundle} );
		}
		undef $self->{bundle};
    }
}


1;

__END__

=pod

=head1 NAME

Net::LibLO::Bundle

=head1 SYNOPSIS

  use Net::LibLO::Bundle;

  my $bndl = new Net::LibLO::Bundle();
  my $msg = new Net::LibLO::Message( 'si', 'Hello World', 8 );
  $bndl->add_message( 'si', $msg );


=head1 DESCRIPTION

Net::LibLO::Bundle is a perl class which represents a bundle of OSC messages.

=over 4

=item B<new( [sec, frac] )>

Create a new OSC bundle, with an optional timetag.

sec: The number of seconds since Jan 1st 1900 in the UTC timezone.

frac: The fractions of a second offset from obove, expressed as 1/2^32nds of a second


=item B<add_message( path, message )>

Path is a string of the path to send the message to.

Message is a Net::LibLO::Message object.

=item B<length( )>

Returns the length of the message (in bytes).

=item B<pretty_print( )>

Display the contents of the bundle to STDOUT.

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
