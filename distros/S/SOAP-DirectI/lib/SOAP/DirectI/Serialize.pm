#
#===============================================================================
#
#         FILE:  Serialize.pm
#
#  DESCRIPTION:  SOAP::DirectI::Serialize -- serialization of requests to DirectI
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  18.03.2009 13:38:32 MSK
#     REVISION:  ---
#===============================================================================

package SOAP::DirectI::Serialize;

use strict;
use warnings;

use Carp;

sub hash_to_soap {
    my $self = shift;
    my ($data, $signature) = @_;

    my @output;

    push @output, $self->request_prefix( $signature );

    my $args = $signature->{ args };

    push @output, $self->serialize_args( $args, $data );

    push @output, $self->request_suffix( $signature );

    #warn @output;

    return join '', @output;
}

sub serialize_args {
    my $self = shift;
    my $args = shift;
    my $data = shift;

    my @output;

    foreach my $arg (@$args) {
	my $hash_key = $arg->{hash_key	};
	my $key	     = $arg->{key	};

	if ( not $hash_key ) {
	    $hash_key = join '_', map { lc $_ } ($key =~ m/([A-Z]?[a-z0-9]+)/g);
	}

	if ( ! exists $data->{ $hash_key } && $arg->{required} ) {
	    croak "Required field $key missed";
	}

	#warn $hash_key;

	my $d = $data->{ $hash_key  };
	# NOTE FUCKING RECURSION!
	if ( ! $d && (my $s = $self->can('_default_value_'.$hash_key)) ) {
	    $d = $s->( $self, $arg, $data );
	}
	#my $t = $arg ->{ type	    };

	push @output, $self->serialize( $arg, $d );
    }

    return @output;
}


sub request_prefix {
    my ($self, $signature) = @_;

    $signature->{namespace} ||= 'com.logicboxes.foundation.sfnb.user.Customer';

    return <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<SOAP-ENV:Envelope SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" xmlns:si="http://soapinterop.org/xsd" xmlns:apachesoap="http://xml.apache.org/xml-soap" xmlns:impl="$signature->{namespace}">
   <SOAP-ENV:Body>
	 <impl:$signature->{name}>
EOF
}

sub request_suffix {
    my ($self, $signature) = @_;
    return <<EOF;
\n
	</impl:$signature->{name}>
    </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
}

sub serialize {
    my ($self, $arg, $d) = @_;

    if ( my $serializer = $self->can('serialize_'.$arg->{type}) ) {
	return $serializer->( $self, $arg, $d );
    }

    return _serialize_simple( $arg, $d );

    croak "Cannot find serializer for $arg->{type}";
}

sub serialize_array {
    return _serialize_array_or_vector( @_ );
}

sub serialize_vector {
    return _serialize_array_or_vector( @_ );
}

sub serialize_map {
    my ($self, $arg, $hash) = @_;

    if ( ref $hash ne 'HASH' ) {
	croak "$arg->{key} is not HASH ref";
    }

    #warn Dumper $hash;

    if ( ! exists $arg->{key_sig} && exists $arg->{key_type} ) {

	$arg->{key_sig} = {
	    type => $arg->{key_type},
	    key  => 'key',
	};
    }

    if ( ! exists $arg->{value_sig} && exists $arg->{value_type} ) {

	$arg->{value_sig} = {
	    type => $arg->{value_type},
	    key  => 'value',
	};
    }

    my $key_sig    = $arg->{key_sig}
	or croak "Unspecified key type for $arg->{key} map";
    my $value_sig  = $arg->{value_sig}
	or croak "Unspecified key type for $arg->{key} map";

    my @output;

    push @output, _tag_start( $arg->{key}, q{xsi:type="apachesoap:Map"});

    while ( my ( $k, $v ) = each %$hash ) {
	my @pair;

	push @pair, q{<item>};
	push @pair, $self->serialize(
	    $key_sig,
	    $k
	);
	push @pair, $self->serialize(
	    $value_sig,
	    $v
	);
	push @pair, q{</item>};

	push @output, @pair;
    }

    push @output, _tag_stop( $arg->{key} );

    return join '', @output;
}

sub _serialize_array_or_vector {
    my ($self, $arg, $array) = @_;

    if ( ref $array ne 'ARRAY' ) {
	croak "$arg->{key} is not ARRAY ref";
    }

    if ( ! exists $arg->{elem_sig} && exists $arg->{elem_type} ) {

	$arg->{elem_sig} = {
	    type => $arg->{elem_type},
	    key  => 'item',
	};
    }

    my $elem_sig = $arg->{elem_sig}
	or croak "Unspecified element type for $arg->{key} array";

    my @output;

    my $attr = q{xsi:type="apachesoap:Vector"};

    if ( $arg->{type} eq 'array' ) {
	my $elem_type_xml = get_xml_type( $elem_sig->{type} );
	my $length	      = scalar @$array;

	$attr = 
	 q{xsi:type="SOAP-ENC:Array" }.
	qq{SOAP-ENC:arrayType="$elem_type_xml\[$length]"};
    }
    
    push @output, _tag_start( $arg->{key}, $attr );

#    my $fake_arg_signature = {
#	key	=> 'item',
#	type	=> $elem_type,
#    };

    foreach my $elem (@$array) {
	push @output, $self->serialize( $elem_sig, $elem );
    }

    push @output, _tag_stop( $arg->{key} );

    return join '', @output;
}

sub _serialize_simple {
    my ($a, $d) = @_;

    croak "Undefined data for key $a->{key}\n" if not defined $d;

    my $t = eval { get_xml_type( $a->{type} ) };
    $t or croak "Cannot simple serialize $t: $@";
    return "<$a->{key} xsi:type=\"$t\">$d</$a->{key}>";
}

sub _tag_start {
    my ($tname, $attr) = @_;
    return "<$tname $attr>";
}

sub _tag_stop {
    my ($tname) = @_;
    return "</$tname>";
}

sub get_xml_type {
    my $t = shift;

    return 'xsd:'.$t if ( $t eq 'int' or $t eq 'string' or $t eq 'boolean' );

    croak "Unknown type: $t";
}

sub serialize_boolean {
    my ($self, $arg, $d) = @_;

    if ( ! $d || $d =~ m/^false$/i ) {
	$d = 'false';
    } 
    elsif ( $d =~ m/^true$/i || $d ) {
	$d = 'true';
    }

    return _serialize_simple( $arg, $d );
}

sub serialize_int {
    my ($self, $arg, $d) = @_;

    if ( not $d =~ m/^[0-9]+$/ ) {
	croak "$arg->{key} is not integer";
    }

    return _serialize_simple( $arg, $d );
}

sub serialize_string {
    my ($self, $arg, $d) = @_;

    return _serialize_simple( $arg, escape_xml( $d ) );
}

sub escape_xml {
    $_ = shift;

    return $_ unless $_;

    s/&/&amp;/xgs;
    s/</&lt;/xgs;
    s/>/&gt;/xgs;
    s/\"/&quot;/xgs;

    return $_;
}



1;
