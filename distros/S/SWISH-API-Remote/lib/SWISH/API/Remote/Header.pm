package SWISH::API::Remote::Header;

# SWISH::API::Remote::Header
#   object to encapsulate SWISH-E header data
#   
# rewritten from file originally from pek 

use strict;
use warnings;
use Carp; 
use URI::Escape; 
use SWISH::API::Remote::FunctionGenerator;

use fields qw( Name Value );	 
    # NOTE that there is no corresponding "SWISH::API::Header" to model,
	# so we write the interface to be similar to SWISH::API::MetaList

############################################
# SWISH::API::Remote::Header->new()
# creates a new SWISH::API::Remote::Header object
sub new {
	my SWISH::API::Remote::Header $self = shift;
	unless (ref $self) {
		$self = fields::new($self);
	}
	return $self;
}

############################################
# Parse_MetaNames_From_Query_String( $line )
#  given a string of Header objects (eg from swished)
# returns A LIST of Header objects (which also are used to describe Properties)
sub Parse_Headers_From_Query_String {
	my $line = shift;
    my @parts = split ( /&/, $line );
	my @toreturn;
	for my $p (@parts) {
		my $newobj = new SWISH::API::Remote::Header;
        my ( $name, $v ) = split ( /=/, $p, 2 );
        $newobj->{Name} = uri_unescape($name);
        $newobj->{Value} = uri_unescape($v);
		push(@toreturn, $newobj);
	}
	return @toreturn; 
}

############################################
# $self->Name()  
# returns the value of $self->{Name}
sub Name  { return $_[0]->{Name}  or die "$0: no Name"; }	# only for reading

############################################
# $self->Value()  
# returns the value of $self->{Value}
sub Value { return $_[0]->{Value} or die "$0: no Value";  }	# only for reading


1;

__END__


=head1 NAME

SWISH::API::Remote::Header - An index header names/value, from a swished server

=head1 SYNOPSIS

 my $name = $result->Name;
 my $value = $result->Value;
 
=head1 DESCRIPTION

Stores a header names/values from a swished server. Intended to be used with
SWISH::API::Remote.

=head1 METHODS

=head2 Name

Returns the Name

=head2 Value

Returns the Value

=head1 SEE ALSO

L<SWISH::API::Remote::Results>, L<SWISH::API::Remote>, L<swish-e>

=head1 AUTHOR

Josh Rabinowitz, <joshr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Josh Rabinowitz 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1;
