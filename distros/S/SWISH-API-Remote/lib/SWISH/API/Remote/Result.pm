package SWISH::API::Remote::Result;
use SWISH::API::Remote::FunctionGenerator;
use URI::Escape;
use fields qw( properties );
use strict;
use warnings;

############################################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless( $self, $class );
    $self->{properties} = {};    # empty hash
    return $self;
}

############################################
sub New_From_Query_String {
    my ( $qs, $resultsprops ) = @_;
    my $newobj = new SWISH::API::Remote::Result;
    my @parts = split ( /&/, $qs );
    for my $p (@parts) {
        my ( $n, $v ) = map { uri_unescape($_) } split ( /=/, $p, 2 );	# split, THEN unescape
        $resultsprops->[$n] = "Unknown$n" unless defined( $resultsprops->[$n] ); 
        #warn "Property number $n ( $resultsprops->[$n] ) : value $v\n";
		if (defined($n)) {
			$newobj->{properties}{ $resultsprops->[$n] } = $v || "";
		}
    }

    #print Data::Dumper::Dumper($newobj);
    return $newobj;
}

############################################
sub Property {
    my ( $self, $prop ) = @_; 
    #print "Looking up property $prop\n";
    return exists( $self->{properties} ) ? $self->{properties}{$prop} : "";
}

############################################
sub Properties {
	my $self = shift;
	return sort(keys( %{ $self->{properties} } ));	# we sort so the order is consistent
}

1;

__END__

=head1 NAME

SWISH::API::Remote::Result - Represents a single 'hit' from swished

=head1 DESCRIPTION

Performs searches on a remote swished server using an interface similar to SWISH::API

=over 4

=item my @properties = $result->Properties();

returns a sorted list of the properties fetched for the result.

=item my $value = $result->Property('swishtitle');

returns a the named property.

=back

=head1 SEE ALSO

L<SWISH::API::Remote::Results>, L<SWISH::API::Remote>, L<swish-e>

=head1 AUTHOR

Josh Rabinowitz, E<lt>joshr@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 by Josh Rabinowitz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
