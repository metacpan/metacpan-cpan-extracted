package SOAP::Packager;

use strict;
use vars qw($VERSION);
use SOAP::Defs;

$VERSION = '0.28';

sub new {
    my ($class, $soap_prefix, $depth, $print_fcn) = @_;
    my $self = {
        soap_prefix => $soap_prefix, # this allows us to turn on/off namespace support
        depth       => $depth,
        print_fcn   => $print_fcn,
    };
    bless $self, $class;
}

sub is_registered {
    my ($self, $object) = @_;

              $self->{objref_dictionary}{$object}[0]
    if exists $self->{objref_dictionary}{$object};
}

sub register {
    my ($self, $envelope, $object, $already_serialized) = @_;

    #
    # $already_serialized is an optional parameter that you can pass as nonzero
    # to indicate that the object has been serialized into the stream, but might
    # be referred to by other objects. This is used to deal with the special
    # cases where roots (body root, and headers) may be referenced, and *could*
    # be used to implement the special case of strings/bytearrays, if we can figure
    # out a reasonable way of automating string/bytearray matching. I don't expect
    # to implement this feature in my serializing (as opposed to deserializing) code
    # anytime soon though.
    #

    #
    # my dictionaries spring into life the first time we use them,
    # so be careful always to use them via hash references here!
    #
    if (exists $self->{objref_dictionary}{$object}) {
        return $self->{objref_dictionary}{$object}[0];
    }
    elsif (exists $self->{objref_dictionary_while_sealing}) {
        if (exists $self->{objref_dictionary_while_sealing}{$object}) {
            return $self->{objref_dictionary_while_sealing}{$object}[0];
        }
        else {
            my $id = $envelope->_alloc_id();
            $self->{objref_dictionary_while_sealing}{$object} = 
                $already_serialized ? [$id] : [$id, $object];
            return $id;
        }
    }
    else {
        my $id = $envelope->_alloc_id();
        $self->{objref_dictionary}{$object} =
            $already_serialized ? [$id] : [$id, $object];
        return $id;
    }
}

sub seal {
    my ($self, $envelope) = @_;

    #
    # NOTE: seal() explicitly supports sealing off multiple times
    #       to deal with the Envelope/Header/Body special case, where Header
    #       mustn't have any "external pointers", but may have "internal pointers"
    #       coming from Body.
    #       whenever an object is sealed, it is popped from the packager's
    #       dictionary (the hashed objref-->id mapping is left intact though)
    #       so that on a reseal, we won't end up reserializing any objects
    #

    # quit if there's nothing to do
    return unless exists $self->{objref_dictionary};

    #
    # the presence of this member variable indicates that we are sealing
    #
    my $objref_dictionary_while_sealing      =
    $self->{objref_dictionary_while_sealing} = {};

    my $objref_dictionary = $self->{objref_dictionary};
    while (my ($key, $id_and_object) = each %$objref_dictionary) {
        if (2 == @$id_and_object) {
            $self->seal_object($envelope, @$id_and_object);
            pop @{$id_and_object};
        }
    }

    while (%$objref_dictionary_while_sealing) {
        #
        # first merge newly added items into our main identity table
        #
        while (my ($key, $id_and_object) = each %$objref_dictionary_while_sealing) {
            $self->{objref_dictionary}{$id_and_object->[1]} = $id_and_object;
        }

        my $prev_dict = $objref_dictionary_while_sealing;
        $objref_dictionary_while_sealing         =
        $self->{objref_dictionary_while_sealing} = {};

        #
        # finally serialize the items added during the previous pass
        #
        while (my ($key, $id_and_object) = each %$prev_dict) {
            if (2 == @$id_and_object) {
                $self->seal_object($envelope, @$id_and_object);
                pop @{$id_and_object};
            }
        }
    }
    delete $self->{objref_dictionary_while_sealing};
}

sub seal_object {
    my ($self, $envelope, $id, $object) = @_;

    my $serializer = $envelope->_get_type_mapper()->get_serializer($object);

    my ($accessor_uri, $accessor_name) = $serializer->get_typeinfo();

    $accessor_name ||= 'item';

    my $sp = $self->{soap_prefix};

    my $attrs = qq[ ${sp}id="$id"];

    if ($serializer->is_compound()) {
	my $new_depth = $self->{depth} + 1;

	my $nsprefix = '';
	if (defined $accessor_uri) {
	    (my $nsdecl, $nsprefix) = $envelope->_push_ns_decl_and_prefix($accessor_uri, $new_depth);
	    $attrs .= $nsdecl if $nsdecl;
	}
	my $tag = $nsprefix . $accessor_name;

	$self->_print(qq[<$tag$attrs>]);

	my $packager = $serializer->is_package() ?
	    $envelope->_create_new_package($new_depth) : $self;
	
	my $stream = SOAP::OutputStream->new();
	$stream->{tag}          = $tag;
	$stream->{packager}     = $packager;
	$stream->{envelope}     = $envelope;
	$stream->{print_fcn}    = $self->{print_fcn};
	$stream->{soap_prefix}  = $self->{soap_prefix};
	$stream->{depth}        = $new_depth;

	$serializer->serialize($stream, $envelope);
	$stream->term();
    }
    else {
        my $content = $serializer->serialize_as_string();

        my $nsprefix = '';
        if (defined $accessor_uri) {
            (my $nsdecl, $nsprefix) = $envelope->_get_ns_decl_and_prefix($accessor_uri);
            $attrs .= $nsdecl if $nsdecl;
        }
        my $tag = $nsprefix . $accessor_name;

        $self->_print(qq[<$tag$attrs>$content</$tag>]);

        return;

    }
}

sub _print {
    my ($self, $s) = @_;
    
    $self->{print_fcn}->($s);
}



1;
__END__


=head1 NAME

SOAP::Packager - SOAP internal helper class

=head1 SYNOPSIS

    use SOAP::Packager;
    my $packager = SOAP::Packager->new('s:', 1, sub { print shift } );

    # some object used as a reference
    my $object = SOAP::Object->new();

    # on a given packager, register() always returns the same id for a given object
    my $id = $packager->register($env, $object);
    unless($id == $packager->register($env, $object)) { die "internal error" }

    # this serializes objectA
    $packager->seal($envelope);

    # note that the package is still valid
    unless($id == $packager->register($env, $object)) { die "internal error" }

    my $objectB = SOAP::Object->new();
    my $idB = $packager->register($env, $objectB);
    unless($idB == $packager->register($env, $objectB)) { die "internal error" }

    # this just serializes objectB - objectA was already serialized before
    $packager->seal($env);

    # this does nothing except waste some cycles enumerating a hash table
    $packager->seal($env=);

    # hash tables shut down at destruction of packager, releasing object references
    $packager = undef;

=head1 DESCRIPTION

This is an internal class used by the SOAP/Perl implementation. It is designed to
manage a table of object references and XML ids used for serializing object graphs
that may contain multiref data (and perhaps even cycles). If you are extending
SOAP/Perl, the above synopsis will probably be all you need if you want to reuse this
class. Whatever you pass for the $env reference should implement a function called
_alloc_id that returns a unique string each time it is called. This is normally
implemented by SOAP::Envelope, so you can see a sample implementation there.

NOTE NOTE NOTE: The SOAP "package" attribute was dropped when the SOAP spec
                went from version 1.0 to version 1.1. Use package-related
                functionality at your own risk - you may not interoperate
                with other servers if you rely on it. I'll eventually remove
                this feature if it doesn't reappear in the spec soon.

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::Envelope
SOAP::OutputStream

=cut
