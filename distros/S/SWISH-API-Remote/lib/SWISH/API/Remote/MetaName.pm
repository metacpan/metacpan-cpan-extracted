package SWISH::API::Remote::MetaName;
use URI::Escape;

############################################
# an object basically encapsulating a list of [Name, Id, Type]
# and offering methods of the same name to access them.
use fields qw( Name Id Type ); 

############################################
sub new {
	my SWISH::API::Remote::MetaName $self = shift;
	unless (ref $self) {
		$self = fields::new($self);
	}
	return $self;
}

############################################
# Parse_MetaNames_From_Query_String( $line )
# returns A LIST of MetaName objects (which also are used to describe Properties)
sub Parse_MetaNames_From_Query_String {
	my $line = shift;
    my @parts = split ( /&/, $line );
	my @toreturn;
	for my $p (@parts) {
        my ( $id, $v ) = split ( /=/, $p, 2 );
		my ( $name, $type ) = split(',', uri_unescape($v), 2);
		my $newobj = new SWISH::API::Remote::MetaName;
        $newobj->{Id} = $id;
        $newobj->{Name} = $name;
        $newobj->{Type} = $type;
		push(@toreturn, $newobj);
	}
	return @toreturn; 
}

############################################
#
# $self->Name(), $self->Id(), and $self->Type()
# return the corresponding values from $self
#  Note: why not let user reset value. We might as well use FunctionGenerator. TODO.
#
sub Name { my $s = shift; return $s->{Name} or die "$0: no Name"; }	# only for reading
sub Id   { my $s = shift; return $s->{Id}   or die "$0: no Id";  }	# only for reading
sub Type { my $s = shift; return $s->{Type} or die "$0: no Type"; }	# only for reading
############################################

1;


