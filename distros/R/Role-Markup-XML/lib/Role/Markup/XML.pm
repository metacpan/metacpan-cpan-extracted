package Role::Markup::XML;

use 5.010;
use strict;
use warnings FATAL => 'all';

use Moo::Role;
use namespace::autoclean;

use XML::LibXML  ();
use Scalar::Util ();
use Carp         ();

use constant XHTMLNS => 'http://www.w3.org/1999/xhtml';

# XXX this is a shitty qname regex: no unicode but whatever
#use constant QNAME_RE =>
#    qr/^(?:([A-Za-z][0-9A-Za-z_-]*):)?([A-Za-z][0-9A-Za-z_-]*)$/;

use constant NCNAME_PAT => do {
    my $ns = '_A-Za-z\N{U+C0}-\N{U+D6}\N{U+D8}-\N{U+F6}\N{U+F8}-\N{U+2FF}' .
        '\N{U+370}-\N{U+37D}\N{U+37F}-\N{U+1FFF}\N{U+200C}-\N{U+200D}' .
            '\N{U+2070}-\N{U+218F}\N{U+2C00}-\N{U+2FEF}\N{U+3001}-\N{U+D7FF}' .
                '\N{U+F900}-\N{U+FDCF}\N{U+FDF0}-\N{U+FFFD}' .
                    '\N{U+10000}-\N{U+EFFFF}';
    my $nc = '0-9\N{U+B7}\N{U+300}-\N{U+36F}\N{U+203F}-\N{U+2040}-';
    sprintf '[%s][%s%s]*', $ns, $ns, $nc;
};

use constant NCNAME_RE => do {
    my $nc = NCNAME_PAT;
    qr/^($nc)$/o;
};

use constant QNAME_RE => do {
    my $nc = NCNAME_PAT;
    qr/^(?:($nc):)?($nc)$/o;
};

#STDERR->binmode('utf8');
#warn NCNAME_RE;


has _ATTRS => (
    is      => 'ro',
    isa     => sub { Carp::croak('Input must be a HASH reference')
          unless ref $_[0] eq 'HASH' },
    default => sub { { } },
);

has _ACTUAL_XPC => (
    is  => 'ro',
    default => sub {
        my $x = XML::LibXML::XPathContext->new;
        $x->registerNs(html => XHTMLNS);
        $x;
    },
);


=head1 NAME

Role::Markup::XML - Moo(se) role for bolt-on lazy XML markup

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

    package My::MarkupEnabled;

    use Moo;                  # or Moose, or something compatible
    with 'Role::Markup::XML'; # ...and this of course

    # write some other code...

    sub something_useful {
        my $self = shift;

        # put your XML-generating data structure here
        my %spec = (
            -name      => 'my:foo',              # element name
            -content   => { -name => 'my:bar' }, # element content
            hurr       => 'durr',                # attribute
            'my:derp'  => 'lulz',                # namespaced attribute
            'xmlns:my' => 'urn:x-bogus:foo',     # namespaces go inline
        );

        # create a document object to hang on to
        my $doc  = $self->_DOC;

        # returns the last node generated, which is <my:bar/>
        my $stub = $self->_XML(
            doc  => $doc,
            spec => \%spec,
        );

        my @contents = (
            # imagine a bunch of things in here
        );

        # since these nodes will be appended to $stub, we aren't
        # interested in the output this time
        $self->_XML(
            parent => $stub,          # owner document is derived
            spec   => \@contents,     # also accepts ARRAY refs
            args   => $self->cb_args, # some useful state data
        );

        # the rest of the ops come from XML::LibXML
        return $doc->toString(1);
    }

=head1 DESCRIPTION

This is indeed yet another module for lazy XML markup generation. It
exists because it is different:

=over 4

=item

It converses primarily in reusable, inspectable, and most importantly,
I<inert> Perl data structures,

=item

It also ingests existing L<XML::LibXML> nodes,

=item

It enables you to generate markup I<incrementally>, rather than all at
once,

=item

It Does the Right ThingE<0x2122> around a bunch of otherwise tedious
boilerplate operations, such as namespaces, XHTML, or flattening
token lists in attributes,

=item

It has a callback infrastructure to help you create modular templates,
or otherwise override behaviour you don't like,

=item

It is implemented as a Role, to be more conducive to modern Perl
development.

=back

I began by using L<XML::LibXML::LazyBuilder>. It is pretty good,
definitely preferable to typing out reams of L<XML::LibXML> DOM-like
API any time I wanted to make some (guaranteed well-formed) XML. I
even submitted a patch to it to make it better. Nevertheless, I have
reservations about the general approach to terse markup-generating
libraries, in particular about the profligate use of anonymous
subroutines. (You also see this in
L<lxml.etree|http://lxml.de/tutorial.html> for Python,
L<Builder::XmlMarkup|http://builder.rubyforge.org/classes/Builder/XmlMarkup.html>
for Ruby, etc.)

The main issue is that these languages aren't Lisp: it costs something
at runtime to gin up a stack of nested anonymous subroutines, run them
once, and then immediately throw them away. It likewise costs in
legibility to have to write a bunch of imperative code to do what is
essentially data declaration. It also costs in sanity to have to write
function-generating-function-generating functions just to get the mess
under control. What you get for your trouble is an interim product
that is impossible to inspect or manipulate. This ostensibly
time-saving pattern quickly hits a wall in both development, and at
runtime.

The answer? Use (in this case) Perl's elementary data structures to
convey the requisite information: data structures which can be built
up from bits and pieces, referenced multiple times, sliced, diced,
spliced, frozen, thawed, inspected, and otherwise operated on by
ordinary Perl routines. Provide mix-and-match capability with vanilla
L<XML::LibXML>, callbacks, and make the whole thing an unobtrusive
mix-in that you can bolt onto your existing code.

=head1 METHODS

Methods in this module are named such as to stay out of the way of
I<your> module's interface.

=head2 _DOC [$VERSION,] [$ENCODING]

Generate a document node. Shorthand for L<XML::LibXML::Document/new>.

=cut

sub _DOC {
    my (undef, $version, $encoding) = @_;
    $version  ||= '1.0';
    $encoding ||= 'utf-8';

    XML::LibXML::Document->new($version, $encoding);
}

=head2 _ELEM $TAG [, $DOC, \%NSMAP ]

Generate a single XML element. Generates a new document unless C<$DOC>
is specified. Defaults to XHTML if no namespace map is provided.

=cut

sub _ELEM {
    my ($self, $tag, $doc, $nsmap) = @_;
    my ($prefix, $local) = ($tag =~ QNAME_RE);
    $prefix ||= '';
    $doc    ||= $self->_DOC;

    my $ns = $nsmap && $nsmap->{$prefix} ? $nsmap->{$prefix} : XHTMLNS;

    my $elem = $doc->createElementNS($ns, $tag);
    for my $k (sort keys %$nsmap) {
        $elem->setNamespace($nsmap->{$k}, $k, $prefix eq $k);
    }

    # add boilerplate attributes (but only if we're an instance!)
    if (ref $self and my $a = $self->_ATTRS->{$tag}) {
        map { $elem->setAttribute($_ => $a->{$_}) } keys %$a;
    }

    $elem;
}

=head2 _XPC [ %NS | \%NS ]

Return an XPath context with the given (optional) namespaces
registered.The XHTML namespace is registered by default with the
prefix C<html>. This context will persist if called from an instance.

=cut

sub _XPC {
    my $self = shift;
    my %p = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    my $xpc;
    if (ref $self) {

        $xpc = $self->_ACTUAL_XPC;
    }
    else {
        # if calling from a class we'll just mint a new one
        $xpc = XML::LibXML::XPathContext->new;
        $p{html} ||= XHTMLNS;
    }

    map { $xpc->registerNs($_ => $p{$_}) } grep { defined $p{$_} } keys %p;

    $xpc;
}


=head2 _XML $SPEC [, $PARENT, $DOC, \@ARGS | @ARGS ] | %PARAMS

Generate an XML tree according to the L<specification
format|/Specification Format>. Returns the I<last node generated> by
the process. Parameters are as follows:

=over 4

=item spec

The node specification. Strictly speaking this is optional, but there
isn't much of a point of running this method if there is no spec to
run it over.

=item doc

The L<XML::LibXML::Document> object intended to own the
contents. Optional, however it is often desirable to supply a document
object along with the initial call to this method, so as not to have
to fish it out later.

=item parent

The L<XML::LibXML::Element> (or, redundantly, Document) object which
is intended to be the I<parent node> of the spec. Optional; defaults
to the document.

=item replace

Suppose we're doing surgery to an existing XML document. Instead of
supplying a L</parent>, we can supply a node in said document which we
want to I<replace>. Note that this parameter is incompatible with
L</parent>, is meaningless for some node types (e.g. C<-doctype>), and
may fail in some contexts (e.g. when the node to be replaced is the
document).

=item before, after

Why stop at replacing nodes? Sometimes we need to snuggle a new set of
nodes up to one side or the other of a sibling at the same level.
B<Will fail if the sibling node has no parent.> Will also fail if you
do things like try to add a second root element. Optional of course.
Once again, all these parameters, L</parent>, L</replace>, C<before>
and C<after>, are I<mutually conflicting>.

=item args

An C<ARRAY> reference of arguments to be passed into C<CODE>
references embedded in the spec. Optional.

=back

=head3 Specification Format

The building blocks of the spec are, unsurprisingly, C<HASH> and
C<ARRAY> references. The former correspond to elements and other
things, while the latter correspond to lists thereof. Literals become
text nodes, and blessed objects will be treated like strings, so it
helps if they have a string L<overload>. C<CODE> references may be
used just about anywhere, and will be dereferenced recursively using
the supplied L</args> until there is nothing left to dereference. It
is up to I<you> to keep these data structures free of cycles.

=over 4

=item Elements

Special keys designate the name and content of an element spec. These
are, unimaginitively, C<-name> and C<-content>. They work like so:

    { -name => 'body', -content => 'hurr' }

    # produces <body>hurr</body>

Note that C<-content> can take any primitive: literal, C<HASH>,
C<ARRAY> or C<CODE> reference, L<XML::LibXML::Node> object, etc.

=item Attributes

Any key is not C<-name> or C<-content> will be interpreted as an attribute.

    { -name => 'body', -content => 'hurr', class => 'lolwut' }

    # produces <body class="lolwut">hurr</body>

When references are values of attributes, they are flattened into strings:

    { -name => 'body', -content => 'hurr', class => [qw(one two three)] }

    # produces <body class="one two three">hurr</body>

=item Namespaces

If there is a colon in either the C<-name> key value or any of the
attribute keys, the processor will expect a namespace that corresponds
to that prefix. These are specified exactly as one would with ordinary
XML, with the use of an C<xmlns:foo> attribute>. (Prefix-free C<xmlns>
attributes likewise work as expected.)

    { -name => 'svg',
      xmlns => 'http://www.w3.org/2000/svg',
      'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
      -content => [
          { -name => 'a', 'xlink:href' => 'http://some.host/' },
      ],
    }

    # produces:
    # <svg xmlns="http://www.w3.org/2000/svg"
    #      xmlns:xlink="http://www.w3.org/1999/xlink">
    #   <a xlink:href="http://some.host/"/>
    # </svg>

=item Other Nodes

=over 4

=item C<-pi>

Processing instructions are designated by the special key C<-pi> and
accept arbitrary pseudo-attributes:

    { -pi => 'xml-stylesheet', type => 'text/xsl', href => '/my.xsl' }

    # produces <?xml-stylesheet type="text/xsl" href="/my.xsl"?>

=item C<-doctype>

Document type declarations are designated by the special key
C<-doctype> and accept values for the keys C<public> and C<system>:

    { -doctype => 'html' }

    # produces <!DOCTYPE html>

=item C<-comment>

Comments are designated by the special key C<-comment> and whatever is
in the value of that key:

    { -comment => 'hey you guyyyys' }

    # produces <!-- hey you guyyyys -->

=back

=item Callbacks

Just about any part of a markup spec can be replaced by a C<CODE>
reference, which can return any single value, including another
C<CODE> reference. These are called in the context of C<$self>, i.e.,
as if they were a method of the object that does the role. The
L</args> in the original method call form the subsequent input:

    sub callback {
        my ($self, @args) = @_;

        my %node = (-name => 'section', id => $self->generate_id);

        # ...do things to %node, presumably involving @args...

        return \%node;
    }

    sub make_xml {
        my $self = shift;

        my $doc = $self->_DOC;
        $self->_XML(
            doc  => $doc,
            spec => { -name => 'p', -content => \&callback },
        );

       return $doc;
    }

C<CODE> references can appear in attribute values as well.

=back

=cut

sub _flatten {
    my ($self, $spec, $args) = @_;
    if (my $ref = ref $spec) {
        if ($ref eq 'ARRAY') {
            return join ' ', grep { defined $_ }
                map { $self->_flatten($_, $args) } @$spec;
        }
        elsif ($ref eq 'HASH') {
            return join ' ',
                map { join ': ', $_, $self->_flatten($spec->{$_}, $args) }
                    grep { defined $spec->{$_} } sort keys %$spec;
        }
        elsif ($ref eq 'CODE') {
            return $self->_flatten($spec->($self, @$args), $args);
        }
        else {
            return "$spec";
        }
    }
    else {
        return $spec;
    }
}

# figure out if the child should be some kind of table tag based on the parent
sub _table_tag {
    my $parent = shift or return;

    my %is_tr = (thead => 1, tfoot => 1, tbody => 1);
    my %is_th = (thead => 1, tfoot => 1);

    if ($parent->nodeType == 1) {
        my $pln = $parent->localname;

        return 'tr' if $is_tr{$pln};

        if ($pln eq 'tr') {
            my $gp = $parent->parentNode;
            if ($gp and $gp->nodeType == 1) {
                return $is_th{$gp->localname} ? 'th' : 'td';
            }
        }
    }

    return;
}

sub _attach {
    my ($node, $parent) = @_;

    if ($node && $parent) {
        if ($parent->nodeType == 9 and $node->nodeType == 1) {
            $parent->setDocumentElement($node);
        }
        else {
            $parent->appendChild($node);
        }
    }
    $node;
}

sub _replace {
    my ($node, $target) = @_;

    if ($node && $target) {
        $target->replaceNode($node);
    }

    $node;
}

my %ADJ = (
    parent => sub {
        my ($node, $parent) = @_;
        if ($parent->nodeType == 9 and $node->nodeType == 1) {
            $parent->setDocumentElement($node);
        }
        else {
            $parent->appendChild($node);
        }

        $node;
    },
    before => sub {
        my ($node, $next) = @_;
        my $parent = $next->parentNode;
        $parent->insertBefore($node, $next);

        $node;
    },
    after => sub {
        my ($node, $prev) = @_;
        my $parent = $prev->parentNode;
        $parent->insertAfter($node, $prev);

        $node;
    },
    replace => sub {
        my ($node, $target) = @_;
        my $od = $target->ownerDocument;
        if ($target->isSameNode($od->documentElement)) {
            if ($node->nodeType == 1) {
                $od->removeChild($target);
                $od->setDocumentElement($node);
            }
            else {
                # this may not be an element
                $od->insertAfter($node, $target);
                $od->removeChild($target);
            }
        }
        else {
            $target->replaceNode($node);
        }

        $node;
    },
);

sub _ancestor_is {
    my ($node, $local, $ns) = @_;
    return unless $node->nodeType == 1;

    return 1 if $node->localName eq $local
        and (!defined($ns) or $node->namespaceURI eq $ns);

    my $parent = $node->parentNode;
    _ancestor_is($parent, $local, $ns) if $parent and $parent->nodeType == 1;
}

sub _XML {
    my $self = shift;
    my %p;
    if (ref $_[0]) {
        $p{spec} = $_[0];
        @p{qw(parent doc)} = @_[1,2];
        if (defined $_[3] and ref $_[3] eq 'ARRAY') {
            $p{args} = $_[3];
        }
        else {
            $p{args} = [@_[3..$#_]];
        }
    }
    else {
        %p = @_;
    }

    $p{args} ||= [];

    my $adj;
    for my $k (keys %ADJ) {
        if ($p{$k}) {
            Carp::croak('Conflicting adjacent nodes ' .
                            join ', ', sort grep { $p{$_} } keys %ADJ) if $adj;
            Carp::croak("$k must be an XML node")
                  unless _isa_really($p{$k}, 'XML::LibXML::Node');

            $adj = $k;
        }
    }

    if ($adj) {
        Carp::croak('Adjacent node must be attached to a document')
              unless $p{$adj}->ownerDocument;
        unless ($adj eq 'parent') {
            Carp::croak('Replace/prev/next node must have a parent node')
                  unless $p{parent} = $p{$adj}->parentNode;
        }

        $p{doc} ||= $p{$adj}->ownerDocument;
    }
    else {
        $p{$adj = 'parent'} = $p{doc} ||= $self->_DOC;
    }

    # $p{doc} ||= $p{parent} && $p{parent}->ownerDocument
    #     ? $p{parent}->ownerDocument : $self->_DOC;
    # $p{parent} ||= $p{doc}; # this might be problematic

    my $node;

    my $ref = ref($p{spec}) || '';
    if ($ref eq 'ARRAY') {
        my $par = $adj ne 'parent' ?
            $p{doc}->createDocumentFragment : $p{parent};

        # we add a _pseudo parent because it's the only way to
        # propagate things like the namespace
        my @out = map {
            $self->_XML(spec => $_, parent => $par, _pseudo => $p{parent},
                        doc  => $p{doc}, args => $p{args}) } @{$p{spec}};
        if (@out) {
            $ADJ{$adj}->($par, $p{$adj}) unless $adj eq 'parent';

            return wantarray ? @out : $out[-1];
        }
        return $p{$adj};
    }
    elsif ($ref eq 'CODE') {
        return $self->_XML(spec   => $p{spec}->($self, @{$p{args}}),
                           $adj   => $p{$adj},
                           doc    => $p{doc},
                           args   => $p{args});
    }
    elsif ($ref eq 'HASH') {
        # copy the spec so we don't screw it up
        my %spec = %{$p{spec}};

        if (my $c = $spec{'-comment'}) {
            $node = $p{doc}->createComment($self->_flatten($c, @{$p{args}}));

            return $ADJ{$adj}->($node, $p{$adj});
        }
        if (my $target = delete $spec{'-pi'}) {
            # take -content over content
            my $content = defined $spec{'-content'} ?
                delete $spec{'-content'} : delete $spec{content};
            my $data = join ' ', map {
                sprintf q{%s="%s"}, $_, $self->_flatten($spec{$_}, @{$p{args}})
            } sort keys %spec;

            $data .= ' ' .
                $self->_flatten($content, @{$p{args}}) if defined $content;

            $node = $p{doc}->createProcessingInstruction($target, $data);

            return $ADJ{$adj}->($node, $p{$adj});
        }
        elsif (my $dtd = $spec{'-doctype'} || $spec{'-dtd'}) {
            # in XML::LibXML::LazyBuilder i wrote that there is some
            # XS issue and these values have to be explicitly passed
            # in as undef.
            my $public = $spec{public};
            my $system = $spec{system};
            $node = $p{doc}->createExternalSubset
                ($dtd, $public || undef, $system || undef);
            _attach($node, $p{doc});
            return $node;
        }
        else {
            # check for specified tag
            my $tag = delete $spec{'-name'};

            my ($prefix, $local);
            if (defined $tag) {
                ($prefix, $local) = ($tag =~ QNAME_RE);
                Carp::croak("Cannot make use of tag $tag")
                      unless defined $local;
            }
            $prefix ||= '';

            # detect appropriate table tag
            unless ($tag ||= _table_tag($p{_pseudo} || $p{parent})) {
                my $is_head = _ancestor_is($p{_pseudo} || $p{parent}, 'head');
                # detect tag
                if (defined $spec{src}) {
                    $tag = $is_head ? 'script' : 'img';
                }
                elsif (defined $spec{href}) {
                    $tag = $is_head ? 'link' : 'a';
                }
                else {
                    $tag = $is_head ? 'meta' : 'span';
                }
            }

            # okay generate the node
            my %ns;

            if (my $nsuri =
                    ($p{_pseudo} || $p{parent})->lookupNamespaceURI($prefix)) {
                $ns{$prefix} = $nsuri;
            }

            for my $k (keys %spec) {
                next unless $k =~ /^xmlns(?::(.*))?/;
                my $prefix = $1 || '';

                my $v = delete $spec{$k};
                $v =~ s/^\s*(.*?)\s*$/$1/; # trim
                $ns{$prefix} = $v;
            }
            $node = $self->_ELEM($tag, $p{doc}, \%ns);
            $ADJ{$adj}->($node, $p{$adj});

            # now do the attributes
            for my $k (sort grep { $_ =~ QNAME_RE } keys %spec) {

                my $val = $self->_flatten($spec{$k}, $p{args});
                $node->setAttribute($k => $val) if (defined $val);
            }

            # special handler for explicit content
            my $content = delete $spec{'-content'};
            return $self->_XML(
                spec   => $content,
                parent => $node,
                doc    => $p{doc},
                args   => $p{args}
            ) if defined $content;
        }
    }
    elsif (Scalar::Util::blessed($p{spec})
          and $p{spec}->isa('XML::LibXML::Node')) {
        $node = $p{spec}->cloneNode(1);
        $ADJ{$adj}->($node, $p{$adj});
    }
    else {
        # spec is a text node, if defined
        if (defined $p{spec}) {
            $node = $p{doc}->createTextNode("$p{spec}");
            $ADJ{$adj}->($node, $p{$adj});
        }
    }

    $node;
}

=head2 _XHTML | %PARAMS

Generate an XHTML+RDFa stub. Return the C<E<lt>bodyE<gt>> and the
document when called in list context, otherwise return just the
C<E<lt>bodyE<gt>> in scalar context (which can be used in subsequent
calls to L</_XML>).

  my ($body, $doc) = $self->_XHTML(%p);

  # or

  my $body = $self->_XHTML(%p);

=head3 Parameters

=over 4

=item uri

The C<href> attribute of the C<E<lt>baseE<gt>> element.

=item ns

A mapping of namespace prefixes to URIs, which by default will appear
as I<both> XML namespaces I<and> the C<prefix> attribute.

=item prefix

Also a mapping of prefixes to URIs. If this is set rather than C<ns>,
then the XML namespaces will I<not> be set. Conversely, if this
parameter is defined but false, then I<only> the contents of C<ns>
will appear in the conventional C<xmlns:foo> way.

=item vocab

This will specify a default C<vocab> attribute in the
C<E<lt>htmlE<gt>> element, like L<http://www.w3.org/1999/xhtml/vocab/>.

=item title

This can either be a literal title string, or C<CODE> reference, or
C<HASH> reference assumed to encompass the whole C<E<lt>titleE<gt>>
element, or an C<ARRAY> reference where the first element is the title
and subsequent elements are predicates.

=item link

This can either be an C<ARRAY> reference of ordinary markup specs, or
a C<HASH> reference where the keys are the C<rel> attribute and the
values are one or more (via C<ARRAY> ref) URIs. In the latter form the
following behaviour holds:

=over 4

=item

Predicates are grouped by C<href>, folded, and sorted alphabetically.

=item

C<E<lt>linkE<gt>> elements are sorted first lexically by the sorted
C<rel>, then by sorted C<rev>, then by C<href>.

=item

A special empty C<""> hash key can be used to pass in another similar
structure whose keys represent C<rev>, or reverse predicates.

=item

A special C<-about> key can be used to specify another C<HASH>
reference where the keys are subjects and the values are similar
structures to the one described.

=back

  {
    # ordinary links
    'rel:prop' => [qw(urn:x-target:1 urn:x-target:2)],

    # special case for reverse links
    '' => { 'rev:prop' => 'urn:x-demo-subject:id' },

    # special case for alternate subject
    -about => {
      'urn:x-demo-subject:id' => { 'some:property' => 'urn:x-target' } },
  }

The C<ARRAY> reference form is passed along as-is.

=item meta

Behaves similarly to the C<link> parameter, with the following exceptions:

=over 4

=item

No C<""> or C<-about> pseudo-keys, as they are meaningless for
literals.

=item

Literal values can be expressed as an C<ARRAY> reference of the form
C<[$val, $lang, $type]> with either the second or third element
C<undef>. They may also be represented as a C<HASH> reference where
the keys are the language (denoted by a leading C<@>) or datatype
(everything else), and the values are the literal values.

=back

  {
    'prop:id' => ['foo', [2.3, undef, 'xsd:decimal']],
    'exotic'  => { '@en' => ['yo dawg', 'derp'] }
  }

=item head

This is an optional C<ARRAY> reference of C<<headE<gt>> elements that
are neither C<<linkE<gt>> nor C<<metaE<gt>> (or, if you want,
additional unmolested C<<linkE<gt>> and C<<metaE<gt>> elements).

=item attr

These attributes (including C<-content>) will be passed into the
C<<bodyE<gt>> element.

=item content

This parameter enables us to isolate the C<<bodyE<gt>> content without
additional attributes.

Note that setting this parameter will cause the method to return the
innermost, last node that is specified, rather than the C<<bodyE<gt>>.

=item transform

This is the URI of a (e.g. XSLT) transform which will be included in a
processing instruction if supplied.

=item args

Same as C<args> in L</_XML>.

=back

=cut

sub _sort_links {
    # first test is about
    #warn Data::Dumper::Dumper(\@_);
    my @a  = map { defined $_->{about} ? $_->{about} : '' } @_;
    my $t1 = $a[0] cmp $a[1];
    return $t1 if $t1;

    # then rel
    my @rl = map { defined $_->{rel} ? $_->{rel} : '' } @_;
    my $t2 = $rl[0] cmp $rl[1];
    return $t2 if $t2;

    # then rev
    my @rv = map { defined $_->{rev} ? $_->{rev} : '' } @_;
    my $t3 = $rv[0] cmp $rv[1];
    return $t3 if $t3;

    # then finally href
    my @h  = map { defined $_->{href} ? $_->{href} : '' } @_;
    return $h[0] cmp $h[1];
}

sub _handle_links {
    my ($links, $uri) = @_;
    $links ||= [];
    return @$links if ref $links eq 'ARRAY';
    Carp::croak('links must be ARRAY or HASH ref') unless ref $links eq 'HASH';

    my %l = %$links;
    my %r = %{delete $l{''} || {}};
    my %s = %{delete $l{-about} || {}};


    # merge subjects; blank subject is document
    %{$s{''} ||= {}} = (%{$s{''} || {}}, %l);

    my (%types, %titles); # map URIs to types and titles

    # accumulate predicates into a hierarchical structure of S -> O -> P
    my (%fwd, %rev);
    for my $s (keys %s) {
        for my $p (keys %{$s{$s}}) {
            my @o = ref $s{$s}{$p} eq 'ARRAY' ? @{$s{$s}{$p}} : ($s{$s}{$p});
            for my $o (@o) {
                my ($href, $type, $title) = ref $o eq 'ARRAY' ? @$o : ($o);
                # XXX do a better uri match
                $href = '' if $uri and $href eq $uri;
                # XXX this overwrites titles oh well suck one
                $types{$href}  = $type;
                $titles{$href} = $title;

                # accumulate the predicates
                my $x = $fwd{$s}    ||= {};
                my $y = $rev{$href} ||= {};
                my $z = $x->{$href} ||= $y->{$s} ||= {};
                $z->{$p}++;
            }
        }
    }

    # now do reverse links
    for my $p (keys %r) {
        my @o = ref $r{$p} eq 'ARRAY' ? @{$r{$p}} : ($r{$p});

        for my $o (@o) {
            # we skip type and title because the link is reversed
            my ($s) = ref $o eq 'ARRAY' ? @$o : ($o);
            # XXX do a better uri match
            $s = '' if $uri and $s eq $uri;
            my $x = $fwd{$s} ||= {};
            my $y = $rev{''} ||= {};
            my $z = $x->{''} ||= $y->{$s} ||= {};
            $z->{$p}++;
        }
    }

    # now we have accumulated all the predicates and aimed all the
    # triples in the forward direction. now to construct the list.

    my (%fout, %rout, @out);

    # begin by making sure typed links point forward
    for my $o (keys %types) {
        for my $s (keys %{$rev{$o}}) {
            $fout{$s} ||= {};
            $rout{$o} ||= {};

            my $x = $fout{$s}{$o};
            unless ($x) {
                $x = $fout{$s}{$o} = $rout{$o}{$s} = { href => $o,
                                                       type => $types{$o} };
                $x->{about} = $s if $s ne '';
                push @out, $x;
            }

            $x->{type} = $types{$o};
        }
    }

    # now do the same with titles
    for my $o (keys %titles) {
        for my $s (keys %{$rev{$o}}) {
            $fout{$s} ||= {};
            $rout{$o} ||= {};

            my $x = $fout{$s}{$o};
            unless ($x) {
                $x = $fout{$s}{$o} = $rout{$o}{$s} = { href => $o,
                                                       title => $titles{$o} };
                $x->{about} = $s if $s ne '';
                push @out, $x;
            }

            $x->{title} = $titles{$o};
        }
    }

    # now we make sure blank subjects always face forward
    if ($fwd{''}) {
        for my $o (sort keys %{$fwd{''}}) {
            $fout{''} ||= {};
            $rout{$o} ||= {};

            my $x = $fout{''}{$o};
            unless ($x) {
                $x = $fout{''}{$o} = $rout{$o}{''} = { href => $o };
                push @out, $x;
            }
        }
    }

    # now do forward predicates (this mapping is symmetric)
    for my $s (sort keys %fwd) {
        for my $o (sort keys %{$fwd{$s}}) {
            $fout{$s} ||= {};
            $rout{$o} ||= {};

            # collate up the predicates
            my $p = join ' ', sort keys %{$fwd{$s}{$o}};

            # first try forward
            my $x = $fout{$s}{$o};
            if ($x) {
                # set the link direction based on derp 
                $x->{$x->{href} eq $o ? 'rel' : 'rev'} = $p;
                # make sure rel exists
                $x->{rel} = '' unless defined $x->{rel};
            }
            else {
                # then try backward
                $x = $rout{$s}{$o};
                if ($x) {
                    # do the same thing but the other way around
                    $x->{$x->{href} eq $o ? 'rel' : 'rev' } = $p;
                    # and make sure rel exists
                    $x->{rel} = '' unless defined $x->{rel};
                }
                else {
                    # now just construct the thing
                    $x = $fout{$s}{$o} = $rout{$o}{$s} = {
                        href => $o, rel => $p };
                    $x->{about} = $s if $s ne '';
                    push @out, $x;
                }
            }
        }
    }

    #warn Data::Dumper::Dumper(\%fwd);

    # XXX LOLWUT this shit reuses @_ from *this* function
    return sort { _sort_links($a, $b) } @out;
}

sub _sort_meta {
    # first test property
    my @p = map { defined $_->{property} ? $_->{property} : '' } @_;
    my $t1 = $p[0] cmp $p[1];
    return $t1 if $t1;

    # next test language
    my @l = map { defined $_->{'xml:lang'} ? $_->{'xml:lang'} : '' } @_;
    my $t2 =  $l[0] cmp $l[1];
    return $t2 if $t2;

    # next test datatype
    my @d = map { defined $_->{'datatype'} ? $_->{'datatype'} : '' } @_;
    my $t3 = $d[0] cmp $d[1];
    return $t3 if $t3;

    # finally test content
    my @c = map { defined $_->{'content'} ? $_->{'content'} : '' } @_;
    # TODO numeric comparison for appropriate datatypes
    return $d[0] cmp $d[1];
}

sub _handle_metas {
    my $metas = shift || [];
    return @$metas if ref $metas eq 'ARRAY';
    Carp::croak('meta must be ARRAY or HASH ref') unless ref $metas eq 'HASH';

    my %m = %$metas;
    my %c;
    while (my ($k, $v) = each %m) {
        my $rv = ref $v;

        # normalize the input into something we can use
        my @v;
        if ($rv eq 'HASH') {
            # keys are lang/datatype
            for my $dt (keys %$v) {
                my $y = $v->{$dt};
                my @z = ref $y eq 'ARRAY' ? @$y : ($y);
                my $l = $dt if $dt =~ /^@/;
                undef $dt if $l;
                map { push @v, [$_, $l, $dt] } @z;
            }
        }
        else {
            @v = $rv eq 'ARRAY' ? @$v : ($v);
        }

        # now we turn the thing inside out
        for my $val (@v) {
            my ($x, $l, $dt) = ref $val eq 'ARRAY' ? @$val : ($val);
            next unless defined $x;

            # language becomes datatype if it is set
            if (defined $l and $l ne '') {
                $l  = "\@$l" unless $l =~ /^@/;
                $dt = $l;
            }
            #$dt ||= '';

            # now we create the structure
            my $y = $c{$v}    ||= {};
            my $z = $y->{$dt || ''} ||= {};
            $z->{$k}++;
        }
    }

    # now we have meta sorted by content
    my @out;
    for my $content (keys %c) {
        while (my ($dt, $preds) = each %{$c{$content}}) {
            my %meta = (content => $content,
                        property => join ' ', sort keys %$preds);
            if ($dt =~ /^@(.+)/) {
                $meta{'xml:lang'} = lc $1;
            }
            else {
                $meta{datatype} = $dt unless $dt eq '';
            }
            push @out, \%meta;
        }
    }
    return sort { _sort_meta($a, $b) } @out;
}

sub _handle_title {
    my $title = shift;
    my $tr    = ref $title;
    # this is a title tag but let's make sure
    return (%$title, -name => 'title') if $tr eq 'HASH';

    # this is a title tag with shorthand for predicate(s)
    if ($tr eq 'ARRAY') {
        my ($t, @p) = @{$title};
        my ($dt, $l);
        ($t, $dt, $l) = @$t if ref $t eq 'ARRAY';
        return (-name => 'title', -content => $t,
                property => join(' ', sort @p), datatype => $dt, lang => $l);
    }

    # this is anything else
    return (-name => 'title', -content => $title);
}

sub _isa_really {
    my ($obj, $class) = @_;

    defined $obj and ref $obj
        and Scalar::Util::blessed($obj) and $obj->isa($class);
}

sub _strip_ns {
    my $ns = shift;
    if (_isa_really($ns, 'URI::NamespaceMap')) {
        return { map +($_ => $ns->namespace_uri($_)->as_string),
                 $ns->list_prefixes };
    }
    elsif (_isa_really($ns, 'RDF::Trine::NamespaceMap')) {
        return { map +($_, $ns->namespace_uri($_)->uri_value->uri_value),
                 $ns->list_prefixes };
    }
    else {
        return $ns;
    }
}

sub _XHTML {
    my $self = shift;
    my %p = @_;

    # ns is empty if prefix has stuff in it
    my $nstemp = _strip_ns($p{ns} || {});
    my %ns = map +("xmlns:$_" => $nstemp->{$_}), keys %{$nstemp || {}}
        unless $p{prefix};

    # deal with fancy metadata
    my @link = _handle_links($p{link}, $p{uri});
    my @meta = _handle_metas($p{meta});
    my @head = @{$p{head} || []};

    # deal with title
    my %title = _handle_title($p{title});
    # deal with base
    my $base  = { -name => 'base', href => $p{uri} } if defined $p{uri};

    # deal with body
    my %body = (-name => 'body', %{$p{attr} || {}});
    $body{-content} = $p{content} if defined $p{content};

    my @spec = (
        { -doctype => 'html' },
        { -name => 'html', xmlns => XHTMLNS, %ns,
          -content => [
              { -name => 'head',
                -content => [\%title, $base, @link, @meta, @head] }, \%body ] }
    );

    # prefix is empty if it is defined but false, otherwise overrides ns
    my $pfxtemp = _strip_ns($p{prefix}) if $p{prefix};
    $spec[1]{prefix} = $pfxtemp ? $pfxtemp : defined $pfxtemp ? {} : $nstemp;

    # add a default vocab too
    $spec[1]{vocab} = $p{vocab} if $p{vocab};

    # add transform if present
    unshift @spec, { -pi => 'xml-stylesheet', type => 'text/xsl',
                     href => $p{transform} } if $p{transform};

    my $doc = $p{doc} || $self->_DOC;
    my $body = $self->_XML(
        doc  => $doc,
        spec => \@spec,
        args => $p{args} || [],
    );

    return wantarray ? ($body, $doc) : $body;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-role-markup-xml at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Role-Markup-XML>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Role::Markup::XML

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Role-Markup-XML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Role-Markup-XML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Role-Markup-XML>

=item * Search CPAN

L<http://search.cpan.org/dist/Role-Markup-XML/>

=back

=head1 SEE ALSO

=over 4

=item

L<XML::LibXML::LazyBuilder>

=item

L<XML::LibXML>

=item

L<Moo>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Role::Markup::XML
