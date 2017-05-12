package SOAP::OutputStream;

use strict;
use vars qw($VERSION);
use SOAP::Defs;

$VERSION = '0.28';

########################################################################
# constructor
########################################################################
sub new {
    my ($class) = @_;
    my $self = {
        tag             => undef,   # the closing tag we write at term
        packager        => undef,   # if we're not a package, this points to an ancestor who is
                                    # and implements the functions for maintaining objrefs
        soap_prefix     => '',      # this allows us to turn on/off namespace support
        envelope        => 0,       # manages ids and namespaces
        depth           => 1,       # use a one-based depth simply for consistency
                                    # with expat on the other side
        print_fcn       => undef,
        seal_package    => undef,   # do we need to seal our package on term or not?
    };
    bless $self, $class;
}

########################################################################
# interface ISoapStream
########################################################################
sub simple_accessor {
#   my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $content) = @_;
    &_simple_accessor;
}

sub compound_accessor {
#    my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $is_package) = @_;
    &_compound_accessor;
}

sub reference_accessor {
#    my ($self, $accessor_uri, $accessor_name, $object) = @_;
    &_reference_accessor;
}

sub term {
#   my ($self) = @_;
    &_term;
}

########################################################################
# implementation
########################################################################
sub _simple_accessor {
    my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $content) = @_;

    my $attrs = '';

    my $nsprefix = '';
    if (defined $accessor_uri) {
        (my $nsdecl, $nsprefix) = $self->{envelope}->_get_ns_decl_and_prefix($accessor_uri);
        $attrs .= $nsdecl if $nsdecl;
    }
    my $tag = $nsprefix . $accessor_name;

    if (defined $typename) {
        my $nsprefix = '';
        if (defined $typeuri) {
            (my $nsdecl, $nsprefix) = $self->{envelope}->_get_ns_decl_and_prefix($typeuri);
            $attrs .= $nsdecl if $nsdecl;
        }
        $attrs .= qq[ $xsi_prefix:type="$nsprefix$typename"];
    }

    $self->_print(qq[<$tag$attrs>$content</$tag>]);
}

sub _compound_accessor {
    my ($self, $accessor_uri, $accessor_name, $typeuri, $typename, $is_package) = @_;

    my $sp = $self->{soap_prefix};

    my $attrs = '';

    my $packager = $is_package ? $self->_create_new_package() : $self->{packager};
    my $envelope = $self->{envelope};

    my $new_depth = $self->{depth} + 1;

    my $stream = SOAP::OutputStream->new();
    $stream->{packager}       = $packager;
    $stream->{envelope}       = $self->{envelope};
    $stream->{depth}          = $new_depth;
    $stream->{print_fcn}      = $self->{print_fcn};
    $stream->{soap_prefix}    = $self->{soap_prefix};
    $stream->{seal_package}   = $is_package;

    my $nsprefix = '';
    if (defined $accessor_uri) {
        (my $nsdecl, $nsprefix) = $self->{envelope}->_push_ns_decl_and_prefix($accessor_uri, $new_depth);
        $attrs .= $nsdecl if $nsdecl;
    }
    my $tag = $nsprefix . $accessor_name;

    $stream->{tag} = $tag;

    if (defined $typename) {
        my $nsprefix = '';
        if (defined $typeuri) {
            (my $nsdecl, $nsprefix) = $self->{envelope}->_push_ns_decl_and_prefix($typeuri, $new_depth);
            $attrs .= $nsdecl if $nsdecl;
        }
        $attrs .= qq[ $xsi_prefix:type="$nsprefix$typename"];
    }

    $self->_print(qq[<$tag$attrs>]);

    $stream;
}

sub _reference_accessor {
    my ($self, $accessor_uri, $accessor_name, $object) = @_;

    my $sp = $self->{soap_prefix};

    my $attrs = '';
    if (defined $object) {
        my $id = $self->{packager}->register($self->{envelope}, $object);

        $attrs = qq[ $soap_href="#$id"];
    }
    else {
        $attrs .= qq[ $xsi_prefix:$xsd_null="1"];
    }

    my $nsprefix = '';
    if (defined $accessor_uri) {
        (my $nsdecl, $nsprefix) = $self->{envelope}->_get_ns_decl_and_prefix($accessor_uri);
        $attrs .= $nsdecl if $nsdecl;
    }
    my $tag = $nsprefix . $accessor_name;

    if ($accessor_uri) {
        $self->_clean_up_namespace_dictionary($self->{depth} + 1);
    }

    $self->_print(qq[<$tag$attrs />]);
}

sub _term {
    my ($self) = @_;

    if ($self->{seal_package}) {
        $self->{packager}->seal($self->{envelope});
    }

    my $tag = $self->{tag};
    $self->_print(qq[</$tag>]);

    $self->_clean_up_namespace_dictionary($self->{depth});
}

########################################################################
# misc
########################################################################
sub _create_new_package {
    my ($self) = @_;
    SOAP::Packager->new($self->{soap_prefix},
                        $self->{depth},
                        $self->{print_fcn});
}

sub _clean_up_namespace_dictionary {
    my ($self, $depth) = @_;
    $self->{envelope}->_clean_up_namespace_dictionary($depth);
}

sub _print {
    my ($self, $s) = @_;
    
    $self->{print_fcn}->($s);
}

1;
__END__


=head1 NAME

SOAP::OutputStream - Writes SOAP fragments

=head1 SYNOPSIS

    # note that we need SOAP::Envelope to bootstrap
    use SOAP::Envelope;

    sub output_fcn {
        my $string = shift;
        print $string;
    }

    my $namespaces_to_preload = ["urn:foo", "urn:bar"];
    my $env = SOAP::Envelope->new(\&output_fcn,
                                  $namespaces_to_preload);
    my $body = $env->body();
    
    # here is where we actually use SOAP::OutputStream
    my $child = $body->compound_accessor("urn:quux", "reverse_string", undef, undef, 0);

    $child->simple_accessor(undef, "s", undef, undef, "dlrow olleH");

    $child->term();
    $body->term();
    $env->term();

This creates the following XML:

<s:Envelope xmlns:s="urn:schemas-xmlsoap-org:soap.v1" 
            xmlns:xsd="http://www.w3.org/1999/XMLSchema" 
            xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
            xmlns:n1="urn:foo" 
            xmlns:n2="urn:bar">
  <s:Body>
    <n3:reverse_string xmlns:n3="urn:quux">
      <s>dlrow olleH</s>
    </n3:reverse_string>
  </s:Body>
</s:Envelope>


=head1 DESCRIPTION

SOAP::OutputStream encapsulates the details of writing SOAP packets into a few easy
to use functions. In order to bootstrap a SOAP stream (and get your first
SOAP::OutputStream reference), you'll need to use SOAP::Envelope, as shown in
the example above.

=head2 The simple_accessor function

This function writes a simple accessor (e.g., a string or number, as opposed
to a compound type). It takes two sets of URI/typenames, one for the accessor
and one for the optional xsi:type attribute. At a minimum, you must specify the
accessor_name and content.

=head2 The compound_accessor function

This function opens a new compound accessor (by writing an open XML tag), and
returns a new SOAP::OutputStream that you should use to write the contents of that
accessor. This function always creates nested elements. If you want to create
an independent element, call reference_accessor instead. The is_package parameter
allows you to open a new package at this node; the OutputStream will write all
further independent elements at this level in the XML document, creating a
standalone XML fragment within the SOAP envelope. The OutputStream will complain
if all references within the package cannot be resolved when this node is closed.
See the SOAP spec for details on packages.

NOTE NOTE NOTE: The SOAP "package" attribute was dropped when the SOAP spec
                went from version 1.0 to version 1.1. Use package-related
                functionality at your own risk - you may not interoperate
                with other servers if you rely on it. I'll eventually remove
                this feature if it doesn't reappear in the spec soon.

=head2 The reference_accessor function

This function creates a reference (SOAP:href) node, and stores the specified
object until the current package is closed, at which time a serializer is obtained
for the object (based on its type) and is asked to serialize itself to
a new stream at the level of the package. Note that if you're not using
packages explicitly, then the system will perform this resolution and
serialization when you switch from creating Headers to creating the Body,
and once again when the Body is terminated. The object referenced is guaranteed
to only be serialized once (assuming you've obeyed the SOAP rules for packages
and Header/Body object reference sharing).

=head2 The term function

Call this function when you want to close the node you're working with.
This does several things - it seals the package if the node you're using
was created as a package, and it writes an end tag (along with doing some
other internal bookeeping that's pretty important). Don't forget to call
this function before opening a new sibling node.

=head1 DEPENDENCIES

SOAP::Defs

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::Envelope

=cut
