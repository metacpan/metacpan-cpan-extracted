package SOAP::GenericInputStream;

use strict;
use vars qw($VERSION);
use SOAP::Defs;
use SOAP::TypeMapper;

$VERSION = '0.28';

########################################################################
# constructor
########################################################################
sub new {
    my ($class, $typeuri, $typename, $resolver, $type_mapper) = @_;

    $type_mapper ||= SOAP::TypeMapper->defaultMapper();

    my $self = {
        resolver    => $resolver,
        diags       => 'root',
        type_mapper => $type_mapper,
        hash        => {},
        text        => '',
        has_accessors => 0,
    };

    $self->{$soapperl_intrusive_hash_key_typeuri}  = $typeuri  if $typeuri;
    $self->{$soapperl_intrusive_hash_key_typename} = $typename if $typename;

    bless $self, $class;
}

########################################################################
# interface ISoapStream
########################################################################
sub content {
#   my ($self, $text) = @_;
    &_content;
}
sub simple_accessor {
#   my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $content) = @_;
    &_simple_accessor;
}

sub compound_accessor {
#    my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $is_package, $resolver) = @_;
    &_compound_accessor;
}

sub reference_accessor {
#    my ($self, $accessor_uri, $accessor_name, $object) = @_;
    &_reference_accessor;
}

sub forward_reference_accessor {
#    my ($self, $accessor_uri, $accessor_name) = @_;
    &_forward_reference_accessor;
}

sub term {
#   my ($self) = @_;
    &_term;
}

########################################################################
# implementation
########################################################################
sub _content {
    my ($self, $text) = @_;

    $self->{text} = $text;
}
sub _simple_accessor {
    my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $content) = @_;

    #
    # TBD: perform appropriate transformation based on $typename
    #

    ++$self->{has_accessors};

    $self->_add_accessor($accessor_name, $content);
}

sub _compound_accessor {
    my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $is_package, $resolver) = @_;

    my $my_resolver = sub {
        my $child_object = shift;
        $self->_add_accessor($accessor_name, $child_object);
        $resolver->($child_object) if $resolver;
    };

    my $stream = $self->{type_mapper}->get_deserializer($typeuri,
                                                        $typename,
                                                        $my_resolver);

    ++$self->{has_accessors};

    #
    # DIAGS
    #
    {
        my $typename_or_undef = defined($typename) ? $typename : '<undef>';
        $stream->{diags} = "parent accessor: <$accessor_name>, type: $typename_or_undef";
    }
    $stream;
}

sub _reference_accessor {
    my ($self, $accessor_uri, $accessor_name, $object) = @_;

    ++$self->{has_accessors};

    $self->_add_accessor($accessor_name, $object);
}

sub _forward_reference_accessor {
    my ($self, $accessor_uri, $accessor_name) = @_;

    ++$self->{has_accessors};

    # return a closure to complete the transaction at a later date
    sub { $self->_add_accessor($accessor_name, shift) };
}

sub _term {
    my ($self) = @_;

    my $text = $self->{text};
    my $hash = $self->{hash};

    #
    # to determine whether this is a hash or a scalar node,
    # see if there were any accessors
    #
    my $object;
    if ($self->{has_accessors}) {
	#
	# there were accessors, so verify that there was no
	# non-whitespace text interspersed in between them
	#
	if ($text =~ /\S/) {
	    die "Found non-whitespace content between accessors: [$text]";
	}
	$object = $self->{hash};
    }    
    else {
	$object = $self->{text};
    }

    $hash->{$soapperl_intrusive_hash_key_typeuri}  = $self->{$soapperl_intrusive_hash_key_typeuri}  if exists $self->{$soapperl_intrusive_hash_key_typeuri};
    $hash->{$soapperl_intrusive_hash_key_typename} = $self->{$soapperl_intrusive_hash_key_typename} if exists $self->{$soapperl_intrusive_hash_key_typename};

    $self->{resolver}->($object);
}

#############################################################
# misc
#############################################################
sub _add_accessor {
    my ($self, $accessor_name, $object) = @_;

    my $hash = $self->{hash};

    if (exists $hash->{$accessor_name}) {
        die "Duplicate accessor: $accessor_name"
    }
    $hash->{$accessor_name} = $object;
}

1;

__END__

=head1 NAME

SOAP::GenericInputStream - Default handler for SOAP::Parser output

=head1 SYNOPSIS

    use SOAP::Parser;
  
    my $parser = SOAP::Parser->new();

    $parser->parsefile('soap.xml');

    my $headers = $parser->get_headers();
    my $body    = $parser->get_body();


=head1 DESCRIPTION

As you can see from the synopsis, you won't use SOAP::GenericInputStream
directly, but rather the SOAP::Parser will create instances of it when
necessary to unmarshal SOAP documents.

The main reason for this documentation is to describe the interface
exposed from SOAP::GenericInputStream because you need to implement this
interface if you'd like to have the parser create something more exotic
than what SOAP::GenericInputStream produces.

=head2 new(TypeUri, TypeName, Resolver)

TypeUri and TypeName are strings that indicate the type of object being
unmarshaled. Resolver is a function pointer takes a single argument,
the resulting object, and you should call through this pointer in your
implementation of term (which means you need to store it until term is
called). Here's an example of a minimal implementation, assuming you've
stored the object reference in $self->{object}:

    sub new {
        my ($class, $typeuri, $typename, $resolver) = @_;
        return bless { resolver => $resolver }, $class;
    }

    sub term {
        my ($self) = @_;
        $self->{resolver}->($self->{object});
    }

=head2 simple_accessor(AccessorUri, AccessorName, TypeUri, TypeName, Content)

SOAP::Parser calls this function when it encounters a simple (scalar) accessor.
You are told the uri and name of both the accessor and any xsi:type attribute.
If the packet being unmarshaled doesn't use namespaces (this is possible but isn't
recommended by the SOAP spec), AccessorUri will be undefined. Unless there is an
explicit xsi:type, TypeUri and TypeName will also be undefined. So the only two
parameters that are guaranteed to be defined are AccessorName and Content.

AccessorUri and AccessorName gives the namespace and name of the element,
and Content contains the scalar content (always a string).

=head2 compound_accessor(AccessorUri, AccessorName, TypeUri, TypeName, IsPackage, Resolver)


SOAP::Parser calls this function when it encounters a compound accessor (e.g.,
a structured type whose value is inlined under the accessor). The first four
parameters here are as described in simple_accessor above. IsPackage is a hint
that tells you that this node is a package (generally you can ignore this; SOAP::Parser
does all the work to deal with packages). Resolver may or may not be defined,
and I'll discuss how it works shortly.

NOTE NOTE NOTE: The SOAP "package" attribute was dropped when the SOAP spec
                went from version 1.0 to version 1.1. Use package-related
                functionality at your own risk - you may not interoperate
                with other servers if you rely on it. I'll eventually remove
                this feature if it doesn't reappear in the spec soon.

This function must return a blessed object reference that implements the
same interface (nothing prohibits you from simply returning $self, but since SOAP::Parser
keeps track of these object references on a per-node basis, it's usually easier just
to create a new instance of your class and have each instance know how to unmarshal
a single object).

If Resolver is defined, you'll need to call it when the new stream is term'd to
communicate the resulting object reference to the Parser, so be sure to propagate
this reference to the new stream you create to do the unmarshaling. Since you probably
also need to be notified when the new object is created, you'll not normally hand Resolver
directly to the new stream, but rather you'll provide your own implementation of Resolver
that does something with the object and then chains to the Resolver passed in from the
parser:

    sub compound_accessor {
        my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $is_package, $resolver) = @_;

        my $object = $self->{object};

        # create a closure to pass to the new input stream
        my $my_resolver = sub {
            my ($newly_unmarshaled_object) = @_;

            # do something with the object yourself
            $object->{$accessor_name} = $newly_unmarshaled_object;

            # chain to the Parser's resolver if it's defined
            $resolver->($child_object) if $resolver;
        };

        return $self->{type_mapper}->get_deserializer($typeuri, $typename, $my_resolver);
    }

=head2 reference_accessor(AccessorUri, AccessorName, Object)

SOAP::Parser calls this function when it encounters a reference to an object that
it's already unmarshaled. AccessorUri and AccessorName are the same as in simple_accessor,
and Object is a reference to a thingy; it's basically whatever was resolved when
another stream (perhaps one that you implemented) unmarshaled the thingy. This could
be a blessed object reference, or simply a reference to a scalar (in SOAP it is possible
to communicate pointers to multiref scalars). In any case, you should add this new
reference to the object graph. Here's a simple example:

    sub reference_accessor {
        my ($self, $accessor_uri, $accessor_name, $object) = @_;

        $self->{object}{$accessor_name} = $object;
    }

=head2 forward_reference_accessor(AccessorUri, AccessorName)

SOAP::Parser calls this function when it encounters a reference to an object that
has not yet been unmarshaled (a forward reference). You should return a function
pointer that expects a single argument (the unmarshaled object). This can be as simple
as creating a closure that simply delays a call to reference_accessor on yourself:


    sub forward_reference_accessor {
        my ($self, $accessor_uri, $accessor_name) = @_;

        # return a closure to complete the transaction at a later date
        return sub {
            my ($object) = @_;
            $self->reference_accessor($accessor_uri, $accessor_name, $object);
        };
    }

=head2 term()

SOAP::Parser calls this function when there are no more accessors for the given node.
You are expected to call the Resolver you were passed at construction time at this point
to pass the unmarshaled object reference to your parent. Note that due to forward
references, the object may not be complete yet (it may have oustanding forward references
that haven't yet been resolved). This isn't a problem, because the parse isn't finished
yet, and as long as you've provided a resolver that fixes up these object references
from your implementation of forward_reference_accessor, by the time the parse is complete,
your object have all its references resolved by the parser.

See the description of new() for an example implementation of this function.

=head1 DEPENDENCIES

SOAP::TypeMapper

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

perl(1).

=cut
