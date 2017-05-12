package SOAP::Parser;

use strict;
use vars qw($VERSION);
$VERSION = '0.28';

use SOAP::Defs;
use SOAP::GenericInputStream;
use XML::Parser::Expat;

my $enum = 0;
my $m_ctx_soap_stream            = $enum++;
my $m_ctx_id                     = $enum++;
my $m_ctx_is_package             = $enum++;
my $m_ctx_typeuri                = $enum++;
my $m_ctx_typename               = $enum++;
my $m_ctx_child_id               = $enum++;
my $m_ctx_child_is_package       = $enum++;
my $m_ctx_child_accessor_uri     = $enum++;
my $m_ctx_child_typeuri          = $enum++;
my $m_ctx_child_typename         = $enum++;
my $m_ctx_depth                  = $enum++;
my $m_ctx_package                = $enum++;

$enum = 0;
my $m_pkgslot_object             = $enum++;
my $m_pkgslot_resolver_list      = $enum++;

$enum = 0;
my $c_accessor_type_simple   = $enum++;
my $c_accessor_type_compound = $enum++;

my $g_attr_parse_table = {
    $soap_id            => [undef,           'id'           ],
    $soap_href          => [undef,           'href'         ],
    $soap_package       => [$soap_namespace, 'package'      ],
    $soap_root_with_id  => [$soap_namespace, 'root_with_id' ],
    $xsd_type           => [$xsi_namespace,  'typename'     ],
    $xsd_null           => [$xsi_namespace,  'null'         ],
};

sub new {
    my ($class, $type_mapper)  = @_;

    $type_mapper ||= SOAP::TypeMapper->defaultMapper();

    my $self = {
        type_mapper             => $type_mapper,
        parser                  => undef,
        has_namespaces          => 0,
        handler_stack           => [],
        context_stack           => [],
        text                    => '',
        href                    => undef,
        is_null                 => 0,
        headers                 => [],
        root_with_id            => 0,
    };

    bless $self, $class;
}

sub DESTROY {
    my ($self) = @_;

    # important: Expat has internal circular refs that won't
    #            get cleaned up unless you call release
    $self->{parser}->release() if defined $self->{parser};
}

sub parsestring {
    my ($self, $soap_bar) = @_;
    $self->_create_parser()->parsestring($soap_bar);
}

sub parsefile {
    my ($self, $file) = @_;
    $self->_create_parser()->parsefile($file);
}

sub get_body {
    my ($self) = @_;
    $self->{body_root};
}

sub get_headers {
    my ($self) = @_;
    $self->{headers};
}

sub _bootstrapper_on_start {
    my ($self, $parser, $element) = (shift, shift, shift);
    __diagnostic_enter_element($parser, $element);

    my $depth = $parser->depth();

    # look for Envelope
    unless ($soap_envelope eq $element) { $self->_throw("expected $soap_envelope") }

    #
    # determine whether or not this SOAP bar uses namespaces
    # by looking for a namespace qualified start tag
    #
    $self->{has_namespaces} = my $has_namespaces = defined $parser->namespace($element);

    #
    # if there *is* a namespace, make sure it's the SOAP namespace
    #
    $self->_verify_soap_namespace($parser, $element);

    $self->_push_context(undef, 0, 1);

    $self->_push_handlers(Start => sub { $self->_envelope_on_start(@_) },
                          Char  => sub { $self->_envelope_on_char (@_) },
                          End   => sub { $self->_envelope_on_end  (@_) },
                         );
}

sub _envelope_on_start {
    my ($self, $parser, $element) = (shift, shift, shift);
    __diagnostic_enter_element($parser, $element);

    $self->_verify_no_new_namespaces($parser) unless $self->{has_namespaces};

    if ($soap_body eq $element) {
        $self->_verify_soap_namespace($parser, $element);

        $self->_push_handlers(Start => sub { $self->_body_on_start(@_) },
                              Char  => sub { $self->_body_on_char (@_) },
                              End   => sub { $self->_body_on_end  (@_) },
                              );
    }
    elsif ($soap_header eq $element) {
        unless (2 == $parser->element_index()) { $self->_throw("Unexpected $soap_header element (if present, $soap_header must be the first element under $soap_envelope)") }
        $self->_verify_soap_namespace($parser, $element);

        $self->_push_handlers(Start => sub { $self->_header_on_start(@_) },
                              Char  => sub { $self->_header_on_char (@_) },
                              End   => sub { $self->_header_on_end  (@_) },
                              );
    }
    else {
        $self->_throw("Unexpected element: $element");
    }
}

sub _envelope_on_char {
    my ($self, $parser, $s) = @_;
    $self->_complain_if_contains_non_whitespace($s);
}

sub _envelope_on_end {
    my ($self, $parser, $element) = @_;
    __diagnostic_leave_element($parser, $element);
    
    $self->_pop_context();
    $self->_pop_handlers();
}

sub _header_on_start {
    my ($self, $parser, $element) = (shift, shift, shift);

    __diagnostic_enter_element($parser, $element);
    $self->_verify_no_new_namespaces($parser) unless $self->{has_namespaces};

    # TBD: how can I verify that the header has an explicit namespace qualifier?
    #      (what I'm wondering is if there will be any headers that come out
    #       of urn:schemas-xmlsoap-org:soap.v1
    #
    #      perhaps i can use new_ns_prefixes somehow...

    $self->_parse_child_element_attrs($parser, \@_);

    my $id = $self->_child_id();

    my $is_root = !defined($id) || $self->{root_with_id};

    my $child_typeuri;
    my $child_typename;

    #
    # if no explicit type is specified, use the element name as the type
    # (this only applies to independent elements)
    #
    unless ($is_root) {    
        $child_typename = $self->_child_typename();
        if (defined $child_typename) {
            $child_typeuri = $self->_child_typeuri();
        }
    }

    #
    # pick up the type for header roots (and indep. elems without explicit xsi:type)
    #
    unless (defined $child_typename) {
        $child_typename = $element;
        $child_typeuri  = $parser->namespace($element);
    }

    my $resolver;
    if ($is_root) {
        #
        # the roots could potentially be references
        #
        if (my $href = $self->{href}) {
            my ($found_it, $result) = $self->_lookup_href($href);
            if ($found_it) {
                $self->_add_header($child_typeuri, $child_typename, $result);
            }
            else {
                push @$result, sub {
                    $self->_add_header($child_typeuri, $child_typename, shift);
                };
            }
            $self->_push_handlers(Start => sub { $self->_ref_on_start(@_) },
                                  Char  => sub { $self->_ref_on_char (@_) },
                                  End   => sub { $self->_ref_on_end  (@_) },
                                 );
            #
            # there's nothing more to do in this case
            #
            return;
        }
        $resolver = sub {
            my $object = shift;
            $self->_add_header($child_typeuri, $child_typename, $object);
            $self->_found_id($id, $object) if $id;
        };
    }
    else {
        $resolver = sub { $self->_found_id($id, shift) };
    }

    my $type_mapper = $self->{type_mapper};
    my $stream = $type_mapper->get_deserializer($child_typeuri,
                                                $child_typename,
                                                $resolver);

    $self->_push_context($stream, $parser->depth() + 1, $self->_child_is_package());

    $self->_push_handlers(Start => sub { $self->_generic_on_start(@_) },
                          Char  => sub { $self->_generic_on_char (@_) },
                          End   => sub { $self->_generic_on_end  (@_) },
                         );
}

sub _header_on_char {
    my ($self, $parser, $s) = @_;
    $self->_complain_if_contains_non_whitespace($s);
}

sub _header_on_end {
    my ($self, $parser, $element) = @_;
    __diagnostic_leave_element($parser, $element);

    #
    # note that both Body and Headers don't pop the root context,
    # rather they defer to Envelope, since Envelope is a package,
    # not Body or Headers.
    #
    $self->_pop_handlers();
}

sub _body_on_start {
    my ($self, $parser, $element) = (shift, shift, shift);

    __diagnostic_enter_element($parser, $element);
    $self->_verify_no_new_namespaces($parser) unless $self->{has_namespaces};

    $self->_parse_child_element_attrs($parser, \@_);

    my $id = $self->_child_id();

    my $resolver;
    if (exists $parser->{body_root}) {
        # we've already seen the body root, so this is an independent element
        # and independent elements *must* have ids
        unless (defined $id) { $self->_throw("$element is an independent element with no id attribute") }

        $resolver = sub { $self->_found_id($id, shift) };
    }
    else {
        # the first element under SOAP:Body is the root - indicate that we've seen it
        $parser->{body_root} = undef;
        #
        # the roots could potentially be references
        #
        if (my $href = $self->{href}) {
            my ($found_it, $result) = $self->_lookup_href($href);
            if ($found_it) {
                $self->{body_root} = $result;
            }
            else {
                push @$result, sub { $self->{body_root} = shift; };
            }
            $self->_push_handlers(Start => sub { $self->_ref_on_start(@_) },
                                  Char  => sub { $self->_ref_on_char (@_) },
                                  End   => sub { $self->_ref_on_end  (@_) },
                                 );
            #
            # there's nothing more to do in this case
            #
            return;
        }
        $resolver = sub {
            my $object = shift;
            $self->_found_id($id, $object) if defined $id;
            $self->{body_root} = $object;
        };
    }
    
    #
    # if no explicit type is specified, use the element name as the type
    #
    my $child_typeuri;
    my $child_typename = $self->_child_typename();
    if (defined $child_typename) {
        $child_typeuri = $self->_child_typeuri();
    }
    else {
        $child_typename = $element;
        $child_typeuri  = $parser->namespace($element);
    }

    my $type_mapper = $self->{type_mapper};
    my $stream = $type_mapper->get_deserializer($child_typeuri,
                                                $child_typename,
                                                $resolver);

    $self->_push_context($stream, $parser->depth() + 1, $self->_child_is_package());

    $self->_push_handlers(Start => sub { $self->_generic_on_start(@_) },
                          Char  => sub { $self->_generic_on_char (@_) },
                          End   => sub { $self->_generic_on_end  (@_) },
                         );
}

sub _body_on_char {
    my ($self, $parser, $s) = @_;
    $self->_complain_if_contains_non_whitespace($s);
}

sub _body_on_end {
    my ($self, $parser, $element) = @_;
    __diagnostic_leave_element($parser, $element);

    #
    # note that both Body and Headers don't pop the root context,
    # rather they defer to Envelope, since Envelope is a package,
    # not Body or Headers.
    #
    $self->_pop_handlers();
}

sub _generic_on_start {
    my ($self, $parser, $element) = (shift, shift, shift);

    __diagnostic_enter_element($parser, $element);
    $self->_verify_no_new_namespaces($parser) unless $self->{has_namespaces};

    my $depth       = $parser->depth();
    my $ctx_depth   = $self->_get_ctx_depth();

    if ($depth != $ctx_depth) {
        #
        # we just drilled down another level, so we need to setup
        # a new marshaler for this node.
        #
        $self->_complain_if_contains_non_whitespace($self->{text});

        my $parent_id           = $self->_child_id();
        my $parent_is_package   = $self->_child_is_package();
        my $parent_accessor_uri = $self->_child_accessor_uri();
        my $parent_typeuri      = $self->_child_typeuri();
        my $parent_typename     = $self->_child_typename();

        #
        # we need to determine whether this is an accessor or not...
        # right now, we use the presence of the id attribute
        #
        my $is_root = defined $parent_id;

        my $parent_accessor = (defined $parent_id) ? undef : $parser->current_element();

        my $new_stream;
        if ($is_root) {
            my $resolver = sub { $self->_found_id($parent_id, shift) };
            my $type_mapper = $self->{type_mapper};
            $new_stream = $type_mapper->get_deserializer($parent_typeuri,
                                                         $parent_typename,
                                                         $resolver);
        }
        else {
            #
            # TBD: for an accessor, why would the Parser care about being notified
            #      when the object is unmarshaled? I can see the parent stream wanting
            #      to know (so it can add the object as an accessor). Exactly why do we
            #      pass $resolver as a parameter to compound_accessor???
            #
            my $resolver = 0;
            $new_stream = $self->_soap_stream()->compound_accessor($parent_accessor_uri,
                                                                   $parent_accessor,
                                                                   $parent_typeuri,
                                                                   $parent_typename,
                                                                   $resolver);
            unless ($new_stream) { $self->_throw("Unexpected: compound_accessor failed to return a new stream") }
        }
        $self->_push_context($new_stream, $parser->depth(), $parent_is_package);

        #
        # remember important stuff about the new node
        #
        $self->_id        ($parent_id        );
        $self->_typeuri   ($parent_typeuri   );
        $self->_typename  ($parent_typename  );
    }

    $self->_parse_child_element_attrs($parser, \@_);

    $self->_child_accessor_uri($parser->namespace($element));
    $self->{text} = '';

    # TBD: how much checking do we want to do for invalid attribute combinations?
    #      (for instance, if xsi:null="1", then it doesn't make sense
    #       to also have an href attribute)
    if ($self->{is_null}) {
        $self->_push_handlers(Start => sub { $self->_null_on_start(@_) },
                              Char  => sub { $self->_null_on_char (@_) },
                              End   => sub { $self->_null_on_end  (@_) }
                              );
    }
    elsif (my $href = $self->{href}) {
        if (defined $self->_child_id()) { $self->_throw('SOAP elements cannot contain both href and id attributes') }

        my ($found_it, $result) = $self->_lookup_href($href);

        my $soap_stream = $self->_soap_stream();
        if ($found_it) {
            $soap_stream->reference_accessor($parser->namespace($element),
                                             $element,
                                             $result);
        }
        else {
            push @$result, $soap_stream->forward_reference_accessor($parser->namespace($element),
                                                                    $element);
        }
        $self->_push_handlers(Start => sub { $self->_ref_on_start(@_) },
                              Char  => sub { $self->_ref_on_char (@_) },
                              End   => sub { $self->_ref_on_end  (@_) }
                              );
    }
}

sub _generic_on_char {
    my ($self, $parser, $s) = @_;
    $self->{text} .= $s;
}

sub _generic_on_end {
    my ($self, $parser, $element) = @_;
    __diagnostic_leave_element($parser, $element);

    my $depth     = $parser->depth();
    my $ctx_depth = $self->_get_ctx_depth();

    if ($depth == $ctx_depth) {
        #
        # this is a simple accessor
        #
        $self->_soap_stream()->simple_accessor($parser->namespace($element),
                                               $element,
                                               $self->_child_typeuri(),
                                               $self->_child_typename(),
                                               $self->{text});
    }
    else {
        #
        # we just left the scope of the current compound accessor,
        # so we need to close the current marshaling scope
        #
	my $stream = $self->_soap_stream();
	my $text = $self->{text};
	$stream->content($text) if (length $text and $text =~ /\S/);
        $stream->term();
        $self->_pop_context();
    }
    $self->{text} = '';
    $self->_pop_handlers();
}

sub _ref_on_start {
    my $self = shift;
    $self->_throw('Elements with the href attribute cannot have child nodes');
}

sub _ref_on_char {
    my ($self, $parser, $s) = @_;

    $self->_complain_if_contains_non_whitespace($s);
}

sub _ref_on_end {
    my ($self, $parser, $element) = @_;
    __diagnostic_leave_element($parser, $element);

    $self->_pop_handlers();
}

sub _null_on_start {
    my $self = shift;
    $self->_throw('Elements with the xsi:null attribute cannot have child nodes');
}

sub _null_on_char {
    my $self = shift;
                                    # TBD: is this correct?
    $self->_throw('Elements with the xsi:null attribute must be empty of content');
}

sub _null_on_end {
    my ($self, $parser, $element) = @_;

    $self->_soap_stream()->reference_accessor($parser->namespace($element),
                                              $element,
                                              undef);
    $self->_pop_handlers();
}

sub _found_id {
    my ($self, $id, $object) = @_;

    my $package = $self->_get_package();
    my $slot;
    if (exists $package->{$id}) {
        $slot = $package->{$id};
        if (defined $slot->[$m_pkgslot_object]) { $self->_throw("Duplicate id: $id") }
        $slot->[$m_pkgslot_object] = $object;
        my $resolver_list = pop @$slot;
        foreach my $resolver (@$resolver_list) {
            $resolver->($object);
        }
    }
    else {
        $package->{$id} = [$object];
    }
}

sub _lookup_href {
    my ($self, $href) = @_;

    my $package = $self->_get_package();
    my $slot;
    if (exists $package->{$href}) {
        $slot = $package->{$href};
    }
    else {
        $slot = $package->{$href} = [undef, []];
    }

    if (defined $slot->[$m_pkgslot_object]) {
        (1, $slot->[$m_pkgslot_object]);
    }
    else {
        (0, $slot->[$m_pkgslot_resolver_list]);
    }
}

sub _verify_resolved_all_references {
    my ($self, $package) = @_;

    my @unresolved_refs;
    while (my ($id, $slot) = each %$package) {
        #
        # resolved slots will only have one entry - the object
        #
        if (1 != @$slot) {
            push @unresolved_refs, $id;
        }
    }
    if (@unresolved_refs) {
        my $ids = join ', ', @unresolved_refs;
        $self->_throw("Could not resolve the following references: $ids");
    }
}

sub _push_context {
    my ($self, $soap_stream, $depth, $create_new_package) = @_;

    my $package = $create_new_package ? {} : $self->_get_package();

    push @{$self->{context_stack}}, [
        $soap_stream,           # $m_ctx_soap_stream
        undef,                  # $m_ctx_id
        $create_new_package,    # $m_ctx_is_package
        undef,                  # $m_ctx_typeuri
        undef,                  # $m_ctx_typename
        undef,                  # $m_ctx_child_id
        undef,                  # $m_ctx_child_is_package
        undef,                  # $m_ctx_child_accessor_uri
        undef,                  # $m_ctx_child_typeuri
        undef,                  # $m_ctx_child_typename
        $depth,                 # $m_ctx_depth
        $package,               # $m_ctx_package
    ];
}

sub _pop_context {
    my ($self) = @_;

    if ($self->_is_package()) {
        $self->_verify_resolved_all_references($self->_get_package());
    }
    pop @{$self->{context_stack}};
}

sub _soap_stream {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_soap_stream, @_);
}

sub _id {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_id, @_);
}

sub _is_package {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_is_package, @_);
}

sub _typeuri {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_typeuri, @_);
}

sub _typename {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_typename, @_);
}

sub _child_id {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_child_id, @_);
}

sub _child_is_package {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_child_is_package, @_);
}

sub _child_accessor_uri {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_child_accessor_uri, @_);
}

sub _child_typeuri {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_child_typeuri, @_);
}

sub _child_typename {
    my $self = shift;
    $self->_set_or_get_context_item($m_ctx_child_typename, @_);
}

sub _get_ctx_depth {
    my ($self) = @_;
    $self->{context_stack}[-1][$m_ctx_depth];
}

sub _get_package {
    my ($self) = @_;
    $self->{context_stack}[-1][$m_ctx_package];
}

sub _set_or_get_context_item {
    my ($self, $index) = @_;
    return $self->{context_stack}[-1][$index] if (2 == @_);
    $self->{context_stack}[-1][$index] = $_[2];
}

sub _parse_child_element_attrs {
    my ($self, $parser, $attrs) = @_;

    $self->{href}           = undef;
    $self->{is_null}        = 0;
    $self->{root_with_id}   = 0;

    $self->_child_id(undef);
    $self->_child_is_package(0);
    $self->_child_typeuri(undef);
    $self->_child_typename(undef);

    for (my $i = 0; $i < @$attrs; $i += 2) {
        my $attr = $attrs->[$i];
        if (exists $g_attr_parse_table->{$attr}) {
            my ($ns, $method_suffix) = @{$g_attr_parse_table->{$attr}};
            if (defined $ns and $self->{has_namespaces}) {
                #
                # verify namespace
                #
                my $expected_qname = $parser->generate_ns_name($attr, $ns);

                #
                # this code assumes we're being called in the context of a start tag
                #
                next unless ($parser->eq_name($attr, $expected_qname));
            }
            my $method_name = '_parse_attr_' . $method_suffix;
            $self->$method_name($attrs->[$i+1]);
        }
    }
}

sub _parse_attr_id {
    my ($self, $value) = @_;

    $self->_child_id($value);
}

sub _parse_attr_href {
    my ($self, $value) = @_;

    unless ($value =~ s/^#(.+)/$1/) { $self->_throw('Badly formed href') }

    $self->{href} = $value;
}

sub _parse_attr_null {
    my ($self, $value) = @_;

    $self->{is_null} = $soap_true eq $value;
}

sub _parse_attr_package {
    my ($self, $value) = @_;

    $self->_child_is_package($soap_true eq $value);
}

sub _parse_attr_typename {
    my ($self, $value) = @_;

    my ($typeuri, $typename) = $self->_resolve_xsd_type($value);
    $self->_child_typeuri($typeuri);
    $self->_child_typename($typename);
}

sub _parse_attr_root_with_id {
    my ($self, $value) = @_;

    $self->{root_with_id} = $soap_true eq $value;
}

sub _resolve_xsd_type {
    my ($self, $typename) = @_;

    #
    # TBD: what if no namespace prefix appears? Do we use the default namespace?
    #
    my $parser = $self->{parser};
    my ($ns, $name);
    if ($typename =~ /([^:]+):(.+$)/) {
        my $ns_prefix = $1;
        $name = $2;
        $ns = $parser->expand_ns_prefix($ns_prefix);
    }
    unless (defined $ns) {
        $name = $typename;
        $ns = $parser->expand_ns_prefix('#default');
    }
    ($ns, $name);
}

sub _complain_if_contains_non_whitespace {
    my ($self, $text) = @_;

    if ($text =~ /\S/) { $self->_throw('Unexpected non-whitespace character') }
}

sub _verify_no_new_namespaces {
    my ($self, $parser) = @_;
    #
    # verify that nobody introduces any namespaces
    # if the root isn't namespace qualified
    #
    if (scalar $parser->new_ns_prefixes()) {
        $self->_throw('Unexpected namespace declaration');
    }
}

sub _verify_soap_namespace {
    my ($self, $parser, $element) = @_;
    my $ns = $parser->namespace($element);
    if ($self->{has_namespaces}) {
        if (!defined($ns) || ($soap_namespace ne $ns)) {
            $self->_throw("expected namespace $soap_namespace on element $element");
        }
    }
}

sub _create_parser {
    my ($self) = @_;
    $self->_assert(!$self->{parser});
    my $parser = XML::Parser::Expat->new(Namespaces => 1);
    $parser->setHandlers(Start => sub { $self->_bootstrapper_on_start(@_) } );
    $self->{parser} = $parser;
}

sub _add_header {
    my ($self, $typeuri, $typename, $object) = @_;
    my $headers = $self->{headers};
    push @$headers, { soap_typeuri  => $typeuri,
		      soap_typename => $typename,
		      content       => $object
                    };
}

sub _push_handlers {
    my $self = shift;
    $self->_assert(@_);
    my $parser        = $self->{parser};
    my $handler_stack = $self->{handler_stack};

    my $depth = $parser->depth();
    my @old_handlers = $parser->setHandlers(@_);
    push @$handler_stack, [$depth, \@old_handlers];
}

sub _pop_handlers {
    my $self = shift;
    my $parser        = $self->{parser};
    my $handler_stack = $self->{handler_stack};

    while(@$handler_stack)
    {
        my $top = $handler_stack->[-1];
    
        last unless ($top->[0] == $parser->depth());

        $parser->setHandlers(@{$top->[1]});
        pop @$handler_stack;
    }
}

sub _throw {
    my ($self, $msg) = @_;

    if (defined $self->{parser}) {
        $self->{parser}->xpcroak($msg);
    }
    else {
        die $msg;
    }
}

sub _assert {
    my ($self, $assertion, $msg) = @_;
    $msg ||= '';
    unless($assertion) { $self->_throw('ASSERTION FAILED. ' . $msg) }
}

sub __diagnostic_enter_element {
#    my ($parser, $element) = @_;
#    print ' ' x (2 * $parser->depth()), "<$element>\n";
}

sub __diagnostic_leave_element {
#    my ($parser, $element) = @_;
#    print ' ' x (2 * $parser->depth()), "</$element>\n";
}

1;

__END__

=head1 NAME

SOAP::Parser - Parses SOAP documents

=head1 SYNOPSIS

    use SOAP::Parser;
  
    my $parser = SOAP::Parser->new();

    $parser->parsefile('soap.xml');

    my $headers = $parser->get_headers();
    my $body    = $parser->get_body();

=head1 DESCRIPTION

SOAP::Parser has all the logic for traversing a SOAP packet, including
Envelope, Header, and Body, dealing with namespaces and tracking down
references. It is basically an extension of a SAX-like parser, which
means that it exposes an event-driven interface that you can implement
to get the results of the parse. By default, SOAP/Perl provides
SOAP::GenericInputStream to handle these events, which simply produces
an object graph of hash references. If you want something
different, on a per type URI basis, you can register alternate handlers
so you can produce different output. See SOAP::TypeMapper for details.

The handler needs to implement a set of methods, and these are outlined
in SOAP::GenericInputStream along with descriptions of what the default
behavior is (in other words, what SOAP::GenericInputStream does for each
of these methods).

The benefit of this design is that it avoids using a DOM to parse SOAP
packets; rather, the packet is unmarshaled directly into whatever final
form you need. This is more efficient in space and time than first unmarshaling
into a DOM and then traversing the DOM to create an object graph that is
meaningful to your program. To get the full benefit of this, you may need to
implement a handler that creates your custom object graph from the SOAP packet
(see SOAP::GenericInputStream for details). Since SOAP::Parser does all the
hard work, implementing a handler (or set of handlers) is really pretty
painless.

=head2 new(TypeMapper)

Creates a new parser. Be sure *not* to reuse a parser for multiple SOAP
packets - create one, use it, and then throw it away and get a new one if you
need to parse a second SOAP packet.

TypeMapper is an optional parameter that points to an instance of SOAP::TypeMapper
that allows you to register alternate serializers and deserializers for different
classes of objects. See the docs for that class for more details. If you don't
pass this parameter, the system uses a default TypeMapper object.

=head2 parsestring(String)

Parses the given string.

=head2 parsefile(Filename)

Parses the given file.

=head2 get_headers()

After parsing, this function returns the array of headers
in the SOAP envelope.

Specifically, this function returns an array reference that
contains zero or more hash references, each
of which always take the following form:

  {
    soap_typeuri  => 'namespace qualification of header',
    soap_typename => 'unqualified name of header',
    content       => <header object>
  }

For instance, the following header:

 <f:MyHeader xmlns:f="urn:foo">42 </f:MyHeader>

would be deserialized in this form:

  {
    soap_typeuri  => 'urn:foo',
    soap_typename => 'MyHeader',
    content       => 42,
  }
 
while this header:

 <f:MyHeader xmlns:f="urn:foo">
  <m1>something</m1>
  <m2>something else</m2>
 </f:MyHeader>

would be deserialized (by default) in this form:

  {
    soap_typeuri  => 'urn:foo',
    soap_typename => 'MyHeader',
    content       => {
        soap_typeuri  => 'urn:foo',
        soap_typename => 'MyHeader',
        m1 => 'something',
        m2 => 'something else',
    },
  }

Note the redundancy of the soap_typeuri and soap_typename isn't
strictly necessary in this case because this information is embedded
in the content itself. However, because of the potential (and common
need) for sending scalars as the entirety of the header content,
we need some way of communicating the namespace and typename of the
header. Thus the content, for consistency, is always packaged in
a hash along with explicit type information. 

=head2 get_body()

After parsing, this function retrieves the body of the SOAP envelope.

Since it doesn't make sense to send just a scalar as the body
of a SOAP request, we don't need the redundancy of packaging the content
inside of a hash along with its type and namespace (as was done above
with headers). For instance:


 <f:MyBody xmlns:f="urn:foo">
  <m1>something</m1>
  <m2>something else</m2>
 </f:MyBody>

would be deserialized (by default) as the following:

 {
   soap_typeuri  => 'urn:foo',
   soap_typename => 'MyBody',
   m1 => 'something',
   m2 => 'something else',
 }

=head1 DEPENDENCIES

XML::Parser::Expat
SOAP::GenericInputStream
SOAP::Defs

=head1 AUTHOR

Keith Brown

=head1 SEE ALSO

SOAP::GenericInputStream

=cut
