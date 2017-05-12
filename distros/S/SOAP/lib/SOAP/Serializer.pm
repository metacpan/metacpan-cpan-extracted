package SOAP::Serializer;

require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(_serialize_object);

use strict;
use vars qw($VERSION);

$VERSION = '0.28';

sub _serialize_object {
    my ($stream, $envelope, $k_uri, $k, $v) = @_;

    my $serializer = $envelope->_get_type_mapper()->get_serializer($v);
    if ($serializer->is_multiref()) {
	$stream->reference_accessor($k_uri, $k, $v);
    }
    else {
	if ($serializer->is_compound()) {
	    my ($typeuri, $typename) = $serializer->get_typeinfo();
	    my $is_package = $serializer->is_package();
	    my $child_stream = $stream->compound_accessor(undef, $k, $typeuri, $typename, $is_package);
	    $serializer->serialize($child_stream, $envelope);
	}
	else {
	    # assume it's a simple type, but ask the serializer to do the work
	    # and also ask him for the type URI
	    my $content = $serializer->serialize_as_string();
	    my ($typeuri, $typename) = $serializer->get_typeinfo();
	    $stream->simple_accessor($k_uri, $k, $typeuri, $typename, $content);
	}
    }
}

1;
__END__

=head1 NAME

SOAP::Serializer - serialization utilities

=head1 SYNOPSIS

Used internally by SOAP/Perl

=head1 DESCRIPTION

Used internally by SOAP/Perl

=head1 AUTHOR

Keith Brown

=cut
