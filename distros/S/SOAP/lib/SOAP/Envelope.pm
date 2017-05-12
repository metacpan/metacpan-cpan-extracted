package SOAP::Envelope;

use strict;
use vars qw($VERSION);
$VERSION = '0.28';

use SOAP::Defs;
use SOAP::OutputStream;
use SOAP::Packager;
use SOAP::TypeMapper;

########################################################################
# constructor
########################################################################
sub new {
    my ($class, $print_fcn, $namespace_uris_to_preload, $type_mapper) = @_;

    $type_mapper ||= SOAP::TypeMapper->defaultMapper();

    my $self = {
        print_fcn       => $print_fcn || \&__default_print_fcn,
        use_namespaces  => 1,
        header_count    => 0,
        soap_prefix     => '',
        cur_id          => 0,
        packager        => undef,
        type_mapper     => $type_mapper,
    };
    bless $self, $class;

    #
    # calculating $self->{soap_prefix} should be done VERY EARLY
    # because lots of objects (like the packager I create below)
    # copies this value for their own use...
    #
    my $attrs = '';
    if ($self->{use_namespaces}) {
        $self->{soap_prefix} = $soap_prefix . ':';

        $attrs .= $self->_preload_ns($soap_namespace, $soap_prefix);
        $attrs .= $self->_preload_ns($xsd_namespace, $xsd_prefix);
        $attrs .= $self->_preload_ns($xsi_namespace, $xsi_prefix);
    }

    $self->{packager} = $self->_create_new_packager();

    if ($namespace_uris_to_preload) {
        foreach my $uri (@$namespace_uris_to_preload) {
            $attrs .= $self->_preload_ns($uri);
        }
    }
    my $sp = $self->{soap_prefix};

    $attrs .= qq[ $sp$soap_encoding_style="$soap_section5_encoding"];

    $self->_print(qq[<$sp$soap_envelope$attrs>]);

    $self;
}

sub header {
    my ($self, $accessor_uri, $accessor_name,
               $typeuri, $typename,
               $must_understand, $is_package, $object) = @_;

    my $sp = $self->{soap_prefix};

    my $header_number = ++$self->{header_count};
    if (1 == $header_number) {
        #
        # this is the first header, so print the SOAP::Header tag to
        # delimit the headers
        #
        $self->_print(qq[<$sp$soap_header>]);
    }
    my $tag;
    my $attrs = '';
    if (defined $accessor_name) {
        my $nsprefix = '';
        if (defined $accessor_uri) {
            (my $nsdecl, $nsprefix) = $self->_get_ns_decl_and_prefix($accessor_uri);
            $attrs .= $nsdecl if $nsdecl;
        }
        $tag = qq[$nsprefix$accessor_name];
    }
    else {
        $tag = qq[header$header_number];
    }

    if (defined $typename) {
        my $nsprefix = '';
        if (defined $typeuri) {
            (my $nsdecl, $nsprefix) = $self->_get_ns_decl_and_prefix($typeuri);
            $attrs .= $nsdecl if $nsdecl;
        }
        $attrs .= qq[ $xsi_prefix:type="${nsprefix}$typename"];
    }

    if ($must_understand) {
        $attrs .= qq[ $sp$soap_must_understand="1"];
    }

    my $already_marshaled = 0;
    my $packager = $self->{packager};
    if ($object) {
        #
        # by passing in this optional parameter,
        # the header may be used as a multi-reference root
        #
        my $id = $packager->is_registered($object);
        if ($id) {
            $attrs .= qq[ $soap_href="#$id"];
            $already_marshaled = 1;
        }
        else {
            $id = $packager->register($self, $object, 1);
            $attrs .= qq[ $soap_id="$id"];
        }
        $attrs .= qq[ $sp$soap_root_with_id="1"];
    }

    if (!$already_marshaled && $is_package) {
        $attrs .= qq[ $sp$soap_package="1"];
    }

    $self->_print(qq[<$tag$attrs>]);

    my $stream = undef;
    if ($already_marshaled) {
        $self->_print(qq[</$tag>]);
    }
    else {
        my $child_packager = $is_package ? $self->_create_new_packager() : $packager;

        $stream = SOAP::OutputStream->new();
        $stream->{tag}            = $tag;    
        $stream->{packager}       = $child_packager;
        $stream->{soap_prefix}    = $self->{soap_prefix};
        $stream->{envelope}       = $self;    
        $stream->{print_fcn}      = $self->{print_fcn};
        $stream->{seal_package}   = $is_package;
    }
    $stream;
}

sub body {
    my ($self, $accessor_uri, $accessor_name,
               $typeuri, $typename, $is_package, $object) = @_;

    my $sp = $self->{soap_prefix};

    if ($self->{header_count}) {
        # delimit any headers
        $self->{packager}->seal($self);
        $self->_print(qq[</$sp$soap_header>]);
    }

    $self->_print(qq[<$sp$soap_body>]);

    my $tag;
    my $attrs = '';
    if (defined $accessor_name) {
        my $nsprefix = '';
        if (defined $accessor_uri) {
            (my $nsdecl, $nsprefix) = $self->_get_ns_decl_and_prefix($accessor_uri);
            $attrs .= $nsdecl if $nsdecl;
        }
# CLR (CLR doesn't like URI prefix on body root :-/
        $tag = qq[$nsprefix$accessor_name];
#        $tag = qq[$accessor_name];
    }

    if (defined $typename) {
        my $nsprefix = '';
        if (defined $typeuri) {
            (my $nsdecl, $nsprefix) = $self->_get_ns_decl_and_prefix($typeuri);
            $attrs .= $nsdecl if $nsdecl;
        }
	if (defined $accessor_name) {
	    $attrs .= qq[ $xsi_prefix:type="$nsprefix$typename"];
	}
	else {
	    # if no accessor name defined, pick it up from the type name
	    $tag = qq[$nsprefix$typename];
	}
    }

    my $already_marshaled = 0;
    my $packager = $self->{packager};
    if ($object) {
        #
        # by passing in this optional parameter,
        # the root element of the body may be used as a multi-reference root
        #
        my $id = $packager->is_registered($object);
        if ($id) {
            $attrs .= qq[ $soap_href="#$id"];
            $already_marshaled = 1;
        }
        else {
            $id = $packager->register($self, $object, 1);
            $attrs .= qq[ $soap_id="$id"];
        }
        $attrs .= qq[ $sp$soap_root_with_id="1"];
    }

    if (!$already_marshaled && $is_package) {
        $attrs .= qq[ $sp$soap_package="1"];
    }

    $self->_print(qq[<$tag$attrs>]);

    my $stream = undef;
    if ($already_marshaled) {
        $self->_print(qq[</$tag>]);
    }
    else {
        my $child_packager = $is_package ? $self->_create_new_packager() : $packager;

        $stream = SOAP::OutputStream->new();
        $stream->{tag}            = $tag;    
        $stream->{packager}       = $child_packager;
        $stream->{soap_prefix}    = $self->{soap_prefix};
        $stream->{envelope}       = $self;    
        $stream->{print_fcn}      = $self->{print_fcn};
        $stream->{seal_package}   = $is_package;
    }
    $stream;
}

sub term {
    my ($self) = @_;
    
    $self->{packager}->seal($self);

    my $sp = $self->{soap_prefix};
    $self->_print(qq[</$sp$soap_body></$sp$soap_envelope>]);
}

########################################################################
# misc
########################################################################
sub _get_type_mapper {
    my ($self) = @_;
    $self->{type_mapper};
}

sub _create_new_packager {
    my ($self, $depth) = @_;
    
    $depth ||= 1;
    
    SOAP::Packager->new($self->{soap_prefix},
                        $depth,
                        $self->{print_fcn});
}

sub _get_ns_decl_and_prefix {
    #
    # if the uri is already in use, just use the existing prefix,
    # otherwise, declare a new, temporary one, but don't bother caching it
    #
    my ($self, $uri) = @_;

    my $nsdecl = '';
    my $ns_prefix;
    if (exists $self->{uri_to_prefix}{$uri}) {
        $ns_prefix = $self->{uri_to_prefix}{$uri};
    }
    else {
        $ns_prefix = ('n' . ++$self->{cur_ns_prefix});
        $nsdecl = qq[ xmlns:${ns_prefix}="$uri"];
    }

    ($nsdecl, qq[${ns_prefix}:]);
}

sub _push_ns_decl_and_prefix {
    #
    # if the uri is already in use, just use the existing prefix,
    # otherwise, declare a new one, and save it for child scopes to use also
    #
    my ($self, $uri, $depth) = @_;

    my $nsdecl = '';
    my $ns_prefix;

    if (exists $self->{uri_to_prefix}{$uri}) {
        $ns_prefix = $self->{uri_to_prefix}{$uri};
    }
    else {
        #
        # add this uri to our namespace dictionary with an auto-generated prefix
        # and remember the depth at which we registered it, so we can remove it
        # during termination
        #
        $ns_prefix = $self->{uri_to_prefix}{$uri} = ('n' . ++$self->{cur_ns_prefix});
        push @{$self->{depth_to_uri_list}{$depth}}, $uri;

        $nsdecl = qq[ xmlns:${ns_prefix}="$uri"];
    }

    ($nsdecl, qq[${ns_prefix}:]);
}

sub _preload_ns {
    my ($self, $uri, $ns_prefix) = @_;

    my $nsdecl = '';
    unless (exists $self->{uri_to_prefix}{$uri}) {
        $ns_prefix ||= 'n' . ++$self->{cur_ns_prefix};
        $self->{uri_to_prefix}{$uri} = $ns_prefix;
        $nsdecl = qq[ xmlns:${ns_prefix}="$uri"];
    }
    $nsdecl;
}

sub _clean_up_namespace_dictionary {
    my ($self, $depth) = @_;

    if (exists $self->{depth_to_uri_list}{$depth}) {
        my $uri_to_prefix = $self->{uri_to_prefix};
        foreach my $uri (@{$self->{depth_to_uri_list}{$depth}}) {
            delete $uri_to_prefix->{$uri};
        }
        delete $self->{depth_to_uri_list}{$depth};
    }
}

sub _alloc_id {
    my ($self) = @_;

    my $id = ++$self->{cur_id};

    qq[ref-$id];  # follow SOAP examples (for clarity only)
}

sub _print {
    my ($self, $s) = @_;
    
    $self->{print_fcn}->($s);
}

sub __default_print_fcn {
    my ($s) = @_;
    print $s;
}

1;
__END__

=head1 NAME

SOAP::Envelope - Creates SOAP streams

=head1 SYNOPSIS

    use SOAP::Envelope;

    sub output_fcn {
        my $string = shift;
        print $string;
    }

    my $namespaces_to_preload = ["urn:foo", "urn:bar"];
    my $env = SOAP::Envelope->new(\&output_fcn,
                                  $namespaces_to_preload);
    my $header = $env->header("urn:a", "MyHeaderA",
                              undef, undef,
                              0, 0);
    ...
    $header->term();

    $header = $env->header("urn:b", "MyHeaderB",
                           undef, undef,
                           0, 0);
    ...
    $header->term();

    my $body = $env->body("urn:c", "MyCall",
                          undef, undef);
    ...
    $body->term();

    $env->term();


=head1 DESCRIPTION

This class bootstraps and manages the serialization of an object graph
into a SOAP stream. It is used by the SOAP::Transport classes, but may
be used directly as well.

=head2 The new function

Creates a new envelope. If you know you'll be using certain namespaces
a lot, you can save some space by preloading those namespaces (pass the
set of URI strings as an array when creating a new envelope, as in the example
above).

=head2 The header function

Creates a new header in the specified namespace URI (which is required).
You can call this function multiple times to create several different headers,
but don't call the body function until you've created all the headers.
If omitted, the typename and typeuri will be taken from the accessor name
and accessor uri, but the accessor name and uri are required.
Be sure to term() the current header before creating a new one.
For a discussion of the $object optional parameter, please see body(), below.

=head2 The body function

Creates the body. You can only call this function once per envelope,
and you must call it after you're done creating all the headers you need
to create. If omitted, the typename and typeuri will be taken from the accessor
name and accessor uri, but the accessor name is required.
The $object parameter is optional, but must be passed if headers (or subelements
in the body) may point to the body itself. SOAP::Envelope adds this object
reference into its identity dictionary to correctly deal with these cases
(a doubly-linked list is a simple example of this case).
If you pass $object, you have to be prepared for body() to return undef,
which indicates that the object was already marshaled into the header area
(because it was referred to by a header element). In this case, the body
element will simply be a reference to the previously marshaled body.
If body() returns a value, don't forget to call term() through it when you're done
serializing the body, because this forces the output of any outstanding multi-ref
items.

=head2 The term function

This writes an end tag, terminating the SOAP envelope.

=head1 DEPENDENCIES

SOAP::OutputStream
SOAP::Packager
SOAP::Defs

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::OutputStream
SOAP::Transport::HTTP

=cut
